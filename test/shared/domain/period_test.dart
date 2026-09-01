import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/shared/domain/period.dart';

void main() {
  final august = DateTime(2026, 8, 15);

  group('Period.month', () {
    test('spans the whole calendar month, end exclusive', () {
      final period = Period.month(DateTime(2026, 8));

      expect(period.start, DateTime(2026, 8, 1));
      expect(period.end, DateTime(2026, 9, 1));
      expect(period.lastDay, DateTime(2026, 8, 31));
      expect(period.daySpan, 31);
    });

    test('steps across a year boundary', () {
      expect(
        Period.month(DateTime(2026, 1)).previousMonth.start,
        DateTime(2025, 12, 1),
      );
      expect(
        Period.month(DateTime(2026, 12)).nextMonth.start,
        DateTime(2027, 1, 1),
      );
    });

    test('labels as Tháng M/YYYY, shortening within the current year', () {
      final period = Period.month(DateTime(2026, 8));

      expect(period.label, 'Tháng 8/2026');
      expect(period.shortLabel(august), 'Tháng 8');
      // A different year has to keep the year to stay unambiguous.
      expect(period.shortLabel(DateTime(2027, 3, 1)), 'Tháng 8/2026');
    });
  });

  group('Period.custom', () {
    test('treats both ends as inclusive days', () {
      final period = Period.custom(DateTime(2026, 8, 1), DateTime(2026, 8, 10));

      expect(period.start, DateTime(2026, 8, 1));
      // End is exclusive internally so the range query needs no adjustment.
      expect(period.end, DateTime(2026, 8, 11));
      expect(period.lastDay, DateTime(2026, 8, 10));
      expect(period.daySpan, 10);
    });

    test('labels a span, dropping the repeated year', () {
      expect(
        Period.custom(DateTime(2026, 8, 1), DateTime(2026, 9, 15)).label,
        '01/08 – 15/09/2026',
      );
      expect(
        Period.custom(DateTime(2025, 12, 20), DateTime(2026, 1, 5)).label,
        '20/12/2025 – 05/01/2026',
      );
    });
  });

  group('presets', () {
    test('thisMonth and lastMonth resolve to whole months', () {
      expect(
        PeriodPreset.thisMonth.resolve(august),
        Period.month(DateTime(2026, 8)),
      );
      expect(
        PeriodPreset.lastMonth.resolve(august),
        Period.month(DateTime(2026, 7)),
      );
    });

    test('lastThreeMonths covers June through August inclusive', () {
      final period = PeriodPreset.lastThreeMonths.resolve(august);

      expect(period.start, DateTime(2026, 6, 1));
      expect(period.end, DateTime(2026, 9, 1));
      expect(period.isMonth, isFalse);
    });

    test('thisYear runs from 1 January to today', () {
      final period = PeriodPreset.thisYear.resolve(august);

      expect(period.start, DateTime(2026, 1, 1));
      expect(period.lastDay, DateTime(2026, 8, 15));
    });

    test('a period matching a preset reports that preset', () {
      final period = PeriodPreset.lastThreeMonths.resolve(august);

      expect(period.matchingPreset(august), PeriodPreset.lastThreeMonths);
    });

    test('a preset resolved against today labels itself with its name', () {
      // `label` has no injected clock, so this is the real-now path the UI
      // takes: the picker shows "3 tháng gần nhất", not a raw date span.
      expect(PeriodPreset.lastThreeMonths.resolve().label, '3 tháng gần nhất');
      expect(PeriodPreset.thisYear.resolve().label, 'Năm nay');
    });

    test('an arbitrary span matches no preset', () {
      final period = Period.custom(DateTime(2026, 3, 7), DateTime(2026, 4, 2));

      expect(period.matchingPreset(august), isNull);
    });
  });

  test('isCurrentMonth is only true for the month containing now', () {
    expect(Period.month(DateTime(2026, 8)).isCurrentMonth(august), isTrue);
    expect(Period.month(DateTime(2026, 7)).isCurrentMonth(august), isFalse);
    // A custom span is never "the current month", even if it covers it.
    expect(
      PeriodPreset.thisYear.resolve(august).isCurrentMonth(august),
      isFalse,
    );
  });

  test('equality is by mode and bounds, so presets compare cleanly', () {
    expect(Period.month(DateTime(2026, 8)), Period.month(DateTime(2026, 8, 20)));
    expect(
      Period.month(DateTime(2026, 8)),
      isNot(Period.custom(DateTime(2026, 8, 1), DateTime(2026, 8, 31))),
    );
  });
}
