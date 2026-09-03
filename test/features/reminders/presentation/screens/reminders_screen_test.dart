import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/features/categories/domain/category.dart';
import 'package:spendo/features/categories/presentation/providers/category_provider.dart';
import 'package:spendo/features/habits/domain/detected_habit.dart';
import 'package:spendo/features/habits/presentation/providers/habit_provider.dart';
import 'package:spendo/features/reminders/domain/recurring_reminder.dart';
import 'package:spendo/features/reminders/presentation/providers/reminder_provider.dart';
import 'package:spendo/features/reminders/presentation/screens/reminders_screen.dart';
import 'package:spendo/shared/widgets/spendo/spendo.dart';

const _categories = [
  Category(
    id: 'bills',
    name: 'Hoá đơn',
    colorHex: '#5E7E8A',
    iconName: 'home',
    isDefault: true,
    isIncome: false,
    sortOrder: 0,
  ),
];

/// Two days from now at 20:00 — ahead of the clock whenever the suite runs,
/// so the "Lần tới" line is asserted against a live date, not a fixed one.
final _ahead = () {
  final day = DateTime.now().add(const Duration(days: 2));
  return DateTime(day.year, day.month, day.day, 20);
}();

const _weekdays = ['', 'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'CN'];

String _nextLine(DateTime next) =>
    'Lần tới: ${_weekdays[next.weekday]}, ${next.day}/${next.month} · '
    '${next.hour.toString().padLeft(2, '0')}:00';

RecurringReminder _reminder({
  bool active = true,
  int? amountHint = 300000,
  DateTime? nextTrigger,
}) => RecurringReminder(
  id: 'r1',
  title: 'Tiền điện',
  categoryId: 'bills',
  amountHint: amountHint,
  frequency: ReminderFrequency.monthly,
  dayOfMonth: 5,
  hour: 20,
  minute: 0,
  isActive: active,
  nextTrigger: nextTrigger ?? _ahead,
);

ProviderContainer _container({
  List<RecurringReminder>? reminders,
  List<DetectedHabit> habits = const [],
}) {
  return ProviderContainer(
    overrides: [
      remindersProvider.overrideWith(
        (ref) => Stream.value(reminders ?? [_reminder()]),
      ),
      categoriesProvider.overrideWith((ref) => Stream.value(_categories)),
      detectedHabitsProvider.overrideWith((ref) => Stream.value(habits)),
      habitAnalysisProvider.overrideWith((ref) async {}),
    ],
  );
}

Future<void> _pump(WidgetTester tester, ProviderContainer container) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(AppColorScheme.roseDefault),
        home: const RemindersScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a tile shows the next firing and the suggested amount', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);

    await _pump(tester, container);

    expect(tester.takeException(), isNull);
    // The audit found the tile showing only the recurrence rule; the next
    // trigger and the amount were both in the model and both hidden.
    expect(find.text('${_nextLine(_ahead)} · ~300.000 ₫'), findsOneWidget);
    expect(find.text('Ghi ngay'), findsOneWidget);
  });

  testWidgets('a row whose trigger already passed shows the next firing', (
    tester,
  ) async {
    // Swiped-away notifications never advanced the row, and the tile read
    // "Lần tới" with a date already gone.
    final stale = DateTime(2026, 8, 5, 20);
    final container = _container(reminders: [_reminder(nextTrigger: stale)]);
    addTearDown(container.dispose);

    await _pump(tester, container);

    final next = RecurringReminder.calcNextTrigger(
      frequency: ReminderFrequency.monthly,
      hour: 20,
      minute: 0,
      dayOfMonth: 5,
    );
    expect(find.text('${_nextLine(next)} · ~300.000 ₫'), findsOneWidget);
    expect(find.textContaining('5/8'), findsNothing);
  });

  testWidgets('a switched-off reminder says so and drops Ghi ngay', (
    tester,
  ) async {
    final container = _container(reminders: [_reminder(active: false)]);
    addTearDown(container.dispose);

    await _pump(tester, container);

    expect(
      find.text('Đã tắt · Ngày 5 hàng tháng lúc 20:00'),
      findsOneWidget,
    );
    expect(find.text('Ghi ngay'), findsNothing);
  });

  testWidgets('habits and presets share one suggestion row', (tester) async {
    final container = _container(
      habits: [
        DetectedHabit(
          id: 'h1',
          keyword: 'xăng xe',
          categoryId: 'bills',
          medianGapDays: 7,
          // Past 80% of the median gap, which is what makes a habit "due" and
          // therefore worth suggesting.
          lastOccurrence: DateTime.now().subtract(const Duration(days: 6)),
          occurrenceCount: 5,
          isDismissed: false,
          analyzedAt: DateTime.now(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await _pump(tester, container);

    // The audit found two kinds of suggestion in two different shapes — a
    // card list and a chip strip — stacked above the list.
    expect(find.text('GỢI Ý'), findsOneWidget);
    // The habit read off the user's own history leads the row.
    expect(find.text('Xăng xe · mỗi 7 ngày'), findsOneWidget);
    // Presets follow it in the same strip. Only some are on screen at once,
    // so this asks the row for its contents rather than the viewport.
    final presetLabels = tester
        .widgetList<SpendoChip>(find.byType(SpendoChip, skipOffstage: false))
        .map((chip) => chip.label)
        .toSet();
    expect(presetLabels, contains('Dầu gội'));
    expect(presetLabels, contains('Tiền nước'));
    // "Tiền điện" already has a reminder, so it drops out of the presets —
    // the only "Tiền điện" left is the reminder's own tile.
    expect(find.text('Tiền điện'), findsOneWidget);
  });

  testWidgets('the screen answers to the name every entry point uses', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);

    await _pump(tester, container);

    expect(find.text('Nhắc nhở'), findsOneWidget);
    expect(find.text('Nhắc chi tiêu định kỳ'), findsNothing);
  });

  testWidgets('there is one way to add a reminder, not three', (tester) async {
    final container = _container();
    addTearDown(container.dispose);

    await _pump(tester, container);

    expect(find.text('Thêm nhắc nhở'), findsOneWidget);
  });

  testWidgets('a failed load offers a retry, not a raw exception', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        remindersProvider.overrideWith(
          (ref) => Stream<List<RecurringReminder>>.error(StateError('db down')),
        ),
        categoriesProvider.overrideWith((ref) => Stream.value(_categories)),
        detectedHabitsProvider.overrideWith(
          (ref) => Stream.value(const <DetectedHabit>[]),
        ),
        habitAnalysisProvider.overrideWith((ref) async {}),
      ],
    );
    addTearDown(container.dispose);

    await _pump(tester, container);

    expect(find.text('Không tải được nhắc nhở'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.textContaining('db down'), findsNothing);
  });
}
