import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/db/powersync_db.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../categories/domain/category.dart';

// ── Result ────────────────────────────────────────────────────────────────────

class NotePickerResult {
  final String note;
  final String? categoryId;

  const NotePickerResult({required this.note, required this.categoryId});
}

// ── Default notes per icon_name ───────────────────────────────────────────────

const _kDefaultNotes = <String, List<String>>{
  'restaurant': ['Ăn sáng', 'Ăn trưa', 'Ăn tối', 'Cà phê', 'Trà sữa', 'Đi ăn', 'Bia', 'Đặt đồ ăn'],
  'directions_car': ['Xăng xe', 'Grab', 'Taxi', 'Gửi xe', 'Sửa xe', 'Gojek', 'Be'],
  'school': ['Học phí', 'Sách giáo khoa', 'Khóa học online', 'Văn phòng phẩm', 'Udemy'],
  'shopping_bag': ['Shopee', 'Lazada', 'Tiki', 'Siêu thị', 'Quần áo', 'Giày dép', 'Mỹ phẩm'],
  'favorite': ['Thuốc', 'Khám bệnh', 'Gym', 'Spa', 'Vitamin', 'Bệnh viện'],
  'sports_esports': ['Netflix', 'Spotify', 'Game', 'Phim rạp', 'CGV', 'Karaoke', 'Steam'],
  'work': ['Lương tháng', 'Thưởng', 'Lương thưởng', 'Phụ cấp'],
  'laptop': ['Freelance', 'Dự án', 'Hợp đồng', 'Thu nhập thêm'],
  'storefront': ['Bán hàng', 'Doanh thu', 'Hàng bán được'],
  'card_giftcard': ['Quà sinh nhật', 'Tiền mừng', 'Quà tặng', 'Lì xì'],
  'home': ['Tiền nhà', 'Điện', 'Nước', 'Internet', 'Sửa nhà'],
  'flight': ['Vé máy bay', 'Khách sạn', 'Du lịch', 'Visa'],
  'movie': ['Phim', 'Rạp chiếu', 'Streaming'],
  'fitness_center': ['Gym', 'Thể dục', 'Yoga', 'Chạy bộ'],
  'pets': ['Thức ăn thú cưng', 'Thú y', 'Phụ kiện thú cưng'],
  'more_horiz': ['Chi tiêu khác', 'Linh tinh', 'Khác'],
};

// ── Screen ────────────────────────────────────────────────────────────────────

class NotePickerScreen extends StatefulWidget {
  final String initialNote;
  final String? initialCategoryId;
  final List<Category> categories;

  const NotePickerScreen({
    super.key,
    required this.initialNote,
    required this.initialCategoryId,
    required this.categories,
  });

  @override
  State<NotePickerScreen> createState() => _NotePickerScreenState();
}

class _NotePickerScreenState extends State<NotePickerScreen> {
  late final TextEditingController _ctrl;
  late String? _categoryId;
  List<String> _historyNotes = [];
  bool _historyLoading = true;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialNote);
    _categoryId = widget.initialCategoryId;
    _loadHistory();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    if (_categoryId == null) {
      setState(() => _historyLoading = false);
      return;
    }
    try {
      final rows = await db.getAll(
        "SELECT note, COUNT(*) as cnt FROM transactions "
        "WHERE category_id = ? AND note IS NOT NULL AND note != '' "
        "GROUP BY note ORDER BY cnt DESC LIMIT 20",
        [_categoryId],
      );
      if (mounted) {
        setState(() {
          _historyNotes = rows.map((r) => r['note'] as String).toList();
          _historyLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _historyLoading = false);
    }
  }

  void _onCategoryChanged(String id) {
    setState(() {
      _categoryId = id;
      _historyNotes = [];
      _historyLoading = true;
    });
    _loadHistory();
  }

  /// Suggestions = history + defaults, filtered by current input, deduplicated
  List<String> get _suggestions {
    final query = _ctrl.text.toLowerCase().trim();
    final cat = _categoryId == null
        ? null
        : widget.categories.where((c) => c.id == _categoryId).firstOrNull;
    final defaults = cat != null ? (_kDefaultNotes[cat.iconName] ?? []) : [];

    // Merge: history first (user habits), then defaults
    final merged = <String>[];
    final seen = <String>{};
    for (final s in [..._historyNotes, ...defaults]) {
      final key = s.toLowerCase();
      if (!seen.contains(key)) {
        seen.add(key);
        merged.add(s);
      }
    }

    if (query.isEmpty) return merged;
    return merged.where((s) => s.toLowerCase().contains(query)).toList();
  }

  void _confirm() {
    Navigator.of(context).pop(
      NotePickerResult(
        note: _ctrl.text.trim(),
        categoryId: _categoryId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final suggestions = _suggestions;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.x, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Ghi chú'),
        actions: [
          TextButton(
            onPressed: _confirm,
            child: Text(
              'Xác nhận',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: cs.primary,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Note input ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              style: TextStyle(fontSize: 15, color: cs.onSurface),
              decoration: InputDecoration(
                hintText: 'Nhập ghi chú...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                suffixIcon: _ctrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 16),
                        onPressed: () => setState(() => _ctrl.clear()),
                      )
                    : null,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Category chips ──────────────────────────────────────────
          if (widget.categories.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Text(
                'Danh mục',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = widget.categories[i];
                  final selected = cat.id == _categoryId;
                  return _CategoryChip(
                    category: cat,
                    selected: selected,
                    onTap: () => _onCategoryChanged(cat.id),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          const Divider(height: 1),

          // ── Suggestions ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              _ctrl.text.isEmpty ? 'Gợi ý' : 'Kết quả tìm kiếm',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),

          Expanded(
            child: _historyLoading
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : suggestions.isEmpty
                    ? Center(
                        child: Text(
                          _ctrl.text.isEmpty
                              ? 'Chưa có gợi ý cho danh mục này'
                              : 'Không tìm thấy gợi ý phù hợp',
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: suggestions
                              .map((s) => _SuggestionChip(
                                    label: s,
                                    onTap: () {
                                      setState(() => _ctrl.text = s);
                                      _ctrl.selection = TextSelection.fromPosition(
                                        TextPosition(offset: s.length),
                                      );
                                    },
                                  ))
                              .toList(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Category chip ─────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final Category category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = category.color;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : cs.outlineVariant,
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              categoryIcon(category.iconName),
              size: 13,
              color: selected ? color : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Text(
              category.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? color : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Suggestion chip ───────────────────────────────────────────────────────────

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outlineVariant, width: 0.5),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 13, color: cs.onSurface),
        ),
      ),
    );
  }
}
