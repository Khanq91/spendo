import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/notice/notice.dart';
import '../../../../shared/widgets/spendo/spendo.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../transactions/presentation/widgets/amount_input_controller.dart';
import '../../domain/recurring_reminder.dart';
import '../providers/reminder_provider.dart';

/// Opens the reminder form. The single place the sheet is presented.
Future<void> showReminderFormSheet(
  BuildContext context, {
  RecurringReminder? existing,
  ReminderPreset? preset,
  String? preselectedCategoryId,
  String? prefillTitle,
  int? prefillAmount,
}) {
  return SpendoSheet.showModal<void>(
    context: context,
    builder: (_) => ReminderFormSheet(
      existing: existing,
      preset: preset,
      preselectedCategoryId: preselectedCategoryId,
      prefillTitle: prefillTitle,
      prefillAmount: prefillAmount,
    ),
  );
}

/// How far ahead the "sắp hết" nudge fires. `0` turns it off.
///
/// The model has carried `warnBeforeHours` and the presets have set it all
/// along, but the form had no control for it, so every preset's value was
/// dropped on the way in (`19-reminder-form-sheet.md` §F).
enum WarnBefore {
  off(0, 'Tắt'),
  sixHours(6, '6 giờ'),
  oneDay(24, '1 ngày'),
  twoDays(48, '2 ngày');

  const WarnBefore(this.hours, this.label);

  final int hours;
  final String label;

  /// The option [hours] falls into, rounding down to what the form can show.
  static WarnBefore nearest(int hours) {
    if (hours <= 0) return WarnBefore.off;
    return WarnBefore.values.lastWhere(
      (option) => option.hours <= hours,
      orElse: () => WarnBefore.sixHours,
    );
  }
}

/// Screen 16 of the redesign.
class ReminderFormSheet extends ConsumerStatefulWidget {
  const ReminderFormSheet({
    super.key,
    this.existing,
    this.preset,
    this.preselectedCategoryId,
    this.prefillTitle,
    this.prefillAmount,
  });

  final RecurringReminder? existing;
  final ReminderPreset? preset;

  /// Pre-selected category, used when creating from a habit suggestion.
  final String? preselectedCategoryId;

  /// Seeds the title when the sheet is opened from a transaction in progress
  /// ("Lặp lại" in the add sheet), so the user does not retype what they just
  /// entered.
  final String? prefillTitle;

  /// Seeds the estimated amount, same origin as [prefillTitle].
  final int? prefillAmount;

  @override
  ConsumerState<ReminderFormSheet> createState() => _ReminderFormSheetState();
}

class _ReminderFormSheetState extends ConsumerState<ReminderFormSheet> {
  final _titleCtrl = TextEditingController();
  final _titleFocus = FocusNode();
  final _amountCtrl = AmountInputController();

  late ReminderFrequency _frequency;
  late int _hour;
  late int _minute;
  late int _dayOfWeek;
  late int _dayOfMonth;
  late WarnBefore _warnBefore;
  String? _categoryId;
  bool _saving = false;
  String? _titleError;

  /// True while the keypad is driving the amount instead of the fields.
  bool _editingAmount = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final preset = widget.preset;

