/// ParticleField
/// Origin: reimplemented — dựng lại ý tưởng "Particles" của react-bits
/// (bản gốc là WebGL point sprites; bản này là CustomPainter 2D với depth
/// giả lập — xem README/Caveats).
/// Deps: flutter only
/// Flutter: 3.44.5
/// Entry file. Copy the whole folder into another project and import this file.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Drifting particle field: each particle oscillates sinusoidally with its
/// own phase/frequency, deeper particles are smaller and dimmer, and the
/// whole field parallax-shifts toward the finger while touched.
///
/// As a `kind: paint` it is transparent by default so it layers over any
/// background; pass [child] to use it as the backdrop of a card/button.
///
/// [scale] is detail density (§9.1): it multiplies the particle density per
/// area, so a 48px button gets a few particles instead of a flat smear —
/// the particle *count* adapts to the painted area, not the widget tree.
class ParticleField extends StatefulWidget {
  const ParticleField({
    super.key,
    this.scale = 1.0,
    this.density = 6.0,
    this.maxParticles = 400,
    this.colors = const <Color>[Color(0xFFFFFFFF)],
    this.baseSize = 2.6,
    this.sizeRandomness = 1.0,
    this.driftAmplitude = 14.0,
    this.speed = 1.0,
    this.twinkle = true,
    this.softParticles = false,
    this.backgroundColor,
    this.interactive = true,
    this.touchFactor = 1.0,
    this.seed = 7,
    this.animate = true,
    this.child,
  });

  /// Detail density (§9.1): multiplies [density].
  final double scale;

  /// Particles per 10,000 logical px² (≈ 170 on a 360×800 screen at 6.0).
  final double density;

  /// Hard cap on the particle count (mobile perf guard).
  final int maxParticles;

  /// Palette; each particle picks one color at spawn.
  final List<Color> colors;

  /// Radius in logical px of a front-most, average-sized particle.
  final double baseSize;

  /// 0 = uniform size, 1 = sizes vary roughly 0.3×–1.8× of [baseSize].
  final double sizeRandomness;

  /// Max sinusoidal drift distance in logical px (scaled by depth).
  final double driftAmplitude;

  /// Animation tempo multiplier.
  final double speed;

  /// Slow per-particle opacity shimmer.
  final bool twinkle;

  /// Soft blurred dots instead of hard circles. Costs a MaskFilter per
  /// frame — keep off for large counts on low-end devices.
  final bool softParticles;

  /// Painted behind the particles; `null` keeps the field transparent.
  final Color? backgroundColor;

  /// Parallax-shift the field toward the pointer while touched.
  final bool interactive;

  /// Strength of the touch parallax (0 disables it like [interactive]).
  final double touchFactor;

  /// Seed for the deterministic particle layout.
  final int seed;

  /// External stop switch: set `false` to halt the internal ticker (no
  /// frames scheduled while stopped). Resuming continues from the same phase.
  final bool animate;

  /// Optional foreground content rendered on top of the field.
  final Widget? child;

  @override
  State<ParticleField> createState() => _ParticleFieldState();
}

