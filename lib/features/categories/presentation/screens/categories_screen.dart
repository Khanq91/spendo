import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/widgets/spendo/spendo.dart';
import '../../../../core/utils/category_icons.dart';
import '../../domain/category.dart';
import '../providers/category_provider.dart';
import '../widgets/category_form_sheet.dart';

/// Screen 14 of the redesign — `/settings/categories`.
///
/// Categories used to live at the bottom of the Settings list inside an
/// expansion tile (`20-settings.md` §L): a core entity buried under eight
/// unrelated groups. They get their own page, with the type toggle promoted
/// to a segmented control and the transaction count on every row.
class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  bool _income = false;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final countsAsync = ref.watch(categoryTransactionCountsProvider);

    final all = categoriesAsync.valueOrNull ?? const <Category>[];
    final expense = all.where((c) => !c.isIncome).toList();
    final income = all.where((c) => c.isIncome).toList();
    final shown = _income ? income : expense;
    final counts = countsAsync.valueOrNull ?? const <String, int>{};

    final hasInitialError =
        categoriesAsync.hasError && !categoriesAsync.hasValue;
    final isLoading = categoriesAsync.isLoading && !categoriesAsync.hasValue;

    return Scaffold(
      floatingActionButton: SpendoExtendedFab(
        heroTag: 'categories_fab',
        label: 'Thêm danh mục',
        onPressed: () => showCategoryFormSheet(context, isIncome: _income),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SpendoScreenHeader(title: 'Danh mục'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SpendoSegmented<bool>(
                  value: _income,
                  onChanged: (value) => setState(() => _income = value),
                  options: [
                    (value: false, label: 'Chi (${expense.length})'),
                    (value: true, label: 'Thu (${income.length})'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: switch ((hasInitialError, isLoading)) {
                (true, _) => SpendoEmptyState(
                  icon: LucideIcons.circleAlert,
                  title: 'Không tải được danh mục',
                  message: 'Kiểm tra kết nối rồi thử lại.',
                  actionLabel: 'Thử lại',
                  onAction: () => ref.invalidate(categoriesProvider),
                ),
                (_, true) => const Center(child: CircularProgressIndicator()),
                _ when shown.isEmpty => SpendoEmptyState(
                  icon: LucideIcons.tag,
                  title: _income
                      ? 'Chưa có danh mục thu nào'
                      : 'Chưa có danh mục chi nào',
                  message: 'Thêm danh mục để phân loại giao dịch.',
                  actionLabel: 'Thêm danh mục',
                  onAction: () =>
                      showCategoryFormSheet(context, isIncome: _income),
                ),
                _ => _CategoryList(
                  // Rebuilds the reorderable list from scratch when the side
                  // flips, so it never animates an expense row into an income
                  // one.
                  key: ValueKey(_income),
                  categories: shown,
                  counts: counts,
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  const _CategoryList({
    super.key,
    required this.categories,
    required this.counts,
  });

  final List<Category> categories;
  final Map<String, int> counts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 120),
      itemCount: categories.length + 1,
      // Already adjusts newIndex for the removed row, so no off-by-one fix up.
      onReorderItem: (oldIndex, newIndex) =>
          _reorder(context, ref, oldIndex, newIndex),
      itemBuilder: (context, index) {
        if (index == categories.length) {
          return const Padding(
            key: ValueKey('categories_hint'),
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _Hint(
              text:
                  'Danh mục còn giao dịch không xoá được. Kéo ☰ để đổi thứ tự '
                  '— thứ tự này là thứ tự trong lưới Thêm giao dịch.',
            ),
          );
        }

        final category = categories[index];
        return _CategoryTile(
          key: ValueKey(category.id),
          index: index,
          category: category,
          count: counts[category.id] ?? 0,
        );
      },
    );
  }

  Future<void> _reorder(
    BuildContext context,
    WidgetRef ref,
    int oldIndex,
    int newIndex,
  ) async {
    // The hint sits in the list so it scrolls with the rows, but it is not a
    // droppable position and never moves.
    if (oldIndex >= categories.length) return;
    if (newIndex >= categories.length) newIndex = categories.length - 1;
    if (newIndex == oldIndex) return;

    final ordered = List<Category>.from(categories);
    ordered.insert(newIndex, ordered.removeAt(oldIndex));

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(categoryRepoProvider)
          .reorder(ordered.map((c) => c.id).toList());
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Không lưu được thứ tự. Thử lại.')),
      );
    }
  }
}

class _CategoryTile extends ConsumerWidget {
  const _CategoryTile({
    super.key,
    required this.index,
    required this.category,
    required this.count,
  });

  final int index;
  final Category category;
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    // A default category has no delete affordance to begin with, and one that
    // still holds transactions cannot be deleted at all — so the swipe is only
    // armed where it can actually finish.
    final canDelete = !category.isDefault && count == 0;

    final row = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showCategoryFormSheet(context, existing: category),
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              SpendoIconTile(
                icon: categoryIcon(category.iconName),
                color: category.color,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    LucideIcons.gripVertical,
                    size: 20,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!canDelete) return row;

    return Dismissible(
      key: ValueKey('dismiss_${category.id}'),
      direction: DismissDirection.endToStart,
      background: const _DeleteBackground(),
      onDismissed: (_) => _deleteWithUndo(context, ref, category),
      child: row,
    );
  }

  String get _subtitle {
    final usage = count == 0 ? 'Chưa dùng' : '$count giao dịch';
    return category.isDefault ? 'Mặc định · $usage' : usage;
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.errorContainer,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: Icon(LucideIcons.trash2, size: 20, color: cs.onErrorContainer),
    );
  }
}

/// Deletes [category] and offers an undo, matching every other delete in the
/// app since Phase 3 (`HANDOFF-STATE` §2.4c).
Future<void> deleteCategoryWithUndo(
  BuildContext context,
  WidgetRef ref,
  Category category,
) => _deleteWithUndo(context, ref, category);

Future<void> _deleteWithUndo(
  BuildContext context,
  WidgetRef ref,
  Category category,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final repo = ref.read(categoryRepoProvider);

  try {
    await repo.delete(category.id);
  } catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text(error.toString().replaceAll('Exception: ', ''))),
    );
    return;
  }

  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Text('Đã xoá "${category.name}"'),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'Hoàn tác',
        onPressed: () async {
          try {
            await repo.restore(category);
          } catch (_) {
            messenger.showSnackBar(
              const SnackBar(content: Text('Không khôi phục được danh mục.')),
            );
          }
        },
      ),
    ),
  );
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SpendoCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      color: cs.surfaceContainerLowest,
      child: Text(
        text,
        style: TextStyle(fontSize: 12, height: 1.5, color: cs.onSurfaceVariant),
      ),
    );
  }
}
