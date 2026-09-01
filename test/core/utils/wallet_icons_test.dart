import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:spendo/core/utils/category_icons.dart';
import 'package:spendo/core/utils/wallet_icons.dart';
import 'package:spendo/features/wallets/domain/wallet.dart';

void main() {
  test('every wallet type has its own glyph', () {
    final icons = {
      for (final type in WalletType.values) type: walletTypeIcon(type),
    };

    expect(
      icons.values.toSet().length,
      WalletType.values.length,
      reason: 'two wallet types share an icon, so they read as the same type',
    );
  });

  test('no wallet type falls through to the unknown-icon placeholder', () {
    // Wallet types used to be drawn through categoryIcon, whose map has no
    // entry for any of them — so all six rendered as circleEllipsis and every
    // wallet looked identical.
    for (final type in WalletType.values) {
      expect(
        categoryIcon(type.iconName),
        LucideIcons.circleEllipsis,
        reason: 'guards the reason walletTypeIcon exists',
      );
      expect(
        walletTypeIcon(type),
        isNot(LucideIcons.circleEllipsis),
        reason: '${type.name} still has no icon of its own',
      );
    }
  });
}
