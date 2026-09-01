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

/// The four-tab bar: 80px tall, brand pill behind the active icon.
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      color: cs.surfaceContainer,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 80,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
          ),
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
    final duration = appMotion.whenMotionAllowed(
      context,
      appMotion.tapUpDuration,
    );

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
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: duration,
              curve: appMotion.curveStandard,
              width: 56,
              height: 32,
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: selected ? spendo.brand : Colors.transparent,
                shape: const StadiumBorder(),
              ),
              child: Icon(
                destination.icon,
                size: 20,
                color: selected ? spendo.onBrand : cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? cs.onSurface : cs.onSurfaceVariant,
                height: 1.1,
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
