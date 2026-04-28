import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/notifications/notification_provider.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/app_theme.dart';
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
          // ── Export ──────────────────────────────────────────────────────
          _SectionHeader(title: 'Xuất dữ liệu'),
          _ExportTile(
            label: 'Tháng này',
            subtitle: 'Xuất giao dịch tháng hiện tại',
            onTap: () => _export(context, ExportRange.thisMonth),
          ),
          _ExportTile(
            label: '3 tháng gần đây',
            subtitle: 'Xuất giao dịch 3 tháng gần nhất',
            onTap: () => _export(context, ExportRange.threeMonths),
          ),
          _ExportTile(
            label: 'Tất cả',
            subtitle: 'Toàn bộ lịch sử giao dịch',
            onTap: () => _export(context, ExportRange.all),
          ),

          const SizedBox(height: 8),

          // ── Import ──────────────────────────────────────────────────────
          _SectionHeader(title: 'Nhập dữ liệu'),
          ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(LucideIcons.upload, size: 18, color: AppTheme.primary),
            ),
            title: const Text('Nhập từ file CSV', style: TextStyle(fontSize: 14)),
            subtitle: Text(
              'Import dữ liệu đã xuất trước đó',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            trailing: Icon(LucideIcons.chevronRight,
                size: 18, color: cs.onSurfaceVariant),
            onTap: () => _import(context, ref),
          ),

          const SizedBox(height: 8),

          // ── Theme ────────────────────────────────────────────────────────
          _SectionHeader(title: 'Giao diện'),
          Consumer(
            builder: (context, ref, _) {
              final mode = ref.watch(themeModeProvider);
              return Container(
                color: surface,
                child: Column(
                  children: [
                    _ThemeTile(
                      label: 'Theo hệ thống',
                      icon: LucideIcons.monitor,
                      selected: mode == ThemeMode.system,
                      onTap: () => ref
                          .read(themeModeProvider.notifier)
                          .setMode(ThemeMode.system),
                    ),
                    _ThemeTile(
                      label: 'Sáng',
                      icon: LucideIcons.sun,
                      selected: mode == ThemeMode.light,
                      onTap: () => ref
                          .read(themeModeProvider.notifier)
                          .setMode(ThemeMode.light),
                    ),
                    _ThemeTile(
                      label: 'Tối',
                      icon: LucideIcons.moon,
                      selected: mode == ThemeMode.dark,
                      onTap: () => ref
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

              return Container(
                color: surface,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        LucideIcons.bell,
                        size: 18,
                        color: enabled
                            ? AppTheme.primary
                            : cs.onSurfaceVariant,
                      ),
                      title: const Text('Nhắc nhập chi tiêu',
                          style: TextStyle(fontSize: 14)),
                      subtitle: Text(
                        'Mỗi ngày lúc ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant),
                      ),
                      trailing: Switch(
                        value: enabled,
                        activeColor: AppTheme.primary,
                        onChanged: (val) async {
                          if (val) {
                            final granted = await NotificationService
                                .requestPermission();
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
                        leading: Icon(LucideIcons.clock,
                            size: 18, color: cs.onSurfaceVariant),
                        title: const Text('Giờ nhắc nhở',
                            style: TextStyle(fontSize: 14)),
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
                            initialTime:
                            TimeOfDay(hour: hour, minute: minute),
                          );
                          if (picked != null) {
                            await ref
                                .read(notificationHourProvider.notifier)
                                .set(picked.hour);
                            await ref
                                .read(notificationMinuteProvider.notifier)
                                .set(picked.minute);
                            await NotificationService
                                .scheduleDailyReminder(
                              hour: picked.hour,
                              minute: picked.minute,
                            );
                          }
                        },
                      ),
                    if (enabled)
                      ListTile(
                        leading: Icon(LucideIcons.bellRing,
                            size: 18, color: cs.onSurfaceVariant),
                        title: const Text('Gửi thông báo thử',
                            style: TextStyle(fontSize: 14)),
                        subtitle: Text('Hiện sau 5 giây',
                            style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant)),
                        trailing: Icon(Icons.chevron_right,
                            size: 18, color: cs.onSurfaceVariant),
                        onTap: () async {
                          await NotificationService
                              .sendTestNotification();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Thông báo sẽ hiện sau 5 giây'),
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
              child: Icon(LucideIcons.bellRing, size: 18, color: AppTheme.primary),
            ),
            title: const Text('Quản lý nhắc nhở', style: TextStyle(fontSize: 14)),
            subtitle: Text(
              'Nhắc mua đồ và ghi chi tiêu định kỳ',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            trailing: Icon(LucideIcons.chevronRight, size: 18, color: cs.onSurfaceVariant),
            onTap: () => context.push('/reminders'),
          ),
          const SizedBox(height: 8),

          // ── Widget pin ───────────────────────────────────────────────────
          _SectionHeader(title: 'Widget màn hình chính'),
          Container(
            color: surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: const WidgetPinSection(),
          ),
          const SizedBox(height: 8),

          // ── Categories (collapsible) ─────────────────────────────────────
          _SectionHeader(title: 'Danh mục'),
          _CategoriesExpansionTile(
            expenseCats: expenseCats,
            incomeCats: incomeCats,
            onAddExpense: () => _openForm(context, isIncome: false),
            onAddIncome: () => _openForm(context, isIncome: true),
            onEdit: (cat) => _openEditForm(context, cat),
            onDelete: (cat) => _confirmDelete(context, cat),
          ),

          // // ── Account section ─────────────────────────────────────────────
          // _SectionHeader(title: 'Tài khoản'),
          // Consumer(
          //   builder: (context, ref, _) {
          //     final userAsync = ref.watch(currentUserProvider);
          //     final user = userAsync.valueOrNull;
          //     final isLoggedIn = user != null;
          //
          //     if (isLoggedIn) {
          //       return Column(
          //         children: [
          //           ListTile(
          //             tileColor: Colors.white,
          //             leading: Container(
          //               width: 36,
          //               height: 36,
          //               decoration: BoxDecoration(
          //                 color: const Color(0xFF6C63FF).withOpacity(0.1),
          //                 borderRadius: BorderRadius.circular(8),
          //               ),
          //               child: const Icon(Icons.person_outline,
          //                   size: 18, color: Color(0xFF6C63FF)),
          //             ),
          //             title: Text(
          //               user.email ?? 'Đã đăng nhập',
          //               style: const TextStyle(fontSize: 14),
          //             ),
          //             subtitle: Text(
          //               'Dữ liệu đang được sync',
          //               style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          //             ),
          //           ),
          //           ListTile(
          //             tileColor: Colors.white,
          //             leading: Container(
          //               width: 36,
          //               height: 36,
          //               decoration: BoxDecoration(
          //                 color: const Color(0xFFE53935).withOpacity(0.1),
          //                 borderRadius: BorderRadius.circular(8),
          //               ),
          //               child: const Icon(Icons.logout,
          //                   size: 18, color: Color(0xFFE53935)),
          //             ),
          //             title: const Text(
          //               'Đăng xuất',
          //               style: TextStyle(fontSize: 14, color: Color(0xFFE53935)),
          //             ),
          //             onTap: () async {
          //               await Supabase.instance.client.auth.signOut();
          //             },
          //           ),
          //         ],
          //       );
          //     }
          //
          //     // Chưa login — hiện nút đăng nhập
          //     return ListTile(
          //       tileColor: Colors.white,
          //       leading: Container(
          //         width: 36,
          //         height: 36,
          //         decoration: BoxDecoration(
          //           color: const Color(0xFF6C63FF).withOpacity(0.1),
          //           borderRadius: BorderRadius.circular(8),
          //         ),
          //         child: const Icon(Icons.cloud_upload_outlined,
          //             size: 18, color: Color(0xFF6C63FF)),
          //       ),
          //       title: const Text(
          //         'Đăng nhập để sync',
          //         style: TextStyle(fontSize: 14),
          //       ),
          //       subtitle: Text(
          //         'Sao lưu và đồng bộ đa thiết bị',
          //         style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          //       ),
          //       trailing: const Icon(Icons.chevron_right, size: 18),
          //       onTap: () => Navigator.of(context).push(
          //         MaterialPageRoute(
          //             fullscreenDialog: true,
          //             builder: (_) => const AuthScreen()
          //         ),
          //       ),
          //     );
          //   },
          // ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

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
      builder: (_) =>
          CategoryFormSheet(existing: cat, isIncome: cat.isIncome),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, Category cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
                foregroundColor: AppTheme.expenseAltColor),
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
              content:
              Text(e.toString().replaceAll('Exception: ', '')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xuất file: $e')),
        );
      }
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    try {
      // 1. Chọn file CSV
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (result == null || result.files.single.path == null) return;
      final filePath = result.files.single.path!;

      if (!context.mounted) return;

      // Đợi frame tiếp theo để navigator unlock sau khi FilePicker trả về
      await Future.delayed(Duration.zero);
      if (!context.mounted) return;

      // 2. Hiện loading
      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // 3. Preview (dry-run)
      final preview = await ImportService.previewCSV(filePath);

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // đóng loading

      // 4. Nếu có lỗi nghiêm trọng và không có gì để import
      if (preview.added == 0 && preview.skipped == 0 && preview.errors.isNotEmpty) {
        _showImportError(context, preview.errors.first);
        return;
      }

      // 5. Hiện dialog xác nhận
      final confirmed = await showDialog<bool>(
        context: context,
        useRootNavigator: true,
        builder: (ctx) => _ImportPreviewDialog(preview: preview),
      );

      if (confirmed != true || !context.mounted) return;

      // 6. Import thật
      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final result2 = await ImportService.importCSV(filePath);

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // đóng loading

      // 8. Invalidate providers để UI cập nhật ngay
      ref.invalidate(transactionsProvider);
      ref.invalidate(categoriesProvider);

      // 9. Hiện kết quả
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
        // Đóng dialog loading nếu đang mở (an toàn)
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
        _showImportError(context, e.toString());
      }
    }
  }

  void _showImportError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: AppTheme.expenseAltColor,
      ),
    );
  }
}

