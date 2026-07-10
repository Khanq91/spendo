import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../transactions/presentation/widgets/amount_input_controller.dart';
import '../../../transactions/presentation/widgets/numpad.dart';
import '../../data/category_budget_repository.dart';
import '../providers/category_budget_provider.dart';
import '../../../../shared/widgets/motion/motion.dart';

class CategoryBudgetScreen extends ConsumerWidget {
  const CategoryBudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allCats = ref.watch(expenseCategoriesProvider);
    final budgetMap = ref.watch(categoryBudgetMapProvider);
    final progressMap = ref.watch(categoryBudgetProgressProvider);
    final cs = Theme.of(context).colorScheme;

    // Tách: đã có budget lên trên, chưa có xuống dưới
    final withBudget =
        allCats.where((c) => budgetMap.containsKey(c.id)).toList();
    final withoutBudget =
        allCats.where((c) => !budgetMap.containsKey(c.id)).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder:
          (_, scrollCtrl) => Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    const Text(
                      'Hạn mức theo danh mục',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${withBudget.length}/${allCats.length} danh mục',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  children: [
                    // ── Đã có budget ──────────────────────────────────────────
                    if (withBudget.isNotEmpty) ...[
                      _SectionLabel(label: 'Đang theo dõi'),
                      ...withBudget.map((cat) {
                        final progress = progressMap[cat.id];
                        final budget = budgetMap[cat.id]!;
                        return _CategoryBudgetTile(
                          category: cat,
                          budgetAmount: budget.amount,
                          progress: progress,
                          onEdit:
                              () => _openSetSheet(
                                context,
                                ref,
                                cat,
                                existingAmount: budget.amount,
                              ),
                          onDelete: () async {
                            await CategoryBudgetRepository().delete(cat.id);
                          },
                        );
                      }),
                    ],

                    // ── Chưa có budget ────────────────────────────────────────
                    if (withoutBudget.isNotEmpty) ...[
                      _SectionLabel(
                        label:
                            withBudget.isEmpty
                                ? 'Chọn danh mục để đặt hạn mức'
                                : 'Thêm danh mục',
                      ),
                      ...withoutBudget.map(
                        (cat) => _CategoryNobudgetTile(
                          category: cat,
                          onAdd: () => _openSetSheet(context, ref, cat),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  void _openSetSheet(
    BuildContext context,
    WidgetRef ref,
    Category cat, {
    int? existingAmount,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => _SetCategoryBudgetSheet(
            category: cat,
            existingAmount: existingAmount,
          ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: cs.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Tile: danh mục đã có budget ───────────────────────────────────────────────

class _CategoryBudgetTile extends StatelessWidget {
  final Category category;
  final int budgetAmount;
  final ({int budget, int spent, double percent, bool isOver})? progress;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryBudgetTile({
    required this.category,
    required this.budgetAmount,
    required this.progress,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = category.color;
    final p = progress;

    // Màu progress bar theo mức độ
    Color barColor = AppTheme.incomeColor;
    if (p != null) {
      if (p.isOver) {
        barColor = AppTheme.expenseAltColor;
      } else if (p.percent >= 0.8) {
        barColor = Colors.orange;
      }
    }

    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              categoryIcon(category.iconName),
              size: 20,
              color: color,
            ),
          ),
          title: Text(
            category.name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          subtitle:
              p != null
                  ? Text(
                    '${formatVND(p.spent)} / ${formatVND(budgetAmount)}'
                    '${p.isOver ? '  ⚠️ Vượt hạn' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          p.isOver
                              ? AppTheme.expenseAltColor
                              : cs.onSurfaceVariant,
                    ),
                  )
                  : Text(
                    formatVND(budgetAmount),
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
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
        ),
        // Progress bar
        if (p != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(56, 0, 16, 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: AnimatedProgressBar(
                value: p.percent,
                height: 4,
                trackColor: barColor.withOpacity(0.15),
                valueColor: barColor,
              ),
            ),
          ),
        Divider(height: 1, indent: 56, color: cs.outlineVariant),
      ],
    );
  }
}

// ── Tile: danh mục chưa có budget ─────────────────────────────────────────────

class _CategoryNobudgetTile extends StatelessWidget {
  final Category category;
  final VoidCallback onAdd;

  const _CategoryNobudgetTile({required this.category, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = category.color;

    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              categoryIcon(category.iconName),
              size: 20,
              color: color.withOpacity(0.6),
            ),
          ),
          title: Text(
            category.name,
            style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
          ),
          subtitle: Text(
            'Chưa đặt hạn mức',
            style: TextStyle(fontSize: 12, color: cs.outlineVariant),
          ),
          trailing: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Đặt', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
        Divider(height: 1, indent: 56, color: cs.outlineVariant),
      ],
    );
  }
}

// ── Bottom sheet nhập hạn mức cho 1 category ─────────────────────────────────

class _SetCategoryBudgetSheet extends StatefulWidget {
  final Category category;
  final int? existingAmount;

  const _SetCategoryBudgetSheet({required this.category, this.existingAmount});

  @override
  State<_SetCategoryBudgetSheet> createState() =>
      _SetCategoryBudgetSheetState();
}

class _SetCategoryBudgetSheetState extends State<_SetCategoryBudgetSheet> {
  final _amountCtrl = AmountInputController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingAmount != null) {
      _amountCtrl.prefill(widget.existingAmount!.toString());
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_amountCtrl.hasValue) return;
    setState(() => _loading = true);
    await CategoryBudgetRepository().set(widget.category.id, _amountCtrl.value);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = widget.category.color;
    final isEdit = widget.existingAmount != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    categoryIcon(widget.category.iconName),
                    size: 16,
                    color: color,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? 'Sửa hạn mức' : 'Đặt hạn mức',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        widget.category.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Amount display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ListenableBuilder(
                  listenable: _amountCtrl,
                  builder:
                      (_, __) => Text(
                        _amountCtrl.formatted,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: color,
                          letterSpacing: -1,
                        ),
                      ),
                ),
                const SizedBox(width: 4),
                Text(
                  '₫',
                  style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),

          const Divider(height: 16, thickness: 0.5),

          ListenableBuilder(
            listenable: _amountCtrl,
            builder: (_, __) => Numpad(onKey: _amountCtrl.press),
          ),

          // Save button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: ListenableBuilder(
              listenable: _amountCtrl,
              builder:
                  (_, __) => FilledButton(
                    onPressed: _amountCtrl.hasValue && !_loading ? _save : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: appMotion.whenMotionAllowed(
                        context,
                        appMotion.tapUpDuration,
                      ),
                      child:
                          _loading
                              ? const SizedBox(
                                key: ValueKey('category_budget_loading'),
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : Text(
                                isEdit
                                    ? 'Cập nhật hạn mức'
                                    : 'Đặt hạn mức ${_amountCtrl.formatted} ₫',
                                key: const ValueKey('category_budget_label'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
