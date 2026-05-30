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
/// Watch walletsProvider để trigger rebuild khi initial_balance thay đổi.
final walletBalanceProvider = FutureProvider.autoDispose.family<int, String>((
    ref,
    walletId,
    ) async {
  // Watch stream wallet để reactive khi initial_balance được sửa
  ref.watch(walletsProvider);
  return ref.watch(walletRepoProvider).calculateBalance(walletId);
});

/// Breakdown của 1 wallet: (x1 = initialBalance + income, x2 = expense).
/// Dùng để vẽ progress bar ở WalletDetailScreen.
final walletBreakdownProvider = FutureProvider.autoDispose
    .family<({int x1, int x2}), String>((ref, walletId) async {
  ref.watch(walletsProvider);
  final repo = ref.watch(walletRepoProvider);
  final wallet = await repo.getById(walletId);
  if (wallet == null) return (x1: 0, x2: 0);

  final row = await repo.getIncomeExpense(walletId);
  return (
  x1: wallet.initialBalance + row.income,
  x2: row.expense,
  );
});

/// Tổng net worth = sum balance tất cả wallet active.
final totalNetWorthProvider = FutureProvider.autoDispose<int>((ref) async {
  final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
  final repo = ref.watch(walletRepoProvider);
  int total = 0;
  for (final w in wallets) {
    total += await repo.calculateBalance(w.id);
  }
  return total;
});

/// Breakdown toàn bộ wallets: (x1 = sum(initialBalance + income), x2 = sum(expense)).
/// Dùng để vẽ progress bar ở HomeScreen và WalletsScreen.
final totalWalletBreakdownProvider =
FutureProvider.autoDispose<({int x1, int x2})>((ref) async {
  final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
  final repo = ref.watch(walletRepoProvider);
  int totalX1 = 0;
  int totalX2 = 0;
  for (final w in wallets) {
    final row = await repo.getIncomeExpense(w.id);
    totalX1 += w.initialBalance + row.income;
    totalX2 += row.expense;
  }
  return (x1: totalX1, x2: totalX2);
});

/// Transactions của 1 wallet — filter theo tháng.
final walletTxByMonthProvider = StreamProvider.autoDispose.family<
    List<Transaction>,
    ({String walletId, int year, int month})
>((ref, args) {
  return ref
      .watch(walletRepoProvider)
      .watchAll()
      .asyncMap((_) async {
    final txRepo = TransactionRepository();
    return txRepo.getByWalletAndMonth(args.walletId, args.year, args.month);
  });
});

/// Transactions của 1 wallet — toàn bộ lịch sử.
final walletTxAllProvider = StreamProvider.autoDispose
    .family<List<Transaction>, String>((ref, walletId) {
  return ref.watch(walletRepoProvider).watchAll().asyncMap((_) async {
    final txRepo = TransactionRepository();
    return txRepo.getByWallet(walletId);
  });
});