import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../../core/notifications/reminder_notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../domain/recurring_reminder.dart';
import '../providers/reminder_provider.dart';
import '../widgets/reminder_form_sheet.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(remindersProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhắc chi tiêu định kỳ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
        data: (reminders) => reminders.isEmpty
            ? _EmptyState(onAdd: () => _openForm(context))
            : ListView(
          children: [
            _PresetSection(existing: reminders),
            if (reminders.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Nhắc nhở của bạn',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                        letterSpacing: 0.5)),
              ),
              ...reminders.map((r) => _ReminderTile(reminder: r)),
            ],
            // Debug panel — chỉ hiện khi chạy debug build
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

  Future<void> _fireNow() async {
    final r = _selected;
    if (r == null) return;
    setState(() => _firing = true);

    try {
      // Tạo bản copy với nextTrigger = now + delaySeconds
      final testTrigger = tz.TZDateTime.now(tz.local)
          .add(Duration(seconds: _delaySeconds));

      final testReminder = r.copyWith(
        nextTrigger: testTrigger.toLocal(),
        isActive: true,
      );

      await ReminderNotificationService.scheduleTest(testReminder);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🔔 "${r.title}" sẽ hiện sau $_delaySeconds giây',
            ),
            backgroundColor: AppTheme.primary,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _firing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange.withOpacity(0.5), width: 1),
        borderRadius: BorderRadius.circular(12),
        color: Colors.orange.withOpacity(0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                // Reminder picker
                Text('Chọn reminder:',
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant)),
                const SizedBox(height: 6),
                DropdownButtonFormField<RecurringReminder>(
                  value: _selected,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    isDense: true,
                  ),
                  items: widget.reminders
                      .map((r) => DropdownMenuItem(
                    value: r,
                    child: Text(
                      '${r.title} (${r.frequencyLabel})',
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
                      .toList(),
                  onChanged: (v) => setState(() => _selected = v),
                ),

                const SizedBox(height: 10),

                // Delay picker
                Text('Fire sau:',
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant)),
                const SizedBox(height: 6),
                Row(
                  children: [5, 10, 15, 30].map((s) {
                    final selected = _delaySeconds == s;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _delaySeconds = s),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.orange.withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected
                                  ? Colors.orange
                                  : cs.outlineVariant,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            '${s}s',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: selected
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

                // Payload preview
                if (_selected != null) ...[
                  Text('Payload sẽ gửi:',
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant)),
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
                          height: 1.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Fire button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _firing || _selected == null
                        ? null
                        : _fireNow,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding:
                      const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: _firing
                        ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white),
                    )
                        : const Icon(LucideIcons.bellRing, size: 16),
                    label: Text(
                      _firing
                          ? 'Đang schedule...'
                          : 'Fire notification sau ${_delaySeconds}s',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
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
    final existingTitles =
    existing.map((r) => r.title.toLowerCase()).toSet();

    final available = kReminderPresets
        .where((p) => !existingTitles.contains(p.title.toLowerCase()))
        .toList();

    if (available.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Gợi ý nhanh',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                  letterSpacing: 0.5)),
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
              return GestureDetector(
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => ReminderFormSheet(preset: preset),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: cs.outlineVariant, width: 0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, size: 14),
                      const SizedBox(width: 4),
                      Text(preset.title,
                          style: const TextStyle(fontSize: 13)),
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
  const _ReminderTile({required this.reminder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final allCats = ref.watch(expenseCategoriesProvider);
    final cat =
        allCats.where((c) => c.id == reminder.categoryId).firstOrNull;
    final actions = ref.read(reminderActionsProvider);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: reminder.isActive
              ? AppTheme.primary.withOpacity(0.12)
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          LucideIcons.bell,
          size: 18,
          color: reminder.isActive
              ? AppTheme.primary
              : cs.onSurfaceVariant,
        ),
      ),
      title: Text(
        reminder.title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color:
          reminder.isActive ? cs.onSurface : cs.onSurfaceVariant,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(reminder.scheduleDetail,
              style: TextStyle(
                  fontSize: 12, color: cs.onSurfaceVariant)),
          if (cat != null)
            Text(cat.name,
                style: TextStyle(
                    fontSize: 11,
                    color: cat.color,
                    fontWeight: FontWeight.w500)),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: reminder.isActive,
            activeColor: AppTheme.primary,
            onChanged: (_) => actions.toggleActive(reminder),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert,
                size: 18, color: cs.onSurfaceVariant),
            onSelected: (val) async {
              if (val == 'edit') {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) =>
                      ReminderFormSheet(existing: reminder),
                );
              } else if (val == 'delete') {
                await actions.delete(reminder);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'edit', child: Text('Chỉnh sửa')),
              PopupMenuItem(
                value: 'delete',
                child: Text('Xoá',
                    style:
                    TextStyle(color: AppTheme.expenseAltColor)),
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
              Icon(LucideIcons.bellOff,
                  size: 48, color: cs.outlineVariant),
              const SizedBox(height: 12),
              Text('Chưa có nhắc nhở nào',
                  style: TextStyle(color: cs.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text('Tạo nhắc nhở để không quên chi tiêu định kỳ',
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurfaceVariant)),
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
      ],
    );
  }
}