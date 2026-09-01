import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/spendo/spendo.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../wallets/presentation/providers/wallet_provider.dart';
import '../../domain/transaction_filter.dart';
import '../providers/transaction_provider.dart';

/// The filter sheet behind the funnel button on screen 03.
///
/// Category and wallet filters live here rather than in a chip strip above the
/// list: the strip could only hold one category and mixed income with expense
/// categories in one unlabelled row.
class TransactionFilterSheet extends ConsumerWidget {
  const TransactionFilterSheet({super.key});

  static Future<void> show(BuildContext context) {
    return SpendoSheet.showModal<void>(
      context: context,
      builder: (_) => const TransactionFilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(transactionFilterProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final wallets = ref.watch(walletsProvider).valueOrNull ?? const [];

    // Only the categories that can appear under the current type filter.
    final relevant = categories.where((c) {
      return switch (filter.type) {
        TransactionTypeFilter.all => true,
        TransactionTypeFilter.expense => !c.isIncome,
        TransactionTypeFilter.income => c.isIncome,
      };
    }).toList();

    void update(TransactionFilter next) =>
        ref.read(transactionFilterProvider.notifier).state = next;

    return SpendoSheet(
      header: SpendoSheetHeader(
        title: 'Lọc giao dịch',
        onCancel: filter.activeCount == 0
            ? null
            : () => update(filter.cleared()),
        cancelLabel: 'Xoá lọc',
        action: SpendoButton(
          label: 'Xong',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (relevant.isNotEmpty) ...[
              const SpendoSectionHeader(
                label: 'Danh mục',
                padding: EdgeInsets.only(top: 4, bottom: 10),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in relevant)
                    SpendoChip(
                      label: category.name,
                      selected: filter.categoryIds.contains(category.id),
                      onTap: () => update(filter.toggleCategory(category.id)),
                    ),
                ],
              ),
            ],
            if (wallets.isNotEmpty) ...[
              const SpendoSectionHeader(label: 'Nguồn tiền'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final wallet in wallets)
                    SpendoChip(
                      label: wallet.name,
                      selected: filter.walletIds.contains(wallet.id),
                      leading: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: wallet.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      onTap: () => update(filter.toggleWallet(wallet.id)),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
