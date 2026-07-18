import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/features/loan/presentation/widgets/loan_form_sheet.dart';

void main() {
  testWidgets('shows the loan due-date picker in Vietnamese', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MaterialApp(
          locale: const Locale('vi', 'VN'),
          supportedLocales: const [Locale('vi', 'VN')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const Scaffold(body: LoanFormSheet()),
        ),
      ),
    );

    await tester.tap(find.text('Ngày hết hạn (tuỳ chọn)'));
    await tester.pumpAndSettle();

    expect(find.text('Chọn ngày'), findsOneWidget);
    expect(find.text('Huỷ'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
    expect(find.text('Select date'), findsNothing);
  });
}
