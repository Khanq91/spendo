import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/gdrive_backup_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/gdrive_provider.dart';

class GDriveBackupSection extends ConsumerWidget {
  const GDriveBackupSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gdriveProvider);
    final cs = Theme.of(context).colorScheme;
    final surface = cs.surface;

    // Handle success/error messages
    ref.listen<GDriveState>(gdriveProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${next.error}'),
            backgroundColor: AppTheme.expenseAltColor,
          ),
        );
      }
      if (next.successMessage != null &&
          next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${next.successMessage}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    return Material(
      color: surface,
      child: Column(
        children: [
          if (!state.isSignedIn) ...[
            ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF4285F4,
                  ).withValues(alpha: 0.1), // Google Blue
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.cloud,
                  size: 18,
                  color: Color(0xFF4285F4),
                ),
              ),
              title: const Text(
                'Kết nối Google Drive',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Đăng nhập để tự động sao lưu dữ liệu',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              trailing:
                  state.isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Icon(
                        LucideIcons.chevronRight,
                        size: 18,
                        color: cs.onSurfaceVariant,
                      ),
              onTap:
                  state.isLoading
                      ? null
                      : () => ref.read(gdriveProvider.notifier).signIn(),
            ),
          ] else ...[
            ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF4285F4).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.cloudCheck,
                  size: 18,
                  color: Color(0xFF4285F4),
                ),
              ),
              title: Text(
                state.email ?? 'Đã kết nối Google Drive',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                state.lastBackupTime != null
                    ? 'Lần cuối: ${DateFormat('dd/MM/yyyy, HH:mm').format(state.lastBackupTime!)}'
                    : 'Chưa có bản sao lưu nào',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              trailing: IconButton(
                icon: const Icon(LucideIcons.logOut, size: 20),
                color: cs.onSurfaceVariant,
                onPressed:
                    state.isLoading
                        ? null
                        : () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder:
                                (ctx) => AlertDialog(
                                  title: const Text(
                                    'Ngắt kết nối Google Drive!',
                                  ),
                                  content: const Text(
                                    'Dữ liệu trên thiết bị sẽ không bị xóa, nhưng tính năng sao lưu tự động sẽ bị tắt. Bạn chắc chắn chứ?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(ctx, false),
                                      child: const Text('Hủy'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Ngắt kết nối'),
                                    ),
                                  ],
                                ),
                          );
                          if (confirm == true) {
                            ref.read(gdriveProvider.notifier).signOut();
                          }
                        },
                tooltip: 'Ngắt kết nối',
              ),
            ),
            Divider(height: 1, indent: 68, color: cs.outlineVariant),
            ListTile(
              contentPadding: const EdgeInsets.only(left: 68, right: 16),
              title: const Text(
                'Tự động sao lưu',
                style: TextStyle(fontSize: 14),
              ),
              trailing: DropdownButton<BackupFrequency>(
                value: state.frequency,
                underline: const SizedBox.shrink(),
                icon: Icon(
                  LucideIcons.chevronDown,
                  size: 16,
                  color: cs.onSurfaceVariant,
                ),
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                items:
                    BackupFrequency.values.map((freq) {
                      return DropdownMenuItem(
                        value: freq,
                        child: Text(freq.label),
                      );
                    }).toList(),
                onChanged:
                    state.isLoading
                        ? null
                        : (val) {
                          if (val != null) {
                            ref.read(gdriveProvider.notifier).setFrequency(val);
                          }
                        },
              ),
            ),
            Divider(height: 1, indent: 68, color: cs.outlineVariant),
            ListTile(
              contentPadding: const EdgeInsets.only(left: 68, right: 16),
              title: const Text('Sao lưu ngay', style: TextStyle(fontSize: 14)),
              trailing:
                  state.isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(
                        LucideIcons.uploadCloud,
                        size: 20,
                        color: Color(0xFF4285F4),
                      ),
              onTap:
                  state.isLoading
                      ? null
                      : () => ref.read(gdriveProvider.notifier).backupNow(),
            ),
            Divider(height: 1, indent: 68, color: cs.outlineVariant),
            ListTile(
              contentPadding: const EdgeInsets.only(left: 68, right: 16),
              title: const Text(
                'Khôi phục từ Drive',
                style: TextStyle(fontSize: 14),
              ),
              trailing: const Icon(LucideIcons.downloadCloud, size: 20),
              onTap:
                  state.isLoading
                      ? null
                      : () => _showRestoreDialog(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showRestoreDialog(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final backups = await ref.read(gdriveProvider.notifier).listBackups();

      if (!context.mounted) return;
      Navigator.pop(context); // close loading

      if (backups.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không tìm thấy bản sao lưu nào trên Drive.'),
          ),
        );
        return;
      }

      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Chọn bản sao lưu'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: backups.length,
                  itemBuilder: (context, index) {
                    final backup = backups[index];
                    final dateStr =
                        backup.createdTime != null
                            ? DateFormat(
                              'dd/MM/yyyy HH:mm',
                            ).format(backup.createdTime!)
                            : 'Không rõ ngày';
                    final sizeStr =
                        backup.sizeBytes != null
                            ? '${(backup.sizeBytes! / 1024).toStringAsFixed(1)} KB'
                            : '';

                    return ListTile(
                      title: Text(dateStr),
                      subtitle: sizeStr.isNotEmpty ? Text(sizeStr) : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        _confirmRestore(context, ref, backup);
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Đóng'),
                ),
              ],
            ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải danh sách: $e'),
          backgroundColor: AppTheme.expenseAltColor,
        ),
      );
    }
  }

  Future<void> _confirmRestore(
    BuildContext context,
    WidgetRef ref,
    DriveBackupInfo backup,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await GDriveBackupService.instance.previewRestoreFromDrive(
        backup.fileId,
      );

      if (!context.mounted) return;
      Navigator.pop(context); // close loading

      if (result.errors.isNotEmpty &&
          result.transactionsAdded == 0 &&
          result.categoriesAdded == 0 &&
          result.walletsAdded == 0 &&
          result.monthlyBudgetsAdded == 0 &&
          result.loansAdded == 0 &&
          result.loanPaymentsAdded == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${result.errors.first}'),
            backgroundColor: AppTheme.expenseAltColor,
          ),
        );
        return;
      }

      final confirm = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Xác nhận khôi phục'),
              content: Text(
                'Bạn sắp khôi phục dữ liệu ngày ${DateFormat('dd/MM/yyyy HH:mm').format(backup.createdTime!)}.\n\n'
                'Sẽ thêm:\n'
                '• ${result.transactionsAdded} giao dịch\n'
                '• ${result.categoriesAdded} danh mục\n'
                '• ${result.walletsAdded} nguồn tiền\n'
                '• ${result.monthlyBudgetsAdded} ngân sách tháng\n'
                '• ${result.loansAdded} khoản vay\n'
                '• ${result.loanPaymentsAdded} lần thanh toán\n\n'
                'Dữ liệu trùng lặp sẽ tự động bị bỏ qua.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Khôi phục'),
                ),
              ],
            ),
      );

      if (confirm != true || !context.mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final finalResult = await GDriveBackupService.instance.restoreFromDrive(
        backup.fileId,
      );

      if (!context.mounted) return;
      Navigator.pop(context); // close loading

      // Force UI refresh (providers need to be invalidated in the parent screen usually,
      // but here we just show a message. The parent screen can handle the refresh if needed,
      // or we can assume Riverpod stream providers will auto-update if the DB changes)

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Khôi phục thành công '
            '${finalResult.transactionsAdded} giao dịch, '
            '${finalResult.walletsAdded} nguồn tiền, '
            '${finalResult.monthlyBudgetsAdded} ngân sách tháng, '
            '${finalResult.loansAdded} khoản vay và '
            '${finalResult.loanPaymentsAdded} lần thanh toán.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khôi phục: $e'),
          backgroundColor: AppTheme.expenseAltColor,
        ),
      );
    }
  }
}
