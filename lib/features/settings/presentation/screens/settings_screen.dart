import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/notifications/notification_provider.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/export_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/data/category_repository.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../categories/presentation/widgets/category_form_sheet.dart';
import '../../../auth/presentation/screens/auth_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/theme_provider.dart';
import '../widgets/widget_pin_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final allCats = categoriesAsync.valueOrNull ?? [];
    final expenseCats = allCats.where((c) => !c.isIncome).toList();
    final incomeCats = allCats.where((c) => c.isIncome).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
        title: const Text(
          'Cài đặt',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        children: [
          // ── Export section ──────────────────────────────────────
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

          // ── UI Section ──────────────────────────────────
          _SectionHeader(title: 'Giao diện'),
          Consumer(
            builder: (context, ref, _) {
              final mode = ref.watch(themeModeProvider);
              return Container(
                color: Colors.white,
                child: Column(
                  children: [
                    _ThemeTile(
                      label: 'Theo hệ thống',
                      icon: LucideIcons.monitor,
                      selected: mode == ThemeMode.system,
                      onTap: () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.system),
                    ),
                    _ThemeTile(
                      label: 'Sáng',
                      icon: LucideIcons.sun,
                      selected: mode == ThemeMode.light,
                      onTap: () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.light),
                    ),
                    _ThemeTile(
                      label: 'Tối',
                      icon: LucideIcons.moon,
                      selected: mode == ThemeMode.dark,
                      onTap: () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.dark),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),


          // ── Notification Section ──────────────────────────────────
          _SectionHeader(title: 'Thông báo'),
          Consumer(
            builder: (context, ref, _) {
              final enabled = ref.watch(notificationEnabledProvider);
              final hour = ref.watch(notificationHourProvider);
              final minute = ref.watch(notificationMinuteProvider);

              return Container(
                color: Theme.of(context).listTileTheme.tileColor,
                child: Column(
                  children: [
                    // Toggle on/off
                    ListTile(
                      leading: Icon(
                        LucideIcons.bell,
                        size: 18,
                        color: enabled
                            ? AppTheme.primary
                            : Colors.grey.shade500,
                      ),
                      title: const Text('Nhắc nhập chi tiêu',
                          style: TextStyle(fontSize: 14)),
                      subtitle: Text(
                        'Mỗi ngày lúc ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
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
                          ref.read(notificationEnabledProvider.notifier).toggle(
                            val,
                            hour: hour,
                            minute: minute,
                          );
                        },
                      ),
                    ),

                    // Chọn giờ — chỉ hiện khi enabled
                    if (enabled)
                      ListTile(
                        leading: Icon(LucideIcons.clock,
                            size: 18, color: Colors.grey.shade500),
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
                            initialTime: TimeOfDay(hour: hour, minute: minute),
                          );
                          if (picked != null) {
                            await ref
                                .read(notificationHourProvider.notifier)
                                .set(picked.hour);
                            await ref
                                .read(notificationMinuteProvider.notifier)
                                .set(picked.minute);
                            // Reschedule với giờ mới
                            await NotificationService.scheduleDailyReminder(
                              hour: picked.hour,
                              minute: picked.minute,
                            );
                          }
                        },
                      ),
                    if (enabled)
                      ListTile(
                        leading: Icon(LucideIcons.bellRing,
                            size: 18, color: Colors.grey.shade500),
                        title: const Text('Gửi thông báo thử',
                            style: TextStyle(fontSize: 14)),
                        subtitle: Text('Hiện sau 5 giây',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        trailing: const Icon(Icons.chevron_right, size: 18),
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

          // ── Widgets Pin Section ──────────────────────────────────
          _SectionHeader(title: 'Widget màn hình chính'),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: const WidgetPinSection(),
          ),
          const SizedBox(height: 8),

          // ── Expense categories ──────────────────────────────────
          _SectionHeader(
            title: 'Danh mục Chi',
            action: TextButton.icon(
              onPressed: () => _openForm(context, isIncome: false),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Thêm', style: TextStyle(fontSize: 13)),
            ),
          ),
          ...expenseCats.map((cat) => _CategoryTile(
            category: cat,
            onEdit: () => _openEditForm(context, cat),
            onDelete: () => _confirmDelete(context, cat),
          )),

          const SizedBox(height: 8),

          // ── Income categories ───────────────────────────────────
          _SectionHeader(
            title: 'Danh mục Thu',
            action: TextButton.icon(
              onPressed: () => _openForm(context, isIncome: true),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Thêm', style: TextStyle(fontSize: 13)),
            ),
          ),
          ...incomeCats.map((cat) => _CategoryTile(
            category: cat,
            onEdit: () => _openEditForm(context, cat),
            onDelete: () => _confirmDelete(context, cat),
          )),

          const SizedBox(height: 32),

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
          // const SizedBox(height: 32),

        ],
      ),
    );
  }

  void _openForm(BuildContext context, {required bool isIncome}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CategoryFormSheet(isIncome: isIncome),
    );
  }

  void _openEditForm(BuildContext context, Category cat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CategoryFormSheet(existing: cat, isIncome: cat.isIncome),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Category cat) async {
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
                foregroundColor: const Color(0xFFE53935)),
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
              backgroundColor: const Color(0xFFE53935),
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
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const _SectionHeader({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
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
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(LucideIcons.download,
            size: 18, color: AppTheme.primary),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      subtitle: Text(subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      trailing: const Icon(LucideIcons.chevronRight, size: 18),
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
          style: TextStyle(fontSize: 11, color: Colors.grey.shade400))
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(LucideIcons.pencil,
                size: 16, color: Colors.grey.shade500),
            onPressed: onEdit,
            visualDensity: VisualDensity.compact,
          ),
          if (!category.isDefault)
            IconButton(
              icon: const Icon(LucideIcons.trash2,
                  size: 16, color: AppTheme.expenseColor),
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
    return ListTile(
      leading: Icon(
        icon,
        size: 18,
        color: selected ? AppTheme.primary : Colors.grey.shade500,
      ),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: selected
          ? const Icon(LucideIcons.check, size: 16, color: AppTheme.primary)
          : null,
      onTap: onTap,
    );
  }
}