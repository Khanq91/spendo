import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/spendo_colors.dart';
import '../motion/motion.dart';

/// One destination of [SpendoBottomNav].
class SpendoNavDestination {
  const SpendoNavDestination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// The four-tab bar as a floating snap rail (kinetics "Snap Rail"): a pill
/// hovers above the bottom edge, and a translucent brand pill springs between
/// its four EQUAL cells — always one cell wide, never sized to the label.
///
/// Meant for a `Scaffold` with `extendBody: true`, so content scrolls under
/// the gap around the rail; the Scaffold reports this widget's full height
/// (margins included) as the body's bottom padding.
class SpendoBottomNav extends StatelessWidget {
  const SpendoBottomNav({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<SpendoNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// The shell's four tabs, in the order fixed by the handoff.
  static const spendoDestinations = [
    SpendoNavDestination(icon: LucideIcons.house, label: 'Trang chủ'),
    SpendoNavDestination(icon: LucideIcons.notebookText, label: 'Giao dịch'),
    SpendoNavDestination(icon: LucideIcons.chartPie, label: 'Thống kê'),
    SpendoNavDestination(icon: LucideIcons.settings, label: 'Cài đặt'),
  ];

  /// Key of the sliding pill, for tests.
  static const pillKey = Key('spendo_nav_pill');

  static const double railHeight = 64;
  static const double sideMargin = 16;
  static const double bottomGap = 12;
  static const double _inset = 4;

  /// Overshooting bezier the original rail snaps with.
  static const Curve _spring = Cubic(0.34, 1.56, 0.64, 1);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final spendo = theme.spendo;
    final isDark = theme.brightness == Brightness.dark;
    final snapDuration = appMotion.whenMotionAllowed(
      context,
      const Duration(milliseconds: 450),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        sideMargin,
        0,
        sideMargin,
        MediaQuery.paddingOf(context).bottom + bottomGap,
      ),
      child: Container(
        height: railHeight,
        padding: const EdgeInsets.all(_inset),
        decoration: ShapeDecoration(
          color: cs.surfaceContainer,
          shape: StadiumBorder(side: BorderSide(color: cs.outlineVariant)),
          // Same rule as SpendoFab: a shadow lifts the rail off the light
          // surface but only muddies the dark one.
          shadows: isDark
              ? null
              : [
                  BoxShadow(
                    color: cs.shadow.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cellWidth = constraints.maxWidth / destinations.length;
            return Stack(
              children: [
                AnimatedPositioned(
                  key: pillKey,
                  duration: snapDuration,
                  curve: _spring,
                  left: selectedIndex * cellWidth,
                  top: 0,
                  bottom: 0,
                  width: cellWidth,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: spendo.brand.withValues(alpha: 0.16),
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: spendo.brand.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < destinations.length; i++)
                      Expanded(
                        child: _NavTab(
                          key: ValueKey('spendo_tab_$i'),
                          destination: destinations[i],
                          selected: i == selectedIndex,
                          onTap: () => onSelected(i),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    super.key,
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final SpendoNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final spendo = theme.spendo;
    // The label tints to the accent over 0.25s ease, as in the original.
    final tintDuration = appMotion.whenMotionAllowed(
      context,
      const Duration(milliseconds: 250),
    );
    final color = selected ? spendo.brand : cs.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(destination.icon, size: 20, color: color),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: tintDuration,
              curve: Curves.ease,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: color,
                height: 1.1,
              ),
              child: Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 56px brand FAB with the plus glyph.
class SpendoFab extends StatelessWidget {
  const SpendoFab({
    super.key,
    required this.onPressed,
    this.icon = LucideIcons.plus,
    this.heroTag = 'spendo_fab',
  });

  final VoidCallback onPressed;
  final IconData icon;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spendo = theme.spendo;
    final isDark = theme.brightness == Brightness.dark;

    return PressableScale(
      deferTapToChild: true,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: spendo.onBrand.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: FloatingActionButton(
          heroTag: heroTag,
          onPressed: onPressed,
          backgroundColor: spendo.brand,
          foregroundColor: spendo.onBrand,
          elevation: 0,
          focusElevation: 0,
          hoverElevation: 0,
          highlightElevation: 0,
          shape: const CircleBorder(),
          child: Icon(icon, size: 26),
        ),
      ),
    );
  }
}

/// Pill-shaped extended FAB ("+ Thêm nguồn tiền") used on the list screens.
class SpendoExtendedFab extends StatelessWidget {
  const SpendoExtendedFab({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = LucideIcons.plus,
    this.heroTag,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData icon;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PressableScale(
      deferTapToChild: true,
      child: FloatingActionButton.extended(
        heroTag: heroTag,
        onPressed: onPressed,
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 2,
        shape: const StadiumBorder(),
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
