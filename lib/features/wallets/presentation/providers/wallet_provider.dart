import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../transactions/data/transaction_repository.dart';
import '../../../transactions/domain/transaction.dart';
import '../../data/wallet_repository.dart';
import '../../domain/wallet.dart';

final walletRepoProvider = Provider((_) => WalletRepository());

/// Stream wallets active (chưa archive).
final walletsProvider = StreamProvider<List<Wallet>>((ref) {
  return ref.watch(walletRepoProvider).watchAll();
});

/// Stream wallets đã archive.
final archivedWalletsProvider = StreamProvider<List<Wallet>>((ref) {
  return ref.watch(walletRepoProvider).watchArchived();
});

/// Balance của 1 wallet: initial + income - expense.
/// Query theo dõi cả initial_balance và transactions của wallet.
final walletBalanceProvider = StreamProvider.autoDispose.family<int, String>((
  ref,
  walletId,
) {
  return ref
      .watch(walletRepoProvider)
      .watchFinancialSummary(walletId)
      .map((summary) => summary.balance);
});

/// Breakdown của 1 wallet: (x1 = initialBalance + income, x2 = expense).
/// Dùng để vẽ progress bar ở WalletDetailScreen.
final walletBreakdownProvider = StreamProvider.autoDispose
    .family<({int x1, int x2}), String>((ref, walletId) {
      return ref
          .watch(walletRepoProvider)
          .watchFinancialSummary(walletId)
          .map((summary) => (x1: summary.x1, x2: summary.x2));
    });

/// Tổng net worth = sum balance tất cả wallet active.
final totalNetWorthProvider = StreamProvider.autoDispose<int>((ref) {
  return ref
      .watch(walletRepoProvider)
      .watchActiveFinancialSummary()
      .map((summary) => summary.balance);
});

/// Breakdown toàn bộ wallets: (x1 = sum(initialBalance + income), x2 = sum(expense)).
/// Dùng để vẽ progress bar ở HomeScreen và WalletsScreen.
final totalWalletBreakdownProvider =
    StreamProvider.autoDispose<({int x1, int x2})>((ref) {
      return ref
          .watch(walletRepoProvider)
          .watchActiveFinancialSummary()
          .map((summary) => (x1: summary.x1, x2: summary.x2));
    });

/// Transactions của 1 wallet — filter theo tháng.
final walletTxByMonthProvider = StreamProvider.autoDispose
    .family<List<Transaction>, ({String walletId, int year, int month})>((
      ref,
      args,
    ) {
      return TransactionRepository().watchByWalletAndMonth(
        args.walletId,
        args.year,
        args.month,
      );
    });

/// Transactions của 1 wallet — toàn bộ lịch sử.
final walletTxAllProvider = StreamProvider.autoDispose
    .family<List<Transaction>, String>((ref, walletId) {
      return TransactionRepository().watchByWallet(walletId);
    });
