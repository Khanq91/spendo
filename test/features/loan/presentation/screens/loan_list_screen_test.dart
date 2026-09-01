import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/features/loan/domain/loan.dart';
import 'package:spendo/features/loan/presentation/providers/loan_provider.dart';
import 'package:spendo/features/loan/presentation/screens/loan_list_screen.dart';

final _loans = [
  Loan(
    id: 'borrow',
    title: 'Vay mua xe',
    type: LoanType.borrowed,
    principal: 5000000,
    contactName: 'Anh A',
    startDate: DateTime(2026, 8),
    dueDate: DateTime.now().add(const Duration(days: 3)),
    colorHex: '#B23A2E',
    isClosed: false,
  ),
  Loan(
    id: 'lend',
    title: 'Cho B mượn',
    type: LoanType.lent,
    principal: 2000000,
    contactName: 'Bạn B',
    startDate: DateTime(2026, 8),
    colorHex: '#5A7230',
    isClosed: false,
  ),
  Loan(
    id: 'done',
    title: 'Vay cũ',
    type: LoanType.borrowed,
    principal: 1000000,
    contactName: '',
    startDate: DateTime(2026, 1),
    colorHex: '#86735F',
    isClosed: true,
  ),
];

ProviderContainer _container({
  List<Loan>? loans,
  Map<String, int> paid = const {'borrow': 1000000},
}) {
  return ProviderContainer(
    overrides: [
      loansProvider.overrideWith((ref) => Stream.value(loans ?? _loans)),
      paidByLoanProvider.overrideWith((ref) => Stream.value(paid)),
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
        home: const LoanListScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a row shows what is left, not the principal', (tester) async {
    final container = _container();
    addTearDown(container.dispose);

    await _pump(tester, container);

    expect(tester.takeException(), isNull);
    // 5.000.000 borrowed, 1.000.000 repaid. The audit found the list showing
    // the principal, so the remaining balance meant opening the loan.
    expect(find.text('Còn lại'), findsNWidgets(2));
    expect(find.text('4.000.000 ₫'), findsWidgets);
    expect(find.text('20%'), findsOneWidget);
  });

  testWidgets('the header totals what is owed on each side', (tester) async {
    final container = _container();
    addTearDown(container.dispose);

    await _pump(tester, container);

    expect(find.text('Đang nợ'), findsOneWidget);
    expect(find.text('Được nợ'), findsOneWidget);
    expect(find.text('2.000.000 ₫'), findsWidgets);
  });

  testWidgets('the segmented filter narrows the list in place', (tester) async {
    final container = _container();
    addTearDown(container.dispose);

    await _pump(tester, container);

    // The filter used to arrive only as a query parameter from a screen that
    // no longer exists, leaving the list with no way to narrow itself.
    expect(find.text('Vay mua xe'), findsOneWidget);
    expect(find.text('Cho B mượn'), findsOneWidget);

    await tester.tap(find.widgetWithText(GestureDetector, 'Cho vay'));
    await tester.pumpAndSettle();

    expect(find.text('Vay mua xe'), findsNothing);
    expect(find.text('Cho B mượn'), findsOneWidget);
  });

  testWidgets('closed loans sit behind a collapsed section', (tester) async {
    final container = _container();
    addTearDown(container.dispose);

    await _pump(tester, container);

    expect(find.text('ĐÃ TẤT TOÁN (1)'), findsOneWidget);
    // AnimatedCrossFade keeps both branches in the tree, so what collapses is
    // the crossfade's own height, not the tile's presence.
    final section = find.byType(AnimatedCrossFade);
    expect(tester.getSize(section).height, 0);

    await tester.tap(find.text('ĐÃ TẤT TOÁN (1)'));
    await tester.pumpAndSettle();

    expect(tester.getSize(section).height, greaterThan(0));
    await tester.scrollUntilVisible(find.text('Vay cũ'), 120);
    expect(find.text('Vay cũ'), findsOneWidget);
  });

  testWidgets('there is one way to add a loan, not three', (tester) async {
    final container = _container();
    addTearDown(container.dispose);

    await _pump(tester, container);

    // The audit counted an app-bar +, a FAB and an empty-state CTA.
    expect(find.text('Thêm khoản vay'), findsOneWidget);
  });

  testWidgets('a failed load offers a retry, not a raw exception', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        loansProvider.overrideWith(
          (ref) => Stream<List<Loan>>.error(StateError('db down')),
        ),
        paidByLoanProvider.overrideWith((ref) => Stream.value(const {})),
      ],
    );
    addTearDown(container.dispose);

    await _pump(tester, container);

    expect(find.text('Không tải được khoản vay'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.textContaining('db down'), findsNothing);
  });
}
