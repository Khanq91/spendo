import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../domain/period.dart';
import 'period_picker_sheet.dart';

/// The 52px title row the pushed screens wear instead of an [AppBar].
///
/// The mockups put the screen name in the display font at 23px next to a plain
/// back arrow, with actions — or the period stepper — riding the same line.
/// An `AppBar` cannot give the title that size without restating the text
/// style at every call site, so the row is a widget of its own.
class SpendoScreenHeader extends StatelessWidget {
  const SpendoScreenHeader({
    super.key,
    required this.title,
    this.onBack,
    this.showBack = true,
    this.actions = const [],
  });

  final String title;

  /// Defaults to popping the route.
  final VoidCallback? onBack;

  /// False on a screen that is a shell tab rather than a pushed route — there
  /// is nothing to pop, so the arrow was a dead control on the Settings tab.
  final bool showBack;

  /// Trailing widgets — icon buttons, or a [SpendoPeriodStepper].
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 52,
      child: Row(
        children: [
          SizedBox(width: showBack ? 4 : 16),
          if (showBack)
            SpendoHeaderIconButton(
              icon: LucideIcons.arrowLeft,
              tooltip: 'Quay lại',
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            ),
          // The title yields to the actions: a period stepper needs its full
          // width to stay legible, while a long screen name can ellipsize.
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 23),
            ),
          ),
          const SizedBox(width: 8),
          ...actions,
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

/// 44×44 tap target for a header action, sized to the 48dp guidance once the
/// row's own padding is counted.
class SpendoHeaderIconButton extends StatelessWidget {
  const SpendoHeaderIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 20,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: size,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      padding: EdgeInsets.zero,
      icon: Icon(icon),
    );
  }
}

/// `‹ Tháng 8 ›` — steps a month at a time, and opens [PeriodPickerSheet] when
/// the label is tapped.
///
/// Both the wallet detail and the budget page carry it in their header row,
/// which is why it lives here rather than in either feature.
class SpendoPeriodStepper extends StatelessWidget {
  const SpendoPeriodStepper({
    super.key,
    required this.period,
    required this.onChanged,
    this.allowCustomRange = false,
    this.showArrows = true,
    this.maxLabelWidth = 110,
  });

  final Period period;
  final ValueChanged<Period> onChanged;
  final bool allowCustomRange;

  /// Drop the ‹ › arrows where the row is too tight for them — the label still
  /// opens the picker, which can reach every month the arrows could.
  final bool showArrows;

  final double maxLabelWidth;

  bool get _canStep => period.isMonth;

  Future<void> _pick(BuildContext context) async {
    final picked = await PeriodPickerSheet.show(
      context: context,
      selected: period,
      allowCustomRange: allowCustomRange,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Stepping past the current month would only ever show an empty period.
    final atCurrentMonth = period.isCurrentMonth();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showArrows)
          _StepArrow(
            icon: LucideIcons.chevronLeft,
            tooltip: 'Tháng trước',
            onPressed: _canStep ? () => onChanged(period.previousMonth) : null,
          ),
        // A custom range makes a long label ("01/08 – 15/09/2026"), and the
        // stepper shares its row with a segmented control on the wallet
        // screen — so the label scales down rather than pushing the arrows
        // off the edge. Row is mainAxisSize.min, where a Flexible child would
        // still take its full intrinsic width.
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxLabelWidth),
          child: GestureDetector(
            onTap: () => _pick(context),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  period.shortLabel(),
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (showArrows)
          _StepArrow(
            icon: LucideIcons.chevronRight,
            tooltip: 'Tháng sau',
            onPressed: _canStep && !atCurrentMonth
                ? () => onChanged(period.nextMonth)
                : null,
          )
        else
          Icon(LucideIcons.chevronDown, size: 17, color: cs.onSurfaceVariant),
      ],
    );
  }
}

class _StepArrow extends StatelessWidget {
  const _StepArrow({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: 20,
      constraints: const BoxConstraints.tightFor(width: 40, height: 44),
      padding: EdgeInsets.zero,
      icon: Icon(icon),
      color: cs.onSurfaceVariant,
      disabledColor: cs.outlineVariant,
    );
  }
}
