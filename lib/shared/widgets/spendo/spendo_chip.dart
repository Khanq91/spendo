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
    // Fill and label crossfade when `selected` flips (kinetics "Choice
    // Chips": 0.2s ease).
    final colorDuration = appMotion.whenMotionAllowed(
      context,
      const Duration(milliseconds: 200),
    );

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 6)],
        if (icon != null) ...[
          Icon(icon, size: 15, color: foreground),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: AnimatedDefaultTextStyle(
            duration: colorDuration,
            curve: Curves.ease,
            style: TextStyle(
              fontSize: kind == SpendoChipKind.meta ? 12.5 : 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: foreground,
            ),
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
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

    // No `alignment` here on purpose: a Container with an alignment and a
    // bounded parent (a Wrap, say) grows to the parent's full width before
    // centring its child, which put every chip on a row of its own. The Row
    // already centres its children vertically within [height].
    final chip = AnimatedContainer(
      duration: colorDuration,
      curve: Curves.ease,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: ShapeDecoration(color: background, shape: const StadiumBorder()),
      child: content,
    );

    if (onTap == null) return chip;

    return PressableScale(
      deferTapToChild: true,
      child: _ChipPop(
        // A meta chip reads out a value; only a choice earns the pop.
        pop: kind != SpendoChipKind.meta,
        onTap: onTap!,
        child: chip,
      ),
    );
  }
}

/// Tap feedback from kinetics "Choice Chips": the chip springs to 1.12 for
/// 300ms and settles back. The pop is the chip's own transient; the
/// selected state stays with the parent, so a group of chips is single- or
/// multi-select purely by what the parent does in `onTap`.
class _ChipPop extends StatefulWidget {
  const _ChipPop({
    required this.pop,
    required this.onTap,
    required this.child,
  });

  final bool pop;
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_ChipPop> createState() => _ChipPopState();
}

class _ChipPopState extends State<_ChipPop>
    with SingleTickerProviderStateMixin {
  static const _spring = Cubic(0.34, 1.56, 0.64, 1);
  static const _popDuration = Duration(milliseconds: 300);

  // Holds the popped state for the original's 300ms setTimeout; a controller
  // rather than a Timer so nothing outlives the widget in tests. Created
  // eagerly: a lazy `late` would first be built inside dispose() for a chip
  // that was never tapped, when the ticker can no longer find its TickerMode.
  late final AnimationController _hold;
  bool _popped = false;

  @override
  void initState() {
    super.initState();
    _hold = AnimationController(vsync: this, duration: _popDuration)
      ..addStatusListener(_onHoldStatus);
  }

  void _onHoldStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _popped = false);
    }
  }

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  void _tap() {
    if (widget.pop && !MotionSpec.shouldReduceMotion(context)) {
      setState(() => _popped = true);
      _hold.forward(from: 0);
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    // The scale sits outside the clipping Material so the overshoot can draw
    // past the pill's bounds, as the original does.
    return AnimatedScale(
      scale: _popped ? 1.12 : 1,
      duration: appMotion.whenMotionAllowed(context, _popDuration),
      curve: _spring,
      child: Material(
        color: Colors.transparent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: _tap, child: widget.child),
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
