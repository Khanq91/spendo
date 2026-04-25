import 'package:powersync/powersync.dart';

const schema = Schema(([
  Table('transactions', [
    Column.text('amount'),
    Column.text('type'),
    Column.text('category_id'),
    Column.text('note'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),
  Table('categories', [
    Column.text('name'),
    Column.text('color_hex'),
    Column.text('icon_name'),
    Column.integer('is_default'),
    Column.integer('is_income'),
    Column.integer('sort_order'),
  ]),
]));