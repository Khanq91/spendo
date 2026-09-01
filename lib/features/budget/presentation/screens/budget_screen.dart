import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/domain/period.dart';
import '../../../../shared/widgets/motion/motion.dart';
import '../../../../shared/widgets/spendo/spendo.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../data/budget_repository.dart';
import '../../data/category_budget_repository.dart';
import '../../domain/budget.dart';
import '../providers/budget_page_provider.dart';
import '../providers/category_budget_provider.dart';
import '../widgets/set_budget_sheet.dart';

/// Screen 09 of the redesign — the `/budget` page.
///
/// One page replaces the three stacked sheets the audit found (a chooser, a
/// month-total sheet and a category list that opened yet another sheet): the
/// month total and every category limit are now visible together, against the
/// spending they are meant to hold.
class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final period = ref.watch(budgetPeriodProvider);
    final monthBudget = ref.watch(budgetPageBudgetProvider).valueOrNull;
    final spentTotal = ref.watch(budgetSpentTotalProvider);
    final categories = ref.watch(expenseCategoriesProvider);
    final budgetMap = ref.watch(categoryBudgetMapProvider);
    final progressMap = ref.watch(budgetPageCategoryProgressProvider);

    final tracked = categories.where((c) => budgetMap.containsKey(c.id)).toList();
    final untracked = categories
        .where((c) => !budgetMap.containsKey(c.id))
        .toList();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SpendoScreenHeader(
              title: 'Hạn mức',
              actions: [
                SpendoPeriodStepper(
                  period: period,
                  onChanged: (next) =>
                      ref.read(budgetPeriodProvider.notifier).state = next,
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  _MonthTotalCard(
                    period: period,
                    budget: monthBudget?.amount,
                    spent: spentTotal,
                    onSet: () => _setMonthBudget(
                      context,
                      ref,
                      period: period,
                      existing: monthBudget?.amount,
                      spent: spentTotal,
                    ),
                    onClear: monthBudget == null
                        ? null
                        : () => _clearMonthBudget(context, ref, period: period),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                    child: SpendoSectionHeader(
                      label: 'Theo danh mục',
                      padding: EdgeInsets.zero,
                      trailing: untracked.isEmpty
                          ? null
                          : SpendoChip(
                              label: 'Đặt',
                              icon: LucideIcons.plus,
                              onTap: () => _pickCategory(
                                context,
                                ref,
                                untracked,
                              ),
                            ),
                    ),
                  ),
                  if (tracked.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SpendoEmptyState(
                        icon: LucideIcons.target,
                        title: 'Chưa đặt hạn mức danh mục nào',
                        message: categories.isEmpty
                            ? 'Thêm danh mục chi trước đã.'
                            : 'Đặt giới hạn riêng cho các khoản hay vượt.',
                        actionLabel: untracked.isEmpty ? null : 'Chọn danh mục',
                        onAction: untracked.isEmpty
                            ? null
                            : () => _pickCategory(context, ref, untracked),
                      ),
                    )
                  else
                    for (final category in tracked)
                      _CategoryBudgetRow(
                        key: ValueKey('budget_${category.id}'),
                        category: category,
                        amount: budgetMap[category.id]!.amount,
                        spent: progressMap[category.id]?.spent ?? 0,
                        onEdit: () => _setCategoryBudget(
                          context,
                          ref,
                          category: category,
                          existing: budgetMap[category.id]!.amount,
                          spent: progressMap[category.id]?.spent ?? 0,
                        ),
                        onDelete: () => _deleteCategoryBudget(
                          context,
                          category: category,
                          amount: budgetMap[category.id]!.amount,
                        ),
                      ),
                  if (untracked.isNotEmpty && tracked.isNotEmpty)
                    _UntrackedChips(
                      categories: untracked,
                      onTap: (category) => _setCategoryBudget(
                        context,
                        ref,
                        category: category,
                        existing: null,
                        spent:
                            ref.read(budgetSpentByCategoryProvider)[category.id] ??
                            0,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                    child: _Hint(
                      text: tracked.isEmpty
                          ? 'Hạn mức danh mục áp dụng cho mọi tháng; tiến độ tính theo kỳ đang xem.'
                          : 'Chạm một danh mục để sửa. Vuốt sang trái để xoá hạn mức — có Hoàn tác.',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _setMonthBudget(
    BuildContext context,
    WidgetRef ref, {
    required Period period,
    required int? existing,
    required int spent,
  }) async {
    final amount = await SetBudgetSheet.show(
      context: context,
      title: 'Hạn mức tháng',
      subtitle: period.label,
      existingAmount: existing,
      spent: spent,
    );
    if (amount == null) return;
    await BudgetRepository().set(Budget.monthKey(period.start), amount);
  }

  Future<void> _clearMonthBudget(
    BuildContext context,
    WidgetRef ref, {
    required Period period,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final key = Budget.monthKey(period.start);
    final previous = ref.read(budgetPageBudgetProvider).valueOrNull;
    if (previous == null) return;

    final repo = BudgetRepository();
    await repo.delete(key);
    // Deleting a limit used to happen on one tap with no confirmation and no
    // way back; undo is the same trade the transaction list already makes.
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Đã xoá hạn mức ${period.label.toLowerCase()}'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Hoàn tác',
          onPressed: () => repo.set(key, previous.amount),
        ),
      ),
    );
  }

  Future<void> _pickCategory(
    BuildContext context,
    WidgetRef ref,
    List<Category> categories,
  ) async {
    final picked = await _CategoryPickerSheet.show(context, categories);
    if (picked == null || !context.mounted) return;
    await _setCategoryBudget(
      context,
      ref,
      category: picked,
      existing: null,
      spent: ref.read(budgetSpentByCategoryProvider)[picked.id] ?? 0,
    );
  }

  Future<void> _setCategoryBudget(
    BuildContext context,
    WidgetRef ref, {
    required Category category,
    required int? existing,
    required int spent,
  }) async {
    final amount = await SetBudgetSheet.show(
      context: context,
      title: existing == null ? 'Đặt hạn mức' : 'Sửa hạn mức',
      subtitle: category.name,
      leading: SpendoIconTile.category(
        iconName: category.iconName,
        color: category.color,
        size: 36,
      ),
      existingAmount: existing,
      spent: spent,
    );
    if (amount == null) return;
    await CategoryBudgetRepository().set(category.id, amount);
  }

  Future<void> _deleteCategoryBudget(
    BuildContext context, {
    required Category category,
    required int amount,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = CategoryBudgetRepository();
    await repo.delete(category.id);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Đã xoá hạn mức ${category.name}'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Hoàn tác',
          onPressed: () => repo.set(category.id, amount),
        ),
      ),
    );
  }
}

// ── Month total ──────────────────────────────────────────────────────────────

class _MonthTotalCard extends StatelessWidget {
  const _MonthTotalCard({
    required this.period,
    required this.budget,
    required this.spent,
    required this.onSet,
    required this.onClear,
  });

  final Period period;
  final int? budget;
  final int spent;
  final VoidCallback onSet;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final limit = budget;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SpendoCard(
        feature: true,
        child: limit == null
            ? _NoMonthBudget(spent: spent, onSet: onSet)
            : _MonthBudgetProgress(
                budget: limit,
                spent: spent,
                onSet: onSet,
                onClear: onClear,
                labelColor: cs.onSurfaceVariant,
              ),
      ),
    );
  }
}

