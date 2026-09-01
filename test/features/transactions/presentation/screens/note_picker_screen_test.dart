import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/features/categories/domain/category.dart';
import 'package:spendo/features/transactions/presentation/screens/note_picker_screen.dart';

const _categories = [
  Category(
    id: 'food',
    name: 'Ăn uống',
    colorHex: '#C67139',
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

Future<NotePickerResult?> _open(
  WidgetTester tester, {
  String initialNote = '',
  String? initialCategoryId = 'food',
}) async {
  NotePickerResult? result;

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(AppColorScheme.roseDefault),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              result = await Navigator.of(context).push<NotePickerResult>(
                MaterialPageRoute(
                  builder: (_) => NotePickerScreen(
                    initialNote: initialNote,
                    initialCategoryId: initialCategoryId,
                    categories: _categories,
                  ),
                ),
              );
            },
            child: const Text('Mở'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Mở'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  // The history query hits PowerSync, which is unavailable in tests;
  // loadNoteHistory swallows that, so only the starter notes show.

  testWidgets('suggests the starter notes for the selected category', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _open(tester);

    expect(find.text('GỢI Ý'), findsOneWidget);
    expect(find.text('Ăn sáng'), findsOneWidget);
    expect(find.text('Cà phê'), findsOneWidget);
    expect(find.text('Xăng xe'), findsNothing);
  });

  testWidgets('switching category swaps the suggestions', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _open(tester);

    await tester.tap(find.text('Di chuyển'));
    await tester.pumpAndSettle();

    expect(find.text('Xăng xe'), findsOneWidget);
    expect(find.text('Ăn sáng'), findsNothing);
  });

  testWidgets('tapping a suggestion fills the field without leaving', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _open(tester);

    await tester.tap(find.text('Cà phê'));
    await tester.pumpAndSettle();

    expect(find.byType(NotePickerScreen), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'Cà phê',
    );

    // The label switches once there is a query to match against.
    expect(find.text('KẾT QUẢ TÌM KIẾM'), findsOneWidget);
  });

  testWidgets('typing filters the suggestions', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _open(tester);

    await tester.enterText(find.byType(TextField), 'ăn');
    await tester.pumpAndSettle();

    expect(find.text('Ăn sáng'), findsOneWidget);
    expect(find.text('Cà phê'), findsNothing);
  });
}
