import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_provider.dart';

typedef InitCallback = Future<void> Function(
    void Function(double progress, String message) onProgress,
    );

class SplashScreen extends ConsumerStatefulWidget {
  final InitCallback onInit;
  final Widget nextScreen;

  const SplashScreen({
    super.key,
    required this.onInit,
    required this.nextScreen,
  });

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _progressCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _exitCtrl;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _taglineSlide;
  late final Animation<double> _bottomOpacity;
  late final Animation<double> _pulse;
  late final Animation<double> _exitOpacity;

  double _progress = 0.0;
  String _statusMsg = 'Starting up…';
  bool _initDone = false;

  // ── Resolve brightness từ app theme mode + system ─────────────────────────

  /// Ưu tiên: app ThemeMode (light/dark cứng) → system brightness
  Brightness _resolveBrightness() {
    final themeMode = ref.read(themeModeProvider);
    if (themeMode == ThemeMode.dark) return Brightness.dark;
    if (themeMode == ThemeMode.light) return Brightness.light;
    // ThemeMode.system — đọc từ MediaQuery, luôn chính xác trong build/didChangeDependencies
    return MediaQuery.of(context).platformBrightness;
  }

  void _updateSystemUI(bool isDark) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));
  }

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _entryCtrl.forward().then((_) => _startInit());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Gọi ở đây để có context hợp lệ (MediaQuery available)
    _updateSystemUI(_resolveBrightness() == Brightness.dark);
  }

  void _setupAnimations() {
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.65, curve: Curves.elasticOut),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
      ),
    );
    _taglineSlide = Tween<double>(begin: 12.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOutCubic),
      ),
    );
    _bottomOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
      ),
    );

    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitCtrl, curve: Curves.easeInCubic),
    );
  }

  Future<void> _startInit() async {
    await widget.onInit((progress, message) {
      if (!mounted) return;
      setState(() {
        _progress = progress;
        _statusMsg = message;
      });
    });

    if (!mounted) return;

    setState(() {
      _progress = 1.0;
      _statusMsg = 'Ready!';
      _initDone = true;
    });

    _pulseCtrl.stop();
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    await _exitCtrl.forward();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => widget.nextScreen,
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _progressCtrl.dispose();
    _pulseCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Đọc brightness mỗi frame — đảm bảo luôn đúng
    final isDark = _resolveBrightness() == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0F0A12) : const Color(0xFFFAF5FF);
    final taglineColor = isDark ? const Color(0xFFB89AB0) : const Color(0xFF7B5F8A);
    final statusColor = isDark ? const Color(0xFF8A7090) : const Color(0xFF9E7DB0);
    final versionColor = isDark ? const Color(0xFF5A4560) : const Color(0xFFB09ABF);
    final progressTrackColor = isDark ? const Color(0xFF2A1A2E) : const Color(0xFFE8D8F5);
    final appNameColor = isDark ? Colors.white : const Color(0xFF1A0A2E);

    return FadeTransition(
      opacity: _exitOpacity,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            Positioned.fill(child: _BackgroundMesh(isDark: isDark)),
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedBuilder(
                            animation: Listenable.merge([_entryCtrl, _pulseCtrl]),
                            builder: (_, __) => FadeTransition(
                              opacity: _logoOpacity,
                              child: SlideTransition(
                                position: _logoSlide,
                                child: ScaleTransition(
                                  scale: _logoScale,
                                  child: _LogoMark(
                                    glowIntensity: _initDone ? 0.0 : _pulse.value,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          AnimatedBuilder(
                            animation: _entryCtrl,
                            builder: (_, __) => FadeTransition(
                              opacity: _logoOpacity,
                              child: Text(
                                'Spendo',
                                style: TextStyle(
                                  fontFamily: 'serif',
                                  fontSize: 44,
                                  fontWeight: FontWeight.w700,
                                  color: appNameColor,
                                  letterSpacing: -1.5,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          AnimatedBuilder(
                            animation: _entryCtrl,
                            builder: (_, __) => Opacity(
                              opacity: _taglineOpacity.value,
                              child: Transform.translate(
                                offset: Offset(0, _taglineSlide.value),
                                child: Text(
                                  'Your money, clearly.',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: taglineColor,
                                    letterSpacing: 0.3,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _entryCtrl,
                    builder: (_, __) => FadeTransition(
                      opacity: _bottomOpacity,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(32, 0, 32, 52),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, anim) => FadeTransition(
                                opacity: anim,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.3),
                                    end: Offset.zero,
                                  ).animate(anim),
                                  child: child,
                                ),
                              ),
                              child: Text(
                                _statusMsg,
                                key: ValueKey(_statusMsg),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: statusColor,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _ProgressBar(
                              progress: _progress,
                              trackColor: progressTrackColor,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'v1.0.0',
                              style: TextStyle(
                                fontSize: 11,
                                color: versionColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Logo mark ─────────────────────────────────────────────────────────────────

class _LogoMark extends StatelessWidget {
  final double glowIntensity;
  const _LogoMark({this.glowIntensity = 1.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFFF48FB1), Color(0xFFF06292)],
          center: Alignment(-0.3, -0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF06292)
                .withOpacity(0.25 + 0.25 * glowIntensity),
            blurRadius: 24 + 20 * glowIntensity,
            spreadRadius: 2 + 4 * glowIntensity,
          ),
          BoxShadow(
            color: const Color(0xFFF06292).withOpacity(0.1 * glowIntensity),
            blurRadius: 60,
            spreadRadius: 10,
          ),
        ],
      ),
      child: const Center(
        child: Text('💸', style: TextStyle(fontSize: 46)),
      ),
    );
  }
}

// ── Animated progress bar ─────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final double progress;
  final Color trackColor;
  final bool isDark;

  const _ProgressBar({
    required this.progress,
    required this.trackColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final trackW = constraints.maxWidth;
        return Container(
          height: 3,
          width: trackW,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutCubic,
                width: trackW * progress.clamp(0.0, 1.0),
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF06292), Color(0xFFCE93D8)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF06292).withOpacity(0.6),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              if (progress > 0.0 && progress < 1.0)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOutCubic,
                  left: (trackW * progress - 24).clamp(0.0, trackW - 24),
                  child: Container(
                    width: 24,
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(isDark ? 0.5 : 0.8),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Background mesh ───────────────────────────────────────────────────────────

class _BackgroundMesh extends StatelessWidget {
  final bool isDark;
  const _BackgroundMesh({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _MeshPainter(isDark: isDark));
  }
}

class _MeshPainter extends CustomPainter {
  final bool isDark;
  const _MeshPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final topOrbOpacity = isDark ? 0.35 : 0.18;
    final bottomOrbOpacity = isDark ? 0.18 : 0.12;
    final vignetteOpacity = isDark ? 0.55 : 0.25;

    final topOrb = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF7B1FA2).withOpacity(topOrbOpacity),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.75, size.height * 0.1),
          radius: size.width * 0.65,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.1),
      size.width * 0.65,
      topOrb,
    );

    final bottomOrb = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFF06292).withOpacity(bottomOrbOpacity),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.1, size.height * 0.88),
          radius: size.width * 0.55,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.88),
      size.width * 0.55,
      bottomOrb,
    );

    final bgColor =
    isDark ? const Color(0xFF0F0A12) : const Color(0xFFFAF5FF);
    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          bgColor.withOpacity(vignetteOpacity),
        ],
        radius: 0.85,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      vignette,
    );
  }

  @override
  bool shouldRepaint(covariant _MeshPainter old) => old.isDark != isDark;
}