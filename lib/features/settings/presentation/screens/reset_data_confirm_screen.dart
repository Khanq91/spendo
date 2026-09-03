import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/services/reset_data_service.dart';
import '../../../../core/utils/backup_service.dart';
import '../../../../shared/widgets/app_restart.dart';
import '../../../../shared/widgets/notice/notice.dart';
import '../../../../shared/widgets/spendo/spendo.dart';
import '../providers/gdrive_provider.dart';
import '../widgets/hold_to_delete_button.dart';

/// `/settings/reset/confirm` — the last screen before the data reset.
///
/// Lists what is about to go, with the live counts, offers a backup export,
/// and commits through [HoldToDeleteButton]: 10s countdown, then a 3s hold.
class ResetDataConfirmScreen extends ConsumerStatefulWidget {
  const ResetDataConfirmScreen({
    super.key,
    this.service,
    this.loadSummary,
    this.onCompleted,
  });

  /// Test seams. In the app the service signs out of Drive through the
  /// settings provider and completion restarts the app on the welcome pages.
  final ResetDataService? service;
  final Future<ResetDataSummary> Function()? loadSummary;
  final void Function(BuildContext context)? onCompleted;

  static const String title = 'Xác nhận đặt lại';

  @override
  ConsumerState<ResetDataConfirmScreen> createState() =>
      _ResetDataConfirmScreenState();
}

class _ResetDataConfirmScreenState
    extends ConsumerState<ResetDataConfirmScreen> {
  late final Future<ResetDataSummary> _summary =
      (widget.loadSummary ?? ResetDataService.summarize)();
  bool _busy = false;

  Future<void> _export() async {
    try {
      await BackupService.exportBackup();
    } catch (e) {
      AppNotice.error('Không xuất được bản sao lưu: $e');
    }
  }

  Future<void> _reset() async {
    setState(() => _busy = true);
    final service =
        widget.service ??
        ResetDataService(
          signOutDrive: () => ref.read(gdriveProvider.notifier).signOut(),
        );
    try {
      await service.run();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppNotice.error('Không đặt lại được dữ liệu: $e');
      return;
    }
    if (!mounted) return;
    (widget.onCompleted ?? _restartApp)(context);
  }

  /// Parks the router on Home so the routed app comes back there, then
  /// rebuilds the whole tree as a first launch.
  static void _restartApp(BuildContext context) {
    appRouter.go('/');
    AppRestart.restart(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SpendoScreenHeader(title: ResetDataConfirmScreen.title),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  children: [
                    const SpendoSectionHeader(
                      label: 'NHỮNG GÌ SẼ MẤT',
                      padding: EdgeInsets.fromLTRB(0, 8, 0, 6),
                    ),
                    FutureBuilder<ResetDataSummary>(
                      future: _summary,
                      builder: (context, snapshot) =>
                          _LossList(summary: snapshot.data),
                    ),
                    const SizedBox(height: 16),
                    SpendoCard(
                      color: cs.surfaceContainerLowest,
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      child: Text(
                        'Bản sao lưu trên Google Drive không bị xóa. Android '
                        'cũng có thể giữ một bản sao lưu hệ thống và tự khôi '
                        'phục khi cài lại app; muốn xóa hẳn, tắt "Sao lưu dữ '
                        'liệu ứng dụng" trong cài đặt máy.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SpendoButton.outline(
                      label: 'Xuất bản sao lưu trước',
                      icon: LucideIcons.download,
                      expand: true,
                      onPressed: _busy ? null : _export,
                    ),
                  ],
                ),
              ),
              _Footer(
                bottomInset: bottomInset,
                busy: _busy,
                onCancel: _busy ? null : () => context.pop(),
                onConfirm: _reset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LossList extends StatelessWidget {
  const _LossList({required this.summary});

  final ResetDataSummary? summary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    String count(int Function(ResetDataSummary s) pick) =>
        summary == null ? '…' : pick(summary!).toString();

    return SpendoSettingsGroup(
      children: [
        SpendoSettingsRow(
          icon: LucideIcons.notebookText,
          label: 'Giao dịch',
          trailingText: count((s) => s.transactions),
          showChevron: false,
        ),
        SpendoSettingsRow(
          icon: LucideIcons.wallet,
          label: 'Nguồn tiền',
          trailingText: count((s) => s.wallets),
          showChevron: false,
        ),
        SpendoSettingsRow(
          icon: LucideIcons.handCoins,
          label: 'Khoản vay & sổ theo dõi',
          trailingText: count((s) => s.loans),
          showChevron: false,
        ),
        SpendoSettingsRow(
          icon: LucideIcons.bellRing,
          label: 'Nhắc nhở',
          trailingText: count((s) => s.reminders),
          showChevron: false,
        ),
        SpendoSettingsRow(
          icon: LucideIcons.tag,
          label: 'Danh mục tự tạo',
          trailingText: count((s) => s.customCategories),
          showChevron: false,
        ),
        SpendoSettingsRow(
          icon: LucideIcons.piggyBank,
          label: 'Ngân sách',
          trailingText: count((s) => s.budgets),
          showChevron: false,
        ),
        const SpendoSettingsRow(
          icon: LucideIcons.settings2,
          label: 'Cài đặt giao diện, thông báo, widget',
          showChevron: false,
        ),
        SpendoSettingsRow(
          icon: LucideIcons.cloud,
          label: 'Đăng nhập Google Drive',
          subtitle: 'File sao lưu trên Drive được giữ nguyên',
          subtitleColor: cs.onSurfaceVariant,
          showChevron: false,
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.bottomInset,
    required this.busy,
    required this.onCancel,
    required this.onConfirm,
  });

  final double bottomInset;
  final bool busy;
  final VoidCallback? onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: SpendoButton.secondary(
                  label: 'Hủy',
                  expand: true,
                  onPressed: onCancel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: HoldToDeleteButton(onConfirm: onConfirm, busy: busy),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Nút XÓA mở sau 10 giây. Giữ 3 giây để xóa, không thể hoàn tác.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
