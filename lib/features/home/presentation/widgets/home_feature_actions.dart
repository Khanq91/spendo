import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../budget/presentation/screens/budget_screen.dart';
import '../../../budget/presentation/screens/category_budget_screen.dart';
import '../../../budget/presentation/widgets/budget_type_sheet.dart';
import 'feature_grid.dart';
import '../../../transactions/presentation/widgets/add_transaction_sheet.dart';

class FeatureSection {
  final String title;
  final List<FeatureGridAction> actions;

  const FeatureSection({
    required this.title,
    required this.actions,
  });
}

List<FeatureGridAction> buildHomeFeatureActions(BuildContext context) {
  return [
    FeatureGridAction(
      label: 'Thêm',
      icon: LucideIcons.circlePlus,
      color: const Color(0xFF16A34A),
      onTap: () => showAddTransactionSheet(context),
    ),
    FeatureGridAction(
      label: 'Giao dịch',
      icon: LucideIcons.receiptText,
      color: const Color(0xFF2563EB),
      onTap: () => context.push('/transactions'),
    ),
    FeatureGridAction(
      label: 'Ví',
      icon: LucideIcons.wallet,
      color: const Color(0xFF0EA5E9),
      onTap: () => context.push('/wallets'),
    ),
    FeatureGridAction(
      label: 'Hạn mức',
      icon: LucideIcons.target,
      color: const Color(0xFFF59E0B),
      onTap: () => _showBudgetTypeSheet(context),
    ),
    FeatureGridAction(
      label: 'Vay nợ',
      icon: LucideIcons.handCoins,
      color: const Color(0xFFDC2626),
      onTap: () => context.push('/loans'),
    ),
    FeatureGridAction(
      label: 'Nhắc nhở',
      icon: LucideIcons.bellRing,
      color: const Color(0xFFDB2777),
      onTap: () => context.push('/reminders'),
    ),
    FeatureGridAction(
      label: 'Thống kê',
      icon: LucideIcons.chartPie,
      color: const Color(0xFF7C3AED),
      onTap: () => context.push('/stats'),
    ),
    FeatureGridAction(
      label: 'Xem thêm',
      icon: LucideIcons.ellipsis,
      color: const Color(0xFF7A869A),
      onTap: () => context.push('/features'),
    ),
  ];
}

List<FeatureSection> buildAllFeatureSections(BuildContext context) {
  return [
    FeatureSection(
      title: 'Tài chính',
      actions: [
        FeatureGridAction(
          label: 'Thêm giao dịch',
          icon: LucideIcons.circlePlus,
          color: const Color(0xFF16A34A),
          onTap: () => showAddTransactionSheet(context),
        ),
        FeatureGridAction(
          label: 'Giao dịch',
          icon: LucideIcons.receiptText,
          color: const Color(0xFF2563EB),
          onTap: () => context.push('/transactions'),
        ),
        FeatureGridAction(
          label: 'Ví',
          icon: LucideIcons.wallet,
          color: const Color(0xFF0EA5E9),
          onTap: () => context.push('/wallets'),
        ),
        FeatureGridAction(
          label: 'Hạn mức tháng',
          icon: LucideIcons.calendarDays,
          color: const Color(0xFF8B5CF6),
          onTap: () => _showBudgetSheet(context),
        ),
        FeatureGridAction(
          label: 'Hạn mức danh mục',
          icon: LucideIcons.tags,
          color: const Color(0xFFEC4899),
          onTap: () => _showCategoryBudgetSheet(context),
        ),
      ],
    ),
    FeatureSection(
      title: 'Vay nợ',
      actions: [
        FeatureGridAction(
          label: 'Vay nợ',
          icon: LucideIcons.handCoins,
          color: const Color(0xFFDC2626),
          onTap: () => context.push('/loans'),
        ),
        FeatureGridAction(
          label: 'Đang vay',
          icon: LucideIcons.arrowDownLeft,
          color: const Color(0xFFEA580C),
          onTap: () => context.push('/loans?type=borrowed'),
        ),
        FeatureGridAction(
          label: 'Cho vay',
          icon: LucideIcons.arrowUpRight,
          color: const Color(0xFF0891B2),
          onTap: () => context.push('/loans?type=lent'),
        ),
      ],
    ),
    FeatureSection(
      title: 'Theo dõi',
      actions: [
        FeatureGridAction(
          label: 'Thống kê',
          icon: LucideIcons.chartPie,
          color: const Color(0xFF7C3AED),
          onTap: () => context.push('/stats'),
        ),
        FeatureGridAction(
          label: 'Nhắc nhở',
          icon: LucideIcons.bellRing,
          color: const Color(0xFFDB2777),
          onTap: () => context.push('/reminders'),
        ),
        FeatureGridAction(
          label: 'Widget',
          icon: LucideIcons.smartphone,
          color: const Color(0xFF475569),
          onTap: () => context.push('/settings'),
        ),
      ],
    ),
    FeatureSection(
      title: 'Tiện ích & cài đặt',
      actions: [
        FeatureGridAction(
          label: 'Cài đặt',
          icon: LucideIcons.settings,
          color: const Color(0xFF64748B),
          onTap: () => context.push('/settings'),
        ),
        FeatureGridAction(
          label: 'Backup',
          icon: LucideIcons.hardDriveDownload,
          color: const Color(0xFF6C63FF),
          onTap: () => context.push('/settings'),
        ),
        FeatureGridAction(
          label: 'Google Drive',
          icon: LucideIcons.cloud,
          color: const Color(0xFF0284C7),
          onTap: () => context.push('/settings'),
        ),
        FeatureGridAction(
          label: 'Ngân hàng',
          icon: LucideIcons.landmark,
          color: const Color(0xFF0F766E),
          onTap: () => context.push('/settings'),
        ),
        FeatureGridAction(
          label: 'Giao diện',
          icon: LucideIcons.palette,
          color: const Color(0xFF9333EA),
          onTap: () => context.push('/settings'),
        ),
        FeatureGridAction(
          label: 'Danh mục',
          icon: LucideIcons.tag,
          color: const Color(0xFFCA8A04),
          onTap: () => context.push('/settings'),
        ),
        FeatureGridAction(
          label: 'Xuất báo cáo',
          icon: LucideIcons.fileDown,
          color: const Color(0xFF059669),
          onTap: () => context.push('/settings'),
        ),
      ],
    ),
  ];
}

void _showBudgetTypeSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const BudgetTypeSheet(),
  );
}

void _showBudgetSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const BudgetScreen(),
  );
}

void _showCategoryBudgetSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const CategoryBudgetScreen(),
  );
}
