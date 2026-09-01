import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/spendo_colors.dart';
import '../../../core/utils/category_icons.dart';
import '../motion/motion.dart';

/// The round icon badge used for categories and wallets.
///
/// Background is the owner colour at low alpha (lifted in dark mode, per
/// `01-tokens.md`), stroke is the colour itself.
class SpendoIconTile extends StatelessWidget {
  const SpendoIconTile({
    super.key,
    required this.icon,
    required this.color,
    this.size = 40,
    this.selected = false,
  });

  /// Builds the tile from a category's stored icon name.
  SpendoIconTile.category({
    super.key,
    required String? iconName,
    required this.color,
    this.size = 40,
    this.selected = false,
  }) : icon = categoryIcon(iconName ?? '');

  final IconData icon;
  final Color color;
  final double size;

  /// Selected tiles switch to primaryContainer and gain a ring.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: selected
            ? cs.primaryContainer
            : color.withValues(alpha: isDark ? 0.24 : 0.16),
        shape: BoxShape.circle,
        border: selected
            ? Border.all(color: cs.primary, width: 2)
            : null,
      ),
      child: Icon(
        icon,
        size: size * 0.45,
        color: selected ? cs.onPrimaryContainer : color,
      ),
    );
  }
}

/// A cell of the category picker grid: circle + label underneath.
class SpendoCategoryTile extends StatelessWidget {
  const SpendoCategoryTile({
    super.key,
    required this.label,
    required this.color,
    this.iconName,
    this.icon,
    this.selected = false,
    this.onTap,
  });

  /// The dashed "Thêm" cell that ends the grid.
  const SpendoCategoryTile.add({super.key, this.onTap})
      : label = 'Thêm',
        color = Colors.transparent,
        iconName = null,
        icon = null,
        selected = false;

  final String label;
  final Color color;
  final String? iconName;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  bool get _isAdd => iconName == null && icon == null;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PressableScale(
      deferTapToChild: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isAdd)
              _DashedCircle(
                size: 46,
                color: context.spendo.dashedOutline,
                child: Icon(
                  LucideIcons.plus,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
              )
            else
              SpendoIconTile(
                icon: icon ?? categoryIcon(iconName ?? ''),
                color: color,
                size: 46,
                selected: selected,
              ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? cs.onSurface : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rounded rectangle drawn with the dashed "add" outline.
///
/// The dashed affordance appears both as a circle (the "Thêm" category cell)
/// and as a box (the Home budget CTA, the empty wallet slot); both walk the
/// same 5px dash / 4px gap rhythm.
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({
    super.key,
    required this.child,
    required this.color,
    this.radius = 16,
    this.strokeWidth = 1.5,
  });

  final Widget child;
  final Color color;
  final double radius;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(
        color: color,
        radius: radius,
        strokeWidth: strokeWidth,
      ),
      child: child,
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  const _DashedRectPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  final Color color;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final inset = strokeWidth / 2;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            inset,
            inset,
            size.width - strokeWidth,
            size.height - strokeWidth,
          ),
          Radius.circular(radius),
        ),
      );

    const dash = 5.0;
    const gap = 4.0;
    for (final metric in outline.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = distance + dash;
        canvas.drawPath(
          metric.extractPath(
            distance,
            end > metric.length ? metric.length : end,
          ),
          paint,
        );
        distance = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth;
}

class _DashedCircle extends StatelessWidget {
  const _DashedCircle({
    required this.size,
    required this.color,
    required this.child,
  });

  final double size;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedCirclePainter(color: color),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(child: child),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final radius = size.width / 2;
    final center = Offset(radius, radius);
    // 5px dash, 4px gap, walked around the circumference.
    const dash = 5 / 20;
    const gap = 4 / 20;
    for (double a = 0; a < 6.283; a += dash + gap) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 0.75),
        a,
        dash,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter old) => old.color != color;
}

/// One row of a transaction list: icon, name + meta, signed amount.
class SpendoTransactionRow extends StatelessWidget {
  const SpendoTransactionRow({
    super.key,
    required this.title,
    required this.amountText,
    required this.isIncome,
    this.subtitle,
    this.iconName,
    this.color,
    this.badge,
    this.onTap,
  });

  final String title;

  /// Already formatted, including the sign and the ₫ suffix.
  final String amountText;
  final bool isIncome;
  final String? subtitle;
  final String? iconName;
  final Color? color;

  /// Trailing marker, e.g. the "Tự động · SePay" badge.
  final Widget? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final amountColor = isIncome ? theme.spendo.income : theme.spendo.expense;

    final row = Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SpendoIconTile.category(
            iconName: iconName,
            color: color ?? cs.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // The badge rides beside the title rather than on the
                    // trailing edge, so it can never squeeze the amount — a
                    // ten-digit total plus a badge does not fit a 360dp row.
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      badge!,
                    ],
                  ],
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // The amount leads, but a ten-digit total on a 360dp row would
          // leave the name no width at all — so it scales down rather than
          // overflowing, and the name keeps at least its ellipsis.
          Flexible(
            flex: 0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  amountText,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: amountColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return row;

    return PressableScale(
      deferTapToChild: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, child: row),
      ),
    );
  }
}

/// Date group header above a run of [SpendoTransactionRow]s.
class SpendoDayHeader extends StatelessWidget {
  const SpendoDayHeader({
    super.key,
    required this.label,
    required this.totalText,
    required this.totalIsIncome,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 6),
  });

  final String label;
  final String totalText;
  final bool totalIsIncome;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding,
      child: Row(
        children: [
          // The date label gives way first; the day's total must stay whole.
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            totalText,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: totalIsIncome
                  ? theme.spendo.income
                  : theme.spendo.expense,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Settings-style grouped card: rows with an icon tile and a chevron.
class SpendoSettingsGroup extends StatelessWidget {
  const SpendoSettingsGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusCardFeature),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.only(left: 66),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: cs.surfaceContainerHighest,
                ),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// A single row inside a [SpendoSettingsGroup].
class SpendoSettingsRow extends StatelessWidget {
  const SpendoSettingsRow({
    super.key,
    required this.icon,
    required this.label,
    this.trailingText,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;

  /// Muted value shown before the chevron ("12", "Drive · 2 giờ trước").
  final String? trailingText;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 49),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: cs.onSecondaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (trailingText != null)
                Text(
                  trailingText!,
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
              if (trailing != null) trailing!,
              if (onTap != null) ...[
                const SizedBox(width: 6),
                Icon(
                  LucideIcons.chevronRight,
                  size: 17,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
