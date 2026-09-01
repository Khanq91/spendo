import 'package:powersync/powersync.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/db/powersync_db.dart' as app_db;
import '../domain/loan.dart';

/// The four categories a loan's money moves through.
///
/// Repayments and the principal flow in opposite directions, so each of the
/// four money movements a loan can make needs its own name rather than one
/// "Nợ" bucket that mixes them.
enum LoanCategoryKind {
  /// Paying back a loan you took: money out.
  repay(
    iconName: 'loan_repay',
    name: 'Trả nợ',
    colorHex: '#B0BEC5',
    isIncome: false,
    prefsKey: 'loan_cat_repay_id',
  ),

  /// Being paid back on a loan you gave: money in.
  collect(
    iconName: 'loan_collect',
    name: 'Thu nợ',
    colorHex: '#66BB6A',
    isIncome: true,
    prefsKey: 'loan_cat_collect_id',
  ),

  /// The principal of a loan you took, arriving in a wallet.
  borrowIn(
    iconName: 'loan_in',
    name: 'Đi vay',
    colorHex: '#FFA726',
    isIncome: true,
    prefsKey: 'loan_cat_borrow_in_id',
  ),

  /// The principal of a loan you gave, leaving a wallet.
  lendOut(
    iconName: 'loan_out',
    name: 'Cho vay',
    colorHex: '#FF8E53',
    isIncome: false,
    prefsKey: 'loan_cat_lend_out_id',
  );

  const LoanCategoryKind({
    required this.iconName,
    required this.name,
    required this.colorHex,
    required this.isIncome,
    required this.prefsKey,
  });

  /// Doubles as the lookup key when the saved id is gone: `icon_name` is the
  /// one field a user cannot rename from the Danh mục screen.
  final String iconName;
  final String name;
  final String colorHex;
  final bool isIncome;
  final String prefsKey;

  /// Which category a payment against [type] belongs to.
  static LoanCategoryKind paymentFor(LoanType type) =>
      type == LoanType.borrowed ? repay : collect;

  /// Which category the principal of [type] belongs to.
  static LoanCategoryKind fundingFor(LoanType type) =>
      type == LoanType.borrowed ? borrowIn : lendOut;
}

/// Finds — or, the first time one is needed, creates — a loan category.
///
/// Deliberately not part of the seed: someone who never records a loan should
/// not find four categories they did not ask for sitting in their list. The
/// cost is that the id has to be discovered rather than known, which is what
/// the three steps below are for.
class LoanCategoryResolver {
  LoanCategoryResolver({PowerSyncDatabase? database}) : _database = database;

  final PowerSyncDatabase? _database;

  PowerSyncDatabase get _db => _database ?? app_db.db;

  /// The category's id, creating the row if this is the first time it is
  /// needed.
  ///
  /// Three steps, each covering the way the previous one can go stale:
  /// 1. the id remembered in preferences, verified to still exist;
  /// 2. a lookup by `icon_name` — a restored backup brings the categories back
  ///    with new ids while preferences still point at the old ones, and this
  ///    adopts them instead of minting duplicates;
  /// 3. an insert, as a last resort.
  Future<String> resolve(LoanCategoryKind kind) async {
    final prefs = await SharedPreferences.getInstance();

    final remembered = prefs.getString(kind.prefsKey);
    if (remembered != null && await _exists(remembered)) return remembered;

    final adopted = await _findByIcon(kind);
    if (adopted != null) {
      await prefs.setString(kind.prefsKey, adopted);
      return adopted;
    }

    final created = await _create(kind);
    await prefs.setString(kind.prefsKey, created);
    return created;
  }

  Future<bool> _exists(String id) async {
    final row = await _db.getOptional(
      'SELECT id FROM categories WHERE id = ? LIMIT 1',
      [id],
    );
    return row != null;
  }

  Future<String?> _findByIcon(LoanCategoryKind kind) async {
    final row = await _db.getOptional(
      '''SELECT id FROM categories
         WHERE icon_name = ? AND is_default = 1
         LIMIT 1''',
      [kind.iconName],
    );
    return row?['id'] as String?;
  }

  Future<String> _create(LoanCategoryKind kind) async {
    // `is_default = 1` keeps it undeletable on the Danh mục screen, so a loan
    // transaction can never be orphaned from its category.
    final rows = await _db.execute(
      '''INSERT INTO categories(
           id, name, color_hex, icon_name, is_default, is_income, sort_order
         )
         VALUES(
           uuid(), ?, ?, ?, 1, ?,
           (SELECT COALESCE(MAX(sort_order), -1) + 1
              FROM categories WHERE is_income = ?)
         ) RETURNING id''',
      [
        kind.name,
        kind.colorHex,
        kind.iconName,
        kind.isIncome ? 1 : 0,
        kind.isIncome ? 1 : 0,
      ],
    );
    return rows.first['id'] as String;
  }
}
