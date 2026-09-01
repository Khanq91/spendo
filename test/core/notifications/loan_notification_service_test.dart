import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/core/notifications/loan_notification_service.dart';
import 'package:spendo/features/loan/domain/installment_status.dart';
import 'package:spendo/features/loan/domain/loan.dart';

final _now = DateTime(2026, 11, 1, 8);

Loan _loan({
  RepaymentMode mode = RepaymentMode.installment,
  bool closed = false,
  int principal = 9000000,
}) => Loan(
  id: 'l1',
  title: 'Vay mua xe',
  type: LoanType.borrowed,
  principal: principal,
  contactName: 'Anh A',
  startDate: DateTime(2026, 8),
  colorHex: '#B23A2E',
  isClosed: closed,
  repaymentMode: mode,
);

LoanInstallment _installment(int seq, DateTime due, {int amount = 3000000}) =>
    LoanInstallment(
      id: 'i$seq',
      loanId: 'l1',
      seq: seq,
      amount: amount,
      dueDate: due,
    );

List<InstallmentProgress> _progress(
  List<LoanInstallment> installments, {
  int paid = 0,
  int principal = 9000000,
}) => allocatePayments(
  principal: principal,
  installments: installments,
  totalPaid: paid,
  today: _now,
);

void main() {
  group('reminderTime', () {
    test('fires at 09:00 the morning before the instalment is due', () {
      expect(
        LoanNotificationService.reminderTime(DateTime(2026, 11, 15)),
        DateTime(2026, 11, 14, 9),
      );
    });

    test('crossing a month boundary lands on the last day of the one before', () {
      expect(
        LoanNotificationService.reminderTime(DateTime(2026, 12, 1)),
        DateTime(2026, 11, 30, 9),
      );
    });

    test('a due date carrying a time of day is still reminded at 09:00', () {
      expect(
        LoanNotificationService.reminderTime(DateTime(2026, 11, 15, 23, 30)),
        DateTime(2026, 11, 14, 9),
      );
    });
  });

  group('notificationId', () {
    test('stays inside the range reserved for instalments', () {
      // Below it: the daily nudge (0), the test notifications (99, 9999) and
      // recurring reminders (1000–16999). Colliding would cancel someone
      // else's notification.
      for (final id in ['i1', 'abc-def', '', 'x' * 64]) {
        final notifId = LoanNotificationService.notificationId(id);
        expect(notifId, greaterThanOrEqualTo(kLoanIdBase));
        expect(notifId, lessThan(kLoanIdBase + 10000));
      }
    });

    test('the same instalment always gets the same id', () {
      // The id is derived, not stored — which is the only way a reminder can
      // be cancelled later without a table of what was scheduled.
      expect(
        LoanNotificationService.notificationId('i1'),
        LoanNotificationService.notificationId('i1'),
      );
    });

    test('different instalments get different ids', () {
      final ids = {
        for (final id in ['i1', 'i2', 'i3', 'i4'])
          LoanNotificationService.notificationId(id),
      };
      expect(ids.length, 4);
    });
  });

  group('dueForReminder', () {
    test('takes the next few unpaid instalments, in order', () {
      final installments = [
        _installment(1, DateTime(2026, 11, 15)),
        _installment(2, DateTime(2026, 12, 15)),
        _installment(3, DateTime(2027, 1, 15)),
        _installment(4, DateTime(2027, 2, 15)),
        _installment(5, DateTime(2027, 3, 15)),
      ];

      final due = LoanNotificationService.dueForReminder(
        _loan(principal: 15000000),
        _progress(installments, principal: 15000000),
        now: _now,
      );

      // Only a window's worth: the rest are picked up next time the app opens,
      // rather than queuing a hundred pending notifications.
      expect(due.map((d) => d.installment.seq), [1, 2, 3]);
    });

    test('a settled instalment is skipped and the next one pulled in', () {
      final installments = [
        _installment(1, DateTime(2026, 11, 15)),
        _installment(2, DateTime(2026, 12, 15)),
        _installment(3, DateTime(2027, 1, 15)),
      ];

      final due = LoanNotificationService.dueForReminder(
        _loan(),
        _progress(installments, paid: 3000000),
        now: _now,
      );

      expect(due.map((d) => d.installment.seq), [2, 3]);
    });

    test('an instalment paid short keeps its reminder', () {
      final installments = [_installment(1, DateTime(2026, 11, 15))];

      final due = LoanNotificationService.dueForReminder(
        _loan(principal: 3000000),
        _progress(installments, paid: 1000000, principal: 3000000),
        now: _now,
      );

      expect(due.single.shortfall, 2000000);
    });

    test('an instalment whose reminder time has passed is not scheduled', () {
      // 09:00 the day before is already behind us, so scheduling it would
      // either fire immediately or be dropped by the platform.
      final installments = [
        _installment(1, DateTime(2026, 11, 1)),
        _installment(2, DateTime(2026, 11, 2)),
        _installment(3, DateTime(2026, 12, 15)),
      ];

      final due = LoanNotificationService.dueForReminder(
        _loan(),
        _progress(installments),
        now: _now,
      );

      // Instalment 1 is due today, so its reminder (31 Oct 09:00) is behind
      // us; instalment 2's is 1 Nov 09:00, still an hour ahead of `now`.
      expect(due.map((d) => d.installment.seq), [2, 3]);
    });

    test('an overdue instalment gets no reminder — the date is behind it', () {
      final installments = [_installment(1, DateTime(2026, 10, 1))];

      expect(
        LoanNotificationService.dueForReminder(
          _loan(principal: 3000000),
          _progress(installments, principal: 3000000),
          now: _now,
        ),
        isEmpty,
      );
    });

    test('a settled loan reminds about nothing', () {
      final installments = [_installment(1, DateTime(2026, 12, 15))];

      expect(
        LoanNotificationService.dueForReminder(
          _loan(closed: true, principal: 3000000),
          _progress(installments, principal: 3000000),
          now: _now,
        ),
        isEmpty,
      );
    });

    test('a free-repayment loan reminds about nothing', () {
      final installments = [_installment(1, DateTime(2026, 12, 15))];

      expect(
        LoanNotificationService.dueForReminder(
          _loan(mode: RepaymentMode.free, principal: 3000000),
          _progress(installments, principal: 3000000),
          now: _now,
        ),
        isEmpty,
      );
    });

    test('a fully paid schedule reminds about nothing', () {
      final installments = [
        _installment(1, DateTime(2026, 12, 15)),
        _installment(2, DateTime(2027, 1, 15)),
      ];

      expect(
        LoanNotificationService.dueForReminder(
          _loan(principal: 6000000),
          _progress(installments, paid: 6000000, principal: 6000000),
          now: _now,
        ),
        isEmpty,
      );
    });
  });
}