class _NoMonthBudget extends StatelessWidget {
  const _NoMonthBudget({required this.spent, required this.onSet});

  final int spent;
  final VoidCallback onSet;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tổng tháng',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Chưa đặt hạn mức · đã chi ${formatVND(spent)}',
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurfaceVariant,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 12),
        SpendoButton.outline(label: 'Đặt hạn mức tháng', onPressed: onSet),
      ],
    );
  }
}

class _MonthBudgetProgress extends StatelessWidget {
  const _MonthBudgetProgress({
    required this.budget,
    required this.spent,
    required this.onSet,
    required this.onClear,
    required this.labelColor,
  });

  final int budget;
  final int spent;
  final VoidCallback onSet;
  final VoidCallback? onClear;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    final percent = budget > 0 ? spent / budget : 0.0;
    final display = (percent * 100).clamp(0, 999).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text(
              'Tổng tháng',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              '$display%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: SpendoProgressBar.colorFor(context, percent),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SpendoProgressBar(value: percent),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'Đã chi ${formatVND(spent)} / ${formatVND(budget)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: labelColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 8),
            SpendoChip(label: 'Sửa', onTap: onSet),
            if (onClear != null) ...[
              const SizedBox(width: 6),
              SpendoHeaderIconButton(
                icon: LucideIcons.trash2,
                tooltip: 'Xoá hạn mức tháng',
                size: 17,
                onPressed: onClear!,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ── Category rows ────────────────────────────────────────────────────────────

class _CategoryBudgetRow extends StatelessWidget {
  const _CategoryBudgetRow({
    super.key,
    required this.category,
    required this.amount,
    required this.spent,
    required this.onEdit,
    required this.onDelete,
  });

  final Category category;
  final int amount;
  final int spent;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final percent = amount > 0 ? spent / amount : 0.0;
    final barColor = SpendoProgressBar.colorFor(context, percent);
    final isOver = spent > amount;

    return Dismissible(
      key: ValueKey('budget_dismiss_${category.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: cs.errorContainer,
        child: Icon(LucideIcons.trash2, size: 20, color: cs.onErrorContainer),
      ),
      child: PressableScale(
        deferTapToChild: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onEdit,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      SpendoIconTile.category(
                        iconName: category.iconName,
                        color: category.color,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // "1.800.000 ₫ / 1.500.000 ₫" beside a category name is
                      // wider than a 360dp row, so the figures scale down
                      // rather than pushing the name off the edge.
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${formatVND(spent)} / ${formatVND(amount)}',
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: cs.onSurfaceVariant,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 52, top: 8),
                    child: Row(
                      children: [
                        Expanded(child: SpendoProgressBar(value: percent)),
                        const SizedBox(width: 10),
                        Text(
                          isOver
                              ? 'Vượt +${formatVND(spent - amount)}'
                              : '${(percent * 100).clamp(0, 999).round()}%',
                          maxLines: 1,
                          softWrap: false,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: barColor,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Categories with no limit yet, as tappable chips.
class _UntrackedChips extends StatelessWidget {
  const _UntrackedChips({required this.categories, required this.onTap});

  final List<Category> categories;
  final ValueChanged<Category> onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chưa đặt hạn mức',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in categories)
                SpendoChip(
                  label: category.name,
                  onTap: () => onTap(category),
                  leading: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: category.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Grid of the categories still without a limit.
class _CategoryPickerSheet extends StatelessWidget {
  const _CategoryPickerSheet({required this.categories});

  final List<Category> categories;

  static Future<Category?> show(
    BuildContext context,
    List<Category> categories,
  ) {
    return SpendoSheet.showModal<Category>(
      context: context,
      builder: (_) => _CategoryPickerSheet(categories: categories),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SpendoSheet(
      header: const SpendoSheetHeader(title: 'Chọn danh mục'),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.5,
        ),
        child: GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          mainAxisSpacing: 14,
          crossAxisSpacing: 8,
          childAspectRatio: 0.85,
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          children: [
            for (final category in categories)
              SpendoCategoryTile(
                label: category.name,
                color: category.color,
                iconName: category.iconName,
                onTap: () => Navigator.of(context).pop(category),
              ),
          ],
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SpendoCard(
      color: cs.surfaceContainerLowest,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              LucideIcons.info,
              size: 16,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
