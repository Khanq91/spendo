import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_glass_policy.dart';
import '../../core/theme/spendo_colors.dart';
import '../../core/theme/visual_mode_provider.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/stats/presentation/screens/stats_screen.dart';
import '../../features/transactions/presentation/screens/transactions_screen.dart';
import '../../features/transactions/presentation/widgets/add_transaction_sheet.dart';
import 'aurora_theme_background.dart';
import 'motion/motion.dart';
import 'spendo/spendo.dart';

/// Four-tab shell: Trang chủ · Giao dịch · Thống kê · Cài đặt.
///
/// Tabs keep their state through an [IndexedStack]; only the visible one
/// keeps its tickers running.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, this.initialIndex = 0});

  /// Which tab to open on. Home is the default landing tab.
  final int initialIndex;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late int _index = widget.initialIndex;

  static const _screens = [
    HomeScreen(),
    TransactionsScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  /// Settings has no "add transaction" affordance.
  bool get _showFab => _index != 3;

  @override
  Widget build(BuildContext context) {
    final visualMode = ref.watch(visualModeProvider);
    final isFancy = visualMode == AppVisualMode.fancy;

    return Scaffold(
      extendBody: isFancy,
      body: Stack(
        children: [
          if (isFancy) const Positioned.fill(child: AuroraThemeBackground()),
          Theme(
            data: isFancy
                ? Theme.of(context).copyWith(
                    scaffoldBackgroundColor: Colors.transparent,
                    canvasColor: Colors.transparent,
                  )
                : Theme.of(context),
            child: IndexedStack(
              index: _index,
              children: List.generate(
                _screens.length,
                (i) => TickerMode(enabled: _index == i, child: _screens[i]),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isFancy
          ? _FancySpendoNavBar(selectedIndex: _index, onTap: _selectTab)
          : SpendoBottomNav(
              destinations: SpendoBottomNav.spendoDestinations,
              selectedIndex: _index,
              onSelected: _selectTab,
            ),
      floatingActionButton: _showFab
          ? (isFancy
                ? PressableScale(
                    deferTapToChild: true,
                    child: RepaintBoundary(
                      child: GlassButton(
                        key: const Key('spendo_fab_add_transaction'),
                        icon: const Icon(LucideIcons.plus),
                        iconSize: 28,
                        useOwnLayer: true,
                        quality: AppGlassPolicy.interactiveQuality,
                        width: 56,
                        height: 56,
                        onTap: _showAddTransactionSheet,
                      ),
                    ),
                  )
                : SpendoFab(
                    key: const Key('spendo_fab_add_transaction'),
                    heroTag: 'global_fab',
                    onPressed: _showAddTransactionSheet,
                  ))
          : null,
    );
  }

  void _showAddTransactionSheet() {
    showAddTransactionSheet(context);
  }

  void _selectTab(int i) {
    if (i == _index) return;
    setState(() => _index = i);
  }
}

class _FancySpendoNavBar extends StatelessWidget {
  const _FancySpendoNavBar({required this.selectedIndex, required this.onTap});

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return RepaintBoundary(
      child: GlassTabBar.bottom(
        selectedIndex: selectedIndex,
        onTabSelected: onTap,
        quality: AppGlassPolicy.focalQuality,
        horizontalPadding: 18,
        verticalPadding: 16,
        barHeight: 64,
        selectedIconColor: theme.spendo.brand,
        selectedLabelColor: cs.onSurface,
        unselectedIconColor: cs.onSurfaceVariant,
        unselectedLabelColor: cs.onSurfaceVariant,
        tabs: [
          for (final destination in SpendoBottomNav.spendoDestinations)
            GlassTab(
              icon: Icon(destination.icon),
              activeIcon: Icon(destination.icon),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}
