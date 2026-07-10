import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'motion_spec.dart';

class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
    this.scale = 0.96,
    this.borderRadius,
    this.behavior = HitTestBehavior.opaque,
    this.haptic = false,
    this.deferTapToChild = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final double scale;
  final BorderRadius? borderRadius;
  final HitTestBehavior behavior;
  final bool haptic;
  final bool deferTapToChild;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  bool get _isInteractive =>
      widget.enabled && (widget.onTap != null || widget.deferTapToChild);

  void _setPressed(bool value) {
    if (!_isInteractive || _pressed == value) return;
    setState(() => _pressed = value);
  }

  void _handleTap() {
    if (!_isInteractive) return;
    if (widget.haptic) HapticFeedback.selectionClick();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MotionSpec.shouldReduceMotion(context);
    final duration =
        _pressed ? appMotion.tapDownDuration : appMotion.tapUpDuration;
    final child = AnimatedScale(
      scale: reduceMotion || !_pressed ? 1 : widget.scale,
      duration: reduceMotion ? Duration.zero : duration,
      curve: appMotion.curveStandard,
      child: widget.child,
    );

    final interactiveChild =
        widget.deferTapToChild
            ? Listener(
              behavior: widget.behavior,
              onPointerDown: (_) => _setPressed(true),
              onPointerUp: (_) => _setPressed(false),
              onPointerCancel: (_) => _setPressed(false),
              child: child,
            )
            : GestureDetector(
              behavior: widget.behavior,
              onTap: _handleTap,
              onTapDown: (_) => _setPressed(true),
              onTapUp: (_) => _setPressed(false),
              onTapCancel: () => _setPressed(false),
              child: child,
            );

    return MouseRegion(
      cursor: _isInteractive ? SystemMouseCursors.click : MouseCursor.defer,
      child:
          widget.borderRadius == null
              ? interactiveChild
              : ClipRRect(
                borderRadius: widget.borderRadius!,
                child: interactiveChild,
              ),
    );
  }
}
