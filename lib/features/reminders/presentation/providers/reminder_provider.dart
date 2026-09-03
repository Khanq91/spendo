import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/reminder_repository.dart';
import '../../domain/recurring_reminder.dart';
import '../../../../core/notifications/reminder_notification_service.dart';

final reminderRepoProvider = Provider((_) => ReminderRepository());

final remindersProvider = StreamProvider<List<RecurringReminder>>((ref) {
  return ref.watch(reminderRepoProvider).watchAll();
});

final reminderActionsProvider = Provider((ref) => ReminderActions(ref));

class ReminderActions {
  final Ref _ref;
  ReminderActions(this._ref);

  ReminderRepository get _repo => _ref.read(reminderRepoProvider);

  Future<void> add(RecurringReminder r) async {
    await _repo.add(r);
    // Re-read to get the actual saved record with DB-generated id
    final all = await _repo.getAll();
    final saved = all.firstWhere((x) => x.title == r.title && x.categoryId == r.categoryId);
    await ReminderNotificationService.schedule(saved);
  }

  Future<void> update(RecurringReminder r) async {
    await _repo.update(r);
    if (r.isActive) {
      await ReminderNotificationService.schedule(r);
    } else {
      await ReminderNotificationService.cancel(r.id);
    }
  }

  Future<void> toggleActive(RecurringReminder r) async {
    if (r.isActive) {
      await _repo.setActive(r.id, false);
      await ReminderNotificationService.cancel(r.id);
      return;
    }
    // Switching back on starts the schedule from now. The recomputed trigger
    // is written to the row as well, not only handed to the alarm: the tile
    // reads the row, and a stale one showed a date already gone.
    final updated = r.copyWith(
      isActive: true,
      nextTrigger: r.nextTriggerAfter(DateTime.now()),
    );
    await _repo.update(updated);
    await ReminderNotificationService.schedule(updated);
  }

  Future<void> delete(RecurringReminder r) async {
    await ReminderNotificationService.cancel(r.id);
    await _repo.delete(r.id);
  }
}