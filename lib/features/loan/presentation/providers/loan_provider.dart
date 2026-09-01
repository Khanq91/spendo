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

/// Which side of the ledger the list is showing.
enum LoanFilter {
  all,
  borrowed,
  lent;

  String get label => switch (this) {
    LoanFilter.all => 'Tất cả',
    LoanFilter.borrowed => 'Đang vay',
    LoanFilter.lent => 'Cho vay',
  };

  bool matches(Loan loan) => switch (this) {
    LoanFilter.all => true,
    LoanFilter.borrowed => loan.type == LoanType.borrowed,
    LoanFilter.lent => loan.type == LoanType.lent,
  };

  static LoanFilter fromQuery(String? value) => switch (value) {
    'borrowed' => LoanFilter.borrowed,
    'lent' => LoanFilter.lent,
    _ => LoanFilter.all,
  };
}

/// The list screen's segmented filter.
///
/// The audit found the filter reachable only through a query parameter from a
/// screen that no longer exists, so the list itself had no way to narrow.
final loanFilterProvider = StateProvider<LoanFilter>((_) => LoanFilter.all);

/// How much has been paid against each loan, keyed by loan id.
final paidByLoanProvider = StreamProvider<Map<String, int>>((ref) {
  return ref.watch(loanRepoProvider).watchPaidByLoan();
});

/// What is still owed on [loan] — never below zero, and never above the
/// principal, so an overpayment does not read as a negative balance.
int remainingOf(Loan loan, Map<String, int> paidByLoan) {
  final paid = paidByLoan[loan.id] ?? 0;
  return (loan.principal - paid).clamp(0, loan.principal);
}

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