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
    final next = !r.isActive;
    await _repo.setActive(r.id, next);
    if (next) {
      final updated = RecurringReminder(
        id: r.id,
        title: r.title,
        categoryId: r.categoryId,
        amountHint: r.amountHint,
        frequency: r.frequency,
        dayOfWeek: r.dayOfWeek,
        dayOfMonth: r.dayOfMonth,
        hour: r.hour,
        minute: r.minute,
        isActive: true,
        nextTrigger: RecurringReminder.calcNextTrigger(
          frequency: r.frequency,
          hour: r.hour,
          minute: r.minute,
          dayOfWeek: r.dayOfWeek,
          dayOfMonth: r.dayOfMonth,
        ),
      );
      await ReminderNotificationService.schedule(updated);
    } else {
      await ReminderNotificationService.cancel(r.id);
    }
  }

  Future<void> delete(RecurringReminder r) async {
    await ReminderNotificationService.cancel(r.id);
    await _repo.delete(r.id);
  }
}