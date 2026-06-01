import 'package:powersync/powersync.dart';

const schema = Schema([
  Table('transactions', [
    Column.text('amount'),
    Column.text('type'),
    Column.text('category_id'),
    Column.text('note'),
    Column.text('created_at'),
    Column.text('wallet_id'), // nullable — thêm migration ALTER TABLE
  ]),
  Table('categories', [
    Column.text('name'),
    Column.text('color_hex'),
    Column.text('icon_name'),
    Column.integer('is_default'),
    Column.integer('is_income'),
    Column.integer('sort_order'),
  ]),
  Table('budgets', [Column.text('amount'), Column.text('month')]),
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
  Table.localOnly('detected_habits', [
    Column.text('keyword'),
    Column.text('category_id'),
    Column.integer('median_gap_days'),
    Column.text('last_occurrence'),
    Column.integer('occurrence_count'),
    Column.integer('is_dismissed'),
    Column.text('analyzed_at'),
  ]),
  Table.localOnly('wallets', [
    Column.text('name'),
    Column.text('type'),
    Column.text('initial_balance'),
    Column.text('note'),
    Column.text('color_hex'),
    Column.integer('sort_order'),
    Column.integer('is_archived'),
  ]),
  Table.localOnly('loans', [
    Column.text('title'),
    Column.text('type'),           // 'borrowed' | 'lent'
    Column.text('principal'),      // số tiền gốc
    Column.text('contact_name'),
    Column.text('start_date'),
    Column.text('due_date'),       // nullable
    Column.text('note'),
    Column.text('color_hex'),
    Column.integer('is_closed'),
  ]),
  Table.localOnly('loan_payments', [
    Column.text('loan_id'),
    Column.text('amount'),
    Column.text('paid_at'),
    Column.text('note'),
  ]),
]);