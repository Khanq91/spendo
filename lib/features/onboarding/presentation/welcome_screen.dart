import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/spendo_colors.dart';
import '../../../core/theme/visual_mode_provider.dart';
import '../../../shared/widgets/notice/notice.dart';
import '../../../shared/widgets/aurora_theme_background.dart';
import '../../../shared/widgets/motion/motion.dart';
import '../../../shared/widgets/spendo/spendo.dart';
import '../../settings/presentation/providers/gdrive_provider.dart';
import 'onboarding_prefs.dart';

/// Screen 19 of the redesign.
///
/// Trimmed from three pages to two: the old first page carried one sentence
/// with the bottom half of the screen empty, and graphics mode and Drive each
/// had a page to themselves (`03-welcome.md` §L). Page 1 now says what the app
/// does, page 2 folds both settings together, and every page has dots plus a
/// way out — the old build offered "Bỏ qua" on the last page only.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key, this.destinationBuilder});

  /// What to show once onboarding is done. Defaults to the app itself;
  /// injectable so a test can assert what was saved without mounting the
  /// real destination and everything it initialises.
  final WidgetBuilder? destinationBuilder;

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  static const _pageCount = 2;

  final _pageController = PageController();
  AppVisualMode _selectedMode = AppVisualMode.normal;
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goNext() async {
    if (_page == _pageCount - 1) {
      await _finish();
      return;
    }
    await _pageController.nextPage(
      duration: appMotion.whenMotionAllowed(context, appMotion.listDuration),
      curve: appMotion.curveStandard,
    );
  }

  Future<void> _finish() async {
    // The graphics choice lives on page 2, so it is saved on the way out
    // whichever button ends the flow.
    await ref.read(visualModeProvider.notifier).setMode(_selectedMode);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(onboardingCompletedPrefsKey, true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder:
            widget.destinationBuilder ?? (_) => const SpendoApp(),
      ),
    );
  }

  Future<void> _signInGoogle() async {
    await ref.read(gdriveProvider.notifier).signIn();
    if (!mounted) return;

    final state = ref.read(gdriveProvider);
    if (state.isSignedIn) {
      AppNotice.success('Đã kết nối Google Drive.');
    } else {
      AppNotice.error(state.error ?? 'Đăng nhập Google thất bại.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          const Positioned.fill(child: AuroraThemeBackground()),
          SafeArea(
            child: Stack(
              children: [
                PageView(
                  controller: _pageController,
                  onPageChanged: (value) => setState(() => _page = value),
                  children: [
                    const _IntroPage(),
                    _SetupPage(
                      selectedMode: _selectedMode,
                      onModeChanged: (mode) =>
                          setState(() => _selectedMode = mode),
                      onSignIn: _signInGoogle,
                    ),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 80,
                  child: _Dots(count: _pageCount, index: _page),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 24,
                  // Flexible on both sides: on a 360dp screen the two
                  // labels plus the arrow run just past the available width.
                  child: Row(
                    children: [
                      // On every page now, not just the last one.
                      Flexible(
                        child: TextButton(
                          onPressed: _finish,
                          child: const Text(
                            'Bỏ qua',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Flexible(
                        child: SpendoButton(
                          label: _page == _pageCount - 1
                              ? 'Bắt đầu'
                              : 'Tiếp theo',
                          icon: LucideIcons.arrowRight,
                          onPressed: _goNext,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page 1 ───────────────────────────────────────────────────────────────────

class _IntroPage extends StatelessWidget {
  const _IntroPage();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 130),
      children: const [
        _BrandCard(description: 'Quản lý thu chi cá nhân gọn gàng và rõ ràng.'),
        SizedBox(height: 24),
        // The old page 0 introduced no feature at all; these three are what
        // the app is actually for.
        _FeatureRow(
          icon: LucideIcons.zap,
          title: 'Ghi trong 5 giây',
          body: 'numpad VND, gợi ý danh mục thông minh.',
        ),
        SizedBox(height: 16),
        _FeatureRow(
          icon: LucideIcons.chartPie,
          title: 'Hạn mức & nhắc nhở',
          body: 'biết còn bao nhiêu trước khi chi.',
        ),
        SizedBox(height: 16),
        _FeatureRow(
          icon: LucideIcons.shieldCheck,
          title: 'Dữ liệu của bạn',
          body: 'offline trước, sao lưu Google Drive khi cần.',
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SpendoIconTile(icon: icon, color: theme.spendo.income, size: 44),
        const SizedBox(width: 14),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: ' — $body',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 14.5, height: 1.4),
          ),
        ),
      ],
    );
  }
}

// ── Page 2 ───────────────────────────────────────────────────────────────────

class _SetupPage extends ConsumerWidget {
  const _SetupPage({
    required this.selectedMode,
    required this.onModeChanged,
    required this.onSignIn,
  });

  final AppVisualMode selectedMode;
  final ValueChanged<AppVisualMode> onModeChanged;
  final Future<void> Function() onSignIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final drive = ref.watch(gdriveProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 130),
      children: [
        const _BrandCard(
          description:
              'Hai lựa chọn nhanh, đổi lại bất cứ lúc nào trong '
              'Cài đặt › Giao diện.',
        ),
        const SizedBox(height: 24),
        const SpendoSectionHeader(label: 'Đồ hoạ', padding: EdgeInsets.zero),
        const SizedBox(height: 8),
        _ModeCard(
          title: 'Bình thường',
          body: 'Nhẹ, ổn định, tiết kiệm pin.',
          icon: LucideIcons.circle,
          selected: selectedMode == AppVisualMode.normal,
          onTap: () => onModeChanged(AppVisualMode.normal),
        ),
        const SizedBox(height: 10),
        _ModeCard(
          title: 'Xịn xò',
          body: 'Nền aurora và hiệu ứng mềm hơn.',
          icon: LucideIcons.sparkles,
          selected: selectedMode == AppVisualMode.fancy,
          onTap: () => onModeChanged(AppVisualMode.fancy),
        ),
        const SizedBox(height: 24),
        const SpendoSectionHeader(
          label: 'Sao lưu (tuỳ chọn)',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 8),
        SpendoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                drive.isSignedIn
                    ? 'Đã kết nối ${drive.email ?? "Google Drive"}.'
                    : 'Spendo chạy offline. Kết nối Drive nếu bạn muốn có bản '
                          'sao lưu.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              SpendoButton.outline(
                label: drive.isSignedIn ? 'Đã kết nối' : 'Đăng nhập Google',
                icon: drive.isSignedIn
                    ? LucideIcons.cloudCheck
                    : LucideIcons.cloud,
                expand: true,
                busy: drive.isLoading,
                onPressed: drive.isSignedIn ? null : onSignIn,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.body,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String body;
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: selected ? Border.all(color: cs.primary, width: 2) : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? cs.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? LucideIcons.circleCheck : LucideIcons.circle,
                size: 20,
                color: selected ? cs.primary : cs.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared pieces ────────────────────────────────────────────────────────────

class _BrandCard extends StatelessWidget {
  const _BrandCard({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
      decoration: BoxDecoration(
        // Reads over the aurora without needing a glass layer, which the old
        // build ran at premium quality even for users about to pick
        // "Bình thường" (`03-welcome.md` §L).
        color: cs.surfaceContainerLowest.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          ClipOval(
            child: Image.asset(
              'assets/icons/app_logo.jpg',
              width: 84,
              height: 84,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Spendo',
            style: TextStyle(
              fontFamily: AppTypography.displayFamily,
              fontSize: 34,
              color: cs.onSurface,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Page indicator — the old flow had none, so there was no way to tell how
/// many steps were left (`03-welcome.md` §J).
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: appMotion.whenMotionAllowed(
              context,
              appMotion.tapUpDuration,
            ),
            curve: appMotion.curveStandard,
            margin: EdgeInsets.only(right: i == count - 1 ? 0 : 8),
            width: i == index ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index ? cs.primary : cs.outlineVariant,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}
