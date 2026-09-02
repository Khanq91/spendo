import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../shared/widgets/motion/motion.dart';
import '../../../../shared/widgets/spendo/spendo.dart';
import '../../../categories/domain/category.dart';
import '../../../loan/data/loan_repository.dart';
import '../../domain/transaction.dart';
import 'delete_transaction_action.dart';
import 'transaction_list_item.dart';

enum GroupedTransactionStyle { plain, filledHeader }

class GroupedTransactionSliver extends StatelessWidget {
  const GroupedTransactionSliver({
    super.key,
    required this.transactions,
    required this.categoryMap,
    this.style = GroupedTransactionStyle.plain,
    this.animateItems = true,
    this.dismissible = false,
  });

  final List<Transaction> transactions;
  final Map<String, Category> categoryMap;
  final GroupedTransactionStyle style;
  final bool animateItems;

  /// Allow swiping a row away, with an undo snackbar. Off on Home, where the
  /// list is a summary rather than the place you manage entries.
  final bool dismissible;

  @override
  Widget build(BuildContext context) {
    final rows = _flatten(transactions);
    final childIndexes = <Object, int>{};
    for (var index = 0; index < rows.length; index++) {
      final row = rows[index];
      childIndexes[switch (row) {
            _DayRow() => 'day_${_dateKey(row.date)}',
            _TransactionRow() => row.transaction.id,
          }] =
          index;
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final row = rows[index];
          return switch (row) {
            _DayRow() => _DayHeader(
              key: ValueKey('day_${_dateKey(row.date)}'),
              date: row.date,
              dayNet: row.dayNet,
              style: style,
            ),
            _TransactionRow() => KeyedSubtree(
              key: ValueKey(row.transaction.id),
              child: _maybeReveal(
                row.transaction.id,
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _maybeDismissible(
                      context,
                      row.transaction,
                      TransactionListItem(
                        transaction: row.transaction,
                        category: categoryMap[row.transaction.categoryId],
                      ),
                    ),
                    if (style == GroupedTransactionStyle.filledHeader)
                      Divider(
                        height: 1,
                        indent: 68,
                        endIndent: 16,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                  ],
                ),
              ),
            ),
          };
        },
        childCount: rows.length,
        findChildIndexCallback: (key) {
          if (key is! ValueKey) return null;
          return childIndexes[key.value];
        },
      ),
    );
  }

  /// Rows pop in as they first enter the viewport when the host wraps its
  /// scroll view in a [RevealScope]; day headers stay put (Phase 4).
  Widget _maybeReveal(String id, Widget child) {
    if (!animateItems) return child;
    return RevealItem(id: id, child: child);
  }

  Widget _maybeDismissible(
    BuildContext context,
    Transaction transaction,
    Widget child,
  ) {
    if (!dismissible) return child;

    final cs = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey('dismiss_${transaction.id}'),
      direction: DismissDirection.endToStart,
      background: ColoredBox(
        color: cs.error,
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Icon(LucideIcons.trash2, size: 21, color: cs.onError),
          ),
        ),
      ),
      // A loan's transaction cannot be deleted from here, so the swipe is
      // stopped before the row animates away and springs back (PLAN §2.9).
      confirmDismiss: (_) async {
        if (transaction.source != kLoanTransactionSource) return true;
        await deleteTransactionWithUndo(context, transaction);
        return false;
      },
      // The row is gone as soon as it is swiped; the snackbar carries the undo,
      // so there is no confirm step in the way.
      onDismissed: (_) => deleteTransactionWithUndo(context, transaction),
      child: child,
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    super.key,
    required this.date,
    required this.dayNet,
    required this.style,
  });

  final DateTime date;
  final int dayNet;
  final GroupedTransactionStyle style;

  @override
  Widget build(BuildContext context) {
    final isPositive = dayNet >= 0;
    final header = SpendoDayHeader(
      label: formatDayHeader(date),
      totalText: '${isPositive ? '+' : '−'}${formatVND(dayNet.abs())}',
      totalIsIncome: isPositive,
      padding: style == GroupedTransactionStyle.filledHeader
          ? const EdgeInsets.fromLTRB(16, 8, 16, 6)
          : const EdgeInsets.fromLTRB(16, 10, 16, 2),
    );

    if (style == GroupedTransactionStyle.filledHeader) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: header,
      );
    }

    return header;
  }
}

sealed class _GroupedRow {
  const _GroupedRow();
}

class _DayRow extends _GroupedRow {
  const _DayRow(this.date, this.dayNet);

  final DateTime date;
  final int dayNet;
}

class _TransactionRow extends _GroupedRow {
  const _TransactionRow(this.transaction);

  final Transaction transaction;
}

List<_GroupedRow> _flatten(List<Transaction> transactions) {
  final grouped = <String, List<Transaction>>{};
  for (final transaction in transactions) {
    grouped
        .putIfAbsent(_dateKey(transaction.createdAt), () => [])
        .add(transaction);
  }

  final rows = <_GroupedRow>[];
  for (final transactionsForDay in grouped.values) {
    final dayNet = transactionsForDay.fold<int>(
      0,
      (sum, transaction) =>
          transaction.isExpense
              ? sum - transaction.amount
              : sum + transaction.amount,
    );
    rows.add(_DayRow(transactionsForDay.first.createdAt, dayNet));
    for (final transaction in transactionsForDay) {
      rows.add(_TransactionRow(transaction));
    }
  }
  return rows;
}

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}'
    '${date.month.toString().padLeft(2, '0')}'
    '${date.day.toString().padLeft(2, '0')}';
