import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/visual_mode_provider.dart';

class VisualModePicker extends StatelessWidget {
  const VisualModePicker({
    super.key,
    required this.selectedMode,
    required this.onChanged,
    this.useGlass = false,
  });

  final AppVisualMode selectedMode;
  final ValueChanged<AppVisualMode> onChanged;
  final bool useGlass;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _VisualModeTile(
          selected: selectedMode == AppVisualMode.normal,
          title: 'Bình thường',
          subtitle: 'Giao diện nhẹ, ổn định và tiết kiệm tài nguyên.',
          icon: LucideIcons.circle,
          useGlass: useGlass,
          onTap: () => onChanged(AppVisualMode.normal),
        ),
        const SizedBox(height: 12),
        _VisualModeTile(
          selected: selectedMode == AppVisualMode.fancy,
          title: 'Xịn xò',
          subtitle: 'Nền aurora, điều hướng liquid glass và hiệu ứng mềm hơn.',
          icon: LucideIcons.sparkles,
          useGlass: useGlass,
          onTap: () => onChanged(AppVisualMode.fancy),
        ),
      ],
    );
  }
}

class _VisualModeTile extends StatelessWidget {
  const _VisualModeTile({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.useGlass,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool useGlass;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final foreground = selected ? cs.primary : cs.onSurface;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: foreground, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            selected ? LucideIcons.circleCheck : LucideIcons.circle,
            color: selected ? cs.primary : cs.outline,
            size: 20,
          ),
        ],
      ),
    );

    if (useGlass) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: GlassContainer(
          width: double.infinity,
          padding: EdgeInsets.zero,
          useOwnLayer: true,
          quality: GlassQuality.premium,
          shape: const LiquidRoundedSuperellipse(borderRadius: 22),
          child: content,
        ),
      );
    }

    return Material(
      color: selected ? cs.primaryContainer.withValues(alpha: 0.5) : cs.surface,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}
