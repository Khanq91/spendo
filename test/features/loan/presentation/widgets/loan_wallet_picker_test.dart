import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/features/loan/domain/loan.dart';
import 'package:spendo/features/loan/presentation/widgets/add_payment_sheet.dart';
import 'package:spendo/features/loan/presentation/widgets/loan_form_sheet.dart';
import 'package:spendo/features/wallets/domain/wallet.dart';
import 'package:spendo/features/wallets/presentation/providers/wallet_provider.dart';

const _wallets = [
  Wallet(
    id: 'cash',
    name: 'Tiền mặt',
    type: WalletType.cash,
    initialBalance: 0,
    colorHex: '#5E7E8A',
    sortOrder: 0,
    isArchived: false,
  ),
  Wallet(
    id: 'bank',
    name: 'MB Bank',
    type: WalletType.bank,
    initialBalance: 0,
    colorHex: '#B23A2E',
    sortOrder: 1,
    isArchived: false,
  ),
];

final _loan = Loan(
  id: 'l1',
  title: 'Vay mua xe',
  type: LoanType.borrowed,
  principal: 9000000,
  contactName: 'Anh A',
  startDate: DateTime(2026, 9),
  colorHex: '#B23A2E',
  isClosed: false,
);

/// The same loan, kept in the tracking sổ.
final _trackingLoan = Loan(
  id: 'l2',
  title: 'Nợ Anh B',
  type: LoanType.borrowed,
  principal: 9000000,
  contactName: 'Anh B',
  startDate: DateTime(2026, 9),
  colorHex: '#B23A2E',
  isClosed: false,
  isTrackingOnly: true,
);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  List<Wallet> wallets = _wallets,
}) async {
  tester.view.physicalSize = const Size(400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        walletsProvider.overrideWith((ref) => Stream.value(wallets)),
      ],
      child: MaterialApp(
        theme: AppTheme.light(AppColorScheme.roseDefault),
        locale: const Locale('vi', 'VN'),
        supportedLocales: const [Locale('vi', 'VN')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('payment sheet', () {
    testWidgets('the first wallet stands in until told otherwise', (
      tester,
    ) async {
      await _pump(tester, AddPaymentSheet(loan: _loan, remaining: 5000000));

      expect(find.text('Tiền mặt'), findsOneWidget);
    });

    testWidgets('picking a different wallet swaps the chip', (tester) async {
      await _pump(tester, AddPaymentSheet(loan: _loan, remaining: 5000000));

      await tester.tap(find.byKey(const ValueKey('payment_wallet_chip')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('MB Bank'));
      await tester.pumpAndSettle();

      expect(find.text('MB Bank'), findsOneWidget);
      expect(find.text('Tiền mặt'), findsNothing);
    });

    testWidgets('opting out of a wallet is offered and sticks', (tester) async {
      // Wallet is optional the same way it is in Thêm giao dịch — a repayment
      // in cash outside any tracked wallet is ordinary.
      await _pump(tester, AddPaymentSheet(loan: _loan, remaining: 5000000));

      await tester.tap(find.byKey(const ValueKey('payment_wallet_chip')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Không ghi vào ví nào'));
      await tester.pumpAndSettle();

      expect(find.text('Không ghi ví'), findsOneWidget);
    });

    testWidgets('no wallets at all means no chip to press', (tester) async {
      await _pump(
        tester,
        AddPaymentSheet(loan: _loan, remaining: 5000000),
        wallets: const [],
      );

      expect(find.byKey(const ValueKey('payment_wallet_chip')), findsNothing);
    });
  });

  group('loan form', () {
    testWidgets('booking the principal into a wallet is off by default', (
      tester,
    ) async {
      await _pump(tester, const LoanFormSheet());

      expect(find.text('Ghi vào ví'), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
      // Nothing to pick until the switch is on.
      expect(find.byKey(const ValueKey('funding_wallet_chip')), findsNothing);
    });

    testWidgets('turning it on reveals a wallet, pre-picked', (tester) async {
      await _pump(tester, const LoanFormSheet());

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('funding_wallet_chip')), findsOneWidget);
      expect(find.text('Tiền mặt'), findsOneWidget);
    });

    testWidgets('the side of the loan decides which way the money goes', (
      tester,
    ) async {
      await _pump(tester, const LoanFormSheet());

      expect(find.text('Tiền vay về cộng vào ví'), findsOneWidget);

      await tester.tap(find.text('Tôi cho vay'));
      await tester.pumpAndSettle();

      expect(find.text('Tiền cho vay trừ khỏi ví'), findsOneWidget);
    });

    testWidgets('editing a loan is not offered the toggle', (tester) async {
      // The transaction records the money as it arrived at the time; changing
      // the loan later deliberately does not rewrite it (PLAN §2.8).
      await _pump(tester, LoanFormSheet(existing: _loan));

      expect(find.text('Ghi vào ví'), findsNothing);
    });

    testWidgets('no wallets at all hides the toggle entirely', (tester) async {
      await _pump(tester, const LoanFormSheet(), wallets: const []);

      expect(find.text('Ghi vào ví'), findsNothing);
    });
  });

  group('sổ theo dõi', () {
    testWidgets('the form drops the funding section and says why', (
      tester,
    ) async {
      // Wallets exist and the toggle would otherwise be right here — a
      // tracking loan's principal simply has no wallet side (PLAN §2.4).
      await _pump(tester, const LoanFormSheet(trackingOnly: true));

      expect(find.text('Ghi vào ví'), findsNothing);
      expect(find.text('Tiền vay về cộng vào ví'), findsNothing);
      expect(
        find.text('Sổ theo dõi — chỉ ghi nợ, không đụng ví & thống kê'),
        findsOneWidget,
      );
    });

    testWidgets('the payment sheet offers no wallet, and says so', (
      tester,
    ) async {
      await _pump(
        tester,
        AddPaymentSheet(loan: _trackingLoan, remaining: 5000000),
      );

      // Not "no wallet chosen" — no chip at all, because there is no wallet
      // side to choose from.
      expect(find.byKey(const ValueKey('payment_wallet_chip')), findsNothing);
      expect(find.text('Tiền mặt'), findsNothing);
      expect(
        find.text('Chỉ theo dõi — không tạo giao dịch, không trừ ví'),
        findsOneWidget,
      );
    });

    testWidgets('a spending loan keeps its wallet chip', (tester) async {
      // The guard against the branch above firing for every loan.
      await _pump(tester, AddPaymentSheet(loan: _loan, remaining: 5000000));

      expect(find.byKey(const ValueKey('payment_wallet_chip')), findsOneWidget);
      expect(
        find.text('Chỉ theo dõi — không tạo giao dịch, không trừ ví'),
        findsNothing,
      );
    });
  });
}
