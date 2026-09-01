import 'loan.dart';

/// How far apart two consecutive instalments fall.
enum InstallmentCycle {
  monthly,
  biweekly,
  weekly;

  String get label => switch (this) {
    InstallmentCycle.monthly => 'Hàng tháng',
    InstallmentCycle.biweekly => '2 tuần',
    InstallmentCycle.weekly => 'Hàng tuần',
  };
}

/// The two ways of describing a schedule: by how many instalments, or by how
/// much each one is.
enum GeneratorMode { byCount, byAmount }

/// Beyond this a schedule stops being a plan and starts being a wall of rows —
/// "theo số tiền" with a small amount is the way to trip it.
const int kMaxInstallments = 100;

/// Instalment amounts are rounded down to this, and the remainder is swallowed
/// by the last one, so the schedule reads in round numbers.
const int _kRounding = 1000;

/// The nth date after [first] on [cycle].
///
/// Monthly keeps the day-of-month of the first instalment; a month too short
/// for it (the 31st in a 30-day month) falls back to that month's last day
/// rather than spilling into the next one.
DateTime installmentDate(DateTime first, InstallmentCycle cycle, int index) {
  final start = DateTime(first.year, first.month, first.day);
  if (index <= 0) return start;

  return switch (cycle) {
    InstallmentCycle.weekly => start.add(Duration(days: 7 * index)),
    InstallmentCycle.biweekly => start.add(Duration(days: 14 * index)),
    InstallmentCycle.monthly => _addMonths(start, index),
  };
}

DateTime _addMonths(DateTime start, int months) {
  final total = start.month - 1 + months;
  final year = start.year + total ~/ 12;
  final month = total % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, start.day > lastDay ? lastDay : start.day);
}

/// Splits [total] into [count] instalments.
///
/// Every instalment but the last is `total ÷ count` rounded down to the
/// thousand; the last one takes whatever is left, so the parts always add back
/// up to [total] exactly and the odd đồng never goes missing.
List<int> splitEvenly(int total, int count) {
  if (count <= 0 || total <= 0) return const [];
  if (count == 1) return [total];

  var base = (total ~/ count ~/ _kRounding) * _kRounding;
  // A total too small to round to a thousand per instalment still has to be
  // split somehow; fall back to the plain quotient.
  if (base <= 0) base = total ~/ count;

  final head = base * (count - 1);
  if (head >= total) {
    // Rounding overshot (tiny totals) — spread it flat and let the last row
    // absorb the difference.
    final flat = total ~/ count;
    return [
      for (var i = 0; i < count - 1; i++) flat,
      total - flat * (count - 1),
    ];
  }
  return [for (var i = 0; i < count - 1; i++) base, total - head];
}

/// Splits [total] into instalments of [perInstallment], the last one holding
/// the remainder (so it can be smaller).
List<int> splitByAmount(int total, int perInstallment) {
  if (total <= 0 || perInstallment <= 0) return const [];
  final count = (total + perInstallment - 1) ~/ perInstallment;
  if (count > kMaxInstallments) return const [];

  final head = perInstallment * (count - 1);
  return [
    for (var i = 0; i < count - 1; i++) perInstallment,
    total - head,
  ];
}

/// Builds a schedule for [loanId] — the amounts from [splitEvenly] or
/// [splitByAmount], the dates from [firstDueDate] stepped by [cycle].
///
/// Ids are `seq`-derived placeholders; the repository mints real ones on save.
List<LoanInstallment> generateInstallments({
  required String loanId,
  required int total,
  required GeneratorMode mode,
  required int input,
  required DateTime firstDueDate,
  required InstallmentCycle cycle,
}) {
  if (input <= 0) return const [];
  if (mode == GeneratorMode.byCount && input > kMaxInstallments) return const [];

  final amounts = mode == GeneratorMode.byCount
      ? splitEvenly(total, input)
      : splitByAmount(total, input);
  if (amounts.isEmpty) return const [];

  return [
    for (var i = 0; i < amounts.length; i++)
      LoanInstallment(
        id: 'gen_${i + 1}',
        loanId: loanId,
        seq: i + 1,
        amount: amounts[i],
        dueDate: installmentDate(firstDueDate, cycle, i),
      ),
  ];
}

/// Re-sorts a hand-edited list by due date and renumbers `seq` from 1, so
/// adding or removing a row never leaves a gap or a duplicate.
List<LoanInstallment> resequence(List<LoanInstallment> installments) {
  final ordered = [...installments]
    ..sort((a, b) {
      final byDate = a.dueDate.compareTo(b.dueDate);
      return byDate != 0 ? byDate : a.seq.compareTo(b.seq);
    });
  return [
    for (var i = 0; i < ordered.length; i++) ordered[i].copyWith(seq: i + 1),
  ];
}

/// Pushes the whole difference between the schedule and [target] onto the last
/// instalment — the one-tap fix for a hand-edited schedule that no longer adds
/// up. Returns the list unchanged if that would leave the last row at zero or
/// below.
List<LoanInstallment> absorbIntoLast(
  List<LoanInstallment> installments,
  int target,
) {
  if (installments.isEmpty) return installments;
  final ordered = resequence(installments);
  final sum = ordered.fold(0, (acc, i) => acc + i.amount);
  final last = ordered.last;
  final corrected = last.amount + (target - sum);
  if (corrected <= 0) return ordered;
  return [...ordered.take(ordered.length - 1), last.copyWith(amount: corrected)];
}
