import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/widgets/motion/motion.dart';

/// The Home shortcuts: three destinations Home does not already show, plus
/// "Xem thêm" for the rest.
///
/// Down from eight, then re-cut. Thêm, Giao dịch and Thống kê went first —
/// each already has a tab or the FAB. Ví and Hạn mức followed: `home_wallet_strip`
/// and `home_budget_card` sit further down this very screen and lead to the
/// same places, so a shortcut to them repeated a door the user could already
/// see. What is left is what Home shows no other way.
///
/// "Xem thêm" is back, but not as it was: the screen it opens (`/features`)
/// lists six entries against these three, so it is the longer list rather than
/// this row again — which is what got the old one deleted. Do not "restore"
/// this to four flat destinations.
class HomeShortcuts extends StatelessWidget {
  const HomeShortcuts({super.key});

  @override
  Widget build(BuildContext context) {
    final shortcuts = <({String label, IconData icon, VoidCallback onTap})>[
      (
        label: 'Vay nợ',
        icon: LucideIcons.handCoins,
        onTap: () => context.push('/loans'),
      ),
      (
        label: 'Sổ theo dõi',
        icon: LucideIcons.notebookPen,
        onTap: () => context.push('/loans-tracking'),
      ),
      (
        label: 'Nhắc nhở',
        icon: LucideIcons.bellRing,
        onTap: () => context.push('/reminders'),
      ),
      (
        label: 'Xem thêm',
        icon: LucideIcons.layoutGrid,
        onTap: () => context.push('/features'),
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
