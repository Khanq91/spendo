import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../features/wallets/domain/wallet.dart';

/// Lucide glyph for a wallet type.
///
/// Wallet types were previously drawn through `categoryIcon`, whose map only
/// knows category icon names — so every wallet fell through to the
/// `circleEllipsis` fallback and all six types looked identical
/// (`12-wallets.md` §L).
IconData walletTypeIcon(WalletType type) => switch (type) {
  WalletType.cash => LucideIcons.banknote,
  WalletType.bank => LucideIcons.landmark,
  WalletType.ewallet => LucideIcons.smartphone,
  WalletType.credit => LucideIcons.creditCard,
  WalletType.investment => LucideIcons.trendingUp,
  WalletType.other => LucideIcons.ellipsis,
};
