import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/features/loan/domain/loan.dart';
import 'package:spendo/features/loan/presentation/providers/loan_provider.dart';
import 'package:spendo/features/loan/presentation/screens/loan_detail_screen.dart';

Loan _loan({bool closed = false, DateTime? dueDate}) => Loan(
  id: 'l1',
  title: 'Vay mua xe',
  type: LoanType.borrowed,
  principal: 5000000,
  contactName: 'Anh A',
  startDate: DateTime(2026, 8),
  dueDate: dueDate,
  note: 'Vay sửa xe máy',
  colorHex: '#B23A2E',
  isClosed: closed,
);

final _payments = [
  LoanPayment(
    id: 'p1',
    loanId: 'l1',
    amount: 600000,
    paidAt: DateTime.now().subtract(const Duration(days: 1)),
    note: 'Chuyển khoản MB',
  ),
  LoanPayment(
    id: 'p2',
    loanId: 'l1',
    amount: 400000,
    paidAt: DateTime(2026, 8, 15),
  ),
];

ProviderContainer _container({
  List<Loan>? loans,
  List<LoanPayment> payments = const [],
}) {
  return ProviderContainer(
    overrides: [
      loansProvider.overrideWith((ref) => Stream.value(loans ?? [_loan()])),
      loanPaymentsProvider.overrideWith((ref, id) => Stream.value(payments)),
    ],
  );
}

Future<void> _pump(WidgetTester tester, ProviderContainer container) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

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
  testWidgets('a payment shows the note it was saved with', (tester) async {
    final container = _container(payments: _payments);
    addTearDown(container.dispose);

    await _pump(tester, container);

    expect(tester.takeException(), isNull);
    // The note was captured by the old sheet and then never displayed
    // anywhere (`16-loan-detail.md` §L).
    expect(find.textContaining('Chuyển khoản MB'), findsOneWidget);
    expect(find.text('600.000 ₫'), findsOneWidget);
    expect(find.text('Còn: 4.000.000 ₫'), findsOneWidget);
  });

  testWidgets('paying the last of it offers to close the loan', (tester) async {
    final container = _container(
      payments: [
        LoanPayment(
          id: 'p1',
          loanId: 'l1',
          amount: 5000000,
          paidAt: DateTime(2026, 8, 20),
        ),
      ],
    );
    addTearDown(container.dispose);

    await _pump(tester, container);

    // Reaching zero used to leave the loan open with no prompt at all.
    expect(find.text('Đánh dấu tất toán'), findsOneWidget);
    expect(find.text('Ghi nhận thanh toán'), findsNothing);
    expect(find.text('Còn: 0 ₫'), findsOneWidget);
  });

  testWidgets('a due date within the week reads as a badge, not an emoji', (
    tester,
  ) async {
    final container = _container(
      loans: [_loan(dueDate: DateTime.now().add(const Duration(days: 3)))],
    );
    addTearDown(container.dispose);

    await _pump(tester, container);

    expect(find.text('Còn 3 ngày'), findsOneWidget);
    expect(find.textContaining('⚠️'), findsNothing);
    expect(find.textContaining('🔴'), findsNothing);
  });

  testWidgets('a loan that no longer exists says so', (tester) async {
    final container = _container(loans: const []);
    addTearDown(container.dispose);

    await _pump(tester, container);

    // The old screen kept rendering the Loan it was pushed with, so a loan
    // deleted elsewhere still looked alive.
    expect(find.text('Khoản vay không còn tồn tại'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('a closed loan hides the payment action', (tester) async {
    final container = _container(loans: [_loan(closed: true)]);
    addTearDown(container.dispose);

    await _pump(tester, container);

    expect(find.text('Đã tất toán'), findsOneWidget);
    expect(find.text('Ghi nhận thanh toán'), findsNothing);
    expect(find.text('Đánh dấu tất toán'), findsNothing);
  });
}
