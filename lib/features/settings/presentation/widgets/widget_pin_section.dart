import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/widget_sync.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../providers/widget_pin_provider.dart';

class WidgetPinSection extends ConsumerWidget {
  const WidgetPinSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinnedIds = ref.watch(widgetPinnedIdsProvider);
    final allCats = ref.watch(expenseCategoriesProvider);

    // Đảm bảo đủ 4 slot
    final slots = List<String>.from(pinnedIds);
    while (slots.length < 4) slots.add('');

    final catMap = {for (final c in allCats) c.id: c};

    return Column(
      children: [
        Row(
          children: List.generate(4, (i) {
            final id = slots[i];
            final cat = catMap[id];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: i == 0 ? 0 : 6,
                  right: i == 3 ? 0 : 6,
                ),
                child: _SlotCard(
                  slot: i,
                  category: cat,
                  onTap: () => _pickCategory(context, ref, i, slots, allCats),
                  onClear: cat != null
                      ? () async {
                    await ref
                        .read(widgetPinnedIdsProvider.notifier)
                        .clearSlot(i);
                    await WidgetSync.syncCategories();
                  }
                      : null,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap vào ô để chọn danh mục hiển thị trên widget',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _pickCategory(
      BuildContext context,
      WidgetRef ref,
      int slot,
      List<String> currentSlots,
      List<Category> allCats,
      ) async {
    final picked = await showModalBottomSheet<Category>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CategoryPickerSheet(
        allCats: allCats,
        currentSlots: currentSlots,
        currentSlotIndex: slot,
      ),
    );

    if (picked != null) {
      await ref.read(widgetPinnedIdsProvider.notifier).setSlot(slot, picked.id);
      await WidgetSync.syncCategories();
    }
  }
}

class _SlotCard extends StatelessWidget {
  final int slot;
  final Category? category;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _SlotCard({
    required this.slot,
    required this.category,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final color = category?.color ?? Colors.grey.shade300;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: category != null
              ? color.withOpacity(0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: category != null
                ? color.withOpacity(0.4)
                : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: category != null
            ? Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(categoryIcon(category!.iconName),
                      size: 22, color: color),
                  const SizedBox(height: 4),
                  Text(
                    category!.name,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (onClear != null)
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: onClear,
                  child: Icon(LucideIcons.x,
                      size: 12, color: Colors.grey.shade400),
                ),
              ),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.plus,
                size: 20, color: Colors.grey.shade400),
            const SizedBox(height: 2),
            Text(
              'Slot ${slot + 1}',
              style: TextStyle(
                  fontSize: 10, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPickerSheet extends StatelessWidget {
  final List<Category> allCats;
  final List<String> currentSlots;
  final int currentSlotIndex;

  const _CategoryPickerSheet({
    required this.allCats,
    required this.currentSlots,
    required this.currentSlotIndex,
  });

  @override
  Widget build(BuildContext context) {
    // Các slot khác đang dùng (trừ slot hiện tại)
    final usedIds = currentSlots
        .asMap()
        .entries
        .where((e) => e.key != currentSlotIndex)
        .map((e) => e.value)
        .toSet();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          width: 36, height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Text(
            'Chọn danh mục cho slot ${currentSlotIndex + 1}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        const Divider(height: 1),
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: allCats.length,
            separatorBuilder: (_, __) =>
            const Divider(height: 1, indent: 56),
            itemBuilder: (_, i) {
              final cat = allCats[i];
              final isUsed = usedIds.contains(cat.id);
              return ListTile(
                leading: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: cat.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(categoryIcon(cat.iconName),
                      size: 18, color: cat.color),
                ),
                title: Text(cat.name,
                    style: TextStyle(
                      fontSize: 14,
                      color: isUsed ? Colors.grey.shade400 : null,
                    )),
                subtitle: isUsed
                    ? Text('Đang dùng ở slot khác',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade400))
                    : null,
                trailing: isUsed
                    ? null
                    : const Icon(Icons.chevron_right,
                    size: 18, color: Colors.grey),
                onTap: isUsed ? null : () => Navigator.pop(context, cat),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}