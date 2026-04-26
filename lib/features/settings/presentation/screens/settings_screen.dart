import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/export_service.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/data/category_repository.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../categories/presentation/widgets/category_form_sheet.dart';

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
      tileColor: Colors.white,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF6C63FF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.download_outlined,
            size: 18, color: Color(0xFF6C63FF)),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      subtitle: Text(subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      trailing: const Icon(Icons.chevron_right, size: 18),
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
      tileColor: Colors.white,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: category.color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            _iconEmoji(category.iconName),
            style: const TextStyle(fontSize: 18),
          ),
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
            icon: Icon(Icons.edit_outlined,
                size: 18, color: Colors.grey.shade500),
            onPressed: onEdit,
            visualDensity: VisualDensity.compact,
          ),
          if (!category.isDefault)
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: Color(0xFFE53935)),
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  String _iconEmoji(String iconName) {
    const map = {
      'restaurant': '🍜',
      'directions_car': '🚗',
      'school': '📚',
      'sports_esports': '🎮',
      'favorite': '💊',
      'shopping_bag': '🛍️',
      'more_horiz': '📦',
      'work': '💼',
      'laptop': '💻',
      'storefront': '🏪',
      'card_giftcard': '🎁',
      'home': '🏠',
      'flight': '✈️',
      'movie': '🎬',
      'fitness_center': '💪',
      'pets': '🐾',
    };
    return map[iconName] ?? '💰';
  }
}