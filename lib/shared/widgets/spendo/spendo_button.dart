import 'package:flutter/material.dart';

import '../motion/motion.dart';

/// The three button shapes of the design system (`02-components.md`).
enum SpendoButtonVariant {
  /// Pill h48, filled with `primary`. The commit action of a screen.
  primary,

  /// Pill h48, filled with `secondaryContainer`. Sits next to a primary.
  secondary,

  /// Pill h40, 1.5px outline. Low-emphasis, e.g. "Thử lại".
  outline,
}

/// A button that already carries the token shape, height and text style, so
/// call sites never restate them.
class SpendoButton extends StatelessWidget {
  const SpendoButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = SpendoButtonVariant.primary,
    this.icon,
    this.expand = false,
    this.busy = false,
  });

  const SpendoButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expand = false,
    this.busy = false,
  }) : variant = SpendoButtonVariant.secondary;

  const SpendoButton.outline({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expand = false,
    this.busy = false,
  }) : variant = SpendoButtonVariant.outline;

  final String label;
  final VoidCallback? onPressed;
  final SpendoButtonVariant variant;
  final IconData? icon;

  /// Stretch to the width of the parent instead of hugging the label.
  final bool expand;

  /// Swap the label for a spinner and refuse taps.
  final bool busy;

  bool get _enabled => onPressed != null && !busy;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isOutline = variant == SpendoButtonVariant.outline;

    final (Color background, Color foreground) = switch (variant) {
      SpendoButtonVariant.primary => (cs.primary, cs.onPrimary),
      SpendoButtonVariant.secondary => (
        cs.secondaryContainer,
        cs.onSecondaryContainer,
      ),
      SpendoButtonVariant.outline => (Colors.transparent, cs.primary),
    };

    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: isOutline ? 16 : 18, color: foreground),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isOutline ? 13 : 14,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ),
        ],
      ],
    );

    return Opacity(
      opacity: _enabled ? 1 : 0.45,
      child: PressableScale(
        deferTapToChild: true,
        child: Material(
          color: background,
          shape: isOutline
              ? StadiumBorder(
                  side: BorderSide(color: cs.outlineVariant, width: 1.5),
                )
              : const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _enabled ? onPressed : null,
            child: Container(
              height: isOutline ? 40 : 48,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: isOutline ? 20 : 28),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
