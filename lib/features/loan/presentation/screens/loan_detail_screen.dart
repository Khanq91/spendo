import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/spendo_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../shared/widgets/spendo/spendo.dart';
import '../../data/loan_repository.dart';
import '../../domain/installment_status.dart';
import '../../domain/loan.dart';
import '../providers/loan_provider.dart';
import '../widgets/add_payment_sheet.dart';
import '../widgets/loan_form_sheet.dart';
import 'installment_schedule_screen.dart';
import 'loan_list_screen.dart' show loanStatusLabel;

/// Payments for one loan.
final loanPaymentsProvider = StreamProvider.autoDispose
    .family<List<LoanPayment>, String>((ref, loanId) {
      return ref.watch(loanRepoProvider).watchPayments(loanId);
    });

/// Screen 12 of the redesign.
class LoanDetailScreen extends ConsumerWidget {
  const LoanDetailScreen({super.key, required this.loanId});

  final String loanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(loansProvider);
    final loan = loansAsync.valueOrNull
        ?.where((l) => l.id == loanId)
        .firstOrNull;

    if (loan == null) {
      // The old screen kept the Loan object it was pushed with, so a loan
      // deleted elsewhere went on rendering as though it still existed.
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SpendoScreenHeader(title: 'Khoản vay'),
              Expanded(
                child: loansAsync.hasValue
                    ? SpendoEmptyState(
                        icon: LucideIcons.circleAlert,
                        title: 'Khoản vay không còn tồn tại',
                        message: 'Có thể khoản vay đã bị xoá ở nơi khác.',
                        actionLabel: 'Quay lại',
                        onAction: () => Navigator.of(context).maybePop(),
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
        ),
      );
    }

