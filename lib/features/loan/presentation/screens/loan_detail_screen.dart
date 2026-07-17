import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/motion/motion.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/loan_repository.dart';
import '../../domain/loan.dart';
import '../providers/loan_provider.dart';
import '../widgets/loan_form_sheet.dart';
import '../../../transactions/presentation/widgets/amount_input_controller.dart';
import '../../../transactions/presentation/widgets/numpad.dart';

class LoanDetailScreen extends ConsumerStatefulWidget {
  final Loan loan;
  const LoanDetailScreen({super.key, required this.loan});

  @override
  ConsumerState<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends ConsumerState<LoanDetailScreen> {
  @override
  Widget build(BuildContext context) {
    // Watch stream để tự update khi payment thay đổi
    final loansAsync = ref.watch(loansProvider);
    final loan =
        loansAsync.valueOrNull
            ?.where((l) => l.id == widget.loan.id)
            .firstOrNull ??
        widget.loan;

    final paymentsAsync = ref.watch(_paymentsProvider(loan.id));

    final cs = Theme.of(context).colorScheme;
    final color = loan.isClosed ? cs.outlineVariant : loan.color;
    final typeColor =
        loan.type == LoanType.borrowed
            ? Colors.red.shade400
            : Colors.green.shade500;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loan.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.pencil, size: 18),
            onPressed:
                () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => LoanFormSheet(existing: loan),
                ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (val) => _handleMenu(context, val, loan),
            itemBuilder:
                (_) => [
                  PopupMenuItem(
                    value: 'toggle_close',
                    child: Text(loan.isClosed ? 'Mở lại' : 'Đánh dấu tất toán'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Xoá',
                      style: TextStyle(color: AppTheme.expenseAltColor),
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _InfoCard(loan: loan, color: color, typeColor: typeColor),
          ),
          paymentsAsync.when(
            loading:
                () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
            error:
                (e, _) =>
                    SliverToBoxAdapter(child: Center(child: Text('Lỗi: $e'))),
            data: (payments) {
              final totalPaid = payments.fold(0, (s, p) => s + p.amount);
              final remaining = loan.principal - totalPaid;

              return SliverList(
                delegate: SliverChildListDelegate([
                  _PaidSummaryRow(
                    principal: loan.principal,
                    totalPaid: totalPaid,
                    remaining: remaining,
                    typeColor: typeColor,
                  ),
                  const Divider(height: 1),
                  if (!loan.isClosed)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: FilledButton.icon(
                        onPressed: () => _openAddPayment(context, loan),
                        icon: const Icon(LucideIcons.plus, size: 16),
                        label: const Text('Ghi nhận thanh toán'),
                        style: FilledButton.styleFrom(
                          backgroundColor: typeColor,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      'Lịch sử thanh toán (${payments.length})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: appMotion.whenMotionAllowed(
                      context,
                      appMotion.listDuration,
                    ),
                    transitionBuilder:
                        (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SizeTransition(
                            sizeFactor: animation,
                            alignment: Alignment.topCenter,
                            child: child,
                          ),
                        ),
                    child:
                        payments.isEmpty
                            ? Padding(
                              key: const ValueKey('payments_empty'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 24,
                              ),
                              child: Text(
                                'Chưa có thanh toán nào',
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                            : Column(
                              key: ValueKey(
                                payments.map((payment) => payment.id).join('|'),
                              ),
                              children: [
                                for (final payment in payments)
                                  _PaymentTile(
                                    key: ValueKey(payment.id),
                                    payment: payment,
                                    typeColor: typeColor,
                                    onDelete: () => _deletePayment(payment.id),
                                  ),
                              ],
                            ),
                  ),
                  const SizedBox(height: 80),
                ]),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleMenu(BuildContext context, String val, Loan loan) async {
    final repo = LoanRepository();
    if (val == 'toggle_close') {
      if (loan.isClosed) {
        await repo.reopen(loan.id);
      } else {
        await repo.close(loan.id);
      }
    } else if (val == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
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
                    foregroundColor: AppTheme.expenseAltColor,
                  ),
                  child: const Text('Xoá'),
                ),
              ],
            ),
      );
      if (confirm == true && context.mounted) {
        await repo.delete(loan.id);
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  void _openAddPayment(BuildContext context, Loan loan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddPaymentSheet(loanId: loan.id),
    );
  }

  Future<void> _deletePayment(String paymentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Xoá thanh toán này?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Huỷ'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.expenseAltColor,
                ),
                child: const Text('Xoá'),
              ),
            ],
          ),
    );
    if (confirm == true) {
      await LoanRepository().deletePayment(paymentId);
    }
  }
}

// ── Provider cục bộ cho payments stream ──────────────────────────────────────

