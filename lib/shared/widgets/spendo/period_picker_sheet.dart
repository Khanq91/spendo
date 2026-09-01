import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../domain/period.dart';
import '../motion/motion.dart';
import 'spendo_chip.dart';
import 'spendo_sheet.dart';

/// Screen 24 — the one period picker, shared by Home, Giao dịch, Thống kê and
/// Hạn mức.
///
/// Replaces the month grid (`MonthPickerSheet`) and the preset list
/// (`DateRangePickerSheet`), which asked the same question in two unrelated
/// layouts. The grid picks a month; the pills below reach the spans a grid
/// cannot express.
class PeriodPickerSheet extends StatefulWidget {
  const PeriodPickerSheet({
    super.key,
    required this.selected,
    this.allowCustomRange = true,
    this.yearsBack = 3,
  });

  final Period selected;

  /// Screens that only make sense a month at a time (Home, Hạn mức) hide both
  /// the custom range and the presets that span several months, so every
  /// option the sheet offers is one that screen can actually honour.
  final bool allowCustomRange;

  /// How far back the year stepper reaches.
  final int yearsBack;

  /// Opens the picker and returns the chosen period, or null if dismissed.
  static Future<Period?> show({
    required BuildContext context,
    required Period selected,
    bool allowCustomRange = true,
  }) {
    return SpendoSheet.showModal<Period>(
      context: context,
      builder: (_) => PeriodPickerSheet(
        selected: selected,
        allowCustomRange: allowCustomRange,
      ),
    );
  }

  @override
  State<PeriodPickerSheet> createState() => _PeriodPickerSheetState();
}

class _PeriodPickerSheetState extends State<PeriodPickerSheet> {
  late int _year = widget.selected.start.year;

  static const _monthLabels = [
    'Th.1', 'Th.2', 'Th.3', 'Th.4', //
    'Th.5', 'Th.6', 'Th.7', 'Th.8',
    'Th.9', 'Th.10', 'Th.11', 'Th.12',
  ];

  DateTime get _now => DateTime.now();

  bool _isFuture(int month) {
    final now = _now;
    return _year > now.year || (_year == now.year && month > now.month);
  }

  Future<void> _pickCustomRange() async {
    final now = _now;
    final initial = widget.selected.isMonth
        ? null
        : DateTimeRange(
            start: widget.selected.start,
            end: widget.selected.lastDay,
          );

    final range = await showDateRangePicker(
      context: context,
      initialDateRange: initial,
      firstDate: DateTime(now.year - widget.yearsBack),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (range == null || !mounted) return;
    Navigator.of(context).pop(Period.custom(range.start, range.end));
  }

  @override
  Widget build(BuildContext context) {
    final now = _now;
    final minYear = now.year - widget.yearsBack;
    final selectedPreset = widget.selected.matchingPreset(now);

    return SpendoSheet(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _YearStepper(
            year: _year,
            canGoBack: _year > minYear,
            canGoForward: _year < now.year,
            onChanged: (year) => setState(() => _year = year),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: 12,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisExtent: 40,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (_, i) {
              final month = i + 1;
              final period = Period.month(DateTime(_year, month));
              return _MonthCell(
                label: _monthLabels[i],
                selected: period == widget.selected,
                disabled: _isFuture(month),
                onTap: () => Navigator.of(context).pop(period),
              );
            },
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in PeriodPreset.values)
                if (widget.allowCustomRange ||
                    preset.resolve(now).isMonth)
                  SpendoChip(
                    label: preset.label,
                    selected: preset == selectedPreset,
                    onTap: () => Navigator.of(context).pop(preset.resolve(now)),
                  ),
              if (widget.allowCustomRange)
                SpendoChip.suggestion(
                  key: const ValueKey('period_custom_range'),
                  label: 'Tuỳ chọn…',
                  icon: LucideIcons.calendar,
                  onTap: _pickCustomRange,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _YearStepper extends StatelessWidget {
  const _YearStepper({
    required this.year,
    required this.canGoBack,
    required this.canGoForward,
    required this.onChanged,
  });

  final int year;
  final bool canGoBack;
  final bool canGoForward;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(LucideIcons.chevronLeft, size: 22),
          tooltip: 'Năm trước',
          onPressed: canGoBack ? () => onChanged(year - 1) : null,
          color: cs.onSurfaceVariant,
          disabledColor: cs.outlineVariant,
        ),
        const SizedBox(width: 8),
        Text(
          '$year',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(LucideIcons.chevronRight, size: 22),
          tooltip: 'Năm sau',
          onPressed: canGoForward ? () => onChanged(year + 1) : null,
          color: cs.onSurfaceVariant,
          disabledColor: cs.outlineVariant,
        ),
      ],
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.label,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final foreground = disabled
        ? cs.outlineVariant
        : selected
        ? cs.onPrimary
        : cs.onSurface;

    final cell = AnimatedContainer(
      duration: appMotion.whenMotionAllowed(context, appMotion.tapUpDuration),
      curve: appMotion.curveStandard,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? cs.primary : cs.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusInput),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          color: foreground,
        ),
      ),
    );

    if (disabled) return cell;

    return PressableScale(
      deferTapToChild: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: cell,
      ),
    );
  }
}