    final paymentsAsync = ref.watch(loanPaymentsProvider(loanId));
    final payments = paymentsAsync.valueOrNull ?? const <LoanPayment>[];
    final paid = payments.fold(0, (sum, p) => sum + p.amount);
    final remaining = (loan.principal - paid).clamp(0, loan.principal);
    final installments =
        ref.watch(loanInstallmentsProvider(loanId)).valueOrNull ??
        const <LoanInstallment>[];
    final progress = allocatePayments(
      principal: loan.principal,
      installments: installments,
      totalPaid: paid,
      today: DateTime.now(),
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SpendoScreenHeader(
              title: loan.title,
              actions: [
                SpendoHeaderIconButton(
                  icon: LucideIcons.pencil,
                  tooltip: 'Sửa khoản vay',
                  size: 19,
                  onPressed: () => showLoanFormSheet(context, existing: loan),
                ),
                _LoanMenu(loan: loan),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  _InfoCard(
                    loan: loan,
                    paid: paid,
                    remaining: remaining,
                    progress: progress,
                  ),
                  if (!loan.isClosed)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: remaining == 0
                          // Paying the last of it used to leave the loan open
                          // with no prompt; the button now offers the step the
                          // user is actually at.
                          ? SpendoButton(
                              expand: true,
                              label: 'Đánh dấu tất toán',
                              icon: LucideIcons.check,
                              onPressed: () =>
                                  LoanRepository().close(loan.id),
                            )
                          : SpendoButton(
                              expand: true,
                              label: 'Ghi nhận thanh toán',
                              icon: LucideIcons.plus,
                              onPressed: () {
                                // On a schedule the button pays the instalment
                                // that is next in line, so the common case
                                // arrives with the right amount already in.
                                final next = nextUnsettled(progress);
                                showAddPaymentSheet(
                                  context,
                                  loan: loan,
                                  remaining: next?.shortfall ?? remaining,
                                  installment: next,
                                  installmentCount: progress.length,
                                );
                              },
                            ),
                    ),
                  if (!loan.isClosed)
                    _ScheduleSection(
                      loan: loan,
                      installments: installments,
                      progress: progress,
                      remaining: remaining,
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
                    child: SpendoSectionHeader(
                      label: 'Lịch sử thanh toán (${payments.length})',
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  if (payments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: SpendoEmptyState(
                        icon: LucideIcons.receiptText,
                        title: 'Chưa có thanh toán nào',
                      ),
                    )
                  else
                    for (var i = 0; i < payments.length; i++) ...[
                      if (i > 0) const _PaymentDivider(),
                      _PaymentTile(payment: payments[i]),
                    ],
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 18, 16, 0),
                    child: _Hint(
                      text: 'Vuốt trái một thanh toán để xoá — có Hoàn tác.',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Schedule ─────────────────────────────────────────────────────────────────

/// The repayment schedule, or the offer to build one.
///
/// Progress is measured against what the schedule plans for, not against the
/// principal — the two differ whenever a schedule was built partway through a
/// loan, and the bar above already tracks the principal.
class _ScheduleSection extends ConsumerWidget {
  const _ScheduleSection({
    required this.loan,
    required this.installments,
    required this.progress,
    required this.remaining,
  });

  final Loan loan;
  final List<LoanInstallment> installments;
  final List<InstallmentProgress> progress;
  final int remaining;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (loan.repaymentMode != RepaymentMode.installment ||
        installments.isEmpty) {
      return _ScheduleCta(loan: loan, remaining: remaining);
    }

    final cs = Theme.of(context).colorScheme;
    final scheduled = installments.fold(0, (sum, i) => sum + i.amount);
    final allocated = progress.fold(0, (sum, p) => sum + p.allocated);
    final settled = settledCount(progress);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SpendoSectionHeader(
            label: 'Lịch trả',
            padding: EdgeInsets.zero,
            trailing: _ScheduleMenu(
              loan: loan,
              installments: installments,
              remaining: remaining,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Đã xong $settled/${installments.length} đợt',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Text(
                formatVND(scheduled),
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SpendoProgressBar(
            value: scheduled > 0 ? allocated / scheduled : 0,
            color: cs.primary,
          ),
          const SizedBox(height: 10),
          _InstallmentList(loan: loan, progress: progress),
        ],
      ),
    );
  }
}

/// Free-repayment loans get the door to a schedule, nothing more.
class _ScheduleCta extends StatelessWidget {
  const _ScheduleCta({required this.loan, required this.remaining});

  final Loan loan;
  final int remaining;

  @override
  Widget build(BuildContext context) {
    if (loan.isClosed || remaining <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SpendoButton.outline(
        expand: true,
        label: 'Tạo lịch trả góp',
        icon: LucideIcons.calendarRange,
        // The schedule covers what is left, not the principal: money paid
        // before the schedule existed is no part of the plan (PLAN §2.1).
        onPressed: () =>
            openInstallmentSchedule(context, loan: loan, target: remaining),
      ),
    );
  }
}

class _ScheduleMenu extends StatelessWidget {
  const _ScheduleMenu({
    required this.loan,
    required this.installments,
    required this.remaining,
  });

  final Loan loan;
  final List<LoanInstallment> installments;
  final int remaining;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      tooltip: 'Tuỳ chọn lịch trả',
      icon: Icon(LucideIcons.ellipsis, size: 18, color: cs.onSurfaceVariant),
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      padding: EdgeInsets.zero,
      onSelected: (value) => value == 'edit' ? _edit(context) : _clear(context),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(LucideIcons.pencil, size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: 12),
              const Text('Sửa lịch'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'clear',
          child: Row(
            children: [
              Icon(LucideIcons.calendarX, size: 18, color: cs.error),
              const SizedBox(width: 12),
              Text('Xoá lịch', style: TextStyle(color: cs.error)),
            ],
          ),
        ),
      ],
    );
  }

  void _edit(BuildContext context) {
    final scheduled = installments.fold(0, (sum, i) => sum + i.amount);
    openInstallmentSchedule(
      context,
      loan: loan,
      // Editing keeps the target the schedule was built against, so the total
      // row does not start flagging a difference the user never made.
      target: scheduled > 0 ? scheduled : remaining,
      existing: installments,
    );
  }

