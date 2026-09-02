import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/motion/motion.dart';
import '../../../../shared/widgets/spendo/spendo.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../habits/domain/detected_habit.dart';
import '../../../habits/presentation/providers/habit_provider.dart';
import '../../../transactions/presentation/widgets/add_transaction_sheet.dart';
import '../../domain/recurring_reminder.dart';
import '../providers/reminder_provider.dart';
import '../widgets/debug_reminder_panel.dart';
import '../widgets/reminder_form_sheet.dart';

/// Screen 13 of the redesign.
class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kicks off habit analysis when the screen opens.
    ref.watch(habitAnalysisProvider);

    final remindersAsync = ref.watch(remindersProvider);
    final categories = ref.watch(expenseCategoriesProvider);
    final categoryMap = <String, Category>{for (final c in categories) c.id: c};

    final hasInitialError =
        remindersAsync.hasError && !remindersAsync.hasValue;
    final isLoading = remindersAsync.isLoading && !remindersAsync.hasValue;
    final reminders = remindersAsync.valueOrNull ?? const <RecurringReminder>[];

    return Scaffold(
      floatingActionButton: SpendoExtendedFab(
        heroTag: 'reminders_fab',
        label: 'Thêm nhắc nhở',
        onPressed: () => showReminderFormSheet(context),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // The AppBar said "Nhắc chi tiêu định kỳ" while every way in was
            // labelled "Nhắc nhở"; the screen now answers to its own name.
            const SpendoScreenHeader(title: 'Nhắc nhở'),
            Expanded(
              child: switch ((hasInitialError, isLoading)) {
                (true, _) => SpendoEmptyState(
                  icon: LucideIcons.circleAlert,
                  title: 'Không tải được nhắc nhở',
                  message: 'Kiểm tra kết nối rồi thử lại.',
                  actionLabel: 'Thử lại',
                  onAction: () => ref.invalidate(remindersProvider),
                ),
                (_, true) => const Center(child: CircularProgressIndicator()),
                _ => RevealScope(
                  child: ListView(
                  padding: const EdgeInsets.only(bottom: 96),
                  children: [
                    _SuggestionRow(reminders: reminders),
                    if (reminders.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: SpendoEmptyState(
                          icon: LucideIcons.bellOff,
                          title: 'Chưa có nhắc nhở nào',
                          message:
                              'Tạo nhắc nhở để không quên chi tiêu định kỳ.',
                          actionLabel: 'Thêm nhắc nhở',
                          onAction: () => showReminderFormSheet(context),
                        ),
                      )
                    else ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
                        child: SpendoSectionHeader(
                          label: 'Nhắc nhở của bạn (${reminders.length})',
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      for (var i = 0; i < reminders.length; i++) ...[
                        if (i > 0) const _ReminderDivider(),
                        RevealItem(
                          key: ValueKey(reminders[i].id),
                          id: reminders[i].id,
                          child: _ReminderTile(
                            reminder: reminders[i],
                            category: categoryMap[reminders[i].categoryId],
                          ),
                        ),
                      ],
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: _Hint(
                          text:
                              '"Ghi ngay" mở sheet Thêm giao dịch với số tiền '
                              'và danh mục điền sẵn. Vuốt trái để xoá — có '
                              'Hoàn tác.',
                        ),
                      ),
                    ],
                    if (kDebugMode && reminders.isNotEmpty)
                      DebugReminderPanel(reminders: reminders),
                  ],
                  ),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderDivider extends StatelessWidget {
  const _ReminderDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 72,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}

// ── Suggestions ──────────────────────────────────────────────────────────────

/// Habit suggestions and preset templates in one scrolling row.
///
/// The audit found two kinds of suggestion stacked above the list in two
/// different shapes — a card list and a chip strip — for the same job.
class _SuggestionRow extends ConsumerWidget {
  const _SuggestionRow({required this.reminders});

  final List<RecurringReminder> reminders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final taken = reminders.map((r) => r.title.toLowerCase()).toSet();

    final habits = ref
        .watch(pendingHabitSuggestionsProvider)
        .where((h) => !taken.contains(h.keyword.toLowerCase()))
        .toList();
    final presets = kReminderPresets
        .where((p) => !taken.contains(p.title.toLowerCase()))
        .toList();

    if (habits.isEmpty && presets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SpendoSectionHeader(label: 'Gợi ý', padding: EdgeInsets.zero),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final habit in habits) ...[
                // A habit read off the user's own history leads, marked out
                // from the static presets by its fill and its sparkle.
                _HabitChip(habit: habit),
                const SizedBox(width: 8),
              ],
              for (final preset in presets) ...[
                SpendoChip.suggestion(
                  label: preset.title,
                  icon: LucideIcons.plus,
                  onTap: () => showReminderFormSheet(context, preset: preset),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        // Kept off the chip so dismissing a suggestion is a deliberate second
        // step rather than a mis-tap next to "create".
        if (habits.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Text(
              habits.length == 1
                  ? 'Gợi ý từ lịch sử: ${habits.first.medianGapDays} ngày một lần'
                  : '${habits.length} gợi ý từ lịch sử của bạn',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}

class _HabitChip extends ConsumerWidget {
  const _HabitChip({required this.habit});

  final DetectedHabit habit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = '${_capitalize(habit.keyword)} · mỗi ${habit.medianGapDays} ngày';

    return SpendoChip(
      label: label,
      icon: LucideIcons.sparkles,
      selected: true,
      onTap: () => showReminderFormSheet(
        context,
        preset: ReminderPreset(
          title: _capitalize(habit.keyword),
          iconName: 'more_horiz',
          frequency: habit.medianGapDays >= 25
              ? ReminderFrequency.monthly
              : habit.medianGapDays >= 6
              ? ReminderFrequency.weekly
              : ReminderFrequency.daily,
        ),
        preselectedCategoryId: habit.categoryId,
      ),
      onDeleted: () => ref.read(habitRepoProvider).dismiss(habit.id),
    );
  }
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

// ── Reminder row ─────────────────────────────────────────────────────────────

class _ReminderTile extends ConsumerWidget {
  const _ReminderTile({required this.reminder, this.category});

  final RecurringReminder reminder;
  final Category? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final actions = ref.read(reminderActionsProvider);
    final active = reminder.isActive;
    final color = category?.color ?? cs.primary;

    return Dismissible(
      key: ValueKey('reminder_dismiss_${reminder.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteWithUndo(context, ref, reminder),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: cs.errorContainer,
        child: Icon(LucideIcons.trash2, size: 20, color: cs.onErrorContainer),
      ),
      child: Opacity(
        opacity: active ? 1 : 0.6,
        child: Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              SpendoIconTile(
                icon: LucideIcons.bell,
                color: active ? color : cs.onSurfaceVariant,
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      reminder.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: active ? cs.onSurface : cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _subtitle(reminder),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (active) ...[
                      const SizedBox(height: 6),
                      // The reminder already knows the category and the rough
                      // amount; "Ghi ngay" spends them instead of making the
                      // user retype both.
                      SpendoChip(
                        label: 'Ghi ngay',
                        icon: LucideIcons.plus,
                        onTap: () => showAddTransactionSheet(
                          context,
                          preselectedCategoryId: reminder.categoryId,
                          prefillNote: reminder.title,
                          prefillAmount: reminder.amountHint,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: active,
                onChanged: (_) => actions.toggleActive(reminder),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `Lần tới: Thứ 5, 5/9 · 20:00 · ~300.000 ₫`, or the schedule when off.
///
/// The audit found the tile showing only the recurrence rule: the next firing
/// and the suggested amount were both in the model and both hidden.
String _subtitle(RecurringReminder reminder) {
  if (!reminder.isActive) return 'Đã tắt · ${reminder.scheduleDetail}';

  final next = reminder.nextTrigger;
  final time =
      '${next.hour.toString().padLeft(2, '0')}:'
      '${next.minute.toString().padLeft(2, '0')}';
  final parts = [
    'Lần tới: ${_weekdayLabel(next.weekday)}, ${next.day}/${next.month}',
    time,
    if (reminder.amountHint != null && reminder.amountHint! > 0)
      '~${formatVND(reminder.amountHint!)}',
  ];
  return parts.join(' · ');
}

String _weekdayLabel(int weekday) => const [
  '',
  'Thứ 2',
  'Thứ 3',
  'Thứ 4',
  'Thứ 5',
  'Thứ 6',
  'Thứ 7',
  'CN',
][weekday.clamp(1, 7)];

Future<void> _deleteWithUndo(
  BuildContext context,
  WidgetRef ref,
  RecurringReminder reminder,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final actions = ref.read(reminderActionsProvider);

  await actions.delete(reminder);
  // Deleting used to take one tap from a menu with no confirmation and no way
  // back — the only place in the app that did.
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Text('Đã xoá ${reminder.title}'),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'Hoàn tác',
        onPressed: () => actions.add(reminder),
      ),
    ),
  );
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SpendoCard(
      color: cs.surfaceContainerLowest,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(LucideIcons.info, size: 16, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
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
