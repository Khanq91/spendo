import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/widgets/motion/motion.dart';

/// The four Home shortcuts: Ví · Vay nợ · Nhắc nhở · Hạn mức.
///
/// Trimmed from eight — Thêm, Giao dịch and Thống kê all had a tab or the FAB
/// already, and "Xem thêm" led to a screen that repeated this grid. The icons
/// wear `secondaryContainer` instead of eight one-off accent colours.
class HomeShortcuts extends StatelessWidget {
  const HomeShortcuts({super.key});

  @override
  Widget build(BuildContext context) {
    final shortcuts = <({String label, IconData icon, VoidCallback onTap})>[
      (
        label: 'Ví',
        icon: LucideIcons.wallet,
        onTap: () => context.push('/wallets'),
      ),
      (
        label: 'Vay nợ',
        icon: LucideIcons.handCoins,
        onTap: () => context.push('/loans'),
      ),
      (
        label: 'Nhắc nhở',
        icon: LucideIcons.bellRing,
        onTap: () => context.push('/reminders'),
      ),
      (
        label: 'Hạn mức',
        icon: LucideIcons.target,
        onTap: () => context.push('/budget'),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Row(
        children: [
          for (final shortcut in shortcuts)
            Expanded(
              child: _Shortcut(
                label: shortcut.label,
                icon: shortcut.icon,
                onTap: shortcut.onTap,
              ),
            ),
        ],
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: label,
      child: PressableScale(
        deferTapToChild: true,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 21, color: cs.onSecondaryContainer),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
