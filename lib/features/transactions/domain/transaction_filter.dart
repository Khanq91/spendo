import 'transaction.dart';

/// Which side of the ledger the list is showing.
enum TransactionTypeFilter {
  all,
  expense,
  income;

  String get label => switch (this) {
    TransactionTypeFilter.all => 'Tất cả',
    TransactionTypeFilter.expense => 'Chi',
    TransactionTypeFilter.income => 'Thu',
  };

  bool matches(Transaction t) => switch (this) {
    TransactionTypeFilter.all => true,
    TransactionTypeFilter.expense => t.isExpense,
    TransactionTypeFilter.income => t.isIncome,
  };
}

/// Everything narrowing the transaction list, in one value.
///
/// Held together so the screen can count what is applied (the badge on the
/// filter button) and clear items one at a time from the applied-filter chips.
class TransactionFilter {
  const TransactionFilter({
    this.type = TransactionTypeFilter.all,
    this.categoryIds = const {},
    this.walletIds = const {},
    this.query = '',
  });

  final TransactionTypeFilter type;
  final Set<String> categoryIds;
  final Set<String> walletIds;
  final String query;

  /// How many filters are applied, for the badge. The search box shows its own
  /// text, so the query is not counted.
  int get activeCount =>
      (type == TransactionTypeFilter.all ? 0 : 1) +
      categoryIds.length +
      walletIds.length;

  bool get isEmpty => activeCount == 0 && query.trim().isEmpty;

  /// True when anything at all narrows the list, including the search text —
  /// this is what decides between "no transactions yet" and "nothing matched".
  bool get isNarrowed => !isEmpty;

  TransactionFilter copyWith({
    TransactionTypeFilter? type,
    Set<String>? categoryIds,
    Set<String>? walletIds,
    String? query,
  }) {
    return TransactionFilter(
      type: type ?? this.type,
      categoryIds: categoryIds ?? this.categoryIds,
      walletIds: walletIds ?? this.walletIds,
      query: query ?? this.query,
    );
  }

  TransactionFilter toggleCategory(String id) => copyWith(
    categoryIds: categoryIds.contains(id)
        ? (categoryIds.toSet()..remove(id))
        : (categoryIds.toSet()..add(id)),
  );

  TransactionFilter toggleWallet(String id) => copyWith(
    walletIds: walletIds.contains(id)
        ? (walletIds.toSet()..remove(id))
        : (walletIds.toSet()..add(id)),
  );

  /// Drops every filter but keeps the search text, which the user clears by
  /// emptying the search box.
  TransactionFilter cleared() => TransactionFilter(query: query);

  /// Applies everything to [transactions], preserving their order.
  List<Transaction> apply(List<Transaction> transactions) {
    final needle = query.toLowerCase().trim();

    return transactions.where((t) {
      if (!type.matches(t)) return false;
      if (categoryIds.isNotEmpty && !categoryIds.contains(t.categoryId)) {
        return false;
      }
      if (walletIds.isNotEmpty &&
          (t.walletId == null || !walletIds.contains(t.walletId))) {
        return false;
      }
      if (needle.isEmpty) return true;
      return (t.note?.toLowerCase().contains(needle) ?? false) ||
          t.amount.toString().contains(needle);
    }).toList();
  }

  @override
  bool operator ==(Object other) =>
      other is TransactionFilter &&
      other.type == type &&
      other.query == query &&
      _setEquals(other.categoryIds, categoryIds) &&
      _setEquals(other.walletIds, walletIds);

  @override
  int get hashCode => Object.hash(
    type,
    query,
    Object.hashAllUnordered(categoryIds),
    Object.hashAllUnordered(walletIds),
  );
}

bool _setEquals(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);

/// Totals shown above the list for whatever is currently in view.
({int count, int income, int expense}) summarise(List<Transaction> txs) {
  var income = 0;
  var expense = 0;
  for (final t in txs) {
    if (t.isExpense) {
      expense += t.amount;
    } else {
      income += t.amount;
    }
  }
  return (count: txs.length, income: income, expense: expense);
}
