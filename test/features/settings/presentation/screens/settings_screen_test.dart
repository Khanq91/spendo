import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendo/core/theme/visual_mode_provider.dart';
import 'package:spendo/features/categories/domain/category.dart';
import 'package:spendo/features/categories/presentation/providers/category_provider.dart';
import 'package:spendo/features/settings/presentation/screens/settings_screen.dart';
import 'package:spendo/shared/widgets/app_bottom_nav.dart';

void main() {
  testWidgets('does not paint squeezed category rows while collapsing', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    const categories = [
      Category(
        id: 'food',
        name: 'Ăn uống',
        colorHex: '#FF6B6B',
        iconName: 'utensils',
        isDefault: true,
        isIncome: false,
        sortOrder: 0,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoriesProvider.overrideWith((ref) => Stream.value(categories)),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Danh mục thu chi'),
      find.byType(ListView),
      const Offset(0, -500),
    );
    await tester.tap(find.text('Danh mục thu chi'));
    await tester.pumpAndSettle();
    expect(find.text('Ăn uống'), findsOneWidget);

    for (final label in ['Chi (1)', 'Thu (0)']) {
      final target = find.ancestor(
        of: find.text(label),
        matching: find.byType(InkWell),
      );
      expect(target, findsOneWidget);
      expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
    }

    await tester.tap(find.text('Danh mục thu chi'));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Ăn uống'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the final Settings content above the fancy bottom bar', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      appVisualModePrefsKey: AppVisualMode.fancy.name,
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoriesProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: const MaterialApp(home: AppShell()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Cài đặt').last, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Xuất báo cáo').hitTestable(), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -5000));
    await tester.pump(const Duration(milliseconds: 500));

    final finalContentBottom =
        tester.getRect(find.text('Danh mục thu chi')).bottom;
    final bottomBarTop = tester.getRect(find.byType(GlassTabBar)).top;

    expect(finalContentBottom, lessThanOrEqualTo(bottomBarTop));
    expect(tester.takeException(), isNull);
  });
}
