import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/features/loan/domain/loan.dart';
import 'package:spendo/features/loan/presentation/providers/loan_provider.dart';
import 'package:spendo/features/loan/presentation/screens/loan_detail_screen.dart';

Loan _loan({
  RepaymentMode mode = RepaymentMode.installment,
  int principal = 9000000,
}) => Loan(
  id: 'l1',
  title: 'Vay mua xe',
  type: LoanType.borrowed,
  principal: principal,
  contactName: 'Anh A',
  startDate: DateTime(2026, 8),
  colorHex: '#B23A2E',
  isClosed: false,
  repaymentMode: mode,
);

/// Three instalments of 3tr: one already past, two still ahead.
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

LoanPayment _payment(int amount) => LoanPayment(
  id: 'p$amount',
  loanId: 'l1',
  amount: amount,
  paidAt: DateTime.now().subtract(const Duration(days: 1)),
);

Future<void> _pump(
  WidgetTester tester, {
  Loan? loan,
  List<LoanInstallment> installments = const [],
  List<LoanPayment> payments = const [],
}) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      loansProvider.overrideWith((ref) => Stream.value([loan ?? _loan()])),
      loanPaymentsProvider.overrideWith((ref, id) => Stream.value(payments)),
      loanInstallmentsProvider.overrideWith(
        (ref, id) => Stream.value(installments),
      ),
      paidByLoanProvider.overrideWith(
        (ref) => Stream.value({
          'l1': payments.fold(0, (sum, p) => sum + p.amount),
        }),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(AppColorScheme.roseDefault),
        home: const LoanDetailScreen(loanId: 'l1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a free loan is offered a schedule, not shown one', (
    tester,
  ) async {
    await _pump(tester, loan: _loan(mode: RepaymentMode.free));

    expect(find.text('Tạo lịch trả góp'), findsOneWidget);
    expect(find.text('LỊCH TRẢ'), findsNothing);
  });

  testWidgets('a settled loan is not offered a schedule', (tester) async {
    await _pump(
      tester,
      loan: _loan(mode: RepaymentMode.free),
      payments: [_payment(9000000)],
    );

    expect(find.text('Tạo lịch trả góp'), findsNothing);
  });

  testWidgets('an unpaid schedule shows the first instalment overdue', (
    tester,
  ) async {
    await _pump(tester, installments: _schedule());

    expect(find.text('LỊCH TRẢ'), findsOneWidget);
    expect(find.text('Đã xong 0/3 đợt'), findsOneWidget);
    expect(find.text('Đợt 1/3 · 3.000.000'), findsOneWidget);
    expect(find.textContaining('Quá hạn'), findsWidgets);
    expect(find.textContaining('Chưa đến hạn'), findsWidgets);
  });

  testWidgets('one lump sum settles the first and leaves the second short', (
    tester,
  ) async {
    // 5tr against 3 × 3tr: instalment 1 done, instalment 2 owing 1tr.
    await _pump(
      tester,
      installments: _schedule(),
      payments: [_payment(5000000)],
    );

    expect(find.text('Đã xong 1/3 đợt'), findsOneWidget);
    // The settled instalment drops out of the list; what is owing leads.
    expect(find.text('Đợt 1/3 · 3.000.000'), findsNothing);
    expect(find.text('Đợt 2/3 · 3.000.000'), findsOneWidget);
    expect(find.textContaining('Còn thiếu 1.000.000'), findsOneWidget);
  });

  testWidgets('a fully paid schedule says so instead of going blank', (
    tester,
  ) async {
    await _pump(
      tester,
      installments: _schedule(),
      payments: [_payment(9000000)],
    );

    expect(find.text('Đã xong 3/3 đợt'), findsOneWidget);
    expect(find.text('Đã trả xong tất cả các đợt.'), findsOneWidget);
  });

  testWidgets('money paid before the schedule existed does not fill it', (
    tester,
  ) async {
    // A 12tr loan with 3tr already paid, then a 9tr schedule: offset 3tr, so
    // the instalments start empty (PLAN §2.3).
    await _pump(
      tester,
      loan: _loan(principal: 12000000),
      installments: _schedule(),
      payments: [_payment(3000000)],
    );

    expect(find.text('Đã xong 0/3 đợt'), findsOneWidget);
    expect(find.text('Đợt 1/3 · 3.000.000'), findsOneWidget);
  });

  testWidgets('paying opens the sheet on the instalment that is next', (
    tester,
  ) async {
    await _pump(
      tester,
      installments: _schedule(),
      payments: [_payment(5000000)],
    );

    await tester.tap(find.text('Ghi nhận thanh toán'));
    await tester.pumpAndSettle();

    // The caption names the instalment, and the shortfall arrives pre-filled.
    expect(find.textContaining('Đợt 2/3 · hạn'), findsOneWidget);
    expect(find.text('1.000.000 ₫'), findsOneWidget);
  });
}
