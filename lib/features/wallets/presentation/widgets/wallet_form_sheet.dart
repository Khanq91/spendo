import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/wallet_icons.dart';
import '../../../../shared/widgets/notice/notice.dart';
import '../../../../shared/widgets/spendo/spendo.dart';
import '../../../transactions/presentation/widgets/amount_input_controller.dart';
import '../../data/wallet_repository.dart';
import '../../domain/wallet.dart';

/// Opens the wallet form. The one place the sheet is presented, so every
/// caller gets the same configuration.
Future<void> showWalletFormSheet(BuildContext context, {Wallet? existing}) {
  return SpendoSheet.showModal<void>(
    context: context,
    builder: (_) => WalletFormSheet(existing: existing),
  );
}

/// Screen 08 of the redesign.
class WalletFormSheet extends ConsumerStatefulWidget {
  const WalletFormSheet({super.key, this.existing});

  final Wallet? existing;

  @override
  ConsumerState<WalletFormSheet> createState() => _WalletFormSheetState();
}

class _WalletFormSheetState extends ConsumerState<WalletFormSheet> {
  final _nameCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _nameFocus = FocusNode();
  late final AmountInputController _balanceCtrl;

  late WalletType _type;
  late String _colorHex;
  bool _loading = false;

  /// Set once a submit is attempted with an empty name. The audit found the
  /// old form returning silently, which read as a dead button.
  String? _nameError;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _balanceCtrl = AmountInputController();

    final existing = widget.existing;
    if (existing != null) {
      _nameCtrl.text = existing.name;
      _noteCtrl.text = existing.note ?? '';
      _type = existing.type;
      _colorHex = existing.colorHex;
      if (existing.initialBalance > 0) {
        _balanceCtrl.prefill(existing.initialBalance.toString());
      }
    } else {
      _type = WalletType.cash;
      _colorHex = AppColors.palette[4];
    }
    _nameCtrl.addListener(_clearNameError);
  }

  void _clearNameError() {
    if (_nameError != null && _nameCtrl.text.trim().isNotEmpty) {
      setState(() => _nameError = null);
    }
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_clearNameError);
    _nameCtrl.dispose();
    _noteCtrl.dispose();
    _nameFocus.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Đặt tên cho nguồn tiền này');
      _nameFocus.requestFocus();
      return;
    }

    setState(() => _loading = true);
    final navigator = Navigator.of(context);
    final note = _noteCtrl.text.trim();

    try {
      final repo = WalletRepository();
      final balance = _balanceCtrl.hasValue ? _balanceCtrl.value : 0;
      if (_isEdit) {
        await repo.update(
          widget.existing!.copyWith(
            name: name,
            type: _type,
            initialBalance: balance,
            note: note.isEmpty ? null : note,
            colorHex: _colorHex,
          ),
        );
      } else {
        await repo.add(
          Wallet(
            id: '',
            name: name,
            type: _type,
            initialBalance: balance,
            note: note.isEmpty ? null : note,
            colorHex: _colorHex,
            sortOrder: 0,
            isArchived: false,
          ),
        );
      }
      navigator.pop();
    } catch (_) {
      // The old form swallowed the failure and left the sheet open with no
      // explanation, so a save that never landed looked like one that did.
      if (!mounted) return;
      setState(() => _loading = false);
      AppNotice.error('Không lưu được nguồn tiền. Thử lại.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // The keypad only drives the opening balance; while the name or note field
    // has focus the system keyboard is up and two keypads would stack.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return SpendoSheet(
      header: SpendoSheetHeader(
        title: _isEdit ? 'Sửa nguồn tiền' : 'Thêm nguồn tiền',
        onCancel: () => Navigator.of(context).pop(),
        action: SpendoButton(label: 'Lưu', busy: _loading, onPressed: _submit),
      ),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      // The sheet already gives its content a Flexible slot, so the form takes
      // the height it needs and the field list scrolls inside whatever the
      // keypad leaves.
      child: Column(
        children: [
          // Expanded, not Flexible: a loosely-fitted list claims its full
          // intrinsic height and then the keypad has nowhere to go.
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 8),
              children: [
                _NameField(
                  controller: _nameCtrl,
                  focusNode: _nameFocus,
                  errorText: _nameError,
                ),
                const SpendoSectionHeader(label: 'Loại', padding: _labelPad),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final type in WalletType.values)
                      SpendoChip(
                        label: type.label,
                        icon: walletTypeIcon(type),
                        selected: type == _type,
                        onTap: () => setState(() => _type = type),
                      ),
                  ],
                ),
                const SpendoSectionHeader(label: 'Màu', padding: _labelPad),
                _ColorSwatches(
                  selected: _colorHex,
                  onSelected: (hex) => setState(() => _colorHex = hex),
                ),
                const SpendoSectionHeader(label: 'Ghi chú', padding: _labelPad),
                _NoteField(controller: _noteCtrl),
                const SizedBox(height: 16),
                _BalanceRow(controller: _balanceCtrl),
              ],
            ),
          ),
          if (!keyboardOpen)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ListenableBuilder(
                listenable: _balanceCtrl,
                builder: (_, __) => SpendoNumpad(
                  onKey: _balanceCtrl.press,
                  onLongPressDelete: _balanceCtrl.reset,
                ),
              ),
            )
          else
            // The keypad steps aside for the system keyboard instead of
            // sitting underneath it, which is what the audit found.
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Đóng bàn phím để nhập số dư ban đầu',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

const _labelPad = EdgeInsets.only(top: 16, bottom: 8);

class _NameField extends StatelessWidget {
  const _NameField({
    required this.controller,
    required this.focusNode,
    this.errorText,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.next,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: 'Tên',
        hintText: 'MB Bank, Tiền mặt…',
        errorText: errorText,
      ),
    );
  }
}

class _NoteField extends StatelessWidget {
  const _NoteField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(fontSize: 15),
      decoration: const InputDecoration(hintText: 'Tuỳ chọn'),
    );
  }
}

/// The palette laid out inline.
///
/// The old form hid it behind a dialog while the category form showed the same
/// choice inline — one affordance, two shapes (`14-wallet-form-sheet.md` §L).
class _ColorSwatches extends StatelessWidget {
  const _ColorSwatches({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final hex in AppColors.palette)
          Semantics(
            button: true,
            selected: hex == selected,
            label: 'Màu $hex',
            child: GestureDetector(
              onTap: () => onSelected(hex),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.fromHex(hex),
                  shape: BoxShape.circle,
                  border: hex == selected
                      ? Border.all(color: cs.surfaceContainerLowest, width: 2)
                      : null,
                  boxShadow: hex == selected
                      ? [
                          BoxShadow(
                            color: cs.primary,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({required this.controller});

  final AmountInputController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SpendoSectionHeader(
                label: 'Số dư ban đầu',
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 3),
              Text(
                'Số dư thực tế sẽ tính tự động từ giao dịch ghi vào ví.',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.4,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ListenableBuilder(
          listenable: controller,
          builder: (_, __) => Text(
            '${controller.formatted} ₫',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }
}
