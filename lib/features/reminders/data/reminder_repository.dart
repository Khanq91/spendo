import '../../../core/db/powersync_db.dart';
import '../domain/recurring_reminder.dart';

class ReminderRepository {
  Stream<List<RecurringReminder>> watchAll() {
    return db
        .watch('SELECT * FROM recurring_reminders ORDER BY title ASC')
        .map((rows) => rows.map(RecurringReminder.fromMap).toList());
  }

  Future<List<RecurringReminder>> getAll() async {
    final rows = await db.getAll(
      'SELECT * FROM recurring_reminders ORDER BY title ASC',
    );
    return rows.map(RecurringReminder.fromMap).toList();
  }

  Future<RecurringReminder?> getById(String id) async {
    final row = await db.getOptional(
      'SELECT * FROM recurring_reminders WHERE id = ?',
      [id],
    );
    return row == null ? null : RecurringReminder.fromMap(row);
  }

  Future<void> add(RecurringReminder r) async {
    await db.execute(
      '''INSERT INTO recurring_reminders(
          id, title, category_id, amount_hint, frequency,
          day_of_week, day_of_month, hour, minute, is_active, next_trigger
        ) VALUES(uuid(), ?, ?, ?, ?, ?, ?, ?, ?, 1, ?)''',
      [
        r.title,
        r.categoryId,
        r.amountHint?.toString(),
        r.frequency.name,
        r.dayOfWeek,
        r.dayOfMonth,
        r.hour,
        r.minute,
        r.nextTrigger.toIso8601String(),
      ],
    );
  }

  Future<void> update(RecurringReminder r) async {
    await db.execute(
      '''UPDATE recurring_reminders SET
          title=?, category_id=?, amount_hint=?, frequency=?,
          day_of_week=?, day_of_month=?, hour=?, minute=?,
          is_active=?, next_trigger=?
         WHERE id=?''',
      [
        r.title,
        r.categoryId,
        r.amountHint?.toString(),
        r.frequency.name,
        r.dayOfWeek,
        r.dayOfMonth,
        r.hour,
        r.minute,
        r.isActive ? 1 : 0,
        r.nextTrigger.toIso8601String(),
        r.id,
      ],
    );
  }

  Future<void> setActive(String id, bool active) async {
    await db.execute(
      'UPDATE recurring_reminders SET is_active=? WHERE id=?',
      [active ? 1 : 0, id],
    );
  }

  Future<void> delete(String id) async {
    await db.execute(
      'DELETE FROM recurring_reminders WHERE id=?',
      [id],
    );
  }
}