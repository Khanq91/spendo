import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/spendo/spendo.dart';
import '../../../transactions/presentation/widgets/amount_input_controller.dart';
import '../../../wallets/domain/wallet.dart';
import '../../../wallets/presentation/providers/wallet_provider.dart';
import '../../../wallets/presentation/widgets/wallet_picker_sheet.dart';
import '../../data/loan_repository.dart';
import '../../domain/loan.dart';
import '../screens/installment_schedule_screen.dart';

/// Opens the loan form. The single place the sheet is presented.
///
/// A new loan set to repay in instalments carries straight on to the schedule
/// screen, which is pushed from here rather than from inside the sheet: by the
/// time the sheet has closed, its own context is gone.
Future<void> showLoanFormSheet(
  BuildContext context, {
  Loan? existing,
  LoanType? initialType,
}) async {
  final created = await SpendoSheet.showModal<Loan>(
    context: context,
    builder: (_) => LoanFormSheet(existing: existing, initialType: initialType),
  );
  if (created == null || !context.mounted) return;

  await openInstallmentSchedule(
    context,
    loan: created,
    target: created.principal,
  );
}

/// Screen 17 of the redesign.
class LoanFormSheet extends ConsumerStatefulWidget {
  const LoanFormSheet({super.key, this.existing, this.initialType});

  final Loan? existing;
  final LoanType? initialType;

  @override
  ConsumerState<LoanFormSheet> createState() => _LoanFormSheetState();
}

class _LoanFormSheetState extends ConsumerState<LoanFormSheet> {
  final _titleCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _titleFocus = FocusNode();
  final _amountCtrl = AmountInputController();

  late LoanType _type;
  late RepaymentMode _mode;
  late DateTime _startDate;
  DateTime? _dueDate;

