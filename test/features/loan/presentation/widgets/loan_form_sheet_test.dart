import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/features/loan/domain/loan.dart';
import 'package:spendo/features/loan/presentation/widgets/loan_form_sheet.dart';
import 'package:spendo/shared/widgets/spendo/spendo.dart';

Future<void> _pump(WidgetTester tester, {Loan? existing}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light(AppColorScheme.roseDefault),
        locale: const Locale('vi', 'VN'),
        supportedLocales: const [Locale('vi', 'VN')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: LoanFormSheet(existing: existing)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the due-date picker speaks Vietnamese', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Không hạn'));
    await tester.pumpAndSettle();

    expect(find.text('Chọn ngày'), findsOneWidget);
    expect(find.text('Select date'), findsNothing);
  });

  testWidgets('a due date already in the past still opens the picker', (
    tester,
  ) async {
    // `firstDate: now` used to throw here, because initialDate fell before it
    // (`17-loan-form-sheet.md` §J).
    final past = DateTime.now().subtract(const Duration(days: 400));
    await _pump(
      tester,
      existing: Loan(
        id: 'l1',
        title: 'Vay cũ',
        type: LoanType.borrowed,
        principal: 5000000,
        contactName: 'Anh A',
        startDate: past,
        dueDate: past.add(const Duration(days: 30)),
        colorHex: '#FF6B6B',
        isClosed: false,
      ),
    );

    await tester.tap(find.textContaining('Hạn:'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Chọn ngày'), findsOneWidget);
  });

  testWidgets('the start date is editable, not fixed at creation', (
    tester,
  ) async {
    await _pump(tester);

    // The old form had no way to record a loan taken out last week.
    expect(find.textContaining('Bắt đầu:'), findsOneWidget);

    await tester.tap(find.textContaining('Bắt đầu:'));
    await tester.pumpAndSettle();

    expect(find.text('Chọn ngày'), findsOneWidget);
  });

  testWidgets('saving with no name says what is missing', (tester) async {
    await _pump(tester);

    // Give the amount so the button is live; the name is what is missing.
    await tester.tap(find.descendant(
      of: find.byType(SpendoNumpad),
      matching: find.text('5'),
    ));
    await tester.pumpAndSettle();
    expect(find.text('5 ₫'), findsOneWidget);

    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(find.text('Đặt tên cho khoản vay này'), findsOneWidget);
  });

  testWidgets('editing prefills the loan it was opened on', (tester) async {
    await _pump(
      tester,
      existing: Loan(
        id: 'l1',
        title: 'Vay mua xe',
        type: LoanType.borrowed,
        principal: 5000000,
        contactName: 'Anh A',
        startDate: DateTime(2026, 8),
        colorHex: '#FF6B6B',
        isClosed: false,
      ),
    );

    expect(find.text('Sửa khoản vay'), findsOneWidget);
    expect(find.text('Vay mua xe'), findsOneWidget);
    expect(find.text('5.000.000 ₫'), findsOneWidget);
  });

  testWidgets('a new loan can be set to repay in instalments', (tester) async {
    await _pump(tester);

    expect(find.text('Trả tự do'), findsOneWidget);
    expect(find.text('Trả theo đợt'), findsOneWidget);
  });

  testWidgets('editing does not offer the mode — that lives on the loan', (
    tester,
  ) async {
    // Switching an existing loan between modes means building or dropping a
    // schedule, which belongs beside the schedule itself.
    await _pump(
      tester,
      existing: Loan(
        id: 'l1',
        title: 'Vay mua xe',
        type: LoanType.borrowed,
        principal: 5000000,
        contactName: 'Anh A',
        startDate: DateTime(2026, 8),
        colorHex: '#FF6B6B',
        isClosed: false,
        repaymentMode: RepaymentMode.installment,
      ),
    );

    expect(find.text('Trả tự do'), findsNothing);
    expect(find.text('Trả theo đợt'), findsNothing);
  });

  testWidgets('editing locks the type and the principal', (tester) async {
    // Both were editable, and `update` only rewrites the loans row: the
    // funding transaction, the payments and the schedule kept the old values,
    // so the wallet and the waterfall stopped agreeing with the loan.
    await _pump(
      tester,
      existing: Loan(
        id: 'l1',
        title: 'Cho Bình mượn',
        type: LoanType.lent,
        principal: 5000000,
        contactName: 'Bình',
        startDate: DateTime(2026, 8),
        colorHex: '#FF6B6B',
        isClosed: false,
      ),
    );

    // The type reads back as a label, not a control; there is no keypad.
    expect(find.text('Tôi cho vay'), findsOneWidget);
    expect(find.text('Tôi đang vay'), findsNothing);
    expect(find.byType(SpendoSegmented<LoanType>), findsNothing);
    expect(find.byType(SpendoNumpad), findsNothing);
    expect(find.text('5.000.000 ₫'), findsOneWidget);
    expect(find.textContaining('cố định sau khi tạo'), findsOneWidget);
    // Saving stays possible without a keypad entry.
    expect(
      tester.widget<SpendoButton>(find.byType(SpendoButton)).onPressed,
      isNotNull,
    );
  });
}
