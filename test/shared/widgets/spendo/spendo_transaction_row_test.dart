import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/shared/widgets/spendo/spendo.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light(AppColorScheme.roseDefault),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('a ten-digit amount and a badge still fit a 360dp row', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _host(
        SpendoTransactionRow(
          title: 'Thu nhập từ hợp đồng dài hạn',
          subtitle: 'Lương tháng 8 và thưởng dự án cuối năm · 09:15',
          amountText: '+1.999.999.999 ₫',
          isIncome: true,
          iconName: 'work',
          badge: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            color: Colors.blue,
            child: const Text('Tự động', style: TextStyle(fontSize: 10)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('+1.999.999.999 ₫'), findsOneWidget);
  });

  testWidgets('the day header ellipsises the date before the total', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _host(
        const SpendoDayHeader(
          label: 'Thứ 4, 5 tháng 8 năm 2026',
          totalText: '+1.999.999.999 ₫',
          totalIsIncome: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('+1.999.999.999 ₫'), findsOneWidget);
  });
}
