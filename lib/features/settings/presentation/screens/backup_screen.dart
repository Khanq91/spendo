import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/services/gdrive_backup_service.dart';
import '../../../../core/services/restore_followup.dart';
import '../../../../core/theme/spendo_colors.dart';
import '../../../../core/utils/backup_service.dart';
import '../../../../core/utils/export_service.dart';
import '../../../../shared/widgets/notice/notice.dart';
import '../../../../shared/widgets/spendo/spendo.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/sign_in_sheet.dart';
import '../../../budget/presentation/providers/category_budget_provider.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../loan/presentation/providers/loan_provider.dart';
import '../../../reminders/presentation/providers/reminder_provider.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../wallets/presentation/providers/wallet_provider.dart';
import '../providers/gdrive_provider.dart';

/// Screen 21 of the redesign — `/settings/backup`.
///
/// Drive, JSON backup and CSV export were three separate Settings sections,
/// and a restore ran through three full-screen loading dialogs with no
/// background (`20-settings.md` §L). One page, one status card, and a single
/// inline progress strip for every long operation.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  /// What is running right now, shown in the inline progress strip. Null when
  /// the page is idle.
  String? _busyLabel;

  bool get _busy => _busyLabel != null;

  void _setBusy(String? label) {
    if (mounted) setState(() => _busyLabel = label);
  }

  @override
  Widget build(BuildContext context) {
    final drive = ref.watch(gdriveProvider);

    ref.listen<GDriveState>(gdriveProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        _snack(next.error!);
      }
      if (next.successMessage != null &&
          next.successMessage != prev?.successMessage) {
        _snack(next.successMessage!, kind: NoticeKind.success);
      }
    });

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SpendoScreenHeader(title: 'Sao lưu & đồng bộ'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  _StatusCard(state: drive),
                  const _Label('GOOGLE DRIVE'),
                  _driveGroup(drive),
                  // The Spendo account only exists with the cloud switched
                  // on; off, the page is Drive and local files, as before.
                  if (ref.watch(cloudEnabledProvider)) ...[
                    const _Label('TÀI KHOẢN SPENDO'),
                    _accountGroup(ref.watch(authUserProvider).valueOrNull),
                  ],
                  const _Label('FILE CỤC BỘ & BÁO CÁO'),
                  _localGroup(),
                  if (_busy)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: _ProgressStrip(label: _busyLabel!),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Spendo account (cloud flag) ────────────────────────────────────────────

  Widget _accountGroup(SpendoAccount? user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SpendoSettingsGroup(
        children: [
          if (user == null)
            SpendoSettingsRow(
              icon: LucideIcons.userRound,
              label: 'Đăng nhập tài khoản Spendo',
              subtitle: 'Đồng bộ giữa các máy · mở liên kết ngân hàng',
              enabled: !_busy,
              onTap: () => showSignInSheet(context),
            )
          else
            SpendoSettingsRow(
              icon: LucideIcons.userRoundCheck,
              label: user.email ?? 'Đã đăng nhập',
              subtitle: 'Đang đồng bộ đám mây',
              enabled: !_busy,
              showChevron: false,
              trailing: SpendoHeaderIconButton(
                icon: LucideIcons.logOut,
                tooltip: 'Đăng xuất',
                onPressed: _busy ? () {} : _confirmAccountSignOut,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmAccountSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất tài khoản Spendo?'),
        // The local database is not scoped per account (audit SEC-001): the
        // rows stay on the device, and sync simply stops.
        content: const Text(
          'Dữ liệu trên máy vẫn còn, chỉ dừng đồng bộ đám mây và liên kết '
          'ngân hàng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(authActionsProvider).signOut();
      _snack('Đã đăng xuất.', kind: NoticeKind.info);
    } catch (error) {
      _snack('Không đăng xuất được: ${authErrorMessage(error)}');
    }
  }

  // ── Drive ──────────────────────────────────────────────────────────────────

  Widget _driveGroup(GDriveState drive) {
    final cs = Theme.of(context).colorScheme;
    final blocked = _busy || drive.isLoading;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SpendoSettingsGroup(
        children: drive.isSignedIn
            ? [
                SpendoSettingsRow(
                  icon: LucideIcons.cloudCheck,
                  label: drive.email ?? 'Đã kết nối Google Drive',
                  subtitle: 'Đã kết nối',
                  enabled: !blocked,
                  showChevron: false,
                  trailing: SpendoHeaderIconButton(
                    icon: LucideIcons.logOut,
                    tooltip: 'Ngắt kết nối',
                    onPressed: blocked ? () {} : _confirmSignOut,
                  ),
                ),
                SpendoSettingsRow(
                  icon: LucideIcons.calendarClock,
                  label: 'Tự động sao lưu',
                  enabled: !blocked,
                  showChevron: false,
                  trailing: SpendoChip.meta(
                    label: drive.frequency.label,
                    icon: LucideIcons.chevronDown,
                    onTap: blocked ? null : _pickFrequency,
                  ),
                ),
                SpendoSettingsRow(
                  icon: LucideIcons.uploadCloud,
                  label: 'Sao lưu ngay',
                  enabled: !blocked,
                  showChevron: false,
                  onTap: _backupNow,
                ),
                SpendoSettingsRow(
                  icon: LucideIcons.downloadCloud,
                  label: 'Khôi phục từ Drive',
                  enabled: !blocked,
                  onTap: _restoreFromDrive,
                ),
              ]
            : [
                SpendoSettingsRow(
                  icon: LucideIcons.cloud,
                  label: 'Kết nối Google Drive',
                  subtitle: 'Đăng nhập để tự động sao lưu dữ liệu',
                  enabled: !blocked,
                  trailing: drive.isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.primary,
                          ),
                        )
                      : null,
                  onTap: () => ref.read(gdriveProvider.notifier).signIn(),
                ),
              ],
      ),
    );
  }

  // ── Local files ────────────────────────────────────────────────────────────

  Widget _localGroup() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SpendoSettingsGroup(
        children: [
          SpendoSettingsRow(
            icon: LucideIcons.hardDriveDownload,
            label: 'Xuất backup JSON',
            subtitle: 'Toàn bộ dữ liệu, khôi phục được',
            enabled: !_busy,
            onTap: _exportBackup,
          ),
          SpendoSettingsRow(
            icon: LucideIcons.hardDriveUpload,
            label: 'Nhập từ file backup',
            subtitle: 'Xem trước rồi mới khôi phục',
            enabled: !_busy,
            onTap: _restoreFromFile,
          ),
          SpendoSettingsRow(
            icon: LucideIcons.fileSpreadsheet,
            label: 'Xuất báo cáo CSV',
            subtitle: 'Tháng này · 3 tháng · Tất cả',
            enabled: !_busy,
            onTap: _pickExportRange,
          ),
        ],
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  /// Most of what this page reports is a failure, so that is the default.
  void _snack(String message, {NoticeKind kind = NoticeKind.error}) {
    if (!mounted) return;
    AppNotice.show(message, kind: kind);
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ngắt kết nối Google Drive?'),
        content: const Text(
          'Dữ liệu trên thiết bị không bị xoá, nhưng sao lưu tự động sẽ tắt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ngắt kết nối'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(gdriveProvider.notifier).signOut();
    }
  }

  Future<void> _pickFrequency() async {
    final current = ref.read(gdriveProvider).frequency;
    final picked = await SpendoSheet.showModal<BackupFrequency>(
      context: context,
      builder: (sheetContext) => SpendoSheet(
        header: const SpendoSheetHeader(title: 'Tự động sao lưu'),
        child: SpendoSettingsGroup(
          children: [
            for (final freq in BackupFrequency.values)
              SpendoSettingsRow(
                icon: freq == BackupFrequency.none
                    ? LucideIcons.cloudOff
                    : LucideIcons.calendarClock,
                label: freq.label,
                showChevron: false,
                trailing: freq == current
                    ? Icon(
                        LucideIcons.check,
                        size: 18,
                        color: Theme.of(sheetContext).colorScheme.primary,
                      )
                    : null,
                onTap: () => Navigator.pop(sheetContext, freq),
              ),
          ],
        ),
      ),
    );

    if (picked != null && picked != current) {
      await ref.read(gdriveProvider.notifier).setFrequency(picked);
    }
  }

  Future<void> _backupNow() async {
    _setBusy('Đang sao lưu lên Drive…');
    await ref.read(gdriveProvider.notifier).backupNow();
    _setBusy(null);
  }

  Future<void> _restoreFromDrive() async {
    _setBusy('Đang tải danh sách bản sao lưu…');
    final List<DriveBackupInfo> backups;
    try {
      backups = await ref.read(gdriveProvider.notifier).listBackups();
    } catch (error) {
      _setBusy(null);
      _snack('Lỗi tải danh sách: $error');
      return;
    }
    _setBusy(null);

    if (!mounted) return;
    if (backups.isEmpty) {
      _snack('Không tìm thấy bản sao lưu nào trên Drive.');
      return;
    }

    final chosen = await SpendoSheet.showModal<DriveBackupInfo>(
      context: context,
      builder: (sheetContext) => SpendoSheet(
        header: const SpendoSheetHeader(title: 'Chọn bản sao lưu'),
        child: SpendoSettingsGroup(
          children: [
            for (final backup in backups)
              SpendoSettingsRow(
                icon: LucideIcons.fileClock,
                label: backup.createdTime != null
                    ? DateFormat(
                        'dd/MM/yyyy HH:mm',
                      ).format(backup.createdTime!)
                    : 'Không rõ ngày',
                subtitle: backup.sizeBytes != null
                    ? '${(backup.sizeBytes! / 1024).toStringAsFixed(1)} KB'
                    : null,
                onTap: () => Navigator.pop(sheetContext, backup),
              ),
          ],
        ),
      ),
    );

    if (chosen == null || !mounted) return;

    _setBusy('Đang đọc bản sao lưu…');
    final RestoreResult preview;
    try {
      preview = await GDriveBackupService.instance.previewRestoreFromDrive(
        chosen.fileId,
      );
    } catch (error) {
      _setBusy(null);
      _snack('Lỗi khôi phục: $error');
      return;
    }
    _setBusy(null);

    if (!mounted) return;
    final confirmed = await _confirmRestore(preview);
    if (confirmed != true || !mounted) return;

    _setBusy('Đang khôi phục từ Drive…');
    try {
      final result = await GDriveBackupService.instance.restoreFromDrive(
        chosen.fileId,
      );
      _setBusy(null);
      await _refreshData();
      _snack(_restoredMessage(result), kind: NoticeKind.success);
    } catch (error) {
      _setBusy(null);
      _snack('Lỗi khôi phục: $error');
    }
  }

  Future<void> _exportBackup() async {
    _setBusy('Đang xuất backup…');
    try {
      final result = await BackupService.exportBackup();
      _setBusy(null);
      final parts = <String>[
        '${result.transactions} giao dịch',
        '${result.categories} danh mục',
        if (result.reminders > 0) '${result.reminders} nhắc nhở',
        if (result.categoryBudgets > 0) '${result.categoryBudgets} hạn mức',
        if (result.monthlyBudgets > 0)
          '${result.monthlyBudgets} ngân sách tháng',
        if (result.wallets > 0) '${result.wallets} nguồn tiền',
        if (result.loans > 0) '${result.loans} khoản vay',
        if (result.loanPayments > 0) '${result.loanPayments} lần thanh toán',
        if (result.loanInstallments > 0)
          '${result.loanInstallments} đợt trả góp',
      ];
      _snack('Đã xuất ${parts.join(', ')}', kind: NoticeKind.success);
    } catch (error) {
      _setBusy(null);
      _snack('Lỗi xuất backup: $error');
    }
  }

  Future<void> _restoreFromFile() async {
    final String? filePath;
    try {
      filePath = await BackupService.pickBackupFile();
    } catch (error) {
      _snack('Không đọc được file: $error');
      return;
    }
    if (filePath == null || !mounted) return;

    _setBusy('Đang đọc file backup…');
    final RestoreResult preview;
    try {
      preview = await BackupService.previewRestore(filePath);
    } catch (error) {
      _setBusy(null);
      _snack('Lỗi khôi phục: $error');
      return;
    }
    _setBusy(null);

    if (!mounted) return;
    if (!_hasAnything(preview) && preview.errors.isNotEmpty) {
      _snack(preview.errors.first);
      return;
    }

    final confirmed = await _confirmRestore(preview);
    if (confirmed != true || !mounted) return;

    _setBusy('Đang khôi phục…');
    try {
      final result = await BackupService.restore(filePath);
      _setBusy(null);
      await _refreshData();
      _snack(_restoredMessage(result), kind: NoticeKind.success);
    } catch (error) {
      _setBusy(null);
      _snack('Lỗi khôi phục: $error');
    }
  }

  Future<void> _pickExportRange() async {
    final range = await SpendoSheet.showModal<ExportRange>(
      context: context,
      builder: (sheetContext) => SpendoSheet(
        header: const SpendoSheetHeader(title: 'Xuất báo cáo CSV'),
        child: SpendoSettingsGroup(
          children: [
            SpendoSettingsRow(
              icon: LucideIcons.calendarDays,
              label: 'Tháng này',
              subtitle: 'Giao dịch tháng hiện tại',
              onTap: () => Navigator.pop(sheetContext, ExportRange.thisMonth),
            ),
            SpendoSettingsRow(
              icon: LucideIcons.calendarRange,
              label: '3 tháng gần đây',
              subtitle: 'Giao dịch 3 tháng gần nhất',
              onTap: () => Navigator.pop(sheetContext, ExportRange.threeMonths),
            ),
            SpendoSettingsRow(
              icon: LucideIcons.database,
              label: 'Tất cả',
              subtitle: 'Toàn bộ lịch sử giao dịch',
              onTap: () => Navigator.pop(sheetContext, ExportRange.all),
            ),
          ],
        ),
      ),
    );

    if (range == null || !mounted) return;

    _setBusy('Đang tạo file CSV…');
    try {
      await ExportService.exportCSV(range);
      _setBusy(null);
      _snack('Đã tạo file CSV.', kind: NoticeKind.success);
    } catch (error) {
      _setBusy(null);
      _snack('Lỗi xuất file: $error');
    }
  }

  Future<bool?> _confirmRestore(RestoreResult preview) {
    return SpendoSheet.showModal<bool>(
      context: context,
      builder: (sheetContext) => _RestorePreviewSheet(preview: preview),
    );
  }

  /// Everything a restore has to re-derive: the streams the pages watch, and
  /// — until now missing — the alarms and the widget, which only got rebuilt
  /// on the next cold start.
  Future<void> _refreshData() async {
    ref.invalidate(transactionsProvider);
    ref.invalidate(categoriesProvider);
    ref.invalidate(walletsProvider);
    ref.invalidate(loansProvider);
    ref.invalidate(remindersProvider);
    ref.invalidate(categoryBudgetsProvider);
    await runRestoreFollowUp();
  }

  String _restoredMessage(RestoreResult result) {
    final added = <String>[
      if (result.transactionsAdded > 0) '${result.transactionsAdded} giao dịch',
      if (result.categoriesAdded > 0) '${result.categoriesAdded} danh mục',
      if (result.remindersAdded > 0) '${result.remindersAdded} nhắc nhở',
      if (result.budgetsAdded > 0) '${result.budgetsAdded} hạn mức',
      if (result.walletsAdded > 0) '${result.walletsAdded} nguồn tiền',
      if (result.monthlyBudgetsAdded > 0)
        '${result.monthlyBudgetsAdded} ngân sách tháng',
      if (result.loansAdded > 0) '${result.loansAdded} khoản vay',
      if (result.loanPaymentsAdded > 0)
        '${result.loanPaymentsAdded} lần thanh toán',
      if (result.loanInstallmentsAdded > 0)
        '${result.loanInstallmentsAdded} đợt trả góp',
    ];
    final skipped = _skippedCount(result);
    if (added.isEmpty) return 'Không có gì mới để khôi phục';
    return 'Đã khôi phục ${added.join(', ')}'
        '${skipped > 0 ? ' · bỏ qua $skipped trùng' : ''}';
  }
}

bool _hasAnything(RestoreResult r) =>
    r.categoriesAdded > 0 ||
    r.transactionsAdded > 0 ||
    r.remindersAdded > 0 ||
    r.budgetsAdded > 0 ||
    r.walletsAdded > 0 ||
    r.monthlyBudgetsAdded > 0 ||
    r.loansAdded > 0 ||
    r.loanPaymentsAdded > 0 ||
    r.loanInstallmentsAdded > 0;

int _skippedCount(RestoreResult r) =>
    r.transactionsSkipped +
    r.categoriesSkipped +
    r.remindersSkipped +
    r.budgetsSkipped +
    r.walletsSkipped +
    r.monthlyBudgetsSkipped +
    r.loansSkipped +
    r.loanPaymentsSkipped +
    r.loanInstallmentsSkipped;

// ── Status card ──────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state});

  final GDriveState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final safe = state.isSignedIn && state.lastBackupTime != null;

    final title = switch ((state.isSignedIn, state.lastBackupTime)) {
      (true, final DateTime _) => 'Đã sao lưu an toàn',
      (true, _) => 'Chưa có bản sao lưu nào',
      _ => 'Chưa bật sao lưu',
    };
    final detail = switch ((state.isSignedIn, state.lastBackupTime)) {
      (true, final DateTime at) =>
        'Lần cuối: ${_relative(at)} · Google Drive',
      (true, _) => 'Chạy "Sao lưu ngay" để tạo bản đầu tiên',
      _ => 'Kết nối Google Drive hoặc xuất file backup thủ công',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SpendoCard(
        feature: true,
        color: safe ? cs.secondaryContainer : cs.surfaceContainer,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            SpendoIconTile(
              icon: safe ? LucideIcons.shieldCheck : LucideIcons.shieldAlert,
              color: safe ? theme.spendo.income : theme.spendo.warning,
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: safe ? cs.onSecondaryContainer : cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    detail,
                    style: TextStyle(
                      fontSize: 12,
                      color: safe
                          ? cs.onSecondaryContainer
                          : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _relative(DateTime at) {
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return DateFormat('dd/MM/yyyy, HH:mm').format(at);
  }
}

// ── Inline progress ──────────────────────────────────────────────────────────

/// The one progress pattern on this page, replacing the three bare
/// full-screen loading dialogs a restore used to stack up.
class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SpendoCard(
      color: cs.surfaceContainerLowest,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 4,
              backgroundColor: cs.surfaceContainerHighest,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Restore preview ──────────────────────────────────────────────────────────

class _RestorePreviewSheet extends StatelessWidget {
  const _RestorePreviewSheet({required this.preview});

  final RestoreResult preview;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasAnything = _hasAnything(preview);
    final skipped = _skippedCount(preview);

    return SpendoSheet(
      header: SpendoSheetHeader(
        title: 'Xác nhận khôi phục',
        onCancel: () => Navigator.pop(context, false),
        action: SpendoButton(
          label: 'Khôi phục',
          onPressed: hasAnything ? () => Navigator.pop(context, true) : null,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!hasAnything)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Text(
                'Tất cả dữ liệu trong backup đã tồn tại trên thiết bị này.',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            )
          else ...[
            const SizedBox(height: 4),
            for (final row in _rows)
              if (row.count(preview) > 0)
                _PreviewRow(
                  icon: row.icon,
                  text: '${row.count(preview)} ${row.label} sẽ được thêm',
                ),
          ],
          if (skipped > 0)
            _PreviewRow(
              icon: LucideIcons.circleArrowRight,
              text: '$skipped mục đã tồn tại → bỏ qua',
              muted: true,
            ),
          if (preview.errors.isNotEmpty)
            _PreviewRow(
              icon: LucideIcons.triangleAlert,
              text: '${preview.errors.length} mục bị lỗi (sẽ bỏ qua)',
              muted: true,
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  static final _rows = <({IconData icon, String label, int Function(RestoreResult) count})>[
    (
      icon: LucideIcons.receiptText,
      label: 'giao dịch',
      count: (r) => r.transactionsAdded,
    ),
    (icon: LucideIcons.tag, label: 'danh mục', count: (r) => r.categoriesAdded),
    (
      icon: LucideIcons.wallet,
      label: 'nguồn tiền',
      count: (r) => r.walletsAdded,
    ),
    (
      icon: LucideIcons.bellRing,
      label: 'nhắc nhở',
      count: (r) => r.remindersAdded,
    ),
    (
      icon: LucideIcons.chartPie,
      label: 'hạn mức danh mục',
      count: (r) => r.budgetsAdded,
    ),
    (
      icon: LucideIcons.calendarDays,
      label: 'ngân sách tháng',
      count: (r) => r.monthlyBudgetsAdded,
    ),
    (
      icon: LucideIcons.handCoins,
      label: 'khoản vay',
      count: (r) => r.loansAdded,
    ),
    (
      icon: LucideIcons.banknote,
      label: 'lần thanh toán',
      count: (r) => r.loanPaymentsAdded,
    ),
    (
      icon: LucideIcons.calendarRange,
      label: 'đợt trả góp',
      count: (r) => r.loanInstallmentsAdded,
    ),
  ];
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.icon,
    required this.text,
    this.muted = false,
  });

  final IconData icon;
  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = muted ? cs.onSurfaceVariant : cs.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: muted ? cs.onSurfaceVariant : cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: SpendoSectionHeader(label: text, padding: EdgeInsets.zero),
    );
  }
}
