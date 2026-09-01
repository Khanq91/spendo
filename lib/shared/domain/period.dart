/// The time span a screen is showing.
///
/// Home, Giao dịch, Thống kê and Hạn mức all ask the same question — "which
/// period?" — so they share one model and one picker (`PeriodPickerSheet`,
/// screen 24) instead of the month grid and the range sheet the audit found.
library;

enum PeriodMode {
  /// A whole calendar month. The common case, and the only one the month
  /// stepper can walk through.
  month,

  /// Any other span, from a preset ("3 tháng gần nhất") or a custom range.
  custom,
}

/// One of the quick spans offered under the month grid.
enum PeriodPreset {
  thisMonth,
  lastMonth,
  lastThreeMonths,
  thisYear;

  String get label => switch (this) {
    PeriodPreset.thisMonth => 'Tháng này',
    PeriodPreset.lastMonth => 'Tháng trước',
    PeriodPreset.lastThreeMonths => '3 tháng gần nhất',
    PeriodPreset.thisYear => 'Năm nay',
  };

  /// Resolves against [now] so the presets follow the calendar.
  Period resolve([DateTime? now]) {
    final today = now ?? DateTime.now();
    return switch (this) {
      PeriodPreset.thisMonth => Period.month(
        DateTime(today.year, today.month),
      ),
      PeriodPreset.lastMonth => Period.month(
        DateTime(today.year, today.month - 1),
      ),
      PeriodPreset.lastThreeMonths => Period(
        mode: PeriodMode.custom,
        start: DateTime(today.year, today.month - 2),
        end: DateTime(today.year, today.month + 1),
      ),
      PeriodPreset.thisYear => Period(
        mode: PeriodMode.custom,
        start: DateTime(today.year),
        end: DateTime(today.year, today.month, today.day + 1),
      ),
    };
  }
}

/// A half-open span: `start` inclusive, `end` exclusive.
///
/// Half-open keeps the range queries simple — `created_at >= start AND
/// created_at < end` — with no end-of-day arithmetic at each call site.
class Period {
  const Period({
    required this.mode,
    required this.start,
    required this.end,
  });

  /// The calendar month containing [month].
  factory Period.month(DateTime month) => Period(
    mode: PeriodMode.month,
    start: DateTime(month.year, month.month),
    end: DateTime(month.year, month.month + 1),
  );

  /// A span between two days, both of which the user picked as inclusive.
  factory Period.custom(DateTime start, DateTime end) => Period(
    mode: PeriodMode.custom,
    start: DateTime(start.year, start.month, start.day),
    end: DateTime(end.year, end.month, end.day + 1),
  );

  final PeriodMode mode;
  final DateTime start;

  /// Exclusive — the first instant *after* the period.
  final DateTime end;

  bool get isMonth => mode == PeriodMode.month;

  int get daySpan => end.difference(start).inDays;

  /// The last day inside the period, for display.
  DateTime get lastDay => end.subtract(const Duration(days: 1));

  /// True when this is the calendar month containing [now].
  bool isCurrentMonth([DateTime? now]) {
    if (!isMonth) return false;
    final today = now ?? DateTime.now();
    return start.year == today.year && start.month == today.month;
  }

  /// The month before / after this one. Only meaningful for [PeriodMode.month].
  Period get previousMonth => Period.month(DateTime(start.year, start.month - 1));
  Period get nextMonth => Period.month(DateTime(start.year, start.month + 1));

  /// The preset this period equals, or null for an arbitrary span.
  PeriodPreset? matchingPreset([DateTime? now]) {
    for (final preset in PeriodPreset.values) {
      final resolved = preset.resolve(now);
      if (resolved.start == start && resolved.end == end) return preset;
    }
    return null;
  }

  /// Full label: `Tháng 8/2026` or `01/08 – 15/09/2026`.
  String get label {
    if (isMonth) return 'Tháng ${start.month}/${start.year}';

    String dayMonth(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

    final preset = matchingPreset();
    if (preset != null) return preset.label;

    if (start.year == lastDay.year) {
      return '${dayMonth(start)} – ${dayMonth(lastDay)}/${lastDay.year}';
    }
    return '${dayMonth(start)}/${start.year} – ${dayMonth(lastDay)}/${lastDay.year}';
  }

  /// Compact label for a tight header: `Tháng 8` when the year is the current
  /// one, the full label otherwise.
  String shortLabel([DateTime? now]) {
    final today = now ?? DateTime.now();
    if (isMonth && start.year == today.year) return 'Tháng ${start.month}';
    return label;
  }

  @override
  bool operator ==(Object other) =>
      other is Period &&
      other.mode == mode &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(mode, start, end);

  @override
  String toString() => 'Period($label)';
}