final _paymentsProvider = StreamProvider.autoDispose
    .family<List<LoanPayment>, String>(
      (ref, loanId) => LoanRepository().watchPayments(loanId),
    );

// ── Info card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final Loan loan;
  final Color color;
  final Color typeColor;

  const _InfoCard({
    required this.loan,
    required this.color,
    required this.typeColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = loan.status;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
        borderRadius: BorderRadius.circular(16),
        color: color.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: typeColor.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  loan.type.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: typeColor,
                  ),
                ),
              ),
              if (status == LoanStatus.overdue) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '🔴 Quá hạn',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),
              ] else if (status == LoanStatus.upcoming) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '⚠️ Còn ${loan.dueDate!.difference(DateTime.now()).inDays} ngày',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formatVND(loan.principal),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: typeColor,
              letterSpacing: -0.5,
            ),
          ),
          if (loan.contactName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              loan.contactName,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              _MetaChip(
                label:
                    'Bắt đầu: ${loan.startDate.day}/${loan.startDate.month}/${loan.startDate.year}',
              ),
              if (loan.dueDate != null) ...[
                const SizedBox(width: 8),
                _MetaChip(
                  label:
                      'Hạn: ${loan.dueDate!.day}/${loan.dueDate!.month}/${loan.dueDate!.year}',
                  warning:
                      status == LoanStatus.overdue ||
                      status == LoanStatus.upcoming,
                ),
              ],
            ],
          ),
          if (loan.note != null && loan.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              loan.note!,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final bool warning;
  const _MetaChip({required this.label, this.warning = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            warning
                ? Colors.orange.withValues(alpha: 0.1)
                : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: warning ? Colors.orange : cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ── Paid summary ──────────────────────────────────────────────────────────────

class _PaidSummaryRow extends StatelessWidget {
  final int principal;
  final int totalPaid;
  final int remaining;
  final Color typeColor;

  const _PaidSummaryRow({
    required this.principal,
    required this.totalPaid,
    required this.remaining,
    required this.typeColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ratio = principal > 0 ? (totalPaid / principal).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Đã trả: ${formatVND(totalPaid)}',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              const Spacer(),
              Text(
                'Còn: ${formatVND(remaining.clamp(0, principal))}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: remaining <= 0 ? Colors.green : typeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: AnimatedProgressBar(
              value: ratio,
              height: 6,
              trackColor: typeColor.withValues(alpha: 0.15),
              valueColor: remaining <= 0 ? Colors.green : typeColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Payment tile ──────────────────────────────────────────────────────────────

class _PaymentTile extends StatelessWidget {
  final LoanPayment payment;
  final Color typeColor;
  final VoidCallback onDelete;

  const _PaymentTile({
    super.key,
    required this.payment,
    required this.typeColor,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: typeColor.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(LucideIcons.check, size: 16, color: typeColor),
      ),
      title: Text(
        formatVND(payment.amount),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        formatDayHeader(payment.paidAt),
        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
      ),
      trailing: IconButton(
        icon: Icon(LucideIcons.trash2, size: 16, color: cs.outlineVariant),
        onPressed: onDelete,
      ),
    );
  }
}

// ── Add payment sheet ─────────────────────────────────────────────────────────

class _AddPaymentSheet extends StatefulWidget {
  final String loanId;
  const _AddPaymentSheet({required this.loanId});

  @override
  State<_AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends State<_AddPaymentSheet> {
  final _noteCtrl = TextEditingController();
  late final AmountInputController _amountCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = AmountInputController();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_amountCtrl.hasValue) return;
    setState(() => _loading = true);
    try {
      await LoanRepository().addPayment(
        loanId: widget.loanId,
        amount: _amountCtrl.value,
        paidAt: DateTime.now(),
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ghi nhận thanh toán',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            decoration: InputDecoration(
              labelText: 'Ghi chú (tuỳ chọn)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ListenableBuilder(
                listenable: _amountCtrl,
                builder:
                    (_, __) => Text(
                      _amountCtrl.formatted,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                        letterSpacing: -1,
                      ),
                    ),
              ),
              const SizedBox(width: 4),
              Text(
                '₫',
                style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const Divider(height: 12, thickness: 0.5),
          ListenableBuilder(
            listenable: _amountCtrl,
            builder: (_, __) => Numpad(onKey: _amountCtrl.press),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
            child: ListenableBuilder(
              listenable: _amountCtrl,
              builder:
                  (_, __) => SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed:
                          _loading || !_amountCtrl.hasValue ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: appMotion.whenMotionAllowed(
                          context,
                          appMotion.tapUpDuration,
                        ),
                        child:
                            _loading
                                ? const SizedBox(
                                  key: ValueKey('payment_loading'),
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Text(
                                  'Xác nhận',
                                  key: ValueKey('payment_label'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                      ),
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
