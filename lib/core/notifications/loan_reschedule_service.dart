import 'package:flutter/material.dart';

import '../../features/loan/data/loan_repository.dart';
import '../../features/loan/domain/installment_status.dart';
import '../../features/loan/domain/loan.dart';
import 'loan_notification_service.dart';

/// Keeps instalment reminders in step with the loans they belong to.
///
/// The waterfall decides what is still owed, so every change that moves it —
/// a payment, a payment undone, a schedule edited or dropped — has to be
/// followed by a reschedule. Doing that here rather than at each call site
/// means the rule lives in one place.
class LoanRescheduleService {
  /// Redoes the reminders for one loan.
  ///
  /// Safe to call after anything: it reads the current state and replaces
  /// whatever was pending, so a payment that settles an instalment cancels its
  /// reminder and pulls the next one into the window.
  static Future<void> rescheduleLoan(
    String loanId, {
    LoanRepository? repository,
    DateTime? now,
  }) async {
    try {
      final repo = repository ?? LoanRepository();
      final loan = (await repo.getAll()).where((l) => l.id == loanId).firstOrNull;
      final installments = await repo.getInstallments(loanId);
      if (installments.isEmpty) {
        // The schedule is gone — so are its reminders. The loan may be gone
        // too, in which case the ids are all that is left to cancel by, and
        // the caller passes them through [cancelSchedule] instead.
        return;
      }
      if (loan == null) {
        await LoanNotificationService.cancelAll(
          installments.map((i) => i.id),
        );
        return;
      }

      final paid = await repo.getTotalPaid(loanId);
      final progress = allocatePayments(
        principal: loan.principal,
        installments: installments,
        totalPaid: paid,
        today: now ?? DateTime.now(),
      );
      await LoanNotificationService.rescheduleLoan(
        loan,
        progress,
        now: now,
      );
    } catch (e) {
      // A reminder that fails to reschedule is a nuisance, not a reason to
      // fail the payment or the edit that triggered it.
      debugPrint('[LoanReschedule] $loanId: $e');
    }
  }

  /// Cancels the reminders of instalments that are about to disappear.
  ///
  /// Called *before* a schedule or a loan is deleted, while the ids the
  /// notification ids are derived from can still be read.
  static Future<void> cancelSchedule(Iterable<String> installmentIds) async {
    try {
      await LoanNotificationService.cancelAll(installmentIds);
    } catch (e) {
      debugPrint('[LoanReschedule] cancel: $e');
    }
  }

  /// Redoes the reminders of every loan that repays on a schedule.
  ///
  /// Runs at startup: instalments beyond the scheduling window are picked up
  /// here, which is why opening the app is enough to keep a long schedule
  /// reminded to its end.
  static Future<void> rescheduleAll({
    LoanRepository? repository,
    DateTime? now,
  }) async {
    final repo = repository ?? LoanRepository();
    final loans = await repo.getAll();
    final schedules = await repo.watchInstallmentsByLoan().first;
    final paid = await repo.watchPaidByLoan().first;
    final today = now ?? DateTime.now();

    for (final loan in loans) {
      if (loan.repaymentMode != RepaymentMode.installment) continue;
      final installments = schedules[loan.id];
      if (installments == null || installments.isEmpty) continue;

      await LoanNotificationService.rescheduleLoan(
        loan,
        allocatePayments(
          principal: loan.principal,
          installments: installments,
          totalPaid: paid[loan.id] ?? 0,
          today: today,
        ),
        now: today,
      );
    }
  }
}
