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

/// Summary cho Home card:
/// - totalBorrowed: tổng đang nợ (principal, chưa tính đã trả)
/// - hasOverdue: có khoản quá hạn không
/// - hasUpcoming: có khoản sắp đến hạn (≤ 7 ngày) không
/// - count: số khoản đang active
class LoanSummary {
  final int count;
  final int totalBorrowed; // type == borrowed
  final int totalLent;     // type == lent
  final bool hasOverdue;
  final bool hasUpcoming;

  const LoanSummary({
    required this.count,
    required this.totalBorrowed,
    required this.totalLent,
    required this.hasOverdue,
    required this.hasUpcoming,
  });

  bool get isEmpty => count == 0;

  /// Trạng thái nặng nhất để hiện badge
  LoanStatus get worstStatus {
    if (hasOverdue) return LoanStatus.overdue;
    if (hasUpcoming) return LoanStatus.upcoming;
    return LoanStatus.active;
  }
}

final loanSummaryProvider = Provider.autoDispose<LoanSummary>((ref) {
  final loans = ref.watch(activeLoansProvider);
  if (loans.isEmpty) {
    return const LoanSummary(
      count: 0,
      totalBorrowed: 0,
      totalLent: 0,
      hasOverdue: false,
      hasUpcoming: false,
    );
  }

  int borrowed = 0;
  int lent = 0;
  bool overdue = false;
  bool upcoming = false;

  for (final l in loans) {
    if (l.type == LoanType.borrowed) {
      borrowed += l.principal;
    } else {
      lent += l.principal;
    }
    final s = l.status;
    if (s == LoanStatus.overdue) overdue = true;
    if (s == LoanStatus.upcoming) upcoming = true;
  }

  return LoanSummary(
    count: loans.length,
    totalBorrowed: borrowed,
    totalLent: lent,
    hasOverdue: overdue,
    hasUpcoming: upcoming,
  );
});