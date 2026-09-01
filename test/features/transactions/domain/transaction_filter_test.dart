import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/features/transactions/domain/transaction.dart';
import 'package:spendo/features/transactions/domain/transaction_filter.dart';

Transaction _tx({
  required String id,
  required String type,
  String categoryId = 'food',
  String? walletId,
  String? note,
  int amount = 50000,
}) {
  return Transaction(
    id: id,
    amount: amount,
    type: type,
    categoryId: categoryId,
    note: note,
    createdAt: DateTime(2026, 8, 15),
    walletId: walletId,
  );
}

final _all = [
  _tx(id: 'a', type: 'expense', note: 'Ăn trưa', walletId: 'cash'),
  _tx(id: 'b', type: 'expense', categoryId: 'transport', note: 'Xăng xe'),
  _tx(
    id: 'c',
    type: 'income',
    categoryId: 'salary',
    note: 'Lương tháng 8',
    amount: 18000000,
    walletId: 'bank',
  ),
];

List<String> _ids(List<Transaction> txs) => txs.map((t) => t.id).toList();

void main() {
  test('an empty filter keeps everything', () {
    const filter = TransactionFilter();

    expect(_ids(filter.apply(_all)), ['a', 'b', 'c']);
    expect(filter.activeCount, 0);
    expect(filter.isNarrowed, isFalse);
  });

  test('the type filter splits the ledger and counts as one filter', () {
    const expense = TransactionFilter(type: TransactionTypeFilter.expense);

    expect(_ids(expense.apply(_all)), ['a', 'b']);
    expect(expense.activeCount, 1);

    const income = TransactionFilter(type: TransactionTypeFilter.income);
    expect(_ids(income.apply(_all)), ['c']);
  });

  test('categories are additive — several can be selected at once', () {
    // The old chip strip could only hold one category.
    final filter = const TransactionFilter()
        .toggleCategory('food')
        .toggleCategory('salary');

    expect(_ids(filter.apply(_all)), ['a', 'c']);
    expect(filter.activeCount, 2);
  });

  test('toggling a selected category removes it again', () {
    final filter = const TransactionFilter().toggleCategory('food');

    expect(filter.toggleCategory('food').categoryIds, isEmpty);
  });

  test('the wallet filter skips transactions with no wallet', () {
    final filter = const TransactionFilter().toggleWallet('cash');

    expect(_ids(filter.apply(_all)), ['a']);
  });

  test('the query matches note or amount, case-insensitively', () {
    expect(
      _ids(const TransactionFilter(query: 'TRƯA').apply(_all)),
      ['a'],
    );
    expect(
      _ids(const TransactionFilter(query: '18000000').apply(_all)),
      ['c'],
    );
    expect(
      const TransactionFilter(query: 'không khớp').apply(_all),
      isEmpty,
    );
  });

  test('the query narrows the list but is not counted on the badge', () {
    // The search box already shows its own text, so counting it would
    // double-report the same thing.
    const filter = TransactionFilter(query: 'trưa');

    expect(filter.activeCount, 0);
    expect(filter.isNarrowed, isTrue);
  });

  test('filters combine', () {
    final filter = const TransactionFilter(
      type: TransactionTypeFilter.expense,
    ).toggleCategory('food').toggleCategory('transport');

    expect(_ids(filter.apply(_all)), ['a', 'b']);

    final withQuery = filter.copyWith(query: 'xăng');
    expect(_ids(withQuery.apply(_all)), ['b']);
  });

  test('clearing drops the filters but keeps what was typed', () {
    final filter = const TransactionFilter(
      type: TransactionTypeFilter.income,
      query: 'lương',
    ).toggleCategory('salary');

    final cleared = filter.cleared();
    expect(cleared.activeCount, 0);
    expect(cleared.query, 'lương');
  });

  test('summarise totals each side separately', () {
    final totals = summarise(_all);

    expect(totals.count, 3);
    expect(totals.income, 18000000);
    expect(totals.expense, 100000);
  });
}
