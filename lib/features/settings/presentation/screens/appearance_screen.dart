import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/spendo_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/visual_mode_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/motion/motion.dart';
import '../../../../shared/widgets/spendo/spendo.dart';

/// Screen 20 of the redesign — `/settings/appearance`.
///
/// Mode, accent colour and graphics mode used to be three ListTiles plus two
/// bottom sheets — two patterns for three options in the same group
/// (`27-visual-mode-and-theme-color-sheets.md` §L). One page now holds all
/// three, with a live preview so a colour can be judged before it is applied.
class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final scheme = ref.watch(themeProvider).colorScheme;
    final visualMode = ref.watch(visualModeProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SpendoScreenHeader(title: 'Giao diện'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  const _Label('CHẾ ĐỘ'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SpendoSegmented<ThemeMode>(
                      value: mode,
                      expand: true,
                      height: 36,
                      onChanged: (value) =>
                          ref.read(themeProvider.notifier).setMode(value),
                      options: const [
                        (value: ThemeMode.system, label: 'Hệ thống'),
                        (value: ThemeMode.light, label: 'Sáng'),
                        (value: ThemeMode.dark, label: 'Tối'),
                      ],
                    ),
                  ),
                  const _Label('MÀU CHỦ ĐẠO'),
                  _SchemeSwatches(
                    selected: scheme,
                    onSelected: (value) =>
                        ref.read(themeProvider.notifier).setColorScheme(value),
                  ),
                  const _Label('ĐỒ HOẠ'),
                  _VisualModeRow(
                    selected: visualMode,
                    onSelected: (value) =>
                        ref.read(visualModeProvider.notifier).setMode(value),
                  ),
                  const _Label('XEM TRƯỚC'),
                  const _Preview(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: SpendoSectionHeader(label: text, padding: EdgeInsets.zero),
    );
  }
}

// ── Accent colour ────────────────────────────────────────────────────────────

class _SchemeSwatches extends StatelessWidget {
  const _SchemeSwatches({required this.selected, required this.onSelected});

  final AppColorScheme selected;
  final ValueChanged<AppColorScheme> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final scheme in AppColorScheme.values)
            Padding(
              padding: EdgeInsets.only(
                right: scheme == AppColorScheme.values.last ? 0 : 14,
              ),
              child: Semantics(
                button: true,
                selected: scheme == selected,
                label: scheme.label,
                child: GestureDetector(
                  onTap: () => onSelected(scheme),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: scheme.brandColor,
                          shape: BoxShape.circle,
                          border: scheme == selected
                              ? Border.all(color: cs.surface, width: 2)
                              : null,
                          boxShadow: scheme == selected
                              ? [BoxShadow(color: cs.primary, spreadRadius: 2)]
                              : null,
                        ),
                        child: scheme == selected
                            ? Icon(
                                LucideIcons.check,
                                size: 20,
                                color: scheme.onBrandColor,
                              )
                            : null,
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 66,
                        child: Text(
                          scheme.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: scheme == selected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: scheme == selected
                                ? cs.onSurface
                                : cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Graphics mode ────────────────────────────────────────────────────────────

class _VisualModeRow extends StatelessWidget {
  const _VisualModeRow({required this.selected, required this.onSelected});

  final AppVisualMode selected;
  final ValueChanged<AppVisualMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      // The two cards carry subtitles of different lengths; IntrinsicHeight
      // levels them without asking a ListView child for infinite height.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _VisualModeCard(
                title: 'Bình thường',
                subtitle: 'Nhẹ, ổn định, tiết kiệm pin.',
                icon: LucideIcons.circle,
                selected: selected == AppVisualMode.normal,
                onTap: () => onSelected(AppVisualMode.normal),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _VisualModeCard(
                title: 'Xịn xò',
                subtitle: 'Aurora + liquid glass ở Home, Welcome, Cài đặt.',
                icon: LucideIcons.sparkles,
                selected: selected == AppVisualMode.fancy,
                onTap: () => onSelected(AppVisualMode.fancy),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisualModeCard extends StatelessWidget {
  const _VisualModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      child: PressableScale(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: AnimatedContainer(
          duration: appMotion.whenMotionAllowed(context, appMotion.listDuration),
          curve: appMotion.curveStandard,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: selected ? Border.all(color: cs.primary, width: 2) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: selected ? cs.primary : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: selected ? cs.onSurface : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.4,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Live preview ─────────────────────────────────────────────────────────────

/// A miniature of the Home header so a colour can be judged in place.
///
/// The old sheets applied a colour and closed, leaving the user to navigate
/// back to Home to see what they had picked.
class _Preview extends StatelessWidget {
  const _Preview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SpendoCard(
        feature: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Còn lại tháng này',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              formatVND(4250000),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            // Wraps rather than clips: the three samples together run past
            // 328dp of usable width on a 360dp screen.
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SpendoChip(
                  label: 'Tiền mặt',
                  leading: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: theme.spendo.income,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SpendoButton(label: 'Nút chính'),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: theme.spendo.brand,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.plus,
                    size: 16,
                    color: theme.spendo.onBrand,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
