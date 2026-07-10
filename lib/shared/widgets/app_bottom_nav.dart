import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/visual_mode_provider.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/transactions/presentation/screens/transactions_screen.dart';
import '../../features/transactions/presentation/widgets/add_transaction_sheet.dart';
import 'aurora_theme_background.dart';
import 'motion/motion.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowRetentionPolicy();
    });
  }

  Future<void> _checkAndShowRetentionPolicy() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShown = prefs.getBool('shown_retention_policy_notice') ?? false;

    if (!hasShown && mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (ctx) => AlertDialog(
              title: Row(
                children: [
                  Icon(
                    LucideIcons.shieldAlert,
                    color: Theme.of(ctx).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Chính sách lưu trữ',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
              content: const Text(
                'Để giữ ứng dụng nhanh và mượt mà:\n\n'
                '• Giao dịch > 1 năm sẽ được ẩn khỏi màn hình chính.\n'
                '• Giao dịch > 2 năm sẽ bị xóa vĩnh viễn.\n\n'
                'Hãy vào Cài đặt > Kết nối Google Drive để tự động sao lưu dữ liệu nhé!',
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Đã hiểu'),
                ),
              ],
            ),
      );
      await prefs.setBool('shown_retention_policy_notice', true);
    }
  }

  static const _screens = [
    TransactionsScreen(),
    HomeScreen(),
    SettingsScreen(),
  ];

  bool get _showFab => _index == 0 || _index == 1;

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
            data:
                isFancy
                    ? Theme.of(context).copyWith(
                      scaffoldBackgroundColor: Colors.transparent,
                      canvasColor: Colors.transparent,
                    )
                    : Theme.of(context),
            child: IndexedStack(index: _index, children: _screens),
          ),
        ],
      ),
      bottomNavigationBar:
          isFancy
              ? _FancySpendoNavBar(selectedIndex: _index, onTap: _selectTab)
              : _SpendoNavBar(selectedIndex: _index, onTap: _selectTab),
      floatingActionButton:
          _showFab
              ? isFancy
                  ? PressableScale(
                    deferTapToChild: true,
                    child: GlassButton(
                      key: const Key('spendo_fab_add_transaction'),
                      icon: const Icon(Icons.add),
                      iconSize: 28,
                      useOwnLayer: true,
                      quality: GlassQuality.premium,
                      width: 56,
                      height: 56,
                      onTap: _showAddTransactionSheet,
                    ),
                  )
                  : PressableScale(
                    deferTapToChild: true,
                    child: FloatingActionButton(
                      key: const Key('spendo_fab_add_transaction'),
                      heroTag: 'global_fab',
                      onPressed: _showAddTransactionSheet,
                      shape: const CircleBorder(),
                      child: const Icon(Icons.add, size: 28),
                    ),
                  )
              : null,
    );
  }

  void _showAddTransactionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddTransactionSheet(),
    );
  }

  void _selectTab(int i) {
    HapticFeedback.lightImpact();
    setState(() => _index = i);
  }
}

class _SpendoNavBar extends StatelessWidget {
  const _SpendoNavBar({required this.selectedIndex, required this.onTap});

  final int selectedIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    _NavItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long,
      label: 'Giao dịch',
    ),
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Trang chủ',
    ),
    _NavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Cài đặt',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 80,
          child: Row(
            children: List.generate(_items.length, (i) {
              return Expanded(
                child: _NavButton(
                  key: ValueKey('spendo_tab_$i'),
                  item: _items[i],
                  selected: selectedIndex == i,
                  onTap: () => onTap(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _FancySpendoNavBar extends StatelessWidget {
  const _FancySpendoNavBar({required this.selectedIndex, required this.onTap});

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GlassTabBar.bottom(
      selectedIndex: selectedIndex,
      onTabSelected: onTap,
      quality: GlassQuality.premium,
      horizontalPadding: 18,
      verticalPadding: 16,
      barHeight: 64,
      selectedIconColor: cs.primary,
      selectedLabelColor: cs.primary,
      unselectedIconColor: cs.onSurfaceVariant,
      unselectedLabelColor: cs.onSurfaceVariant,
      tabs: const [
        GlassTab(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long),
          label: 'Giao dịch',
        ),
        GlassTab(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Trang chủ',
        ),
        GlassTab(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings),
          label: 'Cài đặt',
        ),
      ],
    );
  }
}

class _NavButton extends StatefulWidget {
  const _NavButton({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _iconScale;
  late final Animation<double> _textOpacity;
  late final Animation<double> _textSlide;
  late final Animation<double> _pillHeight;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _iconScale = Tween<double>(
      begin: 1.0,
      end: 1.22,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _textSlide = Tween<double>(begin: 6.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _pillHeight = Tween<double>(
      begin: 44.0,
      end: 62.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    if (widget.selected) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(_NavButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      if (widget.selected) {
        _ctrl.forward();
      } else {
        _ctrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primaryColor = cs.primary;
    final mutedColor = cs.onSurfaceVariant;
    final pillColor = cs.primaryContainer;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final color = Color.lerp(mutedColor, primaryColor, _ctrl.value)!;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              width: 90,
              height: _pillHeight.value,
              decoration: BoxDecoration(
                color: widget.selected ? pillColor : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: _iconScale.value,
                    child: Icon(
                      widget.selected
                          ? widget.item.activeIcon
                          : widget.item.icon,
                      size: 26,
                      color: color,
                    ),
                  ),
                  if (_textOpacity.value > 0.01) ...[
                    const SizedBox(height: 3),
                    Opacity(
                      opacity: _textOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, _textSlide.value),
                        child: Text(
                          widget.item.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color,
                            height: 1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}
