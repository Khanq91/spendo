import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/features/loan/domain/loan.dart';
import 'package:spendo/features/loan/presentation/providers/loan_provider.dart';
import 'package:spendo/features/loan/presentation/screens/loan_list_screen.dart';

/// The two sổ, each holding one loan of each side, so a screen that read the
/// wrong book — or both — would be obvious.
final _spending = [
  _loan(id: 's1', title: 'Vay mua xe', type: LoanType.borrowed),
  _loan(id: 's2', title: 'Cho B mượn', type: LoanType.lent),
];

final _tracking = [
  _loan(
    id: 't1',
    title: 'Nợ tiền cưới',
    type: LoanType.borrowed,
    tracking: true,
  ),
  _loan(id: 't2', title: 'Bạn C mượn', type: LoanType.lent, tracking: true),
];

Loan _loan({
  required String id,
  required String title,
  required LoanType type,
  bool tracking = false,
}) => Loan(
  id: id,
  title: title,
  type: type,
  principal: 2000000,
  contactName: '',
  startDate: DateTime(2026, 8),
  colorHex: '#B23A2E',
  isClosed: false,
  isTrackingOnly: tracking,
);

ProviderContainer _container({
  List<Loan>? spending,
  List<Loan>? tracking,
}) {
  return ProviderContainer(
    overrides: [
      loansProvider.overrideWith((ref) => Stream.value(spending ?? _spending)),
      trackingLoansProvider.overrideWith(
        (ref) => Stream.value(tracking ?? _tracking),
      ),
      paidByLoanProvider.overrideWith((ref) => Stream.value(const {})),
      installmentsByLoanProvider.overrideWith(
        (ref) => Stream.value(const <String, List<LoanInstallment>>{}),
      ),
    ],
  );
}

/// Both books behind a real router, so the app-bar door between them is
/// exercised the way it is used.
Future<void> _pump(
  WidgetTester tester,
  ProviderContainer container, {
  String at = '/loans',
}) async {
  tester.view.physicalSize = const Size(360, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: at,
    routes: [
      GoRoute(path: '/loans', builder: (_, __) => const LoanListScreen()),
      GoRoute(
        path: '/loans-tracking',
        builder: (_, __) => const LoanListScreen(trackingOnly: true),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light(AppColorScheme.roseDefault),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('each page shows only its own sổ', (tester) async {
    final container = _container();
    addTearDown(container.dispose);

    await _pump(tester, container);

    expect(find.text('Khoản vay'), findsOneWidget);
    expect(find.text('Vay mua xe'), findsOneWidget);
    expect(find.text('Nợ tiền cưới'), findsNothing);

    await tester.tap(find.byTooltip('Sổ theo dõi'));
    await tester.pumpAndSettle();

    expect(find.text('Sổ theo dõi'), findsOneWidget);
    expect(find.text('Nợ tiền cưới'), findsOneWidget);
    expect(find.text('Bạn C mượn'), findsOneWidget);
    expect(find.text('Vay mua xe'), findsNothing);
  });

  testWidgets('the totals of one sổ never include the other', (tester) async {
    final container = _container(
      // 2.000.000 + 2.000.000 either side of the divide: a header that added
      // both books would read 4.000.000.
      spending: [_loan(id: 's1', title: 'Vay mua xe', type: LoanType.borrowed)],
      tracking: [
        _loan(
          id: 't1',
          title: 'Nợ tiền cưới',
          type: LoanType.borrowed,
          tracking: true,
        ),
      ],
    );
    addTearDown(container.dispose);

    await _pump(tester, container, at: '/loans-tracking');

    expect(find.text('2.000.000 ₫'), findsWidgets);
    expect(find.text('4.000.000 ₫'), findsNothing);
  });

  testWidgets('an empty tracking sổ says what the sổ is for', (tester) async {
    final container = _container(tracking: const []);
    addTearDown(container.dispose);

    await _pump(tester, container, at: '/loans-tracking');

    expect(find.text('Sổ theo dõi còn trống'), findsOneWidget);
    expect(
      find.textContaining('không đụng ví'),
      findsOneWidget,
    );
    // The spending sổ's empty state must not have been borrowed wholesale.
    expect(find.text('Chưa có khoản vay nào'), findsNothing);
  });

  testWidgets('narrowing one sổ leaves the other alone', (tester) async {
    final container = _container();
    addTearDown(container.dispose);

    await _pump(tester, container);

    // The filter used to be one global StateProvider, so the two pages shared
    // it and narrowing here narrowed there (PLAN §2.5).
    await tester.tap(find.widgetWithText(GestureDetector, 'Cho vay'));
    await tester.pumpAndSettle();
    expect(find.text('Vay mua xe'), findsNothing);
    expect(find.text('Cho B mượn'), findsOneWidget);

    await tester.tap(find.byTooltip('Sổ theo dõi'));
    await tester.pumpAndSettle();

    expect(find.text('Nợ tiền cưới'), findsOneWidget);
    expect(find.text('Bạn C mượn'), findsOneWidget);

    // ...and going back finds the spending sổ still narrowed to Cho vay.
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.text('Vay mua xe'), findsNothing);
    expect(find.text('Cho B mượn'), findsOneWidget);
  });

  testWidgets('only the spending sổ carries the door to the other', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);

    await _pump(tester, container, at: '/loans-tracking');

    // One-way: from the tracking page the door is the back button.
    expect(find.byTooltip('Sổ theo dõi'), findsNothing);
    expect(find.text('Thêm khoản theo dõi'), findsOneWidget);
  });
}
