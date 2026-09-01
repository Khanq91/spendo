import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/features/loan/domain/installment_generator.dart';
import 'package:spendo/features/loan/domain/loan.dart';

void main() {
  group('splitEvenly', () {
    test('rounds down to the thousand and pushes the odd đồng onto the last', () {
      // The acceptance case from the plan: 10tr over 3 instalments.
      expect(splitEvenly(10000000, 3), [3333000, 3333000, 3334000]);
      expect(splitEvenly(10000000, 3).fold(0, (a, b) => a + b), 10000000);
    });

    test('a total that divides cleanly needs no remainder', () {
      expect(splitEvenly(9000000, 3), [3000000, 3000000, 3000000]);
    });

    test('one instalment takes the whole total', () {
      expect(splitEvenly(1234567, 1), [1234567]);
    });

    test('a total too small to round still splits and still adds up', () {
      final parts = splitEvenly(2500, 3);
      expect(parts.length, 3);
      expect(parts.fold(0, (a, b) => a + b), 2500);
      expect(parts.every((p) => p > 0), isTrue);
    });

    test('nothing to split gives nothing back', () {
      expect(splitEvenly(0, 3), isEmpty);
      expect(splitEvenly(1000, 0), isEmpty);
    });
  });

  group('splitByAmount', () {
    test('the last instalment holds the remainder', () {
      // 10tr at 3tr each: three full instalments and one of 1tr.
      expect(splitByAmount(10000000, 3000000), [
        3000000,
        3000000,
        3000000,
        1000000,
      ]);
    });

    test('an exact multiple leaves no short instalment', () {
      expect(splitByAmount(9000000, 3000000), [3000000, 3000000, 3000000]);
    });

    test('an amount small enough to blow past the cap is refused', () {
      // 10tr at 50k each would be 200 rows.
      expect(splitByAmount(10000000, 50000), isEmpty);
      // Exactly at the cap is still fine.
      expect(splitByAmount(10000000, 100000).length, kMaxInstallments);
    });
  });

  group('installmentDate', () {
    test('monthly keeps the day of the month', () {
      final first = DateTime(2026, 10, 15);
      expect(installmentDate(first, InstallmentCycle.monthly, 1),
          DateTime(2026, 11, 15));
      expect(installmentDate(first, InstallmentCycle.monthly, 3),
          DateTime(2027, 1, 15));
    });

    test('the 31st falls back to the last day of a shorter month', () {
      final first = DateTime(2026, 1, 31);
      expect(installmentDate(first, InstallmentCycle.monthly, 1),
          DateTime(2026, 2, 28));
      // The day is taken from the first instalment every time, so a short
      // month does not drag the rest of the schedule down with it.
      expect(installmentDate(first, InstallmentCycle.monthly, 2),
          DateTime(2026, 3, 31));
      expect(installmentDate(first, InstallmentCycle.monthly, 3),
          DateTime(2026, 4, 30));
    });

    test('February in a leap year keeps its 29th', () {
      expect(
        installmentDate(DateTime(2028, 1, 31), InstallmentCycle.monthly, 1),
        DateTime(2028, 2, 29),
      );
    });

    test('weekly and biweekly step by days', () {
      final first = DateTime(2026, 10, 15);
      expect(installmentDate(first, InstallmentCycle.weekly, 2),
          DateTime(2026, 10, 29));
      expect(installmentDate(first, InstallmentCycle.biweekly, 2),
          DateTime(2026, 11, 12));
    });
  });

  group('generateInstallments', () {
    test('numbers instalments from 1 and dates them by the cycle', () {
      final rows = generateInstallments(
        loanId: 'l1',
        total: 10000000,
        mode: GeneratorMode.byCount,
        input: 3,
        firstDueDate: DateTime(2026, 10, 15),
        cycle: InstallmentCycle.monthly,
      );

      expect(rows.map((r) => r.seq), [1, 2, 3]);
      expect(rows.map((r) => r.amount), [3333000, 3333000, 3334000]);
      expect(rows.map((r) => r.dueDate), [
        DateTime(2026, 10, 15),
        DateTime(2026, 11, 15),
        DateTime(2026, 12, 15),
      ]);
    });

    test('more instalments than the cap generates nothing', () {
      final rows = generateInstallments(
        loanId: 'l1',
        total: 10000000,
        mode: GeneratorMode.byCount,
        input: kMaxInstallments + 1,
        firstDueDate: DateTime(2026, 10, 15),
        cycle: InstallmentCycle.monthly,
      );
      expect(rows, isEmpty);
    });
  });

  group('resequence', () {
    test('sorts by due date and renumbers from 1', () {
      final rows = [
        _installment(seq: 1, amount: 100, due: DateTime(2026, 12, 1)),
        _installment(seq: 2, amount: 200, due: DateTime(2026, 10, 1)),
        _installment(seq: 3, amount: 300, due: DateTime(2026, 11, 1)),
      ];

      final ordered = resequence(rows);

      expect(ordered.map((r) => r.seq), [1, 2, 3]);
      expect(ordered.map((r) => r.amount), [200, 300, 100]);
    });

    test('a removed row leaves no gap in the numbering', () {
      final rows = resequence([
        _installment(seq: 1, amount: 100, due: DateTime(2026, 10, 1)),
        _installment(seq: 3, amount: 300, due: DateTime(2026, 12, 1)),
      ]);
      expect(rows.map((r) => r.seq), [1, 2]);
    });
  });

  group('absorbIntoLast', () {
    test('a shortfall is added to the last instalment', () {
      final rows = [
        _installment(seq: 1, amount: 3000000, due: DateTime(2026, 10, 1)),
        _installment(seq: 2, amount: 3000000, due: DateTime(2026, 11, 1)),
      ];

      final fixed = absorbIntoLast(rows, 10000000);

      expect(fixed.map((r) => r.amount), [3000000, 7000000]);
      expect(fixed.fold(0, (a, r) => a + r.amount), 10000000);
    });

    test('an overshoot is taken back off the last instalment', () {
      final rows = [
        _installment(seq: 1, amount: 6000000, due: DateTime(2026, 10, 1)),
        _installment(seq: 2, amount: 6000000, due: DateTime(2026, 11, 1)),
      ];
      expect(absorbIntoLast(rows, 10000000).map((r) => r.amount), [
        6000000,
        4000000,
      ]);
    });

    test('a correction that would zero the last instalment is refused', () {
      // Better to leave the schedule visibly wrong than to write a 0 đồng or
      // negative instalment into it.
      final rows = [
        _installment(seq: 1, amount: 9000000, due: DateTime(2026, 10, 1)),
        _installment(seq: 2, amount: 3000000, due: DateTime(2026, 11, 1)),
      ];
      expect(absorbIntoLast(rows, 9000000).map((r) => r.amount), [
        9000000,
        3000000,
      ]);
    });
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
