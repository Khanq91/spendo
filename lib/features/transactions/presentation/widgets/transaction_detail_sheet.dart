import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/spendo_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../shared/widgets/notice/notice.dart';
import '../../../../shared/widgets/motion/motion.dart';
import '../../../../shared/widgets/spendo/spendo.dart';
import '../../../categories/domain/category.dart';
import '../../../loan/data/loan_repository.dart';
import '../../../loan/domain/loan.dart';
import '../../../wallets/domain/wallet.dart';
import '../../../wallets/presentation/providers/wallet_provider.dart';
import '../../data/transaction_repository.dart';
import '../../domain/transaction.dart';
import 'add_transaction_sheet.dart';
import 'delete_transaction_action.dart';

/// Screen 04 — one transaction in full, with the actions that act on it.
class TransactionDetailSheet extends ConsumerStatefulWidget {
  const TransactionDetailSheet({
    super.key,
    required this.transaction,
    required this.category,
  });

  final Transaction transaction;
  final Category? category;

  @override
  ConsumerState<TransactionDetailSheet> createState() =>
      _TransactionDetailSheetState();
}

class _TransactionDetailSheetState
    extends ConsumerState<TransactionDetailSheet> {
  late Transaction _transaction = widget.transaction;
  bool _busy = false;

  /// The loan that owns this transaction, when it has one.
  ///
  /// A loan's money is edited from the loan, never from here: the payment and
  /// the transaction are one fact recorded twice, and letting the two ends be
  /// changed independently is how they come apart.
  Loan? _owner;
  bool get _isLoanOwned => _transaction.source == kLoanTransactionSource;

  @override
  void initState() {
    super.initState();
    if (_isLoanOwned) _loadOwner();
  }

  Future<void> _loadOwner() async {
    try {
      final loan = await LoanRepository().findByTransaction(_transaction.id);
      if (mounted) setState(() => _owner = loan);
    } catch (_) {
      // The banner still says the transaction belongs to a loan; it just
      // cannot offer the shortcut to it.
    }
  }

  void _openOwner() {
    final loan = _owner;
    if (loan == null) return;
    Navigator.of(context).pop();
    context.push('/loans/${loan.id}');
  }

  /// Lets the user correct the timestamp without opening the edit sheet — the
  /// audit noted the date was not editable anywhere at all.
  Future<void> _editDate() async {
    final current = _transaction.createdAt;
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (!mounted) return;

    final updated = _copyWithDate(
      _transaction,
      DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? current.hour,
        time?.minute ?? current.minute,
      ),
    );

    setState(() => _busy = true);
    try {
      await TransactionRepository().update(updated);
      if (mounted) setState(() => _transaction = updated);
    } catch (_) {
      AppNotice.error('Không đổi được ngày. Thử lại.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Opens the add sheet pre-filled with this transaction, so a repeating
  /// expense is a couple of taps instead of a full re-entry.
  void _duplicate() {
    Navigator.of(context).pop();
    showAddTransactionSheet(
      context,
      preselectedCategoryId: _transaction.categoryId,
      prefillNote: _transaction.note,
      prefillAmount: _transaction.amount,
    );
  }

  void _edit() {
    Navigator.of(context).pop();
    showAddTransactionSheet(context, existing: _transaction);
  }

  Future<void> _delete() async {
    Navigator.of(context).pop();
    await deleteTransactionWithUndo(context, _transaction);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isExpense = _transaction.isExpense;
    final amountColor = isExpense ? theme.spendo.expense : theme.spendo.income;

    final wallets = ref.watch(walletsProvider).valueOrNull ?? const <Wallet>[];
    final wallet = _transaction.walletId == null
        ? null
        : wallets.where((w) => w.id == _transaction.walletId).firstOrNull;

    return SpendoSheet(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 14),
            Center(
              child: SpendoIconTile.category(
                iconName: widget.category?.iconName,
                color: widget.category?.color ?? cs.onSurfaceVariant,
                size: 56,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.category?.name ?? 'Không rõ',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              '${isExpense ? '−' : '+'}${formatVND(_transaction.amount)}',
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall?.copyWith(
                fontSize: 30,
                color: amountColor,
              ),
            ),
            if (_transaction.isAutomatic) ...[
              const SizedBox(height: 8),
              Center(
                child: SpendoChip.meta(
                  label: 'Tự động · SePay',
                  icon: LucideIcons.zap,
                ),
              ),
            ],
            if (_isLoanOwned) ...[
              const SizedBox(height: 10),
              _LoanOwnerBanner(loan: _owner, onOpen: _openOwner),
            ],
            const SizedBox(height: 16),
            Divider(height: 1, color: cs.outlineVariant),
            const SizedBox(height: 6),
            _DetailRow(
              key: const ValueKey('detail_date_row'),
              icon: LucideIcons.calendar,
              label: 'Ngày',
              value:
                  '${formatDayHeader(_transaction.createdAt)}, '
                  '${formatTime(_transaction.createdAt)}',
              onEdit: _busy || _isLoanOwned ? null : _editDate,
            ),
            if (_transaction.note != null && _transaction.note!.isNotEmpty)
              _DetailRow(
                icon: LucideIcons.fileText,
                label: 'Ghi chú',
                value: _transaction.note!,
              ),
            _DetailRow(
              icon: isExpense
                  ? LucideIcons.arrowUpRight
                  : LucideIcons.arrowDownLeft,
              label: 'Loại',
              value: isExpense ? 'Chi tiêu' : 'Thu nhập',
              valueColor: amountColor,
            ),
            if (wallet != null)
              _DetailRow(
                icon: LucideIcons.wallet,
                label: 'Nguồn tiền',
                value: wallet.name,
                leadingDot: wallet.color,
              )
            else if (_transaction.walletId != null)
              // The wallet exists but is archived, so it is not in the active
              // list. Saying so beats hiding the row and implying no wallet.
              const _DetailRow(
                icon: LucideIcons.wallet,
                label: 'Nguồn tiền',
                value: 'Ví đã lưu trữ',
              ),
            const SizedBox(height: 18),
            if (_isLoanOwned)
              // Duplicating is gone too: a copy would be a loan transaction
              // with no payment behind it.
              SpendoButton.secondary(
                label: 'Mở khoản vay',
                icon: LucideIcons.handCoins,
                expand: true,
                onPressed: _owner == null ? null : _openOwner,
              )
            else
              Row(
                children: [
                  _DeleteButton(onPressed: _busy ? null : _delete),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SpendoButton.secondary(
                      label: 'Nhân bản',
                      icon: LucideIcons.copy,
                      expand: true,
                      onPressed: _busy ? null : _duplicate,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SpendoButton(
                      label: 'Chỉnh sửa',
                      icon: LucideIcons.pencil,
                      expand: true,
                      onPressed: _busy ? null : _edit,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Says the transaction belongs to a loan, and offers the way there.
class _LoanOwnerBanner extends StatelessWidget {
  const _LoanOwnerBanner({required this.loan, required this.onOpen});

  final Loan? loan;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final title = loan?.title;

    return SpendoCard(
      color: cs.surfaceContainerLowest,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: loan == null ? null : onOpen,
      child: Row(
        children: [
          Icon(LucideIcons.handCoins, size: 17, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title == null
                  ? 'Giao dịch này thuộc một khoản vay'
                  : 'Giao dịch này thuộc khoản vay «$title»',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          if (loan != null)
            Icon(LucideIcons.chevronRight, size: 17, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }
}

/// Round destructive button — the trash icon alone, so the two labelled
/// actions keep the width.
class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: 'Xoá giao dịch',
      child: PressableScale(
        deferTapToChild: true,
        child: Material(
          color: Colors.transparent,
          shape: CircleBorder(
            side: BorderSide(color: cs.error.withValues(alpha: 0.45), width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(LucideIcons.trash2, size: 19, color: cs.error),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.leadingDot,
    this.onEdit,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  /// Coloured dot before the value, used for the wallet.
  final Color? leadingDot;

  /// Shows a pencil affordance and makes the whole row tappable.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 17, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (leadingDot != null) ...[
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: leadingDot,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    value,
                    // A long note wraps instead of overflowing, which the
                    // audit flagged on the old fixed-height row.
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                      color: valueColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (onEdit != null) ...[
            const SizedBox(width: 8),
            Icon(LucideIcons.pencil, size: 15, color: cs.primary),
          ],
        ],
      ),
    );

    if (onEdit == null) return row;

    return Semantics(
      button: true,
      label: 'Sửa $label',
      child: GestureDetector(
        onTap: onEdit,
        behavior: HitTestBehavior.opaque,
        child: row,
      ),
    );
  }
}

/// Rebuilds [Transaction] with a new timestamp — the model has no copyWith.
Transaction _copyWithDate(Transaction t, DateTime createdAt) => Transaction(
  id: t.id,
  amount: t.amount,
  type: t.type,
  categoryId: t.categoryId,
  note: t.note,
  createdAt: createdAt,
  walletId: t.walletId,
  source: t.source,
);
