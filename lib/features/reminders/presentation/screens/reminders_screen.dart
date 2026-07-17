import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../../core/db/powersync_db.dart';
import '../../../../core/notifications/reminder_notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/motion/motion.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../habits/domain/detected_habit.dart';
import '../../../habits/presentation/providers/habit_provider.dart';
import '../../domain/recurring_reminder.dart';
import '../providers/reminder_provider.dart';
import '../widgets/reminder_form_sheet.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Trigger analysis khi mở màn hình
    ref.watch(habitAnalysisProvider);

    final remindersAsync = ref.watch(remindersProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nhắc chi tiêu định kỳ',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openForm(context),
          ),
        ],
      ),
      body: remindersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data:
            (reminders) =>
                reminders.isEmpty
                    ? _EmptyState(onAdd: () => _openForm(context))
                    : ListView(
                      children: [
                        _PresetSection(existing: reminders),
                        // Habit suggestions từ lịch sử giao dịch
                        _HabitSuggestionSection(existingReminders: reminders),
                        if (reminders.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              'Nhắc nhở của bạn',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurfaceVariant,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: appMotion.whenMotionAllowed(
                              context,
                              appMotion.listDuration,
                            ),
                            child: Column(
                              key: ValueKey(
                                reminders
                                    .map((reminder) => reminder.id)
                                    .join('|'),
                              ),
                              children: [
                                for (final reminder in reminders)
                                  _ReminderTile(
                                    key: ValueKey(reminder.id),
                                    reminder: reminder,
                                  ),
                              ],
                            ),
                          ),
                        ],
                        if (kDebugMode && reminders.isNotEmpty) ...[
                          _DebugPanel(reminders: reminders),
                        ],
                        const SizedBox(height: 80),
                      ],
                    ),
      ),
    );
  }

  void _openForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const ReminderFormSheet(),
    );
  }
}

// ── Habit suggestion section ──────────────────────────────────────────────────

class _HabitSuggestionSection extends ConsumerWidget {
  final List<RecurringReminder> existingReminders;

  const _HabitSuggestionSection({required this.existingReminders});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(pendingHabitSuggestionsProvider);
    final cs = Theme.of(context).colorScheme;

    // Lọc bỏ những habit đã có reminder với title tương tự
    final existingTitles =
        existingReminders.map((r) => r.title.toLowerCase()).toSet();
    final filtered =
        suggestions
            .where((h) => !existingTitles.contains(h.keyword.toLowerCase()))
            .toList();

