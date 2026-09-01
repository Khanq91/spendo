import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/spendo_colors.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/widget_sync.dart';
import '../../../../shared/widgets/spendo/spendo.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../providers/widget_pin_provider.dart';

/// Screen 23 of the redesign — `/settings/widget`.
///
/// The old section packed four 75px cards into one row, each clearable only
/// through a 12px `×` in its corner (`29-widget-pin-picker-sheet.md` §L). The
/// page shows what the widget will actually look like and gives each slot a
/// full row with a real "Bỏ ghim" button.
class WidgetScreen extends ConsumerWidget {
  const WidgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinnedIds = ref.watch(widgetPinnedIdsProvider);
    final categories = ref.watch(expenseCategoriesProvider);
    final byId = {for (final c in categories) c.id: c};

    final slots = List<String>.from(pinnedIds);
    while (slots.length < 4) {
      slots.add('');
    }
    final pinned = [for (final id in slots) byId[id]];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SpendoScreenHeader(title: 'Widget màn hình chính'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  const _Label('XEM TRƯỚC (2×2)'),
                  _Preview(pinned: pinned),
                  const _Label('4 SLOT'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SpendoSettingsGroup(
                      children: [
                        for (var i = 0; i < 4; i++)
                          _SlotRow(
                            index: i,
                            category: pinned[i],
                            usedIds: {
                              for (var j = 0; j < 4; j++)
                                if (j != i && slots[j].isNotEmpty) slots[j],
                            },
                            categories: categories,
                          ),
                      ],
                    ),
                  ),
                  const _Hint(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Preview ──────────────────────────────────────────────────────────────────

class _Preview extends StatelessWidget {
  const _Preview({required this.pinned});

  final List<Category?> pinned;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppTheme.radiusCardFeature),
        ),
        child: Center(
          child: Container(
            width: 210,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppTheme.radiusCardFeature),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Spendo',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: theme.spendo.brand,
                  ),
                ),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.5,
                  children: [
                    for (final category in pinned)
                      _PreviewCell(category: category),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewCell extends StatelessWidget {
  const _PreviewCell({required this.category});

  final Category? category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (category == null) {
      return DottedBorderBox(
        color: theme.spendo.dashedOutline,
        radius: 14,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.plus, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(height: 4),
              Text(
                'Trống',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: category!.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              categoryIcon(category!.iconName),
              size: 16,
              color: category!.color,
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                category!.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── One slot ─────────────────────────────────────────────────────────────────

class _SlotRow extends ConsumerWidget {
  const _SlotRow({
    required this.index,
    required this.category,
    required this.usedIds,
    required this.categories,
  });

  final int index;
  final Category? category;
  final Set<String> usedIds;
  final List<Category> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _pick(context, ref),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
          child: Row(
            children: [
              SizedBox(
                width: 42,
                child: Text(
                  'Slot ${index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (category != null)
                SpendoIconTile(
                  icon: categoryIcon(category!.iconName),
                  color: category!.color,
                  size: 32,
                )
              else
                SpendoDashedCircle(
                  size: 32,
                  color: Theme.of(context).spendo.dashedOutline,
                  child: Icon(
                    LucideIcons.plus,
                    size: 15,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category?.name ?? 'Chọn danh mục…',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: category != null
                        ? cs.onSurface
                        : cs.onSurfaceVariant,
                  ),
                ),
              ),
              if (category != null) ...[
                const SizedBox(width: 8),
                // Replaces the 12px `×` in the card corner — a real tap target
                // that says what it does.
                SpendoChip(
                  label: 'Bỏ ghim',
                  onTap: () async {
                    await ref
                        .read(widgetPinnedIdsProvider.notifier)
                        .clearSlot(index);
                    await WidgetSync.syncCategories();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final picked = await SpendoSheet.showModal<Category>(
      context: context,
      builder: (sheetContext) => _CategoryPickerSheet(
        slot: index,
        categories: categories,
        usedIds: usedIds,
        selectedId: category?.id,
      ),
    );

    if (picked == null) return;
    await ref.read(widgetPinnedIdsProvider.notifier).setSlot(index, picked.id);
    await WidgetSync.syncCategories();
  }
}

class _CategoryPickerSheet extends StatelessWidget {
  const _CategoryPickerSheet({
    required this.slot,
    required this.categories,
    required this.usedIds,
    required this.selectedId,
  });

  final int slot;
  final List<Category> categories;
  final Set<String> usedIds;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (categories.isEmpty) {
      return SpendoSheet(
        header: SpendoSheetHeader(title: 'Chọn danh mục cho slot ${slot + 1}'),
        child: const SpendoEmptyState(
          icon: LucideIcons.tag,
          title: 'Chưa có danh mục chi nào',
          message: 'Thêm danh mục chi trước khi ghim lên widget.',
        ),
      );
    }

    return SpendoSheet(
      header: SpendoSheetHeader(title: 'Chọn danh mục cho slot ${slot + 1}'),
      child: SingleChildScrollView(
        child: SpendoSettingsGroup(
          children: [
            for (final category in categories)
              SpendoSettingsRow(
                icon: categoryIcon(category.iconName),
                label: category.name,
                subtitle: usedIds.contains(category.id)
                    ? 'Đang dùng ở slot khác'
                    : null,
                enabled: !usedIds.contains(category.id),
                showChevron: false,
                trailing: category.id == selectedId
                    ? Icon(LucideIcons.check, size: 18, color: cs.primary)
                    : null,
                onTap: () => Navigator.pop(context, category),
              ),
          ],
        ),
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

class _Hint extends StatelessWidget {
  const _Hint();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SpendoCard(
        color: cs.surfaceContainerLowest,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Text(
          'Ghim bao nhiêu dùng bấy nhiêu — slot trống hiện "+" trên widget. '
          'Chỉ danh mục chi mới ghim được.',
          style: TextStyle(
            fontSize: 12,
            height: 1.5,
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
