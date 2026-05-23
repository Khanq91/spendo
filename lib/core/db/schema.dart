import 'package:powersync/powersync.dart';

const schema = Schema([
  Table('transactions', [
    Column.text('amount'),
    Column.text('type'),
    Column.text('category_id'),
    Column.text('note'),
    Column.text('created_at'),
  ]),
  Table('categories', [
    Column.text('name'),
    Column.text('color_hex'),
    Column.text('icon_name'),
    Column.integer('is_default'),
    Column.integer('is_income'),
    Column.integer('sort_order'),
  ]),
  Table('budgets', [
    Column.text('amount'),
    Column.text('month'),
  ]),
  Table.localOnly('category_budgets', [
    Column.text('category_id'),
    Column.text('amount'),
  ]),
  Table('recurring_reminders', [
    Column.text('title'),
    Column.text('category_id'),
    Column.text('amount_hint'),
    Column.text('frequency'),
    Column.integer('day_of_week'),
    Column.integer('day_of_month'),
    Column.integer('hour'),
    Column.integer('minute'),
    Column.integer('is_active'),
    Column.text('next_trigger'),
    Column.integer('warn_before_hours'),
  ]),
  // Habit suggestions detected from transaction history — local only
  Table.localOnly('detected_habits', [
    Column.text('keyword'),           // normalized note text
    Column.text('category_id'),
    Column.integer('median_gap_days'),
    Column.text('last_occurrence'),   // ISO8601
    Column.integer('occurrence_count'),
    Column.integer('is_dismissed'),   // 1 = user dismissed
    Column.text('analyzed_at'),       // ISO8601
  ]),
]);