    if (filtered.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(LucideIcons.sparkles, size: 13, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'Gợi ý từ lịch sử của bạn',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        ...filtered.map((habit) => _HabitSuggestionTile(habit: habit)),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _HabitSuggestionTile extends ConsumerWidget {
  final DetectedHabit habit;

  const _HabitSuggestionTile({required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final allCats = ref.watch(expenseCategoriesProvider);
    final cat = allCats.where((c) => c.id == habit.categoryId).firstOrNull;
    final repo = ref.read(habitRepoProvider);

    final daysText =
        habit.daysSinceLast == 0
            ? 'hôm nay'
            : '${habit.daysSinceLast} ngày trước';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
          width: 0.8,
        ),
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.04),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                LucideIcons.repeat,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _capitalize(habit.keyword),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Thường mỗi ${habit.medianGapDays} ngày · lần cuối $daysText'
                    '${cat != null ? ' · ${cat.name}' : ''}',
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Actions
            TextButton(
              onPressed: () => _openForm(context, habit),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
              ),
              child: const Text(
                'Tạo',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            PressableScale(
              onTap: () => repo.dismiss(habit.id),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  LucideIcons.x,
                  size: 14,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openForm(BuildContext context, DetectedHabit habit) {
    // Tạo preset từ habit để pre-fill ReminderFormSheet
    final preset = ReminderPreset(
      title: _capitalize(habit.keyword),
      iconName: 'more_horiz',
      frequency:
          habit.medianGapDays >= 25
              ? ReminderFrequency.monthly
              : habit.medianGapDays >= 6
              ? ReminderFrequency.weekly
              : ReminderFrequency.daily,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => ReminderFormSheet(
            preset: preset,
            preselectedCategoryId: habit.categoryId,
          ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Debug panel ───────────────────────────────────────────────────────────────

class _DebugPanel extends StatefulWidget {
  final List<RecurringReminder> reminders;
  const _DebugPanel({required this.reminders});

  @override
  State<_DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends State<_DebugPanel> {
  RecurringReminder? _selected;
  bool _firing = false;
  int _delaySeconds = 5;

  @override
  void initState() {
    super.initState();
    _selected = widget.reminders.first;
  }

  @override
  void didUpdateWidget(_DebugPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reminders != oldWidget.reminders) {
      final currentId = _selected?.id;
      if (currentId != null) {
        _selected =
            widget.reminders.where((r) => r.id == currentId).firstOrNull;
      }
      _selected ??= widget.reminders.firstOrNull;
    }
  }

  Future<void> _fireNow() async {
    final r = _selected;
    if (r == null) return;
    setState(() => _firing = true);

    try {
      final testTrigger = tz.TZDateTime.now(
        tz.local,
      ).add(Duration(seconds: _delaySeconds));
      final testReminder = r.copyWith(
        nextTrigger: testTrigger.toLocal(),
        isActive: true,
      );
      await ReminderNotificationService.scheduleTest(testReminder);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔔 "${r.title}" sẽ hiện sau $_delaySeconds giây'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _firing = false);
    }
  }

  Future<void> _seedHabitTestData() async {
    // Lấy category id đầu tiên có sẵn
    final cats = await db.getAll(
      "SELECT id FROM categories WHERE is_income = 0 LIMIT 1",
    );
    if (cats.isEmpty) return;
    final catId = cats.first['id'] as String;

    final now = DateTime.now();
    // 3 lần mua "dầu gội", cách nhau 10 ngày
    for (int i = 3; i >= 1; i--) {
      final date = now.subtract(Duration(days: i * 10));
      await db.execute(
        "INSERT INTO transactions(id, amount, type, category_id, note, created_at) "
        "VALUES(uuid(), '50000', 'expense', ?, 'dầu gội', ?)",
        [catId, date.millisecondsSinceEpoch.toString()],
      );
    }
    // 3 lần mua "xăng xe", cách nhau 7 ngày
    for (int i = 3; i >= 1; i--) {
      final date = now.subtract(Duration(days: i * 7));
      await db.execute(
        "INSERT INTO transactions(id, amount, type, category_id, note, created_at) "
        "VALUES(uuid(), '100000', 'expense', ?, 'xăng xe', ?)",
        [catId, date.millisecondsSinceEpoch.toString()],
      );
    }
    // Data nhiễu: "cà phê" hàng ngày — gap = 1, < minGapDays=3, KHÔNG nên suggest
    for (int i = 10; i >= 1; i--) {
      final date = now.subtract(Duration(days: i));
      await db.execute(
        "INSERT INTO transactions(id, amount, type, category_id, note, created_at) "
        "VALUES(uuid(), '30000', 'expense', ?, 'cà phê', ?)",
        [catId, date.millisecondsSinceEpoch.toString()],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange.withValues(alpha: 0.5), width: 1),
        borderRadius: BorderRadius.circular(12),
        color: Colors.orange.withValues(alpha: 0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                const Icon(Icons.bug_report, size: 16, color: Colors.orange),
                const SizedBox(width: 6),
                const Text(
                  'DEBUG — Test notification',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.orange,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.orange),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chọn reminder:',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<RecurringReminder>(
                  initialValue: _selected,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  items:
                      widget.reminders
                          .map(
                            (r) => DropdownMenuItem(
                              value: r,
                              child: Text(
                                '${r.title} (${r.frequencyLabel})',
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _selected = v),
                ),
                const SizedBox(height: 10),
                Text(
                  'Fire sau:',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                Row(
                  children:
                      [5, 10, 15, 30].map((s) {
                        final selected = _delaySeconds == s;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _delaySeconds = s),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    selected
                                        ? Colors.orange.withValues(alpha: 0.2)
                                        : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                      selected
                                          ? Colors.orange
                                          : cs.outlineVariant,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                '${s}s',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                      selected
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                  color:
                                      selected
                                          ? Colors.orange
                                          : cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 12),
                if (_selected != null) ...[
                  Text(
                    'Payload sẽ gửi:',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'reminder_id: ${_selected!.id.substring(0, 8)}...\n'
                      'category_id: ${_selected!.categoryId.substring(0, 8)}...\n'
                      'note: ${_selected!.title}\n'
                      'amount: ${_selected!.amountHint ?? "—"}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _firing || _selected == null ? null : _fireNow,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon:
                        _firing
                            ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(LucideIcons.bellRing, size: 16),
                    label: Text(
                      _firing
                          ? 'Đang schedule...'
                          : 'Fire notification sau ${_delaySeconds}s',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    await _seedHabitTestData();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✅ Đã seed test data')),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(backgroundColor: Colors.purple),
                  icon: const Icon(Icons.science, size: 16),
                  label: const Text('Seed habit test data'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Preset section ────────────────────────────────────────────────────────────

class _PresetSection extends ConsumerWidget {
  final List<RecurringReminder> existing;
  const _PresetSection({required this.existing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final existingTitles = existing.map((r) => r.title.toLowerCase()).toSet();

    final available =
        kReminderPresets
            .where((p) => !existingTitles.contains(p.title.toLowerCase()))
            .toList();

    if (available.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Gợi ý nhanh',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: available.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final preset = available[i];
              return PressableScale(
                onTap:
                    () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => ReminderFormSheet(preset: preset),
                    ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: cs.outlineVariant, width: 0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, size: 14),
                      const SizedBox(width: 4),
                      Text(preset.title, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Reminder tile ─────────────────────────────────────────────────────────────

class _ReminderTile extends ConsumerWidget {
  final RecurringReminder reminder;
  const _ReminderTile({super.key, required this.reminder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final allCats = ref.watch(expenseCategoriesProvider);
    final cat = allCats.where((c) => c.id == reminder.categoryId).firstOrNull;
    final actions = ref.read(reminderActionsProvider);

    return ListTile(
      leading: AnimatedContainer(
        duration: appMotion.whenMotionAllowed(context, appMotion.listDuration),
        curve: appMotion.curveStandard,
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color:
              reminder.isActive
                  ? Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.12)
                  : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: AnimatedSwitcher(
          duration: appMotion.whenMotionAllowed(
            context,
            appMotion.tapUpDuration,
          ),
          child: Icon(
            LucideIcons.bell,
            key: ValueKey(reminder.isActive),
            size: 18,
            color:
                reminder.isActive
                    ? Theme.of(context).colorScheme.primary
                    : cs.onSurfaceVariant,
          ),
        ),
      ),
      title: AnimatedDefaultTextStyle(
        duration: appMotion.whenMotionAllowed(context, appMotion.listDuration),
        curve: appMotion.curveStandard,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: reminder.isActive ? cs.onSurface : cs.onSurfaceVariant,
        ),
        child: Text(reminder.title),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reminder.scheduleDetail,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          if (cat != null)
            Text(
              cat.name,
              style: TextStyle(
                fontSize: 11,
                color: cat.color,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: reminder.isActive,
            activeThumbColor: Theme.of(context).colorScheme.primary,
            onChanged: (_) => actions.toggleActive(reminder),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 18, color: cs.onSurfaceVariant),
            onSelected: (val) async {
              if (val == 'edit') {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => ReminderFormSheet(existing: reminder),
                );
              } else if (val == 'delete') {
                await actions.delete(reminder);
              }
            },
            itemBuilder:
                (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Xoá',
                      style: TextStyle(color: AppTheme.expenseAltColor),
                    ),
                  ),
                ],
          ),
        ],
      ),
      isThreeLine: cat != null,
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.bellOff, size: 48, color: cs.outlineVariant),
              const SizedBox(height: 12),
              Text(
                'Chưa có nhắc nhở nào',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              Text(
                'Tạo nhắc nhở để không quên chi tiêu định kỳ',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Thêm nhắc nhở'),
              ),
            ],
          ),
        ),
        _PresetSection(existing: const []),
        // Habit suggestions hiện ngay cả khi chưa có reminder nào
        const _HabitSuggestionSection(existingReminders: []),
      ],
    );
  }
}
