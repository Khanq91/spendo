import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/spendo/spendo.dart';
import '../../../transactions/presentation/widgets/amount_input_controller.dart';
import '../../../wallets/domain/wallet.dart';
import '../../../wallets/presentation/providers/wallet_provider.dart';
import '../../../wallets/presentation/widgets/wallet_picker_sheet.dart';
import '../../data/loan_repository.dart';
import '../../domain/installment_status.dart';
import '../../domain/loan.dart';

/// Records a payment against [loan].
///
/// Lives beside the list as well as the detail screen: the mockup puts a
/// "Trả" chip on every row, so paying no longer means opening the loan first.
Future<void> showAddPaymentSheet(
  BuildContext context, {
  required Loan loan,
  required int remaining,
  InstallmentProgress? installment,
  int installmentCount = 0,
}) {
  return SpendoSheet.showModal<void>(
    context: context,
    builder: (_) => AddPaymentSheet(
      loan: loan,
      remaining: remaining,
      installment: installment,
      installmentCount: installmentCount,
    ),
  );
}

class AddPaymentSheet extends ConsumerStatefulWidget {
  const AddPaymentSheet({
    super.key,
    required this.loan,
    required this.remaining,
    this.installment,
    this.installmentCount = 0,
  });

  final Loan loan;

  /// What is still owed, used for the "Trả hết" shortcut and the over-payment
  /// warning — the old sheet let any amount through with no hint of the limit.
  final int remaining;

  /// The instalment being paid, when the sheet was opened from a schedule.
  ///
  /// It only seeds the amount and a caption: a payment is never tied to an
  /// instalment in the data (PLAN §2.2), so the user is free to pay more, less
  /// or two instalments at once and the waterfall still adds up.
  final InstallmentProgress? installment;

  /// How many instalments the schedule has — the "12" of "Đợt 3/12".
  final int installmentCount;

  @override
  ConsumerState<AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends ConsumerState<AddPaymentSheet> {
  final _amountCtrl = AmountInputController();
  final _noteCtrl = TextEditingController();

  /// The old sheet stamped every payment with `DateTime.now()`, so a payment
  /// entered a day late was recorded on the wrong day.
  DateTime _paidAt = DateTime.now();
  bool _saving = false;

  /// The wallet the money leaves or lands in. Optional, like everywhere else
  /// in the app — a repayment made in cash outside any wallet is normal.
  String? _walletId;
  bool _walletChosen = false;

  @override
  void initState() {
    super.initState();
    final shortfall = widget.installment?.shortfall ?? 0;
    if (shortfall > 0) _amountCtrl.prefill(shortfall.toString());
  }

  Future<void> _pickWallet(List<Wallet> wallets) async {
    final picked = await WalletPickerSheet.show(
      context,
      wallets: wallets,
      selectedId: _walletId,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _walletChosen = true;
      _walletId = picked == WalletPickerSheet.kNoWallet ? null : picked;
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _paidAt,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _paidAt = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _submit() async {
    if (!_amountCtrl.hasValue) return;
    setState(() => _saving = true);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final note = _noteCtrl.text.trim();

    try {
      await LoanRepository().addPayment(
        loanId: widget.loan.id,
        amount: _amountCtrl.value,
        paidAt: _paidAt,
        note: note.isEmpty ? null : note,
        // A repayment is real money moving, so it is written as a transaction
        // too — the wallet and the statistics see it like any other entry.
        loanType: widget.loan.type,
        walletId: _walletId,
        title: widget.loan.title,
      );
      navigator.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Không ghi được thanh toán. Thử lại.')),
      );
    }
  }

  /// Names the instalment being paid when there is one, so the amount that
  /// arrived pre-filled is not a mystery.
  String _caption() {
    final entry = widget.installment;
    if (entry == null) {
      return 'Còn lại ${formatVND(widget.remaining)} · ${widget.loan.title}';
    }
    final due = entry.installment.dueDate;
    return 'Đợt ${entry.installment.seq}/${widget.installmentCount} · '
        'hạn ${due.day}/${due.month} · còn ${formatVND(entry.shortfall)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final wallets = ref.watch(walletsProvider).valueOrNull ?? const <Wallet>[];
    // The first wallet stands in until the user says otherwise, matching how
    // Thêm giao dịch behaves; picking "không ghi vào ví nào" opts out.
    if (!_walletChosen && _walletId == null && wallets.isNotEmpty) {
      _walletId = wallets.first.id;
    }
    final wallet = wallets.where((w) => w.id == _walletId).firstOrNull;

    return SpendoSheet(
      header: SpendoSheetHeader(
        title: 'Ghi nhận thanh toán',
        onCancel: () => Navigator.of(context).pop(),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _caption(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 8),
          ListenableBuilder(
            listenable: _amountCtrl,
            builder: (_, __) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${_amountCtrl.formatted} ₫',
                  textAlign: TextAlign.right,
                  style: theme.textTheme.displaySmall?.copyWith(fontSize: 32),
                ),
                if (_amountCtrl.value > widget.remaining)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Nhiều hơn số còn lại ${formatVND(widget.remaining)}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Wrapped, not a Row: the wallet chip made three of them, and a long
          // wallet name on a narrow phone ran off the edge.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SpendoChip.meta(
                label: _dateLabel(_paidAt),
                icon: LucideIcons.calendar,
                onTap: _pickDate,
              ),
              if (widget.remaining > 0)
                SpendoChip.meta(
                  label: widget.installment == null ? 'Trả hết' : 'Đủ đợt này',
                  onTap: () => _amountCtrl.prefill(widget.remaining.toString()),
                ),
              if (wallets.isNotEmpty)
                SpendoChip.meta(
                  key: const ValueKey('payment_wallet_chip'),
                  label: wallet?.name ?? 'Không ghi ví',
                  icon: LucideIcons.wallet,
                  onTap: () => _pickWallet(wallets),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _noteCtrl,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 15),
            decoration: const InputDecoration(hintText: 'Ghi chú (tuỳ chọn)'),
          ),
          const SizedBox(height: 12),
          if (!keyboardOpen) ...[
            SpendoNumpad(
              onKey: _amountCtrl.press,
              onLongPressDelete: _amountCtrl.reset,
            ),
            const SizedBox(height: 12),
          ],
          ListenableBuilder(
            listenable: _amountCtrl,
            builder: (_, __) => SpendoButton(
              expand: true,
              label: 'Xác nhận',
              busy: _saving,
              onPressed: _amountCtrl.hasValue ? _submit : null,
            ),
          ),
        ],
      ),
    );
  }
}

String _dateLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Hôm nay';
  if (diff == 1) return 'Hôm qua';
  return '${date.day}/${date.month}/${date.year}';
}
