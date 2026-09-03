import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/shared/widgets/spendo/spendo.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light(AppColorScheme.roseDefault),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('a pushed screen gets the back arrow', (tester) async {
    await tester.pumpWidget(_host(const SpendoScreenHeader(title: 'Ví')));

    expect(find.byTooltip('Quay lại'), findsOneWidget);
    expect(find.text('Ví'), findsOneWidget);
  });

  testWidgets('a shell tab can drop it, and keeps the title aligned', (
    tester,
  ) async {
    // The Settings tab used to render the arrow with nothing to pop.
    await tester.pumpWidget(
      _host(const SpendoScreenHeader(title: 'Cài đặt', showBack: false)),
    );

    expect(find.byTooltip('Quay lại'), findsNothing);
    // The title starts at the page margin, not flush against the edge.
    expect(tester.getTopLeft(find.text('Cài đặt')).dx, 16);
  });
}
