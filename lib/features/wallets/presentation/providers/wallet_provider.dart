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
/// Recalculate mỗi khi transactions thay đổi.
final walletBalanceProvider = FutureProvider.autoDispose.family<int, String>((
  ref,
  walletId,
) async {
  return ref.watch(walletRepoProvider).calculateBalance(walletId);
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

/// Transactions của 1 wallet — filter theo tháng.
final walletTxByMonthProvider = StreamProvider.autoDispose.family<
  List<Transaction>,
  ({String walletId, int year, int month})
>((ref, args) {
  final start = DateTime(args.year, args.month).millisecondsSinceEpoch;
  final end = DateTime(args.year, args.month + 1).millisecondsSinceEpoch;

  return ref
      .watch(walletRepoProvider)
      // dùng db trực tiếp qua repo — watch qua PowerSync
      .watchAll() // trigger rebuild khi wallets thay đổi
      .asyncMap((_) async {
        // Query transactions filter wallet + tháng
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