  Future<void> _clear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá lịch trả?'),
        content: const Text(
          'Khoản vay quay về trả tự do. Lịch sử thanh toán và số còn lại '
          'không đổi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Xoá lịch'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await LoanRepository().clearInstallments(loan.id);
  }
}

/// The next few instalments, with the rest a tap away.
class _InstallmentList extends StatefulWidget {
  const _InstallmentList({required this.loan, required this.progress});

  final Loan loan;
  final List<InstallmentProgress> progress;

  @override
  State<_InstallmentList> createState() => _InstallmentListState();
}

class _InstallmentListState extends State<_InstallmentList> {
  bool _expanded = false;

  /// What is still owing — the rows the user can act on. Once nothing is left
  /// the settled ones stand in, so the section never goes blank.
  List<InstallmentProgress> get _open =>
      widget.progress.where((p) => !p.isSettled).toList();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final open = _open;
    final allSettled = open.isEmpty;
    final ordered = allSettled ? widget.progress : open;
    final visible = _expanded ? ordered : ordered.take(3).toList();
    final hidden = ordered.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (allSettled)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Đã trả xong tất cả các đợt.',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ),
        for (final entry in visible)
          _InstallmentTile(
            loan: widget.loan,
            entry: entry,
            total: widget.progress.length,
          ),
        if (hidden > 0)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = true),
              icon: const Icon(LucideIcons.chevronDown, size: 16),
              label: Text('Xem tất cả ($hidden đợt nữa)'),
            ),
          ),
      ],
    );
  }
}

class _InstallmentTile extends StatelessWidget {
  const _InstallmentTile({
    required this.loan,
    required this.entry,
    required this.total,
  });

  final Loan loan;
  final InstallmentProgress entry;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = switch (entry.state) {
      InstallmentState.paid => theme.spendo.income,
      InstallmentState.overdue => theme.spendo.expense,
      InstallmentState.partial => theme.spendo.warning,
      InstallmentState.upcoming => cs.onSurfaceVariant,
    };
    final label = entry.state == InstallmentState.partial
        ? 'Còn thiếu ${formatVND(entry.shortfall, withSymbol: false)}'
        : entry.state.label;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SpendoIconTile(
            icon: switch (entry.state) {
              InstallmentState.paid => LucideIcons.check,
              InstallmentState.overdue => LucideIcons.circleAlert,
              InstallmentState.partial => LucideIcons.circleDashed,
              InstallmentState.upcoming => LucideIcons.calendar,
            },
            color: color,
            size: 38,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Đợt ${entry.installment.seq}/$total · '
                  '${formatVND(entry.installment.amount, withSymbol: false)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  'Hạn ${_dateLabel(entry.installment.dueDate)} · $label',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: color),
                ),
              ],
            ),
          ),
          if (!entry.isSettled && !loan.isClosed)
            SpendoChip(
              label: 'Trả',
              onTap: () => showAddPaymentSheet(
                context,
                loan: loan,
                remaining: entry.shortfall,
                installment: entry,
                installmentCount: total,
              ),
            ),
        ],
      ),
    );
  }
}

class _PaymentDivider extends StatelessWidget {
  const _PaymentDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 66,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}

// ── Header menu ──────────────────────────────────────────────────────────────

class _LoanMenu extends ConsumerWidget {
  const _LoanMenu({required this.loan});

