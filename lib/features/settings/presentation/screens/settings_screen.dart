import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/notifications/notification_provider.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/backup_service.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/export_service.dart';
import '../../../../core/utils/import_service.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/data/category_repository.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../categories/presentation/widgets/category_form_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../widgets/widget_pin_section.dart';
import '../widgets/gdrive_backup_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final allCats = categoriesAsync.valueOrNull ?? [];
    final expenseCats = allCats.where((c) => !c.isIncome).toList();
    final incomeCats = allCats.where((c) => c.isIncome).toList();
    final cs = Theme.of(context).colorScheme;
    final surface = cs.surface;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Cài đặt',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        children: [
          // ── Export báo cáo ───────────────────────────────────────────────
          _SectionHeader(title: 'Xuất báo cáo'),
          _ExportTile(
            label: 'Tháng này',
            subtitle: 'Xuất giao dịch tháng hiện tại dạng CSV',
            onTap: () => _export(context, ExportRange.thisMonth),
          ),
          _ExportTile(
            label: '3 tháng gần đây',
            subtitle: 'Xuất giao dịch 3 tháng gần nhất dạng CSV',
            onTap: () => _export(context, ExportRange.threeMonths),
          ),
          _ExportTile(
            label: 'Tất cả',
            subtitle: 'Toàn bộ lịch sử giao dịch dạng CSV',
            onTap: () => _export(context, ExportRange.all),
          ),

          const SizedBox(height: 8),

          // ── Import CSV ───────────────────────────────────────────────────
          // _SectionHeader(title: 'Nhập từ CSV'),
          // ListTile(
          //   leading: Container(
          //     width: 36,
          //     height: 36,
          //     decoration: BoxDecoration(
          //       color: AppTheme.primary.withOpacity(0.1),
          //       borderRadius: BorderRadius.circular(8),
          //     ),
          //     child:
          //     Icon(LucideIcons.upload, size: 18, color: AppTheme.primary),
          //   ),
          //   title: const Text('Nhập từ file CSV', style: TextStyle(fontSize: 14)),
          //   subtitle: Text(
          //     'Import từ file báo cáo CSV đã xuất trước đó',
          //     style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          //   ),
          //   trailing: Icon(LucideIcons.chevronRight,
          //       size: 18, color: cs.onSurfaceVariant),
          //   onTap: () => _import(context, ref),
          // ),
          //
          // const SizedBox(height: 8),

          // ── Backup & Restore ─────────────────────────────────────────────
          _SectionHeader(title: 'Sao lưu & khôi phục'),
          Material(
            color: surface,
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      LucideIcons.hardDriveDownload,
                      size: 18,
                      color: Color(0xFF6C63FF),
                    ),
                  ),
                  title: const Text(
                    'Xuất backup toàn bộ',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    'Lưu toàn bộ dữ liệu ra file JSON để khôi phục sau',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                  trailing: Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                  onTap: () => _exportBackup(context),
                ),
                Divider(height: 1, indent: 16, color: cs.outlineVariant),
                ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      LucideIcons.hardDriveUpload,
                      size: 18,
                      color: Color(0xFF6C63FF),
                    ),
                  ),
                  title: const Text(
                    'Khôi phục từ backup',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    'Nhập file JSON backup để khôi phục dữ liệu',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                  trailing: Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                  onTap: () => _restore(context, ref),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── GDrive Backup ────────────────────────────────────────────────
          _SectionHeader(title: 'Sao lưu Google Drive'),
          const GDriveBackupSection(),

          const SizedBox(height: 8),

          // ── Theme ────────────────────────────────────────────────────────
          _SectionHeader(title: 'Giao diện'),
          Consumer(
            builder: (context, ref, _) {
              final mode = ref.watch(themeModeProvider);
              return Material(
                color: surface,
                child: Column(
                  children: [
                    _ThemeTile(
                      label: 'Theo hệ thống',
                      icon: LucideIcons.monitor,
                      selected: mode == ThemeMode.system,
                      onTap:
                          () => ref
                              .read(themeModeProvider.notifier)
                              .setMode(ThemeMode.system),
                    ),
                    _ThemeTile(
                      label: 'Sáng',
                      icon: LucideIcons.sun,
                      selected: mode == ThemeMode.light,
                      onTap:
                          () => ref
                              .read(themeModeProvider.notifier)
                              .setMode(ThemeMode.light),
                    ),
                    _ThemeTile(
                      label: 'Tối',
                      icon: LucideIcons.moon,
                      selected: mode == ThemeMode.dark,
                      onTap:
                          () => ref
                              .read(themeModeProvider.notifier)
                              .setMode(ThemeMode.dark),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // ── Notifications ────────────────────────────────────────────────
          _SectionHeader(title: 'Thông báo'),
          Consumer(
            builder: (context, ref, _) {
              final enabled = ref.watch(notificationEnabledProvider);
              final hour = ref.watch(notificationHourProvider);
              final minute = ref.watch(notificationMinuteProvider);
              final cs = Theme.of(context).colorScheme;

              return Material(
                color: surface,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        LucideIcons.bell,
                        size: 18,
                        color: enabled ? AppTheme.primary : cs.onSurfaceVariant,
                      ),
                      title: const Text(
                        'Nhắc nhập chi tiêu',
                        style: TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        'Mỗi ngày lúc ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      trailing: Switch(
                        value: enabled,
                        activeColor: AppTheme.primary,
                        onChanged: (val) async {
                          if (val) {
                            final granted =
                                await NotificationService.requestPermission();
                            if (!granted) return;
                          }
                          ref
                              .read(notificationEnabledProvider.notifier)
                              .toggle(val, hour: hour, minute: minute);
                        },
                      ),
                    ),
                    if (enabled)
                      ListTile(
                        leading: Icon(
                          LucideIcons.clock,
                          size: 18,
                          color: cs.onSurfaceVariant,
                        ),
                        title: const Text(
                          'Giờ nhắc nhở',
                          style: TextStyle(fontSize: 14),
                        ),
                        trailing: Text(
                          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primary,
                          ),
                        ),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(hour: hour, minute: minute),
                          );
                          if (picked != null) {
                            await ref
                                .read(notificationHourProvider.notifier)
                                .set(picked.hour);
                            await ref
                                .read(notificationMinuteProvider.notifier)
                                .set(picked.minute);
                            await NotificationService.scheduleDailyReminder(
                              hour: picked.hour,
                              minute: picked.minute,
                            );
                          }
                        },
                      ),
                    if (enabled)
                      ListTile(
                        leading: Icon(
                          LucideIcons.bellRing,
                          size: 18,
                          color: cs.onSurfaceVariant,
                        ),
                        title: const Text(
                          'Gửi thông báo thử',
                          style: TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          'Hiện sau 5 giây',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: cs.onSurfaceVariant,
                        ),
                        onTap: () async {
                          await NotificationService.sendTestNotification();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Thông báo sẽ hiện sau 5 giây'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // ── Recurring reminders ──────────────────────────────────────────
          _SectionHeader(title: 'Nhắc chi tiêu định kỳ'),
          ListTile(
            tileColor: surface,
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                LucideIcons.bellRing,
                size: 18,
                color: AppTheme.primary,
              ),
            ),
            title: const Text(
              'Quản lý nhắc nhở',
              style: TextStyle(fontSize: 14),
            ),
            subtitle: Text(
              'Nhắc mua đồ và ghi chi tiêu định kỳ',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            trailing: Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: cs.onSurfaceVariant,
            ),
            onTap: () => context.push('/reminders'),
          ),
          const SizedBox(height: 8),

          // ── Widget pin ───────────────────────────────────────────────────
          _SectionHeader(title: 'Widget màn hình chính'),
          Container(
            color: surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: const Material(
              color: Colors.transparent,
              child: WidgetPinSection(),
            ),
          ),
          const SizedBox(height: 8),

          // ── Categories ───────────────────────────────────────────────────
          _SectionHeader(title: 'Danh mục'),
          _CategoriesExpansionTile(
            expenseCats: expenseCats,
            incomeCats: incomeCats,
            onAddExpense: () => _openForm(context, isIncome: false),
            onAddIncome: () => _openForm(context, isIncome: true),
            onEdit: (cat) => _openEditForm(context, cat),
            onDelete: (cat) => _confirmDelete(context, cat),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Handlers ─────────────────────────────────────────────────────────────

  void _openForm(BuildContext context, {required bool isIncome}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CategoryFormSheet(isIncome: isIncome),
    );
  }

  void _openEditForm(BuildContext context, Category cat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CategoryFormSheet(existing: cat, isIncome: cat.isIncome),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Category cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Xoá danh mục?'),
            content: Text(
              'Xoá "${cat.name}"?\nDanh mục đang có giao dịch sẽ không thể xoá.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Huỷ'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.expenseAltColor,
                ),
                child: const Text('Xoá'),
              ),
            ],
          ),
    );

    if (confirm == true && context.mounted) {
      try {
        await CategoryRepository().delete(cat.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: AppTheme.expenseAltColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _export(BuildContext context, ExportRange range) async {
    try {
      await ExportService.exportCSV(range);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi xuất file: $e')));
      }
    }
  }

  // ── Backup export ─────────────────────────────────────────────────────────

  Future<void> _exportBackup(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final result = await BackupService.exportBackup();

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      final parts = <String>[
        '${result.transactions} giao dịch',
        '${result.categories} danh mục',
        if (result.reminders > 0) '${result.reminders} nhắc nhở',
        if (result.categoryBudgets > 0) '${result.categoryBudgets} hạn mức',
      ];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Đã xuất ${parts.join(', ')}'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi xuất backup: $e'),
            backgroundColor: AppTheme.expenseAltColor,
          ),
        );
      }
    }
  }

  // ── Backup restore ────────────────────────────────────────────────────────

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    try {
      // 1. Chọn file JSON
      final filePath = await BackupService.pickBackupFile();
      if (filePath == null) return;

      if (!context.mounted) return;
      await Future.delayed(Duration.zero);
      if (!context.mounted) return;

      // 2. Loading
      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // 3. Preview
      final preview = await BackupService.previewRestore(filePath);

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      // 4. Lỗi nghiêm trọng
      if (preview.categoriesAdded == 0 &&
          preview.transactionsAdded == 0 &&
          preview.remindersAdded == 0 &&
          preview.budgetsAdded == 0 &&
          preview.errors.isNotEmpty) {
        _showError(context, preview.errors.first);
        return;
      }

      // 5. Confirm dialog
      final confirmed = await showDialog<bool>(
        context: context,
        useRootNavigator: true,
        builder: (ctx) => _RestorePreviewDialog(preview: preview),
      );

      if (confirmed != true || !context.mounted) return;

      // 6. Restore thật
      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final result = await BackupService.restore(filePath);

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      // 7. Invalidate providers
      ref.invalidate(transactionsProvider);
      ref.invalidate(categoriesProvider);

      // 8. Kết quả
      final added = <String>[
        if (result.transactionsAdded > 0) '${result.transactionsAdded} giao dịch',
        if (result.categoriesAdded > 0) '${result.categoriesAdded} danh mục',
        if (result.remindersAdded > 0) '${result.remindersAdded} nhắc nhở',
        if (result.budgetsAdded > 0) '${result.budgetsAdded} hạn mức',
      ];
      final skipped = result.transactionsSkipped +
          result.categoriesSkipped +
          result.remindersSkipped +
          result.budgetsSkipped;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Đã khôi phục ${added.join(', ')}'
            '${skipped > 0 ? ' · bỏ qua $skipped trùng' : ''}',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
        _showError(context, e.toString());
      }
    }
  }

  // ── Import CSV (giữ nguyên) ───────────────────────────────────────────────

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (result == null || result.files.single.path == null) return;
      final filePath = result.files.single.path!;

      if (!context.mounted) return;
      await Future.delayed(Duration.zero);
      if (!context.mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final preview = await ImportService.previewCSV(filePath);

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (preview.added == 0 &&
          preview.skipped == 0 &&
          preview.errors.isNotEmpty) {
        _showError(context, preview.errors.first);
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        useRootNavigator: true,
        builder: (ctx) => _ImportPreviewDialog(preview: preview),
      );

      if (confirmed != true || !context.mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final result2 = await ImportService.importCSV(filePath);

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      ref.invalidate(transactionsProvider);
      ref.invalidate(categoriesProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Đã nhập ${result2.added} giao dịch'
            '${result2.skipped > 0 ? ', bỏ qua ${result2.skipped} trùng' : ''}'
            '${result2.newCategories > 0 ? ', tạo ${result2.newCategories} danh mục mới' : ''}',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
        _showError(context, e.toString());
      }
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: AppTheme.expenseAltColor,
      ),
    );
  }
}

