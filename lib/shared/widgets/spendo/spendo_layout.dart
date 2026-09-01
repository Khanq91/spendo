import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/spendo_colors.dart';
import '../motion/motion.dart';
import 'spendo_button.dart';

/// Uppercase label that opens a section ("DỮ LIỆU", "GỢI Ý").
///
/// Replaces the three inline variants the audit found.
class SpendoSectionHeader extends StatelessWidget {
  const SpendoSectionHeader({
    super.key,
    required this.label,
    this.trailing,
    this.padding = const EdgeInsets.only(top: 20, bottom: 8),
  });

  final String label;

  /// Optional action on the right, e.g. "Xem tất cả".
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: cs.onSurfaceVariant,
      ),
    );

    return Padding(
      padding: padding,
      child: trailing == null
          ? text
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [text, trailing!],
            ),
    );
  }
}

/// Tonal container that carries the card radius and colour.
class SpendoCard extends StatelessWidget {
  const SpendoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.feature = false,
    this.color,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;

  /// Use the larger 20px radius reserved for hero cards.
  final bool feature;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(
      feature ? AppTheme.radiusCardFeature : AppTheme.radiusCard,
    );

    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? cs.surfaceContainerLow,
        borderRadius: radius,
      ),
      child: child,
    );

    if (onTap == null) return card;

    return PressableScale(
      deferTapToChild: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: card),
      ),
    );
  }
}

/// The single empty-state layout, replacing six inline ones.
class SpendoEmptyState extends StatelessWidget {
  const SpendoEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              SpendoButton.outline(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

/// Progress track whose fill turns amber at 85% and red once over budget.
class SpendoProgressBar extends StatelessWidget {
  const SpendoProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.color,
  });

  /// 0..1 — values above 1 mean "over the limit" and paint as error.
  final double value;
  final double height;

  /// Overrides the threshold colouring.
  final Color? color;

  /// The colour the fill takes for [value], per `02-components.md`.
  static Color colorFor(BuildContext context, double value) {
    final theme = Theme.of(context);
    if (value > 1) return theme.colorScheme.error;
    if (value >= 0.85) return theme.spendo.warning;
    return theme.colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedProgressBar(
      value: value,
      height: height,
      valueColor: color ?? colorFor(context, value),
    );
  }
}

/// Pill search field (screen 03).
class SpendoSearchBar extends StatelessWidget {
  const SpendoSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'Tìm ghi chú, số tiền…',
    this.onChanged,
    this.onClear,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: ShapeDecoration(
        color: cs.surfaceContainer,
        shape: const StadiumBorder(),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.search, size: 19, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: hintText,
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
          if (controller.text.isNotEmpty && onClear != null)
            GestureDetector(
              onTap: onClear,
              behavior: HitTestBehavior.opaque,
              child: Icon(LucideIcons.x, size: 18, color: cs.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}
