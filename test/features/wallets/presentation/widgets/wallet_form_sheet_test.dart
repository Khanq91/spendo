import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/core/theme/app_colors.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/features/wallets/domain/wallet.dart';
import 'package:spendo/features/wallets/presentation/widgets/wallet_form_sheet.dart';
import 'package:spendo/shared/widgets/spendo/spendo.dart';

/// The keypad is a 3-column grid with a fixed aspect ratio, so it only sizes
/// sensibly against a phone-width surface — the test default is 800x600.
void _phoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _pump(
  WidgetTester tester, {
  Wallet? existing,
  double keyboardInset = 0,
}) {
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light(AppColorScheme.roseDefault),
        // The override sits inside the Scaffold: Scaffold consumes the bottom
        // view inset for its body, so an override above it never reaches the
        // sheet.
        home: Scaffold(
          body: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(viewInsets: EdgeInsets.only(bottom: keyboardInset)),
              child: WalletFormSheet(existing: existing),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('submitting an empty name says what is missing', (tester) async {
    _phoneSurface(tester);
    await _pump(tester);
    await tester.pumpAndSettle();

    // The old form returned early in silence, so the button looked dead.
    expect(find.text('Đặt tên cho nguồn tiền này'), findsNothing);

    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(find.text('Đặt tên cho nguồn tiền này'), findsOneWidget);
  });

  testWidgets('the error clears as soon as a name is typed', (tester) async {
    _phoneSurface(tester);
    await _pump(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(find.text('Đặt tên cho nguồn tiền này'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'MB Bank');
    await tester.pumpAndSettle();

    expect(find.text('Đặt tên cho nguồn tiền này'), findsNothing);
  });

  testWidgets('the colour palette is inline, not behind a dialog', (
    tester,
  ) async {
    _phoneSurface(tester);
    await _pump(tester);
    await tester.pumpAndSettle();

    // The category form already showed swatches inline; the wallet form hid
    // the same choice behind a dialog (`14-wallet-form-sheet.md` §L).
    expect(find.text('Chọn màu'), findsNothing);
    for (final hex in AppColors.palette) {
      expect(find.bySemanticsLabel('Màu $hex'), findsOneWidget);
    }
  });

  testWidgets('the keypad gives way to the system keyboard', (tester) async {
    _phoneSurface(tester);
    await _pump(tester);
    await tester.pumpAndSettle();

    // With no keyboard up, the keypad drives the opening balance.
    expect(find.byType(SpendoNumpad), findsOneWidget);

    // The audit found the keypad staying put while the name field's keyboard
    // rose over it, leaving two keypads stacked.
    await _pump(tester, keyboardInset: 300);
    await tester.pumpAndSettle();

    expect(find.byType(SpendoNumpad), findsNothing);
    expect(find.text('Đóng bàn phím để nhập số dư ban đầu'), findsOneWidget);
  });

  testWidgets('editing prefills the wallet it was opened on', (tester) async {
    _phoneSurface(tester);
    await _pump(
      tester,
      existing: const Wallet(
        id: 'bank',
        name: 'MB Bank',
        type: WalletType.bank,
        initialBalance: 12000000,
        colorHex: '#5E7E8A',
        sortOrder: 0,
        isArchived: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sửa nguồn tiền'), findsOneWidget);
    expect(find.text('MB Bank'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('12.000.000 ₫'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('12.000.000 ₫'), findsOneWidget);
  });
}
