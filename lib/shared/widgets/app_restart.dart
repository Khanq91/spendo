import 'package:flutter/widgets.dart';

/// Rebuilds the subtree below it from scratch on demand.
///
/// [builder] receives a generation counter that starts at 0 and goes up by
/// one on every [restart]; key the subtree on it so every widget and provider
/// underneath is recreated. The data reset uses this to drop all cached app
/// state without relaunching the process.
class AppRestart extends StatefulWidget {
  const AppRestart({super.key, required this.builder});

  final Widget Function(BuildContext context, int generation) builder;

  /// Tears down and rebuilds everything below the nearest [AppRestart].
  static void restart(BuildContext context) {
    final state = context.findAncestorStateOfType<_AppRestartState>();
    assert(state != null, 'AppRestart.restart called outside an AppRestart');
    state?._restart();
  }

  @override
  State<AppRestart> createState() => _AppRestartState();
}

class _AppRestartState extends State<AppRestart> {
  int _generation = 0;

  void _restart() => setState(() => _generation++);

  @override
  Widget build(BuildContext context) => widget.builder(context, _generation);
}
