import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/widgets/spendo/spendo.dart';
import '../../../budget/presentation/providers/category_budget_provider.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../loan/presentation/providers/loan_provider.dart';
import '../../../reminders/presentation/providers/reminder_provider.dart';
import '../../../wallets/presentation/providers/wallet_provider.dart';

/// "Tất cả tính năng" — where Home's "Xem thêm" lands.
///
/// A redesign-era screen of the same name was deleted for repeating the Home
/// shortcut grid one-for-one. This one holds six entries against Home's three,
/// so it is a longer list rather than the same list twice, and it leaves out
/// Giao dịch, Thống kê and Cài đặt because those are permanent tabs.
class FeaturesScreen extends ConsumerWidget {
  const FeaturesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(walletsProvider).valueOrNull;
    final loans = ref.watch(loansProvider).valueOrNull;
    final trackingLoans = ref.watch(trackingLoansProvider).valueOrNull;
    final budgets = ref.watch(categoryBudgetsProvider).valueOrNull;
    final reminders = ref.watch(remindersProvider).valueOrNull;
    final categories = ref.watch(categoriesProvider).valueOrNull;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SpendoScreenHeader(title: 'Tất cả tính năng'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  SpendoSettingsGroup(
                    children: [
                      SpendoSettingsRow(
                        icon: LucideIcons.wallet,
                        label: 'Ví',
                        subtitle: 'Số dư từng nguồn tiền',
                        trailingText: _count(wallets?.length),
                        onTap: () => context.push('/wallets'),
                      ),
                      SpendoSettingsRow(
                        icon: LucideIcons.handCoins,
                        label: 'Khoản vay',
                        subtitle: 'Vay & cho vay, có ghi vào ví',
                        trailingText: _count(loans?.length),
                        onTap: () => context.push('/loans'),
                      ),
                      SpendoSettingsRow(
                        icon: LucideIcons.notebookPen,
                        label: 'Sổ theo dõi',
                        subtitle: 'Ghi nợ, không đụng ví & thống kê',
                        trailingText: _count(trackingLoans?.length),
                        onTap: () => context.push('/loans-tracking'),
                      ),
                      SpendoSettingsRow(
                        icon: LucideIcons.target,
                        label: 'Hạn mức',
                        subtitle: 'Ngân sách theo tháng',
                        trailingText: _count(budgets?.length),
                        onTap: () => context.push('/budget'),
                      ),
                      SpendoSettingsRow(
                        icon: LucideIcons.bellRing,
                        label: 'Nhắc nhở',
                        subtitle: 'Khoản chi lặp lại',
                        trailingText: _count(reminders?.length),
                        onTap: () => context.push('/reminders'),
                      ),
                      SpendoSettingsRow(
                        icon: LucideIcons.tag,
                        label: 'Danh mục',
                        subtitle: 'Nhóm thu chi',
                        trailingText: _count(categories?.length),
                        onTap: () => context.push('/settings/categories'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String? _count(int? value) => value?.toString();
}
