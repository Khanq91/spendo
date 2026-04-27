import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
            // Preset section — only show if no reminders yet or as suggestion
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

// ── Preset section ────────────────────────────────────────────────────────────

class _PresetSection extends ConsumerWidget {
  final List<RecurringReminder> existing;
  const _PresetSection({required this.existing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final existingTitles = existing.map((r) => r.title.toLowerCase()).toSet();

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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
  const _ReminderTile({required this.reminder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final allCats = ref.watch(expenseCategoriesProvider);
    final cat = allCats.where((c) => c.id == reminder.categoryId).firstOrNull;
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
          color: reminder.isActive ? AppTheme.primary : cs.onSurfaceVariant,
        ),
      ),
      title: Text(
        reminder.title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: reminder.isActive ? cs.onSurface : cs.onSurfaceVariant,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(reminder.scheduleDetail,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
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
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
              PopupMenuItem(
                value: 'delete',
                child: Text('Xoá',
                    style: TextStyle(color: AppTheme.expenseAltColor)),
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
              Text('Chưa có nhắc nhở nào',
                  style: TextStyle(color: cs.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text('Tạo nhắc nhở để không quên chi tiêu định kỳ',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
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