  /// Whether the principal itself moves through a wallet.
  ///
  /// Off by default: a debt often predates the app, or the cash never passed
  /// through a tracked wallet at all, and inventing a transaction for it would
  /// throw the balance out.
  bool _trackFunding = false;
  String? _fundingWalletId;
  bool _saving = false;
  String? _titleError;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _titleCtrl.text = existing.title;
      _contactCtrl.text = existing.contactName;
      _type = existing.type;
      _mode = existing.repaymentMode;
      _startDate = existing.startDate;
      _dueDate = existing.dueDate;
      _amountCtrl.prefill(existing.principal.toString());
    } else {
      _type = widget.initialType ?? LoanType.borrowed;
      // Free repayment is what every loan did before schedules existed, and
      // what most of them still want.
      _mode = RepaymentMode.free;
      _startDate = DateTime.now();
    }
    _titleCtrl.addListener(_onTitleChanged);
  }

  /// The old form gated its button on the title but never listened to the
  /// field, so typing a name left the button grey until something else
  /// happened to rebuild it (`17-loan-form-sheet.md` §L).
  void _onTitleChanged() => setState(() {
    if (_titleError != null && _titleCtrl.text.trim().isNotEmpty) {
      _titleError = null;
    }
  });

  @override
  void dispose() {
    _titleCtrl.removeListener(_onTitleChanged);
    _titleCtrl.dispose();
    _contactCtrl.dispose();
    _titleFocus.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFundingWallet(List<Wallet> wallets) async {
    final picked = await WalletPickerSheet.show(
      context,
      wallets: wallets,
      selectedId: _fundingWalletId,
      title: 'Ghi tiền gốc vào ví nào?',
      clearLabel: 'Không ghi vào ví nào',
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (picked == WalletPickerSheet.kNoWallet) {
        _trackFunding = false;
        _fundingWalletId = null;
      } else {
        _fundingWalletId = picked;
      }
    });
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final current = _dueDate;
    // `firstDate: now` used to throw on a loan whose due date had already
    // passed, because initialDate fell before it.
    final earliest = DateTime(now.year - 10);
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now.add(const Duration(days: 30)),
      firstDate: earliest,
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Đặt tên cho khoản vay này');
      _titleFocus.requestFocus();
      return;
    }
    if (!_amountCtrl.hasValue) return;

    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final contact = _contactCtrl.text.trim();
    final existing = widget.existing;

    try {
      final repo = LoanRepository();
      final loan = Loan(
        id: existing?.id ?? '',
        title: title,
        type: _type,
        principal: _amountCtrl.value,
        contactName: contact,
        startDate: _startDate,
        dueDate: _dueDate,
        note: existing?.note,
        colorHex: existing?.colorHex ?? _defaultColorFor(_type),
        isClosed: existing?.isClosed ?? false,
        // A loan only becomes `installment` once a schedule is actually saved,
        // so backing out of the schedule screen leaves a working free loan
        // rather than one that claims a schedule it does not have.
        repaymentMode: _isEdit ? existing!.repaymentMode : RepaymentMode.free,
        fundingTransactionId: existing?.fundingTransactionId,
      );
      if (_isEdit) {
        await repo.update(loan);
        navigator.pop();
        return;
      }

      final id = await repo.add(
        loan,
        fundingWalletId: _trackFunding ? _fundingWalletId : null,
      );
      // Only an instalment loan hands a loan back; anything else closes with
      // nothing, so the caller knows not to push the schedule screen.
      navigator.pop(
        _mode == RepaymentMode.installment ? loan.copyWithId(id) : null,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Không lưu được khoản vay. Thử lại.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    // Only offered on a new loan: the transaction is a record of the money as
    // it actually arrived, so editing a loan later does not rewrite it.
    final wallets = ref.watch(walletsProvider).valueOrNull ?? const <Wallet>[];

    return SpendoSheet(
      header: SpendoSheetHeader(
        title: _isEdit ? 'Sửa khoản vay' : 'Thêm khoản vay',
        onCancel: () => Navigator.of(context).pop(),
        // Wrapped, because the button's enabled state depends on the keypad:
        // the old form gated on a value it never listened to, so the button
        // stayed grey after the user had typed one.
        action: ListenableBuilder(
          listenable: _amountCtrl,
          builder: (_, __) => SpendoButton(
            label: 'Lưu',
            busy: _saving,
            onPressed: _amountCtrl.hasValue ? _submit : null,
          ),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 8),
              children: [
                SpendoSegmented<LoanType>(
                  value: _type,
                  onChanged: (next) => setState(() => _type = next),
                  expand: true,
                  height: 34,
                  options: const [
                    (value: LoanType.borrowed, label: 'Tôi đang vay'),
                    (value: LoanType.lent, label: 'Tôi cho vay'),
                  ],
                ),
                if (!_isEdit) ...[
                  const SizedBox(height: 10),
                  // Only offered when creating: changing a live loan's mode
                  // means building or dropping a schedule, which belongs on
                  // the detail screen where the schedule itself lives.
                  Row(
                    children: [
                      for (final option in RepaymentMode.values) ...[
                        SpendoChip(
                          label: option.label,
                          selected: option == _mode,
                          onTap: () => setState(() => _mode = option),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _titleCtrl,
                  focusNode: _titleFocus,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Tên khoản vay',
                    hintText: 'Vay mua xe…',
                    errorText: _titleError,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _contactCtrl,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    labelText: _type == LoanType.borrowed
                        ? 'Người cho vay'
                        : 'Người vay',
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Start date used to be fixed at creation time, with no
                    // way to record a loan taken out last week.
                    SpendoChip.meta(
                      label: 'Bắt đầu: ${_dateLabel(_startDate)}',
                      icon: LucideIcons.calendar,
                      onTap: _pickStartDate,
                    ),
                    SpendoChip.meta(
                      label: _dueDate == null
                          ? 'Không hạn'
                          : 'Hạn: ${_dateLabel(_dueDate!)}',
                      icon: LucideIcons.clock,
                      onTap: _pickDueDate,
                    ),
                    if (_dueDate != null)
                      SpendoChip.meta(
                        label: 'Bỏ hạn',
                        icon: LucideIcons.x,
                        onTap: () => setState(() => _dueDate = null),
                      ),
                  ],
                ),
                if (!_isEdit && wallets.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _FundingToggle(
                    type: _type,
                    enabled: _trackFunding,
                    wallet: wallets
                        .where((w) => w.id == _fundingWalletId)
                        .firstOrNull,
                    amount: _amountCtrl,
                    onChanged: (next) => setState(() {
                      _trackFunding = next;
                      if (next && _fundingWalletId == null) {
                        _fundingWalletId = wallets.first.id;
                      }
                    }),
                    onPickWallet: () => _pickFundingWallet(wallets),
                  ),
                ],
                const SizedBox(height: 16),
                Column(
                  children: [
                    Text(
                      'Số tiền',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    ListenableBuilder(
                      listenable: _amountCtrl,
                      builder: (_, __) => Text(
                        '${_amountCtrl.formatted} ₫',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontSize: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!keyboardOpen)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ListenableBuilder(
                listenable: _amountCtrl,
                builder: (_, __) => SpendoNumpad(
                  onKey: _amountCtrl.press,
                  onLongPressDelete: _amountCtrl.reset,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Đóng bàn phím để nhập số tiền',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Ghi vào ví" — the switch plus, once on, the wallet it writes to.
class _FundingToggle extends StatelessWidget {
  const _FundingToggle({
    required this.type,
    required this.enabled,
    required this.wallet,
    required this.amount,
    required this.onChanged,
    required this.onPickWallet,
  });

  final LoanType type;
  final bool enabled;
  final Wallet? wallet;
  final AmountInputController amount;
  final ValueChanged<bool> onChanged;
  final VoidCallback onPickWallet;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final borrowed = type == LoanType.borrowed;

    return SpendoCard(
      color: cs.surfaceContainerLowest,
      padding: const EdgeInsets.fromLTRB(14, 6, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Ghi vào ví',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      borrowed
                          ? 'Tiền vay về cộng vào ví'
                          : 'Tiền cho vay trừ khỏi ví',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(value: enabled, onChanged: onChanged),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                SpendoChip.meta(
                  key: const ValueKey('funding_wallet_chip'),
                  label: wallet?.name ?? 'Chọn ví',
                  icon: LucideIcons.wallet,
                  onTap: onPickWallet,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ListenableBuilder(
                    listenable: amount,
                    builder: (_, __) => Text(
                      '${borrowed ? '+' : '−'}'
                      '${formatVND(amount.value, withSymbol: false)}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Palette entry each side starts on. The form no longer offers a colour
/// picker — the row's colour comes from the loan's side, not a free choice.
String _defaultColorFor(LoanType type) =>
    type == LoanType.borrowed ? AppColors.palette[0] : AppColors.palette[12];

String _dateLabel(DateTime date) =>
    '${date.day}/${date.month}/${date.year}';
