import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/spendo_colors.dart';
import '../../../../shared/widgets/spendo/spendo.dart';
import '../../domain/sepay_bank_account.dart';
import '../providers/sepay_provider.dart';
import '../widgets/sepay_mapping_sheet.dart';

const _sepayDashboardUrl = 'https://my.sepay.vn';

/// Screen 22 of the redesign — `/settings/bank`.
///
/// SePay was a section inside the Settings list carrying its own accent blue
/// and its own form style (`28-sepay-add-mapping-sheet.md` §L). It gets a page
/// and the shared form tokens.
class BankScreen extends ConsumerWidget {
  const BankScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(sepayAccountsProvider);
    final accounts = accountsAsync.valueOrNull ?? const <SepayBankAccount>[];

    return Scaffold(
      floatingActionButton: SpendoExtendedFab(
        heroTag: 'bank_fab',
        label: 'Thêm tài khoản',
        onPressed: () => showSepayMappingSheet(context),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SpendoScreenHeader(title: 'Ngân hàng tự động'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 120),
                children: [
                  const _SepayCard(),
                  if (accountsAsync.hasError && !accountsAsync.hasValue)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: SpendoEmptyState(
                        icon: LucideIcons.circleAlert,
                        title: 'Không tải được tài khoản',
                        message: 'Kiểm tra kết nối rồi thử lại.',
                        actionLabel: 'Thử lại',
                        onAction: () => ref.invalidate(sepayAccountsProvider),
                      ),
                    )
                  else if (accountsAsync.isLoading && !accountsAsync.hasValue)
                    const Padding(
                      padding: EdgeInsets.only(top: 32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (accounts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: SpendoEmptyState(
                        icon: LucideIcons.landmark,
                        title: 'Chưa liên kết tài khoản nào',
                        message:
                            'Kết nối ngân hàng trên SePay trước, rồi thêm tài '
                            'khoản ở đây để giao dịch tự đồng bộ.',
                        actionLabel: 'Thêm tài khoản',
                        onAction: () => showSepayMappingSheet(context),
                      ),
                    )
                  else ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                      child: SpendoSectionHeader(
                        label: 'TÀI KHOẢN ĐÃ LIÊN KẾT (${accounts.length})',
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SpendoSettingsGroup(
                        children: [
                          for (final account in accounts)
                            _AccountRow(account: account),
                        ],
                      ),
                    ),
                  ],
                  const _Hint(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── SePay dashboard card ─────────────────────────────────────────────────────

class _SepayCard extends StatelessWidget {
  const _SepayCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SpendoCard(
        feature: true,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            SpendoIconTile(
              icon: LucideIcons.landmark,
              color: cs.primary,
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'SePay',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Giao dịch ngân hàng tự động vào Spendo',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SpendoButton.outline(
              label: 'Mở SePay',
              icon: LucideIcons.externalLink,
              onPressed: () => _openDashboard(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDashboard(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.parse(_sepayDashboardUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Không mở được trình duyệt')),
      );
    }
  }
}

// ── One linked account ───────────────────────────────────────────────────────

class _AccountRow extends ConsumerWidget {
  const _AccountRow({required this.account});

  final SepayBankAccount account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return SpendoSettingsRow(
      icon: LucideIcons.landmark,
      label: account.displayName,
      subtitle: account.isActive ? 'Đang đồng bộ' : 'Tạm dừng',
      subtitleColor: account.isActive
          ? theme.spendo.income
          : theme.colorScheme.onSurfaceVariant,
      showChevron: false,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: account.isActive,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (value) => ref
                .read(sepayAccountsProvider.notifier)
                .toggleActive(account.id, value),
          ),
          SpendoHeaderIconButton(
            icon: LucideIcons.trash2,
            tooltip: 'Xoá kết nối',
            size: 18,
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá kết nối?'),
        content: Text(
          'Xoá "${account.displayName}"?\n\n'
          'Giao dịch đã nhập không bị ảnh hưởng. Chỉ dừng tự động đồng bộ từ '
          'tài khoản này.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(sepayAccountsProvider.notifier).removeMapping(account.id);
    }
  }
}

class _Hint extends StatelessWidget {
  const _Hint();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SpendoCard(
        color: cs.surfaceContainerLowest,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Text(
          'Kết nối ngân hàng trên SePay trước, sau đó thêm tài khoản ở đây để '
          'giao dịch tự đồng bộ. Giao dịch tự động mang badge "Tự động".',
          style: TextStyle(
            fontSize: 12,
            height: 1.5,
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
