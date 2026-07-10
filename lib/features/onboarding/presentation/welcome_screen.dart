import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app.dart';
import '../../../core/theme/app_glass_policy.dart';
import '../../../core/theme/visual_mode_provider.dart';
import '../../../shared/widgets/aurora_theme_background.dart';
import '../../../shared/widgets/visual_mode_picker.dart';
import '../../settings/presentation/providers/gdrive_provider.dart';
import 'startup_gate.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _nextController;
  AppVisualMode _selectedMode = AppVisualMode.normal;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _nextController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    Future<void>.delayed(const Duration(seconds: 1), () {
      if (mounted) _nextController.forward();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nextController.dispose();
    super.dispose();
  }

  Future<void> _goNext() async {
    if (_page == 1) {
      await ref.read(visualModeProvider.notifier).setMode(_selectedMode);
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(onboardingCompletedPrefsKey, true);
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const SpendoApp()));
  }

  Future<void> _signInGoogle() async {
    await ref.read(gdriveProvider.notifier).signIn();
    if (!mounted) return;

    final state = ref.read(gdriveProvider);
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          state.isSignedIn
              ? 'Đã kết nối Google Drive.'
              : state.error ?? 'Đăng nhập Google thất bại.',
        ),
      ),
    );
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
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (value) => setState(() => _page = value),
                  children: [
                    _WelcomeStep(
                      description:
                          'Quản lý thu chi cá nhân gọn gàng và rõ ràng.',
                      child: const SizedBox.shrink(),
                    ),
                    _WelcomeStep(
                      description: 'Chọn mức đồ họa',
                      child: VisualModePicker(
                        selectedMode: _selectedMode,
                        useGlass: true,
                        onChanged:
                            (mode) => setState(() => _selectedMode = mode),
                      ),
                    ),
                    _WelcomeStep(
                      description:
                          'Kết nối Google Drive để sao lưu dữ liệu Spendo khi cần.',
                      child: _GoogleDriveOptIn(onSignIn: _signInGoogle),
                    ),
                  ],
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 24,
                  child: _OnboardingActions(
                    page: _page,
                    animation: _nextController,
                    onSkip: _finish,
                    onNext: _page == 2 ? _finish : _goNext,
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

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.description, required this.child});

  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 56, 28, 96),
      child: Column(
        children: [
          RepaintBoundary(
            child: GlassContainer(
              useOwnLayer: true,
              quality: AppGlassPolicy.focalQuality,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              shape: const LiquidRoundedSuperellipse(borderRadius: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _BrandHeader(),
                  const SizedBox(height: 18),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 16,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 36),
          Expanded(child: Center(child: child)),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        ClipOval(
          child: Image.asset(
            'assets/icons/app_logo.jpg',
            width: 92,
            height: 92,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Spendo',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 40,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _GoogleDriveOptIn extends ConsumerWidget {
  const _GoogleDriveOptIn({required this.onSignIn});

  final Future<void> Function() onSignIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gdriveProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GlassButton.custom(
          width: 220,
          height: 52,
          useOwnLayer: true,
          quality: AppGlassPolicy.interactiveQuality,
          enabled: !state.isLoading,
          onTap: state.isLoading ? () {} : onSignIn,
          shape: const LiquidRoundedSuperellipse(borderRadius: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state.isLoading)
                const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.cloud_outlined, size: 20),
              const SizedBox(width: 10),
              const Text(
                'Đăng nhập Google',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        if (state.email != null) ...[
          const SizedBox(height: 12),
          Text(
            state.email!,
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ],
    );
  }
}

class _OnboardingActions extends StatelessWidget {
  const _OnboardingActions({
    required this.page,
    required this.animation,
    required this.onSkip,
    required this.onNext,
  });

  final int page;
  final Animation<double> animation;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final offset = Tween<Offset>(
      begin: const Offset(0.25, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (page == 2)
          TextButton(onPressed: onSkip, child: const Text('Bỏ qua'))
        else
          const SizedBox(width: 88),
        FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: offset,
            child: GlassButton.custom(
              width: 132,
              height: 48,
              useOwnLayer: true,
              quality: AppGlassPolicy.interactiveQuality,
              onTap: onNext,
              shape: const LiquidRoundedSuperellipse(borderRadius: 18),
              child: const Text(
                'Tiếp theo',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
