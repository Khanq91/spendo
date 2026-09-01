import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/features/loan/domain/loan.dart';
import 'package:spendo/features/loan/presentation/screens/installment_schedule_screen.dart';

final _loan = Loan(
  id: 'l1',
  title: 'Vay mua xe',
  type: LoanType.borrowed,
  principal: 10000000,
  contactName: 'Anh A',
  startDate: DateTime(2026, 9),
  colorHex: '#B23A2E',
  isClosed: false,
);

List<LoanInstallment> _schedule(List<int> amounts) => [
  for (var i = 0; i < amounts.length; i++)
    LoanInstallment(
      id: 'i${i + 1}',
      loanId: 'l1',
      seq: i + 1,
      amount: amounts[i],
      dueDate: DateTime(2026, 10 + i, 15),
    ),
];

Future<void> _pump(
  WidgetTester tester, {
  int target = 10000000,
  List<LoanInstallment> existing = const [],
}) async {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light(AppColorScheme.roseDefault),
        home: InstallmentScheduleScreen(
          loan: _loan,
          target: target,
          existing: existing,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('splitting evenly rounds down and gives the last the odd đồng', (
    tester,
  ) async {
    await _pump(tester);

    await tester.enterText(find.byType(TextField), '3');
    await tester.tap(find.text('Tạo lịch'));
    await tester.pumpAndSettle();

    expect(find.text('Đợt 1'), findsOneWidget);
    expect(find.text('Đợt 3'), findsOneWidget);
    expect(find.text('3.333.000'), findsNWidgets(2));
    expect(find.text('3.334.000'), findsOneWidget);
    // The total lines up with the principal, so no warning is offered.
    expect(find.text('Tổng 3 đợt'), findsOneWidget);
    expect(find.textContaining('Tổng các đợt'), findsNothing);
  });

  testWidgets('splitting by amount leaves the remainder in a short last row', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.text('Theo số tiền'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '3000000');
    await tester.tap(find.text('Tạo lịch'));
    await tester.pumpAndSettle();

    expect(find.text('Tổng 4 đợt'), findsOneWidget);
    expect(find.text('3.000.000'), findsNWidgets(3));
    expect(find.text('1.000.000'), findsOneWidget);
  });

  testWidgets('an amount small enough to blow past the cap is refused', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.text('Theo số tiền'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '50000');
    await tester.tap(find.text('Tạo lịch'));
    await tester.pumpAndSettle();

    expect(find.textContaining('vượt quá 100 đợt'), findsOneWidget);
    expect(find.textContaining('Tổng'), findsNothing);
  });

  testWidgets('more instalments than the cap is refused', (tester) async {
    await _pump(tester);

    await tester.enterText(find.byType(TextField), '150');
    await tester.tap(find.text('Tạo lịch'));
    await tester.pumpAndSettle();

    expect(find.text('Tối đa 100 đợt'), findsOneWidget);
  });

  testWidgets('a schedule that does not add up warns and can be corrected', (
    tester,
  ) async {
    // Two instalments of 3tr against a 10tr loan: 4tr short.
    await _pump(tester, existing: _schedule([3000000, 3000000]));

    expect(find.text('Tổng các đợt thiếu 4.000.000 ₫'), findsOneWidget);

    await tester.tap(find.text('Dồn vào đợt cuối'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Tổng các đợt'), findsNothing);
    expect(find.text('7.000.000'), findsOneWidget);
  });

  testWidgets('a schedule over the target warns about the excess', (
    tester,
  ) async {
    await _pump(tester, existing: _schedule([6000000, 6000000]));

    expect(find.text('Tổng các đợt thừa 2.000.000 ₫'), findsOneWidget);
    // Saving a schedule that does not add up is deliberately allowed.
    expect(
      find.textContaining('Lưu được cả khi lệch'),
      findsOneWidget,
    );
  });

  testWidgets('deleting an instalment renumbers the ones left', (tester) async {
    await _pump(tester, existing: _schedule([3000000, 3000000, 4000000]));

    expect(find.text('Đợt 3'), findsOneWidget);
    await tester.tap(find.byTooltip('Xoá đợt 2'));
    await tester.pumpAndSettle();

    expect(find.text('Đợt 3'), findsNothing);
    expect(find.text('Đợt 2'), findsOneWidget);
    expect(find.text('Tổng 2 đợt'), findsOneWidget);
  });

  testWidgets('an existing schedule opens with its rows already listed', (
    tester,
  ) async {
    await _pump(tester, existing: _schedule([5000000, 5000000]));

    expect(find.text('Sửa lịch trả'), findsOneWidget);
    expect(find.text('CÁC ĐỢT (2)'), findsOneWidget);
    expect(find.text('15/10/2026'), findsOneWidget);
    expect(find.text('15/11/2026'), findsOneWidget);
  });

  testWidgets('a long schedule collapses until asked for the rest', (
    tester,
  ) async {
    await _pump(tester);

    await tester.enterText(find.byType(TextField), '12');
    await tester.tap(find.text('Tạo lịch'));
    await tester.pumpAndSettle();

    expect(find.text('Đợt 6'), findsOneWidget);
    expect(find.text('Đợt 7'), findsNothing);

    await tester.tap(find.text('Xem tất cả (6 đợt nữa)'));
    await tester.pumpAndSettle();

    expect(find.text('Đợt 12'), findsOneWidget);
  });

  testWidgets('nothing generated yet leaves the save button disabled', (
    tester,
  ) async {
    await _pump(tester, target: 0);

    expect(find.text('Chưa có đợt nào'), findsOneWidget);
    final button = tester.widget<InkWell>(
      find.ancestor(
        of: find.text('Lưu lịch trả'),
        matching: find.byType(InkWell),
      ).first,
    );
    expect(button.onTap, isNull);
  });
}
