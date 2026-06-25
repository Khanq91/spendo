import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../domain/loan.dart';
import '../providers/loan_provider.dart';

/// ListTile dùng trong SettingsScreen để truy cập /loans.
/// Hiển thị badge đỏ/vàng nếu có khoản quá hạn / sắp hạn.
class LoanSettingsTile extends ConsumerWidget {
  const LoanSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(loanSummaryDataProvider);
    final cs = Theme.of(context).colorScheme;
    final worst = summary.worstStatus;

    Color iconColor = cs.onSurfaceVariant;
    Widget? trailing;

    if (!summary.isEmpty) {
      if (worst == LoanStatus.overdue) {
        iconColor = Colors.red;
        trailing = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            '🔴 Quá hạn',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
        );
      } else if (worst == LoanStatus.upcoming) {
        iconColor = Colors.orange;
        trailing = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            '⚠️ Sắp hạn',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.orange,
            ),
          ),
        );
      } else {
        trailing = Text(
          '${summary.count} khoản',
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        );
      }
    }

    return ListTile(
      leading: Icon(LucideIcons.handCoins, size: 20, color: iconColor),
      title: const Text('Khoản vay', style: TextStyle(fontSize: 14)),
      subtitle: const Text(
        'Theo dõi khoản vay & cho vay',
        style: TextStyle(fontSize: 12),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 18),
      onTap: () => context.push('/loans'),
    );
  }
}
