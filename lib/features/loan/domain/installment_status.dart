import 'loan.dart';

/// Where one instalment stands, worked out from what has actually been paid.
enum InstallmentState {
  /// Fully covered by payments.
  paid,

  /// Partly covered — [InstallmentProgress.shortfall] is what is missing.
  partial,

  /// Nothing (or not enough) paid and the due date has passed.
  overdue,

  /// Still ahead.
  upcoming;

  String get label => switch (this) {
    InstallmentState.paid => 'Đã trả',
    InstallmentState.partial => 'Trả thiếu',
    InstallmentState.overdue => 'Quá hạn',
    InstallmentState.upcoming => 'Chưa đến hạn',
  };
}

/// One instalment plus the slice of the payments that landed on it.
class InstallmentProgress {
  final LoanInstallment installment;

  /// How much of [LoanInstallment.amount] the waterfall filled.
  final int allocated;
  final InstallmentState state;

  const InstallmentProgress({
    required this.installment,
    required this.allocated,
    required this.state,
  });

  int get shortfall => (installment.amount - allocated).clamp(
    0,
    installment.amount,
  );

  bool get isSettled => state == InstallmentState.paid;
}

/// Pours [totalPaid] into [installments] in `seq` order — an instalment has to
/// fill up before the next one gets anything.
///
/// Instalments are a plan, payments are what happened, and nothing links a
/// payment to an instalment (mục 2.2 của PLAN). Deriving each state this way makes
/// paying short, paying over, paying two instalments at once and paying early
/// all fall out correctly without a rule for each.
///
/// A schedule built halfway through a loan covers only what is left, so the
/// money paid *before* the schedule existed must not fill its first rows:
/// `offset = principal − sum(instalments)` is exactly that head start, and it
/// is skimmed off the top before anything is poured.
List<InstallmentProgress> allocatePayments({
  required int principal,
  required List<LoanInstallment> installments,
  required int totalPaid,
  required DateTime today,
}) {
  if (installments.isEmpty) return const [];

  final ordered = [...installments]..sort((a, b) => a.seq.compareTo(b.seq));
  final scheduled = ordered.fold(0, (sum, i) => sum + i.amount);

  final offset = (principal - scheduled).clamp(0, principal < 0 ? 0 : principal);
  var pool = (totalPaid - offset).clamp(0, totalPaid < 0 ? 0 : totalPaid);

  final day = DateTime(today.year, today.month, today.day);

  return [
    for (final installment in ordered)
      () {
        final take = pool >= installment.amount ? installment.amount : pool;
        pool -= take;
        final due = DateTime(
          installment.dueDate.year,
          installment.dueDate.month,
          installment.dueDate.day,
        );
        final overdue = due.isBefore(day);

        final state = switch (take) {
          _ when take >= installment.amount && installment.amount > 0 =>
            InstallmentState.paid,
          // A zero-amount row has nothing to owe, so it is never behind.
          _ when installment.amount == 0 => InstallmentState.paid,
          _ when take > 0 => InstallmentState.partial,
          _ when overdue => InstallmentState.overdue,
          _ => InstallmentState.upcoming,
        };

        return InstallmentProgress(
          installment: installment,
          allocated: take,
          state: state,
        );
      }(),
  ];
}

/// The earliest instalment still owing anything — what the detail screen, the
/// list subtitle and the payment sheet all point at.
InstallmentProgress? nextUnsettled(List<InstallmentProgress> progress) {
  for (final entry in progress) {
    if (!entry.isSettled) return entry;
  }
  return null;
}

/// How many instalments are fully covered.
int settledCount(List<InstallmentProgress> progress) =>
    progress.where((p) => p.isSettled).length;
