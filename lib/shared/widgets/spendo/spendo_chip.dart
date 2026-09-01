import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../motion/motion.dart';

/// The pill shapes that used to be re-implemented per screen
/// (`06-inconsistencies.md` counted seven variants).
/// Every chip is a filled pill: an outline-only variant reads as absent on the
/// dark surfaces, and mixing the two made the same affordance look like two
/// different controls across screens.
enum SpendoChipKind {
  /// Something to pick — a filter, a note suggestion, a period preset.
  /// Selected = primaryContainer, otherwise surfaceContainer.
  filter,

  /// Alias of [filter], kept so call sites can say what they mean.
  suggestion,

  /// Read-out of a chosen value (date · wallet · repeat) inside a sheet.
  /// Sits one step lower so it reads as a value, not a choice.
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

    final (Color background, Color foreground) = switch (kind) {
      SpendoChipKind.filter || SpendoChipKind.suggestion => selected
          ? (cs.primaryContainer, cs.onPrimaryContainer)
          : (cs.surfaceContainer, cs.onSurface),
      SpendoChipKind.meta => (cs.surfaceContainerLow, cs.onSurface),
    };

    final height = kind == SpendoChipKind.meta ? 36.0 : 34.0;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 6)],
        if (icon != null) ...[
          Icon(icon, size: 15, color: foreground),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: kind == SpendoChipKind.meta ? 12.5 : 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: foreground,
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: ShapeDecoration(color: background, shape: const StadiumBorder()),
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
