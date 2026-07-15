import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/features/wallets/domain/wallet.dart';
import 'package:spendo/features/wallets/presentation/providers/wallet_provider.dart';
import 'package:spendo/features/wallets/presentation/widgets/wallet_card_home.dart';

void main() {
  testWidgets('shows a retryable error when wallets fail to load', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletsProvider.overrideWith(
            (ref) => Stream<List<Wallet>>.error(StateError('database')),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: WalletCardHome())),
      ),
    );

    await tester.pump();

    expect(find.byKey(const ValueKey('wallets-error')), findsOneWidget);
    expect(find.text('Không thể tải nguồn tiền'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });
}
