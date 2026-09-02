/// NoticeSlideIn
/// Origin: reimplemented — kinetics "Notification Slide-in" (Feedback &
///   State), https://github.com/ckissi/kinetics, via Snipz
///   `notification_slide_in`. Spendo adds an optional trailing action and a
///   two-line message; the motion and the state machine are the original's.
library;

import 'package:flutter/widgets.dart';

import '../motion/motion_spec.dart';
import 'app_notice.dart';

/// A pill banner that drops from the top edge, overshoots, settles, and then
/// dismisses itself after [displayDuration]. Increment [requestId] to show
/// it; a retrigger while visible only restarts the timer (the pill does not
/// replay its drop). Motion follows CSS-transition semantics: the pill always
/// animates toward its current target with the same overshoot bezier,
/// entering and leaving alike.
class NoticeSlideIn extends StatefulWidget {
  const NoticeSlideIn({
    super.key,
    this.requestId = 0,
    this.message = '',
    this.displayDuration = const Duration(milliseconds: 2200),
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.dotColor,
    required this.actionColor,
    this.action,
    this.maxWidth = 420,
    this.onDismissed,
  });

  /// Change this value to show the banner. Reusing the current value is a
  /// no-op; increasing an integer is the simplest calling pattern.
  final int requestId;
  final String message;
  final Duration displayDuration;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color dotColor;
  final Color actionColor;

  /// Optional text button on the right; tapping it runs the callback and
  /// dismisses the banner at once.
  final NoticeAction? action;
  final double maxWidth;
  final VoidCallback? onDismissed;

  @override
  State<NoticeSlideIn> createState() => _NoticeSlideInState();
}

class _NoticeSlideInState extends State<NoticeSlideIn>
    with SingleTickerProviderStateMixin {
  /// CSS: transform 0.55s cubic-bezier(0.18, 1.25, 0.4, 1), opacity 0.3s.
  static const Curve _drop = Cubic(0.18, 1.25, 0.4, 1);

  late final AnimationController _life;
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    _life = AnimationController(vsync: this, duration: widget.displayDuration)
      ..addStatusListener(_onLifeStatus);
    if (widget.requestId != 0) {
      _shown = true;
      _life.forward();
    }
  }

  @override
  void didUpdateWidget(NoticeSlideIn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.displayDuration != widget.displayDuration) {
      _life.duration = widget.displayDuration;
    }
    if (oldWidget.requestId != widget.requestId) _show();
  }

  void _onLifeStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _dismiss();
  }

  /// Like the original click handler: (re)start the timer; the pill only
  /// animates in when it is not already on screen.
  void _show() {
    if (!_shown) setState(() => _shown = true);
    _life.forward(from: 0);
  }

  void _dismiss() {
    if (!_shown) return;
    _life.stop();
    setState(() => _shown = false);
    // Without motion there is no exit transition to wait for.
    if (MotionSpec.shouldReduceMotion(context)) widget.onDismissed?.call();
  }

  void _onAction() {
    widget.action?.onPressed();
    _dismiss();
  }

  @override
  void dispose() {
    _life.removeStatusListener(_onLifeStatus);
    _life.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.action;
    final slideDuration = appMotion.whenMotionAllowed(
      context,
      const Duration(milliseconds: 550),
    );
    final fadeDuration = appMotion.whenMotionAllowed(
      context,
      const Duration(milliseconds: 300),
    );

    return IgnorePointer(
      ignoring: !_shown,
      child: Align(
        alignment: Alignment.topCenter,
        // -160% of the pill's own height, exactly the CSS transform.
        child: AnimatedSlide(
          offset: _shown ? Offset.zero : const Offset(0, -1.6),
          duration: slideDuration,
          curve: _drop,
          onEnd: () {
            if (!_shown) widget.onDismissed?.call();
          },
          child: AnimatedOpacity(
            opacity: _shown ? 1 : 0,
            duration: fadeDuration,
            curve: Curves.ease,
            child: Semantics(
              liveRegion: true,
              label: widget.message,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: widget.maxWidth),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: widget.backgroundColor,
                    border: Border.all(color: widget.borderColor),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.dotColor,
                        ),
                        child: const SizedBox.square(dimension: 8),
                      ),
                      const SizedBox(width: 9),
                      Flexible(
                        child: Text(
                          widget.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: widget.textColor,
                            fontSize: 13,
                            height: 1.55,
                          ),
                        ),
                      ),
                      if (action != null) ...[
                        const SizedBox(width: 14),
                        Semantics(
                          button: true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _onAction,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                              ),
                              child: Text(
                                action.label,
                                style: TextStyle(
                                  color: widget.actionColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  height: 1.55,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