  final Loan loan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      tooltip: 'Tuỳ chọn',
      icon: const Icon(LucideIcons.ellipsisVertical, size: 20),
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      padding: EdgeInsets.zero,
      onSelected: (value) => value == 'close'
          ? _toggleClosed(context)
          : _delete(context),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'close',
          child: Row(
            children: [
              Icon(
                loan.isClosed ? LucideIcons.rotateCcw : LucideIcons.check,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Text(loan.isClosed ? 'Mở lại' : 'Đánh dấu tất toán'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(LucideIcons.trash2, size: 18, color: cs.error),
              const SizedBox(width: 12),
              Text('Xoá', style: TextStyle(color: cs.error)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _toggleClosed(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = LoanRepository();

    if (loan.isClosed) {
      await repo.reopen(loan.id);
      return;
    }

    await repo.close(loan.id);
    // Closing was one silent tap while deleting asked first; undo evens the
    // two out without adding a dialog to the common case.
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Đã tất toán ${loan.title}'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Hoàn tác',
          onPressed: () => repo.reopen(loan.id),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    // A loan carries its payment history down with it, so this keeps its
    // confirmation rather than trading it for an undo.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá khoản vay?'),
        content: const Text(
          'Xoá khoản vay và toàn bộ lịch sử thanh toán. Không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await LoanRepository().delete(loan.id);
    if (context.mounted) Navigator.of(context).pop();
  }
}

// ── Info card ────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.loan,
    required this.paid,
    required this.remaining,
    this.progress = const [],
  });

  final Loan loan;
  final int paid;
  final int remaining;
  final List<InstallmentProgress> progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final sideColor = loan.type == LoanType.borrowed
        ? theme.spendo.expense
        : theme.spendo.income;
    final paidRatio = loan.principal > 0 ? paid / loan.principal : 0.0;
    final statusLabel = loanStatusLabel(loan, progress: progress);

    final subtitle = [
      if (loan.contactName.isNotEmpty) loan.contactName,
      if (loan.note != null && loan.note!.isNotEmpty) loan.note!,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SpendoCard(
        feature: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SpendoChip(label: loan.type.label, selected: true),
                if (loan.isClosed)
                  SpendoChip.meta(
                    label: 'Đã tất toán',
                    icon: LucideIcons.check,
                  )
                else if (statusLabel != null)
                  // The audit found 🔴 and ⚠️ standing in for status; an icon
                  // in the theme's warning colour survives dark mode and a
                  // screen reader.
                  _StatusBadge(
                    label: statusLabel,
                    color: theme.spendo.warning,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              formatVND(loan.principal),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SpendoChip.meta(
                  label: 'Bắt đầu: ${_dateLabel(loan.startDate)}',
                ),
                if (loan.dueDate != null)
                  SpendoChip.meta(label: 'Hạn: ${_dateLabel(loan.dueDate!)}'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Đã trả: ${formatVND(paid)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Còn: ${formatVND(remaining)}',
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: remaining == 0 ? theme.spendo.income : sideColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SpendoProgressBar(
              value: paidRatio,
              color: remaining == 0 ? theme.spendo.income : cs.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: ShapeDecoration(
        color: color.withValues(alpha: 0.14),
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.clock, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Payment row ──────────────────────────────────────────────────────────────

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment});

  final LoanPayment payment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final note = payment.note;

    // The note was captured by the old sheet and then never shown anywhere.
    final subtitle = [
      formatDayHeader(payment.paidAt),
      if (note != null && note.isNotEmpty) note,
    ].join(' · ');

    return Dismissible(
      key: ValueKey('payment_${payment.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteWithUndo(context, payment),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: cs.errorContainer,
        child: Icon(LucideIcons.trash2, size: 20, color: cs.onErrorContainer),
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            SpendoIconTile(
              icon: LucideIcons.check,
              color: theme.spendo.income,
              size: 38,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatVND(payment.amount),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _deleteWithUndo(BuildContext context, LoanPayment payment) async {
  final messenger = ScaffoldMessenger.of(context);
  final repo = LoanRepository();

  await repo.deletePayment(payment.id);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Text('Đã xoá ${formatVND(payment.amount)}'),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'Hoàn tác',
        onPressed: () => repo.addPayment(
          loanId: payment.loanId,
          amount: payment.amount,
          paidAt: payment.paidAt,
          note: payment.note,
        ),
      ),
    ),
  );
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SpendoCard(
      color: cs.surfaceContainerLowest,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(LucideIcons.info, size: 16, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _dateLabel(DateTime date) => '${date.day}/${date.month}/${date.year}';
