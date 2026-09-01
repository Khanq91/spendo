import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/features/categories/domain/category.dart';
import 'package:spendo/features/categories/presentation/providers/category_provider.dart';
import 'package:spendo/features/reminders/presentation/widgets/reminder_form_sheet.dart';
import 'package:spendo/shared/widgets/spendo/spendo.dart';

const _categories = [
  Category(
    id: 'food',
    name: 'Ăn uống',
    colorHex: '#FF6B6B',
    iconName: 'restaurant',
    isDefault: true,
    isIncome: false,
    sortOrder: 0,
  ),
  Category(
    id: 'transport',
    name: 'Di chuyển',
    colorHex: '#7A8A5E',
    iconName: 'directions_car',
    isDefault: true,
    isIncome: false,
    sortOrder: 1,
  ),
];

Future<void> _openOverAnotherSheet(WidgetTester tester, ThemeData theme) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        categoriesProvider.overrideWith((ref) => Stream.value(_categories)),
      ],
      child: MaterialApp(
        theme: theme,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              // Stand-in for the add-transaction sheet the reminder form
              // opens on top of when "Lặp lại" is tapped.
              onPressed: () => SpendoSheet.showModal<void>(
                context: context,
                builder: (inner) => SpendoSheet(
                  child: TextButton(
                    onPressed: () => SpendoSheet.showModal<void>(
                      context: inner,
                      builder: (_) => const ReminderFormSheet(
                        prefillTitle: 'Tiền nước',
                        prefillAmount: 100000,
                      ),
                    ),
                    child: const Text('Lặp lại'),
                  ),
                ),
              ),
              child: const Text('Thêm giao dịch'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Thêm giao dịch'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Lặp lại'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opens over the add sheet with an opaque background', (
    tester,
  ) async {
    await _openOverAnotherSheet(
      tester,
      AppTheme.dark(AppColorScheme.roseDefault),
    );

    expect(find.text('Thêm nhắc nhở'), findsOneWidget);

    // The bug: the reminder form painted no background of its own, so the
    // add sheet underneath showed straight through it.
    final containers = tester.widgetList<Container>(
      find.ancestor(
        of: find.text('Thêm nhắc nhở'),
        matching: find.byType(Container),
      ),
    );
    final opaque = containers.any((c) {
      final decoration = c.decoration;
      return decoration is BoxDecoration && decoration.color?.a == 1.0;
    });
    expect(opaque, isTrue, reason: 'reminder sheet must be opaque');

    // The add sheet's own control must not be reachable through it.
    expect(find.text('Lặp lại').hitTestable(), findsNothing);
  });

  testWidgets('prefills the title and amount from the transaction', (
    tester,
  ) async {
    await _openOverAnotherSheet(
      tester,
      AppTheme.light(AppColorScheme.roseDefault),
    );

    expect(find.text('Tiền nước'), findsOneWidget);
    expect(find.text('100000'), findsOneWidget);
  });

  testWidgets('the category chips use the shared chip, not raw category red', (
    tester,
  ) async {
    await _openOverAnotherSheet(
      tester,
      AppTheme.dark(AppColorScheme.roseDefault),
    );

    final chip = tester.widget<SpendoChip>(
      find.widgetWithText(SpendoChip, 'Ăn uống'),
    );
    // Selected chips read as selected via primaryContainer. Painting them in
    // the category's own #FF6B6B made a chosen chip look like an error on the
    // dark surface.
    expect(chip.selected, isTrue);
  });
}
