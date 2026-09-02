import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/loan_repository.dart';
import '../../domain/installment_status.dart';
import '../../domain/loan.dart';

final loanRepoProvider = Provider((_) => LoanRepository());

/// The spending book — what `/loans`, the detail screen and everything that
/// existed before the tracking book mean by "loans".
///
/// A loan written before the tracking book existed has no flag at all, and the
/// repository's `COALESCE` puts it here (PLAN §2.5).
final loansProvider = StreamProvider<List<Loan>>((ref) {
  return ref.watch(loanRepoProvider).watchAll();
});

/// The tracking book: loans the app only keeps a record of.
final trackingLoansProvider = StreamProvider<List<Loan>>((ref) {
  return ref.watch(loanRepoProvider).watchAll(trackingOnly: true);
});

/// Whichever book [trackingOnly] names — how the one list screen, drawn twice,
/// reads the sổ it was told to show. Two providers rather than a family so a
/// test can still override either book on its own.
StreamProvider<List<Loan>> loansOfBook(bool trackingOnly) =>
    trackingOnly ? trackingLoansProvider : loansProvider;

/// Every loan of both books, for the screens that look one up by id — the
/// detail screen, the payment deep link — which cannot know which sổ it is in.
final allLoansProvider = Provider<List<Loan>>((ref) {
  return [
    ...?ref.watch(loansProvider).valueOrNull,
    ...?ref.watch(trackingLoansProvider).valueOrNull,
  ];
});

/// Whether both books have settled — the detail screen tells "still loading"
/// from "this loan is gone" by it, and a loan can be in either book.
///
/// A book that failed counts as settled: one broken stream must not leave a
/// loan in the other book spinning forever.
final loansLoadedProvider = Provider<bool>((ref) {
  bool settled(AsyncValue<List<Loan>> book) => book.hasValue || book.hasError;
  return settled(ref.watch(loansProvider)) &&
      settled(ref.watch(trackingLoansProvider));
});

/// One loan by id, from whichever sổ holds it — null while the books are
/// still loading, and once the loan is really gone.
final loanByIdProvider = Provider.family<Loan?, String>((ref, id) {
  return ref.watch(allLoansProvider).where((l) => l.id == id).firstOrNull;
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

/// The list screen's segmented filter, one per sổ.
///
/// The audit found the filter reachable only through a query parameter from a
/// screen that no longer exists, so the list itself had no way to narrow. It
/// is a family because the two books are separate screens: narrowing one to
/// "Cho vay" must not narrow the other (PLAN §2.5).
final loanFilterProvider = StateProvider.family<LoanFilter, bool>(
  (_, trackingOnly) => LoanFilter.all,
);

/// How much has been paid against each loan, keyed by loan id.
final paidByLoanProvider = StreamProvider<Map<String, int>>((ref) {
  return ref.watch(loanRepoProvider).watchPaidByLoan();
});

/// One loan's schedule, in seq order. Empty for a free-repayment loan.
final loanInstallmentsProvider = StreamProvider.autoDispose
    .family<List<LoanInstallment>, String>((ref, loanId) {
      return ref.watch(loanRepoProvider).watchInstallments(loanId);
    });

/// Every schedule at once, keyed by loan id — the list screen needs the next
/// due date of each row and cannot afford a stream per row.
final installmentsByLoanProvider =
    StreamProvider<Map<String, List<LoanInstallment>>>((ref) {
      return ref.watch(loanRepoProvider).watchInstallmentsByLoan();
    });

/// The waterfall (`installment_status.dart`) applied to one loan.
///
/// Every screen that shows instalment state reads it from here, so the list,
/// the detail section and the payment sheet can never disagree about which
/// instalment is next.
final installmentProgressProvider = Provider.autoDispose
    .family<List<InstallmentProgress>, String>((ref, loanId) {
      final loan = ref
          .watch(allLoansProvider)
          .where((l) => l.id == loanId)
          .firstOrNull;
      if (loan == null) return const [];

      final installments =
          ref.watch(loanInstallmentsProvider(loanId)).valueOrNull ??
          const <LoanInstallment>[];
      if (installments.isEmpty) return const [];

      final paid = ref.watch(paidByLoanProvider).valueOrNull ?? const {};
      return allocatePayments(
        principal: loan.principal,
        installments: installments,
        totalPaid: paid[loanId] ?? 0,
        today: DateTime.now(),
      );
    });

/// The waterfall for every loan that has a schedule, keyed by loan id.
///
/// The list screen draws a subtitle per row; joining the three streams once
/// here keeps that off the widgets, which the plan asks for explicitly
/// (PLAN §4.8).
final progressByLoanProvider =
    Provider.autoDispose<Map<String, List<InstallmentProgress>>>((ref) {
      final loans = ref.watch(allLoansProvider);
      final schedules =
          ref.watch(installmentsByLoanProvider).valueOrNull ??
          const <String, List<LoanInstallment>>{};
      if (schedules.isEmpty) return const {};

      final paid = ref.watch(paidByLoanProvider).valueOrNull ?? const {};
      final today = DateTime.now();

      return {
        for (final loan in loans)
          if (schedules[loan.id]?.isNotEmpty ?? false)
            loan.id: allocatePayments(
              principal: loan.principal,
              installments: schedules[loan.id]!,
              totalPaid: paid[loan.id] ?? 0,
              today: today,
            ),
      };
    });

/// The date a loan is next answerable for: the next unpaid instalment's due
/// date for a schedule, `loans.due_date` otherwise.
///
/// The list's overdue flag used to come straight off `loans.due_date`, which
/// says nothing useful once the loan pays back in instalments.
DateTime? effectiveDueDate(Loan loan, List<InstallmentProgress> progress) {
  if (loan.repaymentMode != RepaymentMode.installment || progress.isEmpty) {
    return loan.dueDate;
  }
  return nextUnsettled(progress)?.installment.dueDate ?? loan.dueDate;
}

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

/// The spending book's summary — what Home and the widget mean by "loans".
///
/// The tracking book has no summary provider because it needs none: its
/// totals card adds up the rows the list screen already holds. `trackingOnly`
/// on the repository method is what a second one would use (PLAN §2.5).
///
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