// ── Restore preview dialog ────────────────────────────────────────────────────

class _RestorePreviewDialog extends StatelessWidget {
  final RestoreResult preview;
  const _RestorePreviewDialog({required this.preview});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasAnything =
        preview.categoriesAdded > 0 || preview.transactionsAdded > 0 ||
        preview.remindersAdded > 0 || preview.budgetsAdded > 0;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(
            LucideIcons.hardDriveUpload,
            size: 20,
            color: Color(0xFF6C63FF),
          ),
          const SizedBox(width: 8),
          const Text(
            'Xác nhận khôi phục',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (preview.transactionsAdded > 0)
            _PreviewRow(
              icon: LucideIcons.circlePlus,
              color: const Color(0xFF6C63FF),
              text: '${preview.transactionsAdded} giao dịch mới sẽ được thêm',
            ),
          if (preview.categoriesAdded > 0)
            _PreviewRow(
              icon: LucideIcons.tag,
              color: Colors.orange,
              text: '${preview.categoriesAdded} danh mục mới sẽ được tạo',
            ),
          if (preview.remindersAdded > 0)
            _PreviewRow(
              icon: LucideIcons.bellRing,
              color: AppTheme.primary,
              text: '${preview.remindersAdded} nhắc nhở sẽ được khôi phục',
            ),
          if (preview.budgetsAdded > 0)
            _PreviewRow(
              icon: LucideIcons.wallet,
              color: AppTheme.incomeColor,
              text: '${preview.budgetsAdded} hạn mức danh mục sẽ được khôi phục',
            ),
          if (preview.transactionsSkipped > 0)
            _PreviewRow(
              icon: LucideIcons.circleArrowRight,
              color: cs.onSurfaceVariant,
              text:
                  '${preview.transactionsSkipped} giao dịch đã tồn tại → bỏ qua',
            ),
          if (preview.categoriesSkipped > 0)
            _PreviewRow(
              icon: LucideIcons.circleArrowRight,
              color: cs.onSurfaceVariant,
              text: '${preview.categoriesSkipped} danh mục đã tồn tại → bỏ qua',
            ),
          if (preview.errors.isNotEmpty) ...[
            const SizedBox(height: 8),
            _PreviewRow(
              icon: LucideIcons.triangleAlert,
              color: AppTheme.expenseAltColor,
              text: '${preview.errors.length} mục bị lỗi (sẽ bỏ qua)',
            ),
          ],
          if (!hasAnything) ...[
            const SizedBox(height: 8),
            Text(
              'Tất cả dữ liệu trong backup đã tồn tại trên thiết bị này.',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Huỷ', style: TextStyle(color: cs.onSurfaceVariant)),
        ),
        FilledButton(
          onPressed: hasAnything ? () => Navigator.pop(context, true) : null,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
          ),
          child: const Text('Khôi phục'),
        ),
      ],
    );
  }
}

