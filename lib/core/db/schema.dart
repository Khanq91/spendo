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
  Table('recurring_reminders', [
    Column.text('title'),
    Column.text('category_id'),
    Column.text('amount_hint'),
    Column.text('frequency'),       // 'daily' | 'weekly' | 'monthly'
    Column.integer('day_of_week'),  // 1-7, weekly only
    Column.integer('day_of_month'), // 1-28, monthly only
    Column.integer('hour'),
    Column.integer('minute'),
    Column.integer('is_active'),
    Column.text('next_trigger'),    // ISO8601 string
    // "Sắp hết đồ" mode: cảnh báo trước N giờ (0 = tắt)
    Column.integer('warn_before_hours'),
  ]),
]);