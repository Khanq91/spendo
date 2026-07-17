import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../domain/recurring_reminder.dart';
import '../providers/reminder_provider.dart';

class ReminderFormSheet extends ConsumerStatefulWidget {
  final RecurringReminder? existing;
  final ReminderPreset? preset;

  /// Category ID pre-selected (dùng khi tạo từ habit suggestion)
  final String? preselectedCategoryId;

  const ReminderFormSheet({
    super.key,
    this.existing,
    this.preset,
    this.preselectedCategoryId,
  });

  @override
  ConsumerState<ReminderFormSheet> createState() => _ReminderFormSheetState();
}

class _ReminderFormSheetState extends ConsumerState<ReminderFormSheet> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  late ReminderFrequency _frequency;
  late int _hour;
  late int _minute;
  late int _dayOfWeek;
  late int _dayOfMonth;
  String? _categoryId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final p = widget.preset;

    if (e != null) {
      _titleCtrl.text = e.title;
      _amountCtrl.text = e.amountHint?.toString() ?? '';
      _frequency = e.frequency;
      _hour = e.hour;
      _minute = e.minute;
      _dayOfWeek = e.dayOfWeek ?? 1;
      _dayOfMonth = e.dayOfMonth ?? 1;
      _categoryId = e.categoryId;
    } else {
      _frequency = p?.frequency ?? ReminderFrequency.monthly;
      _titleCtrl.text = p?.title ?? '';
      _amountCtrl.text = p?.suggestedAmount?.toString() ?? '';
      _hour = 20;
      _minute = 0;
      _dayOfWeek = 1;
      _dayOfMonth = 1;
      // Ưu tiên preselectedCategoryId (từ habit suggestion)
      _categoryId = widget.preselectedCategoryId;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.existing != null;

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty || _categoryId == null) return;

    setState(() => _loading = true);
    try {
      final actions = ref.read(reminderActionsProvider);
      final nextTrigger = RecurringReminder.calcNextTrigger(
        frequency: _frequency,
        hour: _hour,
        minute: _minute,
        dayOfWeek: _dayOfWeek,
        dayOfMonth: _dayOfMonth,
      );
      final amountHint = int.tryParse(_amountCtrl.text.trim());

      if (_isEdit) {
        final updated = RecurringReminder(
          id: widget.existing!.id,
          title: title,
          categoryId: _categoryId!,
          amountHint: amountHint,
          frequency: _frequency,
          dayOfWeek: _frequency == ReminderFrequency.weekly ? _dayOfWeek : null,
          dayOfMonth:
              _frequency == ReminderFrequency.monthly ? _dayOfMonth : null,
          hour: _hour,
          minute: _minute,
          isActive: widget.existing!.isActive,
          nextTrigger: nextTrigger,
        );
        await actions.update(updated);
      } else {
        final r = RecurringReminder(
          id: '',
          title: title,
          categoryId: _categoryId!,
          amountHint: amountHint,
          frequency: _frequency,
          dayOfWeek: _frequency == ReminderFrequency.weekly ? _dayOfWeek : null,
          dayOfMonth:
              _frequency == ReminderFrequency.monthly ? _dayOfMonth : null,
          hour: _hour,
          minute: _minute,
          isActive: true,
          nextTrigger: nextTrigger,
        );
        await actions.add(r);
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final allCats = ref.watch(expenseCategoriesProvider);

    // Auto-select từ preset icon nếu chưa có category
    if (_categoryId == null && widget.preset != null && allCats.isNotEmpty) {
      final match =
          allCats
              .where((c) => c.iconName == widget.preset!.iconName)
              .firstOrNull;
      if (match != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _categoryId = match.id);
        });
      } else {
        _categoryId = allCats.first.id;
      }
    }

    // Fallback nếu không có preselectedCategoryId và không có preset
    if (_categoryId == null && allCats.isNotEmpty) {
      _categoryId = allCats.first.id;
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 12,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              _isEdit ? 'Chỉnh sửa nhắc nhở' : 'Thêm nhắc nhở',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _titleCtrl,
              autofocus: !_isEdit,
              decoration: InputDecoration(
                labelText: 'Tên (vd: Dầu gội, Tiền điện...)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Text(
              'Danh mục',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: allCats.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = allCats[i];
                  final selected = cat.id == _categoryId;
                  return GestureDetector(
                    onTap: () => setState(() => _categoryId = cat.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            selected
                                ? cat.color.withValues(alpha: 0.15)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? cat.color : cs.outlineVariant,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            categoryIcon(cat.iconName),
                            size: 14,
                            color: selected ? cat.color : cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: selected ? cat.color : cs.onSurfaceVariant,
                              fontWeight:
                                  selected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Số tiền gợi ý (tuỳ chọn)',
                suffixText: '₫',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Text(
              'Tần suất',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children:
                  ReminderFrequency.values.map((f) {
                    final selected = f == _frequency;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: f == ReminderFrequency.monthly ? 0 : 8,
                        ),
                        child: GestureDetector(
                          onTap: () => setState(() => _frequency = f),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color:
                                  selected
                                      ? cs.primary.withValues(alpha: 0.12)
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    selected ? cs.primary : cs.outlineVariant,
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              f.frequencyLabel,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    selected ? cs.primary : cs.onSurfaceVariant,
                                fontWeight:
                                    selected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 12),

            if (_frequency == ReminderFrequency.weekly) ...[
              Text(
                'Ngày trong tuần',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(7, (i) {
                  final dow = i + 1;
                  final label = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'][i];
                  final selected = dow == _dayOfWeek;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _dayOfWeek = dow),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: selected ? cs.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: selected ? cs.primary : cs.outlineVariant,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                selected ? cs.onPrimary : cs.onSurfaceVariant,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
            ],

            if (_frequency == ReminderFrequency.monthly) ...[
              Text(
                'Ngày trong tháng',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _dayOfMonth,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items:
                    List.generate(28, (i) => i + 1)
                        .map(
                          (d) => DropdownMenuItem(
                            value: d,
                            child: Text('Ngày $d'),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setState(() => _dayOfMonth = v ?? 1),
              ),
              const SizedBox(height: 12),
            ],

            Text(
              'Giờ nhắc nhở',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(hour: _hour, minute: _minute),
                );
                if (picked != null && mounted) {
                  setState(() {
                    _hour = picked.hour;
                    _minute = picked.minute;
                  });
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outlineVariant, width: 0.8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: cs.primary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Tap để thay đổi',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child:
                    _loading
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Text(
                          _isEdit ? 'Lưu thay đổi' : 'Tạo nhắc nhở',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
