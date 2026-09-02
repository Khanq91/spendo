import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'motion_spec.dart';

/// Entrance for list rows, after react-bits "Animated List" (Snipz
/// `reveal_list`): a row pops in — scale 0.7→1 with fade, `easeOutBack` —
/// the first time at least [visibleFraction] of it is inside its viewport.
/// Rows that arrive together (first layout, a data refresh) stagger by
/// [MotionSpec.revealStagger]; rows scrolled into view arrive one at a time.
///
/// Unlike the original, this is not a list widget: wrap any scrollable —
/// a `ListView`, a `CustomScrollView` of slivers, a `ReorderableListView` —
/// in a [RevealScope] and each row in a [RevealItem]. Rows are identified by
/// [RevealItem.id], not index, so a row keeps its revealed state through
/// deletes, filters and viewport recycling and never replays while the scope
/// is alive.
class RevealScope extends StatefulWidget {
  const RevealScope({
    super.key,
    required this.child,
    this.visibleFraction = 0.5,
  });

  final Widget child;

  /// How much of a row must be inside the viewport before it reveals.
  final double visibleFraction;

  @override
  State<RevealScope> createState() => _RevealScopeState();
}

class _RevealScopeState extends State<RevealScope> {
  final Set<_RevealItemState> _items = <_RevealItemState>{};
  final Set<Object> _revealed = <Object>{};
  bool _sweepScheduled = false;

  void _register(_RevealItemState item) {
    _items.add(item);
    _scheduleSweep();
  }

  void _unregister(_RevealItemState item) => _items.remove(item);

  bool _wasRevealed(Object id) => _revealed.contains(id);

  void _scheduleSweep() {
    if (_sweepScheduled) return;
    _sweepScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sweepScheduled = false;
      if (mounted) _sweep();
    });
  }

  /// Reveal every registered row that is far enough inside its viewport.
  void _sweep() {
    final due = <(_RevealItemState item, double top)>[];
    for (final item in _items) {
      if (item._revealed) continue;
      final ro = item.context.findRenderObject();
      if (ro is! RenderBox || !ro.attached || !ro.hasSize) continue;
      final viewport = RenderAbstractViewport.maybeOf(ro);
      final position = Scrollable.maybeOf(item.context)?.position;
      if (viewport == null ||
          position == null ||
          !position.hasPixels ||
          !position.hasViewportDimension) {
        continue;
      }
      final vpTop = position.pixels;
      final vpBottom = vpTop + position.viewportDimension;
      final itemTop = viewport.getOffsetToReveal(ro, 0).offset;
      final itemBottom = itemTop + ro.size.height;
      final overlap =
          itemBottom.clamp(vpTop, vpBottom) - itemTop.clamp(vpTop, vpBottom);
      // A row taller than the viewport can never show half of itself.
      final needed =
          math.min(ro.size.height, position.viewportDimension) *
          widget.visibleFraction;
      if (ro.size.height <= 0 || overlap >= needed) due.add((item, itemTop));
    }
    if (due.isEmpty) return;
    // Rows that become due together stagger top to bottom; a row scrolled in
    // on its own is the only one due and starts at once.
    due.sort((a, b) => a.$2.compareTo(b.$2));
    for (var i = 0; i < due.length; i++) {
      final item = due[i].$1;
      _revealed.add(item.widget.id);
      item._reveal(delay: appMotion.revealStagger * i);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _RevealScopeMarker(
      scope: this,
      child: NotificationListener<ScrollNotification>(
        onNotification: (_) {
          _sweep();
          return false;
        },
        child: widget.child,
      ),
    );
  }
}

class _RevealScopeMarker extends InheritedWidget {
  const _RevealScopeMarker({required this.scope, required super.child});

  final _RevealScopeState scope;

  @override
  bool updateShouldNotify(_RevealScopeMarker oldWidget) =>
      scope != oldWidget.scope;
}

/// One row of a [RevealScope]. Without a scope above it, or under reduce
/// motion, the child simply renders.
class RevealItem extends StatefulWidget {
  const RevealItem({super.key, required this.id, required this.child});

  /// Stable identity of the row (a record id, a date key) — what the scope
  /// remembers as revealed.
  final Object id;
  final Widget child;

  @override
  State<RevealItem> createState() => _RevealItemState();
}

class _RevealItemState extends State<RevealItem>
    with SingleTickerProviderStateMixin {
  _RevealScopeState? _scope;
  bool _attached = false;
  late final AnimationController _controller;
  late CurvedAnimation _curve;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: appMotion.listDuration,
    );
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = context
        .dependOnInheritedWidgetOfExactType<_RevealScopeMarker>()
        ?.scope;
    if (_attached && scope == _scope) return;
    _attached = true;
    _scope?._unregister(this);
    _scope = scope;
    if (scope == null || MotionSpec.shouldReduceMotion(context)) {
      // Nothing to wait for: render the row as-is.
      _revealed = true;
      _controller.value = 1;
      return;
    }
    if (scope._wasRevealed(widget.id)) {
      // Rebuilt by viewport recycling after it already revealed once.
      _revealed = true;
      _controller.value = 1;
    }
    scope._register(this);
  }

  @override
  void didUpdateWidget(RevealItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id && !_revealed) {
      // The slot now shows a different row; let the sweep judge it afresh.
      _scope?._scheduleSweep();
    }
  }

  void _reveal({Duration delay = Duration.zero}) {
    if (_revealed) return;
    _revealed = true;
    if (delay > Duration.zero) {
      // Fold the delay into the controller so no Timer outlives the widget.
      final total = delay + appMotion.listDuration;
      _controller.duration = total;
      _curve.dispose();
      _curve = CurvedAnimation(
        parent: _controller,
        curve: Interval(
          delay.inMicroseconds / total.inMicroseconds,
          1,
          curve: Curves.easeOutBack,
        ),
      );
      setState(() {});
    }
    _controller.forward();
  }

  @override
  void dispose() {
    _scope?._unregister(this);
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.7, end: 1).animate(_curve),
        child: widget.child,
      ),
    );
  }
}
