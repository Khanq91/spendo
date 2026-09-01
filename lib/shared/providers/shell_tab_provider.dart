import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The tab `AppShell` is showing, so a screen inside the shell can move to a
/// sibling tab instead of pushing a second copy of it on the stack.
///
/// Order matches `SpendoBottomNav.spendoDestinations`.
enum ShellTab { home, transactions, stats, settings }

final shellTabProvider = StateProvider<ShellTab>((_) => ShellTab.home);