    if (existing != null) {
      _titleCtrl.text = existing.title;
      if (existing.amountHint != null && existing.amountHint! > 0) {
        _amountCtrl.prefill(existing.amountHint.toString());
      }
      _frequency = existing.frequency;
      _hour = existing.hour;
      _minute = existing.minute;
      _dayOfWeek = existing.dayOfWeek ?? 1;
      _dayOfMonth = existing.dayOfMonth ?? 1;
      _warnBefore = WarnBefore.nearest(existing.warnBeforeHours);
      _categoryId = existing.categoryId;
    } else {
      _frequency = preset?.frequency ?? ReminderFrequency.monthly;
      _titleCtrl.text = widget.prefillTitle ?? preset?.title ?? '';
      final amount = widget.prefillAmount ?? preset?.suggestedAmount;
      if (amount != null && amount > 0) _amountCtrl.prefill(amount.toString());
      _hour = 20;
      _minute = 0;
      _dayOfWeek = 1;
      _dayOfMonth = 1;
      _warnBefore = WarnBefore.nearest(preset?.defaultWarnBeforeHours ?? 0);
      _categoryId = widget.preselectedCategoryId;
    }
    _titleCtrl.addListener(_clearTitleError);
  }

  void _clearTitleError() {
    if (_titleError != null && _titleCtrl.text.trim().isNotEmpty) {
      setState(() => _titleError = null);
    }
  }

  @override
  void dispose() {
    _titleCtrl.removeListener(_clearTitleError);
    _titleCtrl.dispose();
    _titleFocus.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
    );
    if (picked != null) {
      setState(() {
        _hour = picked.hour;
        _minute = picked.minute;
      });
    }
  }

  Future<void> _pickDayOfMonth() async {
    final picked = await SpendoSheet.showModal<int>(
      context: context,
      builder: (_) => _DayOfMonthSheet(selected: _dayOfMonth),
    );
    if (picked != null) setState(() => _dayOfMonth = picked);
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Đặt tên cho nhắc nhở này');
      _titleFocus.requestFocus();
      return;
    }
    final categoryId = _categoryId;
    if (categoryId == null) return;

    setState(() => _saving = true);
    final navigator = Navigator.of(context);

    try {
      final actions = ref.read(reminderActionsProvider);
      final reminder = RecurringReminder(
        id: widget.existing?.id ?? '',
        title: title,
        categoryId: categoryId,
        amountHint: _amountCtrl.hasValue ? _amountCtrl.value : null,
        frequency: _frequency,
        dayOfWeek: _frequency == ReminderFrequency.weekly ? _dayOfWeek : null,
        dayOfMonth: _frequency == ReminderFrequency.monthly
            ? _dayOfMonth
            : null,
        hour: _hour,
        minute: _minute,
        isActive: widget.existing?.isActive ?? true,
        warnBeforeHours: _warnBefore.hours,
        nextTrigger: RecurringReminder.calcNextTrigger(
          frequency: _frequency,
          hour: _hour,
          minute: _minute,
          dayOfWeek: _dayOfWeek,
          dayOfMonth: _dayOfMonth,
        ),
      );

      if (_isEdit) {
        await actions.update(reminder);
      } else {
        await actions.add(reminder);
      }
      navigator.pop();
    } catch (_) {
      // The old form let a failure escape unhandled and left `_loading` stuck.
      if (!mounted) return;
      setState(() => _saving = false);
      AppNotice.error('Không lưu được nhắc nhở. Thử lại.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(expenseCategoriesProvider);

    // Fall back to the preset's icon, then to the first category, so the sheet
    // always opens with a valid selection.
    if (_categoryId == null && categories.isNotEmpty) {
      final preset = widget.preset;
      final byIcon = preset == null
          ? null
          : categories.where((c) => c.iconName == preset.iconName).firstOrNull;
      _categoryId = (byIcon ?? categories.first).id;
    }

    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return SpendoSheet(
      header: SpendoSheetHeader(
        title: _isEdit ? 'Sửa nhắc nhở' : 'Thêm nhắc nhở',
        onCancel: () => Navigator.of(context).pop(),
        action: SpendoButton(
          label: 'Lưu',
          busy: _saving,
          onPressed: _submit,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 8),
              children: [
                TextField(
                  controller: _titleCtrl,
                  focusNode: _titleFocus,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Tên',
                    hintText: 'Tiền điện, Dầu gội…',
                    errorText: _titleError,
                  ),
                ),
                const SpendoSectionHeader(
                  label: 'Danh mục',
                  padding: _labelPad,
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final category in categories)
                      SpendoChip(
                        label: category.name,
                        selected: category.id == _categoryId,
                        leading: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: category.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        onTap: () =>
                            setState(() => _categoryId = category.id),
                      ),
                  ],
                ),
                const SpendoSectionHeader(
                  label: 'Số tiền gợi ý (tuỳ chọn)',
                  padding: _labelPad,
                ),
                // The amount used to run through the system keyboard with no
                // thousands separators, while every other money field in the
                // app used the keypad.
                _AmountField(
                  controller: _amountCtrl,
                  active: _editingAmount,
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    setState(() => _editingAmount = true);
                  },
                ),
                const SpendoSectionHeader(
                  label: 'Tần suất',
                  padding: _labelPad,
                ),
                SpendoSegmented<ReminderFrequency>(
                  value: _frequency,
                  onChanged: (next) => setState(() => _frequency = next),
                  expand: true,
                  height: 34,
                  horizontalPadding: 8,
                  options: [
                    for (final value in ReminderFrequency.values)
                      (value: value, label: value.frequencyLabel),
                  ],
                ),
                if (_frequency == ReminderFrequency.weekly) ...[
                  const SizedBox(height: 12),
                  _WeekdayRow(
                    value: _dayOfWeek,
                    onChanged: (next) => setState(() => _dayOfWeek = next),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (_frequency == ReminderFrequency.monthly) ...[
                      Expanded(
                        child: _ValueField(
                          label: 'Ngày trong tháng',
                          value: 'Ngày $_dayOfMonth',
                          icon: LucideIcons.chevronDown,
                          onTap: _pickDayOfMonth,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: _ValueField(
                        label: 'Giờ nhắc',
                        value:
                            '${_hour.toString().padLeft(2, '0')}:'
                            '${_minute.toString().padLeft(2, '0')}',
                        icon: LucideIcons.clock,
                        onTap: _pickTime,
                      ),
                    ),
                  ],
                ),
                const SpendoSectionHeader(
                  label: 'Nhắc trước',
                  padding: _labelPad,
                ),
                SpendoSegmented<WarnBefore>(
                  value: _warnBefore,
                  onChanged: (next) => setState(() => _warnBefore = next),
                  expand: true,
                  height: 32,
                  horizontalPadding: 8,
                  options: [
                    for (final value in WarnBefore.values)
                      (value: value, label: value.label),
                  ],
                ),
                const SizedBox(height: 14),
                _Summary(
                  title: _titleCtrl.text.trim(),
                  amount: _amountCtrl.hasValue ? _amountCtrl.value : null,
                  frequency: _frequency,
                  dayOfWeek: _dayOfWeek,
                  dayOfMonth: _dayOfMonth,
                  hour: _hour,
                  minute: _minute,
                  warnBefore: _warnBefore,
                ),
              ],
            ),
          ),
          if (_editingAmount && !keyboardOpen)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  ListenableBuilder(
                    listenable: _amountCtrl,
                    builder: (_, __) => SpendoNumpad(
                      onKey: _amountCtrl.press,
                      onLongPressDelete: _amountCtrl.reset,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SpendoButton.outline(
                    label: 'Xong',
                    onPressed: () => setState(() => _editingAmount = false),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

const _labelPad = EdgeInsets.only(top: 14, bottom: 8);

// ── Fields ───────────────────────────────────────────────────────────────────

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.active,
    required this.onTap,
  });

  final AmountInputController controller;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: active ? Border.all(color: cs.primary, width: 1.5) : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: ListenableBuilder(
                listenable: controller,
                builder: (_, __) => Text(
                  '${controller.formatted} ₫',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            Icon(
              LucideIcons.calculator,
              size: 18,
              color: active ? cs.primary : cs.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Label above a tappable value, matching the mockup's paired fields.
class _ValueField extends StatelessWidget {
  const _ValueField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(icon, size: 16, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  static const _labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  Widget build(BuildContext context) {
    return SpendoSegmented<int>(
      value: value,
      onChanged: onChanged,
      expand: true,
      height: 32,
      horizontalPadding: 2,
      options: [
        for (var i = 0; i < _labels.length; i++)
          (value: i + 1, label: _labels[i]),
      ],
    );
  }
}

/// Days 1–28, so a reminder never lands on a date some months lack.
class _DayOfMonthSheet extends StatelessWidget {
  const _DayOfMonthSheet({required this.selected});

  final int selected;

  @override
  Widget build(BuildContext context) {
    return SpendoSheet(
      header: const SpendoSheetHeader(title: 'Ngày trong tháng'),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.45,
        ),
        child: GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          children: [
            for (var day = 1; day <= 28; day++)
              _DayCell(day: day, selected: day == selected),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.selected});

  final int day;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: selected ? cs.primaryContainer : cs.surfaceContainer,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(day),
        child: Center(
          child: Text(
            '$day',
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected ? cs.onPrimaryContainer : cs.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}

/// Plain-language read-back of what the form will schedule.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.title,
    required this.amount,
    required this.frequency,
    required this.dayOfWeek,
    required this.dayOfMonth,
    required this.hour,
    required this.minute,
    required this.warnBefore,
  });

  final String title;
  final int? amount;
  final ReminderFrequency frequency;
  final int dayOfWeek;
  final int dayOfMonth;
  final int hour;
  final int minute;
  final WarnBefore warnBefore;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final time =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    final when = switch (frequency) {
      ReminderFrequency.daily => 'mỗi ngày',
      ReminderFrequency.weekly => 'mỗi ${_weekdayName(dayOfWeek)}',
      ReminderFrequency.monthly => 'ngày $dayOfMonth hàng tháng',
    };
    final name = title.isEmpty ? 'Nhắc nhở' : title;
    final money = amount == null || amount == 0
        ? ''
        : ' ~${formatVND(amount!)}';
    final warn = warnBefore == WarnBefore.off
        ? ''
        : ', báo trước ${warnBefore.label.toLowerCase()}';

    return SpendoCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(LucideIcons.bell, size: 16, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Nhắc "$name$money" $when lúc $time$warn.',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _weekdayName(int day) => const [
  '',
  'Thứ 2',
  'Thứ 3',
  'Thứ 4',
  'Thứ 5',
  'Thứ 6',
  'Thứ 7',
  'Chủ nhật',
][day.clamp(1, 7)];
