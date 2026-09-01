import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../motion/motion.dart';

/// The pill shapes that used to be re-implemented per screen
/// (`06-inconsistencies.md` counted seven variants).
enum SpendoChipKind {
  /// Filter row. Selected = primaryContainer, otherwise surfaceContainer.
  filter,

  /// Tappable hint, e.g. the note suggestions. Outlined by default.
  suggestion,

  /// Read-out of a chosen value (date · wallet · repeat) inside a sheet.
  meta,
}

class SpendoChip extends StatelessWidget {
  const SpendoChip({
    super.key,
    required this.label,
    this.onTap,
    this.kind = SpendoChipKind.filter,
    this.selected = false,
    this.icon,
    this.leading,
    this.onDeleted,
  });

  const SpendoChip.suggestion({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.leading,
  })  : kind = SpendoChipKind.suggestion,
        selected = false,
        onDeleted = null;

  const SpendoChip.meta({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.leading,
  })  : kind = SpendoChipKind.meta,
        selected = false,
        onDeleted = null;

  final String label;
  final VoidCallback? onTap;
  final SpendoChipKind kind;
  final bool selected;
  final IconData? icon;

  /// Arbitrary leading widget — used for the coloured dot on wallet chips.
  final Widget? leading;

  /// Shows a trailing ✕ that clears an applied filter.
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final (Color background, Color foreground, BorderSide side) = switch (kind) {
      SpendoChipKind.filter => selected
          ? (cs.primaryContainer, cs.onPrimaryContainer, BorderSide.none)
          : (cs.surfaceContainer, cs.onSurfaceVariant, BorderSide.none),
      SpendoChipKind.suggestion => (
        Colors.transparent,
        cs.onSurface,
        BorderSide(color: cs.outlineVariant),
      ),
      SpendoChipKind.meta => (
        cs.surfaceContainerLow,
        cs.onSurface,
        BorderSide.none,
      ),
    };

    final height = switch (kind) {
      SpendoChipKind.filter => 34.0,
      SpendoChipKind.suggestion => 34.0,
      SpendoChipKind.meta => 36.0,
    };

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 6)],
        if (icon != null) ...[
          Icon(icon, size: 15, color: foreground),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: kind == SpendoChipKind.filter ? 12.5 : 13,
            fontWeight: FontWeight.w600,
            color: foreground,
          ),
        ),
        if (onDeleted != null) ...[
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDeleted,
            child: Icon(LucideIcons.x, size: 14, color: foreground),
          ),
        ],
      ],
    );

    final chip = Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: background,
        shape: StadiumBorder(side: side),
      ),
      child: content,
    );

    if (onTap == null) return chip;

    return PressableScale(
      deferTapToChild: true,
      child: Material(
        color: Colors.transparent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: chip),
      ),
    );
  }
}

/// The `Chi | Thu` toggle: a pill track holding two options.
class SpendoSegmented<T> extends StatelessWidget {
  const SpendoSegmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.expand = false,
    this.height = 32,
    this.horizontalPadding = 18,
  });

  final List<({T value, String label})> options;
  final T value;
  final ValueChanged<T> onChanged;

  /// Fill the available width instead of hugging the labels.
  final bool expand;

  /// Option height. The default matches `02-components.md`; the transaction
  /// list packs three options into a shared row and runs shorter.
  final double height;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: ShapeDecoration(
        color: cs.surfaceContainer,
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: options.map((option) {
          final isSelected = option.value == value;
          final button = GestureDetector(
            onTap: isSelected ? null : () => onChanged(option.value),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: appMotion.whenMotionAllowed(
                context,
                appMotion.tapUpDuration,
              ),
              curve: appMotion.curveStandard,
              height: height,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              decoration: ShapeDecoration(
                color: isSelected ? cs.primaryContainer : Colors.transparent,
                shape: const StadiumBorder(),
              ),
              child: Text(
                option.label,
                style: TextStyle(
                  fontSize: height < 32 ? 12.5 : 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? cs.onPrimaryContainer
                      : cs.onSurfaceVariant,
                ),
              ),
            ),
          );
          return expand ? Expanded(child: button) : button;
        }).toList(),
      ),
    );
  }
}
