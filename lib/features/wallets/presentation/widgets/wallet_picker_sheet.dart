import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/widgets/spendo/spendo.dart';
import '../../domain/wallet.dart';

/// Picks the wallet a piece of money moves through.
///
/// Lifted out of the Thêm giao dịch sheet when loan payments needed the same
/// list — one picker means the two cannot drift apart in behaviour or wording.
/// Returns the chosen wallet's id, or [kNoWallet] when the user opts out;
/// null means the sheet was dismissed and nothing should change.
class WalletPickerSheet extends StatelessWidget {
  const WalletPickerSheet({
    super.key,
    required this.wallets,
    required this.selectedId,
    this.title = 'Chọn nguồn tiền',
    this.clearLabel = 'Không ghi vào ví nào',
  });

  /// Sentinel for "no wallet", which null cannot express because null already
  /// means the sheet was closed without a choice.
  static const String kNoWallet = '';

  final List<Wallet> wallets;
  final String? selectedId;
  final String title;
  final String clearLabel;

  /// Opens the picker and resolves to the id chosen, [kNoWallet], or null.
  static Future<String?> show(
    BuildContext context, {
    required List<Wallet> wallets,
    String? selectedId,
    String title = 'Chọn nguồn tiền',
    String clearLabel = 'Không ghi vào ví nào',
  }) {
    return SpendoSheet.showModal<String>(
      context: context,
      builder: (_) => WalletPickerSheet(
        wallets: wallets,
        selectedId: selectedId,
        title: title,
        clearLabel: clearLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SpendoSheet(
      header: SpendoSheetHeader(title: title),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SpendoSettingsGroup(
            children: [
              for (final wallet in wallets)
                SpendoSettingsRow(
                  icon: LucideIcons.wallet,
                  label: wallet.name,
                  trailingText: wallet.type.label,
                  trailing: wallet.id == selectedId
                      ? Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(
                            LucideIcons.check,
                            size: 18,
                            color: cs.primary,
                          ),
                        )
                      : null,
                  onTap: () => Navigator.of(context).pop(wallet.id),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SpendoButton.outline(
            label: clearLabel,
            expand: true,
            onPressed: () => Navigator.of(context).pop(kNoWallet),
          ),
        ],
      ),
    );
  }
}