// ── Import preview dialog ─────────────────────────────────────────────────────

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
          const Text('Xác nhận nhập dữ liệu',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                children: preview.newCategoryNames
                    .map((name) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '• $name',
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ))
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
          child: Text('Huỷ',
              style: TextStyle(color: cs.onSurfaceVariant)),
        ),
        FilledButton(
          onPressed: preview.added > 0
              ? () => Navigator.pop(context, true)
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primary,
          ),
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
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  const _SectionHeader({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          if (action != null) action!,
        ],
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
      subtitle: Text(subtitle,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      trailing: Icon(LucideIcons.chevronRight,
          size: 18, color: cs.onSurfaceVariant),
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
      subtitle: category.isDefault
          ? Text('Mặc định',
          style: TextStyle(
              fontSize: 11, color: cs.onSurfaceVariant))
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(LucideIcons.pencil,
                size: 16, color: cs.onSurfaceVariant),
            onPressed: onEdit,
            visualDensity: VisualDensity.compact,
          ),
          if (!category.isDefault)
            IconButton(
              icon: Icon(LucideIcons.trash2,
                  size: 16, color: AppTheme.expenseAltColor),
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
      trailing: selected
          ? const Icon(LucideIcons.check,
          size: 16, color: AppTheme.primary)
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
  int _tab = 0; // 0 = Chi, 1 = Thu

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cats = _tab == 0 ? widget.expenseCats : widget.incomeCats;
    final total = widget.expenseCats.length + widget.incomeCats.length;

    return Column(
      children: [
        // Header row
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
                  child: Icon(LucideIcons.tag, size: 18, color: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Danh mục thu chi',
                          style: TextStyle(fontSize: 14)),
                      Text(
                        '$total danh mục · ${widget.expenseCats.length} chi, ${widget.incomeCats.length} thu',
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down,
                      size: 20, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),

        // Expanded content
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            color: cs.surface,
            child: Column(
              children: [
                const Divider(height: 1),

                // Chi / Thu tab strip + add button
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
                        onPressed: _tab == 0
                            ? widget.onAddExpense
                            : widget.onAddIncome,
                        icon: const Icon(Icons.add, size: 15),
                        label: const Text('Thêm',
                            style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Category list
                ...cats.map((cat) => _CategoryTile(
                  category: cat,
                  onEdit: () => widget.onEdit(cat),
                  onDelete: () => widget.onDelete(cat),
                )),

                const SizedBox(height: 4),
              ],
            ),
          ),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
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
          color: selected
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