import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/features/loan/domain/installment_status.dart';
import 'package:spendo/features/loan/domain/loan.dart';

final _today = DateTime(2026, 11, 1);

/// Three instalments of 2tr each on a 6tr loan, one past, two ahead.
List<LoanInstallment> _schedule() => [
  _installment(seq: 1, amount: 2000000, due: DateTime(2026, 10, 15)),
  _installment(seq: 2, amount: 2000000, due: DateTime(2026, 11, 15)),
  _installment(seq: 3, amount: 2000000, due: DateTime(2026, 12, 15)),
];

List<InstallmentProgress> _run({
  int principal = 6000000,
  List<LoanInstallment>? installments,
  required int paid,
}) => allocatePayments(
  principal: principal,
  installments: installments ?? _schedule(),
  totalPaid: paid,
  today: _today,
);

void main() {
  test('nothing paid leaves the past instalment overdue and the rest ahead', () {
    final progress = _run(paid: 0);

    expect(progress.map((p) => p.state), [
      InstallmentState.overdue,
      InstallmentState.upcoming,
      InstallmentState.upcoming,
    ]);
    expect(progress.first.shortfall, 2000000);
    expect(settledCount(progress), 0);
  });

  test('one lump sum fills instalments in order and stops mid-way', () {
    // The plan's acceptance case: 5tr paid against 3 × 3tr leaves instalment 1
    // settled, instalment 2 short and instalment 3 untouched.
    final progress = _run(
      principal: 9000000,
      installments: [
        _installment(seq: 1, amount: 3000000, due: DateTime(2026, 10, 15)),
        _installment(seq: 2, amount: 3000000, due: DateTime(2026, 11, 15)),
        _installment(seq: 3, amount: 3000000, due: DateTime(2026, 12, 15)),
      ],
      paid: 5000000,
    );

    expect(progress.map((p) => p.state), [
      InstallmentState.paid,
      InstallmentState.partial,
      InstallmentState.upcoming,
    ]);
    expect(progress[1].allocated, 2000000);
    expect(progress[1].shortfall, 1000000);
    expect(settledCount(progress), 1);
  });

  test('paying exactly one instalment settles it and nothing else', () {
    final progress = _run(paid: 2000000);

    expect(progress.map((p) => p.state), [
      InstallmentState.paid,
      InstallmentState.upcoming,
      InstallmentState.upcoming,
    ]);
  });

  test('paying more than the schedule asks for leaves nothing owing', () {
    final progress = _run(paid: 9000000);

    expect(progress.every((p) => p.state == InstallmentState.paid), isTrue);
    expect(nextUnsettled(progress), isNull);
    // The overflow is simply dropped — an instalment never takes more than the
    // amount it is for.
    expect(progress.fold(0, (sum, p) => sum + p.allocated), 6000000);
  });

  test('an overdue instalment paid short still reads as short, not overdue', () {
    final progress = _run(paid: 500000);

    expect(progress.first.state, InstallmentState.partial);
    expect(progress.first.shortfall, 1500000);
  });

  test('money paid before the schedule existed is not poured into it', () {
    // 10tr principal, 4tr already paid, then a schedule for the remaining 6tr:
    // offset = 10tr − 6tr = 4tr, so nothing is allocatable yet (PLAN §2.3).
    final progress = _run(principal: 10000000, paid: 4000000);

    expect(progress.every((p) => p.allocated == 0), isTrue);
    expect(progress.map((p) => p.state), [
      InstallmentState.overdue,
      InstallmentState.upcoming,
      InstallmentState.upcoming,
    ]);
  });

  test('a payment after such a schedule starts filling its first instalment', () {
    final progress = _run(principal: 10000000, paid: 5000000);

    expect(progress.first.allocated, 1000000);
    expect(progress.first.state, InstallmentState.partial);
  });

  test('an instalment due today is not yet overdue', () {
    final progress = allocatePayments(
      principal: 2000000,
      installments: [_installment(seq: 1, amount: 2000000, due: _today)],
      totalPaid: 0,
      today: _today,
    );
    expect(progress.single.state, InstallmentState.upcoming);
  });

  test('the time of day on a due date does not make it overdue', () {
    final progress = allocatePayments(
      principal: 2000000,
      installments: [
        _installment(
          seq: 1,
          amount: 2000000,
          due: DateTime(2026, 11, 1, 23, 59),
        ),
      ],
      totalPaid: 0,
      today: DateTime(2026, 11, 1, 8),
    );
    expect(progress.single.state, InstallmentState.upcoming);
  });

  test('no schedule means no progress to report', () {
    expect(_run(installments: const [], paid: 1000000), isEmpty);
    expect(nextUnsettled(const []), isNull);
  });

  test('instalments out of order are poured by seq, not list order', () {
    final progress = _run(
      installments: [
        _installment(seq: 2, amount: 2000000, due: DateTime(2026, 11, 15)),
        _installment(seq: 1, amount: 2000000, due: DateTime(2026, 10, 15)),
        _installment(seq: 3, amount: 2000000, due: DateTime(2026, 12, 15)),
      ],
      paid: 2000000,
    );

    expect(progress.map((p) => p.installment.seq), [1, 2, 3]);
    expect(progress.first.state, InstallmentState.paid);
  });

  test('nextUnsettled points at the earliest instalment still owing', () {
    final next = nextUnsettled(_run(paid: 3000000));
    expect(next?.installment.seq, 2);
    expect(next?.shortfall, 1000000);
  });
}

LoanInstallment _installment({
  required int seq,
  required int amount,
  required DateTime due,
}) => LoanInstallment(
  id: 'i$seq',
  loanId: 'l1',
  seq: seq,
  amount: amount,
  dueDate: due,
);
