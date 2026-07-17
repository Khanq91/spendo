import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendo/features/categories/domain/category.dart';
import 'package:spendo/features/categories/presentation/providers/category_provider.dart';
import 'package:spendo/features/settings/presentation/screens/settings_screen.dart';

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

    await tester.tap(find.text('Danh mục thu chi'));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Ăn uống'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
