import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/utils/wallet_icons.dart';
import '../../../../shared/widgets/spendo/spendo.dart';
import '../../../wallets/domain/wallet.dart';
import '../../../wallets/presentation/providers/wallet_provider.dart';
import '../../../wallets/presentation/widgets/wallet_form_sheet.dart';
import '../providers/sepay_provider.dart';

/// Banks SePay supports, shortest code first as SePay reports them.
const _kBanks = [
  'VCB',
  'TCB',
  'MB',
  'ACB',
  'VPB',
  'BID',
  'CTG',
  'STB',
  'TPB',
  'OCB',
  'MSB',
  'VIB',
  'SHB',
  'HDBank',
];

/// Opens the SePay account-mapping form — the one place it is presented.
Future<void> showSepayMappingSheet(BuildContext context) {
  return SpendoSheet.showModal<void>(
    context: context,
    builder: (_) => const SepayMappingSheet(),
  );
}

/// The form behind screen 22.
///
/// The old sheet was styled unlike every other form in the app — a 40px
/// handle, outlined fields with prefix icons, default M3 buttons, and
/// validation through a snackbar the sheet itself covered
/// (`28-sepay-add-mapping-sheet.md` §L).
class SepayMappingSheet extends ConsumerStatefulWidget {
  const SepayMappingSheet({super.key});

  @override
  ConsumerState<SepayMappingSheet> createState() => _SepayMappingSheetState();
}

class _SepayMappingSheetState extends ConsumerState<SepayMappingSheet> {
  final _accountCtrl = TextEditingController();
  final _labelCtrl = TextEditingController();
  final _accountFocus = FocusNode();

  String? _bank;
  String? _walletId;
  bool _loading = false;

  String? _accountError;
  String? _bankError;
  String? _walletError;

  @override
  void initState() {
    super.initState();
    _accountCtrl.addListener(_clearAccountError);
  }

  void _clearAccountError() {
    if (_accountError != null && _accountCtrl.text.trim().isNotEmpty) {
      setState(() => _accountError = null);
    }
  }

  @override
  void dispose() {
    _accountCtrl.removeListener(_clearAccountError);
    _accountCtrl.dispose();
    _labelCtrl.dispose();
    _accountFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final account = _accountCtrl.text.trim();

    // Inline, field by field — the old form pushed one generic snackbar for
    // all three and disabled nothing.
    setState(() {
      _accountError = account.isEmpty ? 'Nhập số tài khoản' : null;
      _bankError = _bank == null ? 'Chưa chọn ngân hàng' : null;
      _walletError = _walletId == null ? 'Chưa chọn ví nhận giao dịch' : null;
    });
    if (_accountError != null || _bankError != null || _walletError != null) {
      if (_accountError != null) _accountFocus.requestFocus();
      return;
    }

    setState(() => _loading = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final label = _labelCtrl.text.trim();

    try {
      await ref
          .read(sepayAccountsProvider.notifier)
          .addMapping(
            accountNumber: account,
            bankShortName: _bank!,
            walletId: _walletId!,
            label: label.isEmpty ? null : label,
          );
      navigator.pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Không thêm được kết nối: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletsProvider).valueOrNull ?? const <Wallet>[];
    final selected = wallets.where((w) => w.id == _walletId).firstOrNull;

    // A wallet chosen before it was archived elsewhere would otherwise stay
    // selected while no longer being in the list.
    if (_walletId != null && selected == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _walletId = null);
      });
    }

    return SpendoSheet(
      header: SpendoSheetHeader(
        title: 'Thêm tài khoản',
        onCancel: () => Navigator.of(context).pop(),
        action: SpendoButton(label: 'Lưu', busy: _loading, onPressed: _submit),
      ),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 8),
        children: [
          TextField(
            controller: _accountCtrl,
            focusNode: _accountFocus,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
            decoration: InputDecoration(
              labelText: 'Số tài khoản *',
              hintText: '0123456789',
              errorText: _accountError,
            ),
          ),
          const SpendoSectionHeader(label: 'Ngân hàng *', padding: _labelPad),
          _PickerField(
            value: _bank,
            hint: 'Chọn ngân hàng',
            icon: LucideIcons.landmark,
            errorText: _bankError,
            onTap: _pickBank,
          ),
          const SpendoSectionHeader(label: 'Ghi vào ví *', padding: _labelPad),
          if (wallets.isEmpty)
            const _NoWalletCta()
          else
            _PickerField(
              value: selected?.name,
              hint: 'Chọn nguồn tiền',
              icon: selected != null
                  ? walletTypeIcon(selected.type)
                  : LucideIcons.wallet,
              errorText: _walletError,
              onTap: () => _pickWallet(wallets),
            ),
          const SpendoSectionHeader(
            label: 'Tên hiển thị',
            padding: _labelPad,
          ),
          TextField(
            controller: _labelCtrl,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 15),
            decoration: const InputDecoration(
              hintText: 'VD: Thẻ lương, Thẻ chính',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickBank() async {
    final picked = await SpendoSheet.showModal<String>(
      context: context,
      builder: (sheetContext) => SpendoSheet(
        header: const SpendoSheetHeader(title: 'Chọn ngân hàng'),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final bank in _kBanks)
              SpendoChip(
                label: bank,
                selected: bank == _bank,
                onTap: () => Navigator.pop(sheetContext, bank),
              ),
          ],
        ),
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        _bank = picked;
        _bankError = null;
      });
    }
  }

  Future<void> _pickWallet(List<Wallet> wallets) async {
    final picked = await SpendoSheet.showModal<String>(
      context: context,
      builder: (sheetContext) => SpendoSheet(
        header: const SpendoSheetHeader(title: 'Chọn nguồn tiền'),
        child: SpendoSettingsGroup(
          children: [
            for (final wallet in wallets)
              SpendoSettingsRow(
                icon: walletTypeIcon(wallet.type),
                label: wallet.name,
                trailingText: wallet.type.label,
                onTap: () => Navigator.pop(sheetContext, wallet.id),
              ),
          ],
        ),
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        _walletId = picked;
        _walletError = null;
      });
    }
  }
}

const _labelPad = EdgeInsets.only(top: 16, bottom: 8);

/// A read-only field that opens a picker — the audit found the old form
/// leaving the wallet dropdown empty with no hint when no wallet existed.
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.value,
    required this.hint,
    required this.icon,
    required this.onTap,
    this.errorText,
  });

  final String? value;
  final String hint;
  final IconData icon;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: cs.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      value ?? hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: value != null
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: value != null
                            ? cs.onSurface
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronDown,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 0, 0),
            child: Text(
              errorText!,
              style: TextStyle(fontSize: 12, color: cs.error),
            ),
          ),
      ],
    );
  }
}

/// Offers a way out instead of a dead dropdown when no wallet exists yet.
class _NoWalletCta extends StatelessWidget {
  const _NoWalletCta();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SpendoCard(
      color: cs.secondaryContainer,
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Chưa có nguồn tiền nào để ghi giao dịch vào.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSecondaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SpendoButton.outline(
            label: 'Tạo ví',
            onPressed: () => showWalletFormSheet(context),
          ),
        ],
      ),
    );
  }
}
