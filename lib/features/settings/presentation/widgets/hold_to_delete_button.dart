import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/widgets/motion/motion.dart';

/// The destructive commit of the reset flow.
///
/// Stays disabled for [armDelay] with the seconds counting down in its label,
/// then has to be held for [holdDuration]: a fill sweeps across the pill
/// (kinetics "Hold to Confirm", flattened from a ring to a bar) and releasing
/// early snaps it back in 0.2s. The sweep is functional feedback, so it runs
/// even under reduce-motion; only the snap-back goes instant.
class HoldToDeleteButton extends StatefulWidget {
  const HoldToDeleteButton({
    super.key,
    required this.onConfirm,
    this.armDelay = const Duration(seconds: 10),
    this.holdDuration = const Duration(seconds: 3),
    this.busy = false,
  });

  final VoidCallback onConfirm;

  /// How long the button stays disabled after appearing.
  final Duration armDelay;

  /// How long it must be held once armed.
  final Duration holdDuration;

  /// Shown while the reset runs: spinner, no interaction.
  final bool busy;

  static const String armedLabel = 'GIỮ ĐỂ XÓA';

  static String countdownLabel(int secondsLeft) => 'XÓA (${secondsLeft}s)';

  @override
  State<HoldToDeleteButton> createState() => _HoldToDeleteButtonState();
}

class _HoldToDeleteButtonState extends State<HoldToDeleteButton>
    with TickerProviderStateMixin {
  late final AnimationController _arm = AnimationController(
    vsync: this,
    duration: widget.armDelay,
  );
  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: widget.holdDuration,
  );
  bool _holding = false;
  bool _fired = false;

  bool get _armed => _arm.isCompleted;
  bool get _interactive => _armed && !widget.busy && !_fired;

  int get _secondsLeft {
    final remaining = (1 - _arm.value) * widget.armDelay.inMilliseconds;
    return (remaining / 1000).ceil();
  }

  @override
  void initState() {
    super.initState();
    _arm
      ..addListener(() => setState(() {}))
      ..forward();
    _hold.addStatusListener((status) {
      if (status == AnimationStatus.completed && _holding) _confirm();
    });
  }

  @override
  void dispose() {
    _arm.dispose();
    _hold.dispose();
    super.dispose();
  }

  void _start() {
    if (!_interactive) return;
    setState(() => _holding = true);
    // Constant speed from wherever the fill is, so a re-press during the
    // snap-back resumes mid-bar instead of restarting.
    _hold.animateTo(1, duration: widget.holdDuration * (1 - _hold.value));
  }

  void _release() {
    if (!_holding) return;
    // Letting go on the very last frame of the fill is a completed hold.
    if (_hold.value >= 1) {
      _confirm();
      return;
    }
    setState(() => _holding = false);
    _hold.animateBack(
      0,
      duration: appMotion.whenMotionAllowed(
        context,
        const Duration(milliseconds: 200),
      ),
      curve: Curves.easeOut,
    );
  }

  void _confirm() {
    if (_fired) return;
    setState(() {
      _holding = false;
      _fired = true;
    });
    HapticFeedback.heavyImpact();
    widget.onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = _armed
        ? HoldToDeleteButton.armedLabel
        : HoldToDeleteButton.countdownLabel(_secondsLeft);

    return Semantics(
      button: true,
      enabled: _interactive,
      label: label,
      // Accessibility path: a long-press action confirms without the hold.
      onLongPress: _interactive ? _confirm : null,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _start(),
        onPointerUp: (_) => _release(),
        onPointerCancel: (_) => _release(),
        child: Opacity(
          opacity: _armed || widget.busy ? 1 : 0.45,
          child: Container(
            height: 48,
            clipBehavior: Clip.antiAlias,
            decoration: ShapeDecoration(
              color: cs.error.withValues(alpha: 0.12),
              shape: StadiumBorder(side: BorderSide(color: cs.error, width: 1.5)),
            ),
            child: AnimatedBuilder(
              animation: _hold,
              builder: (context, child) {
                final t = _fired ? 1.0 : _hold.value;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // The fill sweeps in from the left as the hold progresses.
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: t,
                      child: ColoredBox(color: cs.error),
                    ),
                    Center(
                      child: widget.busy
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: t > 0.5 ? cs.onError : cs.error,
                              ),
                            )
                          : Text(
                              label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                color: Color.lerp(cs.error, cs.onError, t),
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
