import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/loan_repository.dart';
import '../../domain/loan.dart';

final loanRepoProvider = Provider((_) => LoanRepository());

final loansProvider = StreamProvider<List<Loan>>((ref) {
  return ref.watch(loanRepoProvider).watchAll();
});

/// Chỉ loans đang active (chưa closed).
final activeLoansProvider = Provider.autoDispose<List<Loan>>((ref) {
  return ref.watch(loansProvider).valueOrNull
      ?.where((l) => !l.isClosed)
      .toList() ?? [];
});

/// Summary cho Home — dùng stream để tính remaining (principal - paid).
class LoanSummary {
  final int count;
  final int remainingBorrowed; // tổng còn nợ (principal - paid) type==borrowed
  final int remainingLent;     // tổng còn được trả (principal - paid) type==lent
  final bool hasOverdue;
  final bool hasUpcoming;
  // Số lượng khoản overdue/upcoming để hiện badge số
  final int overdueCount;
  final int upcomingCount;

  const LoanSummary({
    required this.count,
    required this.remainingBorrowed,
    required this.remainingLent,
    required this.hasOverdue,
    required this.hasUpcoming,
    required this.overdueCount,
    required this.upcomingCount,
  });

  bool get isEmpty => count == 0;

  LoanStatus get worstStatus {
    if (hasOverdue) return LoanStatus.overdue;
    if (hasUpcoming) return LoanStatus.upcoming;
    return LoanStatus.active;
  }

  /// Tổng badge count để hiển thị (overdue ưu tiên hơn)
  int get alertCount => overdueCount > 0 ? overdueCount : upcomingCount;
}

/// StreamProvider — reactive với cả loans lẫn payments.
final loanSummaryProvider = StreamProvider.autoDispose<LoanSummary>((ref) {
  final repo = ref.watch(loanRepoProvider);
  // Watch loans stream để trigger khi loans thay đổi
  return repo.watchSummaryWithRemaining();
});

/// Convenience provider — trả LoanSummary.empty khi loading/error
/// để Home không cần handle AsyncValue.
final loanSummaryDataProvider = Provider.autoDispose<LoanSummary>((ref) {
  return ref.watch(loanSummaryProvider).valueOrNull ?? const LoanSummary(
    count: 0,
    remainingBorrowed: 0,
    remainingLent: 0,
    hasOverdue: false,
    hasUpcoming: false,
    overdueCount: 0,
    upcomingCount: 0,
  );
});