class _ParticleFieldState extends State<ParticleField>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _time = ValueNotifier<double>(0);
  final ValueNotifier<Offset> _touch = ValueNotifier<Offset>(Offset.zero);
  Offset _touchTarget = Offset.zero;
  double _timeBase = 0;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _particles = _spawn(widget.seed, widget.maxParticles);
    _ticker = createTicker(_onTick);
    if (widget.animate) {
      _ticker.start();
    }
  }

  static List<_Particle> _spawn(int seed, int count) {
    final math.Random rng = math.Random(seed);
    return List<_Particle>.generate(count, (_) {
      final double z = 0.35 + 0.65 * rng.nextDouble();
      return _Particle(
        fx: rng.nextDouble(),
        fy: rng.nextDouble(),
        z: z,
        freqX: 0.3 + 0.7 * rng.nextDouble(),
        freqY: 0.3 + 0.7 * rng.nextDouble(),
        phaseX: rng.nextDouble() * 2 * math.pi,
        phaseY: rng.nextDouble() * 2 * math.pi,
        sizeJitter: rng.nextDouble() * 2 - 1,
        twinklePhase: rng.nextDouble() * 2 * math.pi,
        colorIndex: rng.nextInt(1 << 16),
      );
    });
  }

  void _onTick(Duration elapsed) {
    _time.value = _timeBase + elapsed.inMicroseconds / 1e6;
    if (_touch.value != _touchTarget) {
      final Offset next = Offset.lerp(_touch.value, _touchTarget, 0.12)!;
      _touch.value =
          (next - _touchTarget).distanceSquared < 0.01 ? _touchTarget : next;
    }
  }

  @override
  void didUpdateWidget(ParticleField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.seed != oldWidget.seed ||
        widget.maxParticles != oldWidget.maxParticles) {
      _particles = _spawn(widget.seed, widget.maxParticles);
    }
    if (widget.animate && !_ticker.isActive) {
      _ticker.start();
    } else if (!widget.animate && _ticker.isActive) {
      _timeBase = _time.value;
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    _touch.dispose();
    super.dispose();
  }

  void _onPointer(Offset localPosition, Size size) {
    if (!widget.interactive || size.isEmpty) {
      return;
    }
    final Offset center = Offset(size.width / 2, size.height / 2);
    _touchTarget = (localPosition - center) * 0.06 * widget.touchFactor;
    if (!_ticker.isActive) {
      _touch.value = _touchTarget; // no ticker to ease it — snap
    }
  }

  void _onPointerEnd() {
    _touchTarget = Offset.zero;
    if (!_ticker.isActive) {
      _touch.value = Offset.zero;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget field = CustomPaint(
      painter: _ParticlePainter(
        time: _time,
        touch: _touch,
        particles: _particles,
        scale: widget.scale,
        density: widget.density,
        colors: widget.colors,
        baseSize: widget.baseSize,
        sizeRandomness: widget.sizeRandomness,
        driftAmplitude: widget.driftAmplitude,
        speed: widget.speed,
        twinkle: widget.twinkle,
        softParticles: widget.softParticles,
        backgroundColor: widget.backgroundColor,
      ),
      child: widget.child ?? const SizedBox.expand(),
    );
    if (!widget.interactive) {
      return field;
    }
    return LayoutBuilder(
      builder: (context, constraints) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) =>
            _onPointer(event.localPosition, constraints.biggest),
        onPointerMove: (event) =>
            _onPointer(event.localPosition, constraints.biggest),
        onPointerUp: (_) => _onPointerEnd(),
        onPointerCancel: (_) => _onPointerEnd(),
        child: field,
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.fx,
    required this.fy,
    required this.z,
    required this.freqX,
    required this.freqY,
    required this.phaseX,
    required this.phaseY,
    required this.sizeJitter,
    required this.twinklePhase,
    required this.colorIndex,
  });

  final double fx; // base position, fraction of width/height
  final double fy;
  final double z; // depth 0.35..1 (1 = closest)
  final double freqX;
  final double freqY;
  final double phaseX;
  final double phaseY;
  final double sizeJitter; // -1..1
  final double twinklePhase;
  final int colorIndex;
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.time,
    required this.touch,
    required this.particles,
    required this.scale,
    required this.density,
    required this.colors,
    required this.baseSize,
    required this.sizeRandomness,
    required this.driftAmplitude,
    required this.speed,
    required this.twinkle,
    required this.softParticles,
    required this.backgroundColor,
  }) : super(repaint: Listenable.merge(<Listenable>[time, touch]));

  final ValueListenable<double> time;
  final ValueListenable<Offset> touch;
  final List<_Particle> particles;
  final double scale;
  final double density;
  final List<Color> colors;
  final double baseSize;
  final double sizeRandomness;
  final double driftAmplitude;
  final double speed;
  final bool twinkle;
  final bool softParticles;
  final Color? backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || colors.isEmpty) {
      return;
    }
    if (backgroundColor != null) {
      canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor!);
    }
    final int count = ((size.width * size.height / 10000) * density * scale)
        .round()
        .clamp(0, particles.length);
    final double t = time.value * speed;
    final Offset shift = touch.value;
    final Paint dot = Paint();
    if (softParticles) {
      dot.maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6);
    }
    for (int i = 0; i < count; i++) {
      final _Particle p = particles[i];
      final double amp = driftAmplitude * p.z;
      final Offset pos = Offset(
        p.fx * size.width +
            math.sin(t * p.freqX + p.phaseX) * amp +
            shift.dx * p.z,
        p.fy * size.height +
            math.cos(t * p.freqY + p.phaseY) * amp +
            shift.dy * p.z,
      );
      final double radius = baseSize *
          p.z *
          math.max(0.25, 1 + 0.8 * sizeRandomness * p.sizeJitter);
      final double alpha = twinkle
          ? 0.45 + 0.45 * (0.5 + 0.5 * math.sin(t * 0.8 + p.twinklePhase))
          : 0.85;
      dot.color = colors[p.colorIndex % colors.length]
          .withValues(alpha: alpha * (0.5 + 0.5 * p.z));
      canvas.drawCircle(pos, radius, dot);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) =>
      oldDelegate.particles != particles ||
      oldDelegate.scale != scale ||
      oldDelegate.density != density ||
      oldDelegate.colors != colors ||
      oldDelegate.baseSize != baseSize ||
      oldDelegate.sizeRandomness != sizeRandomness ||
      oldDelegate.driftAmplitude != driftAmplitude ||
      oldDelegate.speed != speed ||
      oldDelegate.twinkle != twinkle ||
      oldDelegate.softParticles != softParticles ||
      oldDelegate.backgroundColor != backgroundColor;
}
