import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:spendo/core/router/app_router.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/features/loan/domain/loan.dart';
import 'package:spendo/features/loan/presentation/providers/loan_provider.dart';
import 'package:spendo/features/loan/presentation/screens/loan_detail_screen.dart';
import 'package:spendo/features/wallets/domain/wallet.dart';
import 'package:spendo/features/wallets/presentation/providers/wallet_provider.dart';

final _loan = Loan(
  id: 'l1',
  title: 'Vay mua xe',
  type: LoanType.borrowed,
  principal: 9000000,
  contactName: 'Anh A',
  startDate: DateTime(2026, 8),
  colorHex: '#B23A2E',
  isClosed: false,
  repaymentMode: RepaymentMode.installment,
);

/// Three instalments of 3tr: the first already behind, two ahead.
List<LoanInstallment> _schedule() => [
  LoanInstallment(
    id: 'i1',
    loanId: 'l1',
    seq: 1,
    amount: 3000000,
    dueDate: DateTime.now().subtract(const Duration(days: 10)),
  ),
  LoanInstallment(
    id: 'i2',
    loanId: 'l1',
    seq: 2,
    amount: 3000000,
    dueDate: DateTime.now().add(const Duration(days: 20)),
  ),
  LoanInstallment(
    id: 'i3',
    loanId: 'l1',
    seq: 3,
    amount: 3000000,
    dueDate: DateTime.now().add(const Duration(days: 50)),
  ),
];

/// The app's `/loan-pay` route, standing alone.
///
/// The real router is not used because building it reaches for a database;
/// the page under test is the real one, imported from it.
GoRouter _router(String location) => GoRouter(
  initialLocation: location,
  routes: [
    GoRoute(
      path: '/loan-pay',
      builder: (_, state) {
        final amountStr = state.uri.queryParameters['amount'];
        return LoanPaymentPage(
          loanId: state.uri.queryParameters['loan_id'] ?? '',
          prefillAmount: amountStr != null ? int.tryParse(amountStr) : null,
        );
      },
    ),
  ],
);

Future<void> _pump(
  WidgetTester tester, {
  required String location,
  List<LoanInstallment>? installments,
  int paid = 0,
  List<Loan>? loans,
}) async {
  tester.view.physicalSize = const Size(400, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        loansProvider.overrideWith((ref) => Stream.value(loans ?? [_loan])),
        loanPaymentsProvider.overrideWith(
          (ref, id) => Stream.value(const <LoanPayment>[]),
        ),
        loanInstallmentsProvider.overrideWith(
          (ref, id) => Stream.value(installments ?? _schedule()),
        ),
        paidByLoanProvider.overrideWith((ref) => Stream.value({'l1': paid})),
        walletsProvider.overrideWith((ref) => Stream.value(const <Wallet>[])),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(AppColorScheme.roseDefault),
        routerConfig: _router(location),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the deep link lands on the loan with the sheet already open', (
    tester,
  ) async {
    await _pump(tester, location: '/loan-pay?loan_id=l1&amount=3000000');

    // The loan is behind the sheet, so closing it leaves the user where the
    // notification was pointing rather than dropping them at home.
    expect(find.byType(LoanDetailScreen), findsOneWidget);
    expect(find.text('Ghi nhận thanh toán'), findsWidgets);
    expect(find.textContaining('Đợt 1/3 · hạn'), findsOneWidget);
  });

  testWidgets('the sheet opens on the instalment that is next, not the one '
      'the notification named', (tester) async {
    // A reminder fired for instalment 1, but by the time it is tapped the
    // instalment has been paid. The waterfall decides, so the sheet lands on
    // instalment 2 rather than asking again for money already paid.
    await _pump(
      tester,
      location: '/loan-pay?loan_id=l1&amount=3000000',
      paid: 3000000,
    );

    expect(find.textContaining('Đợt 2/3 · hạn'), findsOneWidget);
    expect(find.text('3.000.000 ₫'), findsWidgets);
  });

  testWidgets('a loan that is gone shows the empty state, not a blank sheet', (
    tester,
  ) async {
    await _pump(tester, location: '/loan-pay?loan_id=l1', loans: const []);

    expect(find.text('Khoản vay không còn tồn tại'), findsOneWidget);
    expect(find.textContaining('Đợt'), findsNothing);
  });

  testWidgets('a free-repayment loan opens on what is left, with no instalment',
      (tester) async {
    await _pump(
      tester,
      location: '/loan-pay?loan_id=l1',
      installments: const [],
      paid: 2000000,
    );

    expect(find.textContaining('Đợt'), findsNothing);
    expect(find.textContaining('Còn lại 7.000.000'), findsOneWidget);
  });
}
