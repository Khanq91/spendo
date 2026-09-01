import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/db/powersync_db.dart';
import '../../../../core/notifications/reminder_notification_service.dart';
import '../../domain/recurring_reminder.dart';

/// Debug-build tooling for firing a reminder notification on demand.
///
/// Lifted out of `reminders_screen.dart` when that screen was redesigned: it
/// is three hundred lines that never ship, and it was the largest thing in a
/// file about a list of reminders.

class DebugReminderPanel extends StatefulWidget {
  final List<RecurringReminder> reminders;
  const DebugReminderPanel({super.key, required this.reminders});

  @override
  State<DebugReminderPanel> createState() => _DebugReminderPanelState();
}

class _DebugReminderPanelState extends State<DebugReminderPanel> {
  RecurringReminder? _selected;
  bool _firing = false;
  int _delaySeconds = 5;

  @override
  void initState() {
    super.initState();
    _selected = widget.reminders.first;
  }

  @override
  void didUpdateWidget(DebugReminderPanel oldWidget) {
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
                const Icon(LucideIcons.bug, size: 16, color: Colors.orange),
                const SizedBox(width: 6),
                const Flexible(
                  child: Text(
                    'DEBUG — Test notification',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange,
                      letterSpacing: 0.5,
                    ),
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
                      'reminder_id: ${_shortId(_selected!.id)}\n'
                      'category_id: ${_shortId(_selected!.categoryId)}\n'
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
                  icon: const Icon(LucideIcons.flaskConical, size: 16),
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

/// First eight characters of an id, or the whole thing when it is shorter.
///
/// A bare `substring(0, 8)` threw on any id under eight characters, which is
/// every id a test or a seeded fixture uses.
String _shortId(String id) =>
    id.length <= 8 ? id : '${id.substring(0, 8)}...';
