import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sensors_plus/sensors_plus.dart';

class AuroraThemeBackground extends StatefulWidget {
  const AuroraThemeBackground({super.key});

  @override
  State<AuroraThemeBackground> createState() => _AuroraThemeBackgroundState();
}

class _AuroraThemeBackgroundState extends State<AuroraThemeBackground>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat();

  final ValueNotifier<Offset> _parallax = ValueNotifier(Offset.zero);
  Offset _targetOffset = Offset.zero;
  late final Ticker _parallaxTicker;
  StreamSubscription<AccelerometerEvent>? _accelSub;

  bool get _supportsAccelerometer =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    _parallaxTicker = createTicker(_tickParallax)..start();

    if (_supportsAccelerometer) {
      _accelSub = accelerometerEventStream(
        samplingPeriod: SensorInterval.uiInterval,
      ).listen(_onAccelerometer);
    }
    // Web (đặc biệt iOS Safari) cần xin permission riêng cho DeviceMotion
    // trước khi đọc được sensor — chưa xử lý ở đây, tạm fallback về
    // pointer-only trên web cho chắc ăn.
  }

  void _onAccelerometer(AccelerometerEvent event) {
    // event.x/y xấp xỉ -9.8..9.8 (thành phần trọng lực). maxTilt=4.0 tương
    // ứng nghiêng máy vừa phải khi cầm tay — không cần nghiêng gắt mới thấy
    // hiệu ứng.
    const maxTilt = 4.0;
    _targetOffset = Offset(
      (event.x / maxTilt).clamp(-1.0, 1.0),
      (-event.y / maxTilt).clamp(-1.0, 1.0),
    );
  }

  void _onPointerMove(PointerEvent event, Size size) {
    if (size.isEmpty) return;
    _targetOffset = Offset(
      ((event.localPosition.dx / size.width) * 2 - 1).clamp(-1.0, 1.0),
      ((event.localPosition.dy / size.height) * 2 - 1).clamp(-1.0, 1.0),
    );
  }

  void _tickParallax(Duration _) {
    // 0.06 = độ trễ theo sau con trỏ/tilt — thấp hơn thì "lì" hơn, cao hơn
    // thì bám sát nhưng dễ giật.
    final next = Offset.lerp(_parallax.value, _targetOffset, 0.06)!;
    if (next != _parallax.value) _parallax.value = next;
  }

  @override
  void dispose() {
    _controller.dispose();
    _parallaxTicker.dispose();
    _accelSub?.cancel();
    _parallax.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return MouseRegion(
          onHover: (e) => _onPointerMove(e, size),
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerMove: (e) => _onPointerMove(e, size),
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: Listenable.merge([_controller, _parallax]),
                builder: (context, _) {
                  return CustomPaint(
                    painter: _AuroraMeshPainter(
                      progress: _controller.value,
                      parallax: _parallax.value,
                      colors: [cs.primary, cs.secondary, cs.tertiary],
                      surface: Theme.of(context).scaffoldBackgroundColor,
                      isDark: isDark,
                    ),
                    child: const SizedBox.expand(),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Blob {
  const _Blob({
    required this.colorIndex,
    required this.radiusFactor,
    required this.speedX,
    required this.speedY,
    required this.orbitX,
    required this.orbitY,
    required this.phase,
    required this.baseX,
    required this.baseY,
    required this.parallaxStrength,
  });

  final int colorIndex;
  final double radiusFactor;
  final double speedX;
  final double speedY;
  final double orbitX;
  final double orbitY;
  final double phase;
  final double baseX;
  final double baseY;
  final double parallaxStrength; // % width/height dịch theo con trỏ/tilt
}

class _AuroraMeshPainter extends CustomPainter {
  _AuroraMeshPainter({
    required this.progress,
    required this.parallax,
    required this.colors,
    required this.surface,
    required this.isDark,
  });

  final double progress;
  final Offset parallax;
  final List<Color> colors;
  final Color surface;
  final bool isDark;

  static final List<_Blob> _blobs = [
    const _Blob(colorIndex: 0, radiusFactor: 0.62, speedX: 1.0, speedY: 1.3, orbitX: 0.22, orbitY: 0.16, phase: 0.0, baseX: 0.20, baseY: 0.28, parallaxStrength: 0.05),
    const _Blob(colorIndex: 1, radiusFactor: 0.55, speedX: -0.7, speedY: 0.9, orbitX: 0.18, orbitY: 0.20, phase: 2.1, baseX: 0.80, baseY: 0.22, parallaxStrength: 0.08),
    const _Blob(colorIndex: 2, radiusFactor: 0.70, speedX: 0.55, speedY: -0.8, orbitX: 0.20, orbitY: 0.18, phase: 4.2, baseX: 0.50, baseY: 0.82, parallaxStrength: 0.04),
    const _Blob(colorIndex: 0, radiusFactor: 0.46, speedX: -1.15, speedY: 0.6, orbitX: 0.16, orbitY: 0.12, phase: 1.4, baseX: 0.85, baseY: 0.78, parallaxStrength: 0.10),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = surface);

    final shortest = math.min(size.width, size.height);
    final t = progress * math.pi * 2;

    for (final blob in _blobs) {
      final baseCx = (blob.baseX + math.cos(t * blob.speedX + blob.phase) * blob.orbitX) * size.width;
      final baseCy = (blob.baseY + math.sin(t * blob.speedY + blob.phase) * blob.orbitY) * size.height;

      // Blob có parallaxStrength lớn hơn = "gần" hơn = dịch nhiều hơn theo
      // con trỏ/tilt, tạo cảm giác chiều sâu thay vì cả nhóm trôi đồng bộ.
      final cx = baseCx + parallax.dx * size.width * blob.parallaxStrength;
      final cy = baseCy + parallax.dy * size.height * blob.parallaxStrength;

      final radius = shortest * blob.radiusFactor;
      final color = colors[blob.colorIndex % colors.length];
      final center = Offset(cx, cy);

      final gradient = RadialGradient(
        colors: [
          color.withValues(alpha: isDark ? 0.55 : 0.38),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 1.0],
      );

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius))
          ..blendMode = isDark ? BlendMode.plus : BlendMode.srcOver,
      );
    }

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: isDark ? 0.03 : 0.10),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _AuroraMeshPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.parallax != parallax ||
        oldDelegate.isDark != isDark ||
        oldDelegate.surface != surface ||
        !_listEquals(oldDelegate.colors, colors);
  }

  bool _listEquals(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