// ── Import CSV preview dialog (giữ nguyên) ────────────────────────────────────

class _ImportPreviewDialog extends StatelessWidget {
  final ImportResult preview;
  const _ImportPreviewDialog({required this.preview});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Row(
        children: [
          Icon(LucideIcons.fileUp, size: 20, color: AppTheme.primary),
          const SizedBox(width: 8),
          const Text(
            'Xác nhận nhập dữ liệu',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PreviewRow(
            icon: LucideIcons.circlePlus,
            color: AppTheme.primary,
            text: '${preview.added} giao dịch mới sẽ được thêm',
          ),
          if (preview.skipped > 0)
            _PreviewRow(
              icon: LucideIcons.circleArrowRight,
              color: cs.onSurfaceVariant,
              text: '${preview.skipped} giao dịch trùng → bỏ qua',
            ),
          if (preview.newCategories > 0) ...[
            _PreviewRow(
              icon: LucideIcons.tag,
              color: Colors.orange,
              text: '${preview.newCategories} danh mục mới sẽ được tạo:',
            ),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    preview.newCategoryNames
                        .map(
                          (name) => Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '• $name',
                              style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
          ],
          if (preview.errors.isNotEmpty) ...[
            const SizedBox(height: 8),
            _PreviewRow(
              icon: LucideIcons.triangleAlert,
              color: AppTheme.expenseAltColor,
              text: '${preview.errors.length} dòng bị lỗi (sẽ bỏ qua)',
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Huỷ', style: TextStyle(color: cs.onSurfaceVariant)),
        ),
        FilledButton(
          onPressed:
              preview.added > 0 ? () => Navigator.pop(context, true) : null,
          style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
          child: const Text('Nhập ngay'),
        ),
      ],
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _PreviewRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: cs.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ExportTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ExportTile({
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(LucideIcons.download, size: 18, color: AppTheme.primary),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
      ),
      trailing: Icon(
        LucideIcons.chevronRight,
        size: 18,
        color: cs.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryTile({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: category.color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          categoryIcon(category.iconName),
          size: 18,
          color: category.color,
        ),
      ),
      title: Text(category.name, style: const TextStyle(fontSize: 14)),
      subtitle:
          category.isDefault
              ? Text(
                'Mặc định',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              )
              : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              LucideIcons.pencil,
              size: 16,
              color: cs.onSurfaceVariant,
            ),
            onPressed: onEdit,
            visualDensity: VisualDensity.compact,
          ),
          if (!category.isDefault)
            IconButton(
              icon: Icon(
                LucideIcons.trash2,
                size: 16,
                color: AppTheme.expenseAltColor,
              ),
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        icon,
        size: 18,
        color: selected ? AppTheme.primary : cs.onSurfaceVariant,
      ),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing:
          selected
              ? const Icon(LucideIcons.check, size: 16, color: AppTheme.primary)
              : null,
      onTap: onTap,
    );
  }
}

// ── Collapsible categories tile ───────────────────────────────────────────────

class _CategoriesExpansionTile extends StatefulWidget {
  final List<Category> expenseCats;
  final List<Category> incomeCats;
  final VoidCallback onAddExpense;
  final VoidCallback onAddIncome;
  final void Function(Category) onEdit;
  final void Function(Category) onDelete;

  const _CategoriesExpansionTile({
    required this.expenseCats,
    required this.incomeCats,
    required this.onAddExpense,
    required this.onAddIncome,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_CategoriesExpansionTile> createState() =>
      _CategoriesExpansionTileState();
}

class _CategoriesExpansionTileState extends State<_CategoriesExpansionTile> {
  bool _expanded = false;
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cats = _tab == 0 ? widget.expenseCats : widget.incomeCats;
    final total = widget.expenseCats.length + widget.incomeCats.length;

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            color: cs.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    LucideIcons.tag,
                    size: 18,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Danh mục thu chi',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        '$total danh mục · ${widget.expenseCats.length} chi, ${widget.incomeCats.length} thu',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            color: cs.surface,
            child: Column(
              children: [
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
                  child: Row(
                    children: [
                      _TabChip(
                        label: 'Chi (${widget.expenseCats.length})',
                        selected: _tab == 0,
                        onTap: () => setState(() => _tab = 0),
                      ),
                      const SizedBox(width: 8),
                      _TabChip(
                        label: 'Thu (${widget.incomeCats.length})',
                        selected: _tab == 1,
                        onTap: () => setState(() => _tab = 1),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed:
                            _tab == 0
                                ? widget.onAddExpense
                                : widget.onAddIncome,
                        icon: const Icon(Icons.add, size: 15),
                        label: const Text(
                          'Thêm',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                ...cats.map(
                  (cat) => _CategoryTile(
                    category: cat,
                    onEdit: () => widget.onEdit(cat),
                    onDelete: () => widget.onDelete(cat),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
          sizeCurve: Curves.easeOutCubic,
        ),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color:
              selected
                  ? AppTheme.primary.withOpacity(0.12)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primary : cs.outlineVariant,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? AppTheme.primary : cs.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
