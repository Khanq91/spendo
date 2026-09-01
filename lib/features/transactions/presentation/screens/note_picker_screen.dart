import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/widgets/spendo/spendo.dart';
import '../../../categories/domain/category.dart';
import '../../domain/note_suggestions.dart';

/// What the picker hands back to the add sheet.
class NotePickerResult {
  final String note;
  final String? categoryId;

  const NotePickerResult({required this.note, required this.categoryId});
}

/// Screen 02b — write a note, with the category's past notes as suggestions.
///
/// The category grid mirrors the add sheet's, so switching category here reads
/// as the same control rather than a second style for the same entity.
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
  List<String> _historyNotes = const [];
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
    final categoryId = _categoryId;
    if (categoryId == null) {
      setState(() => _historyLoading = false);
      return;
    }
    final history = await loadNoteHistory(categoryId);
    if (!mounted || _categoryId != categoryId) return;
    setState(() {
      _historyNotes = history;
      _historyLoading = false;
    });
  }

  void _onCategoryChanged(String id) {
    setState(() {
      _categoryId = id;
      _historyNotes = const [];
      _historyLoading = true;
    });
    _loadHistory();
  }

  Category? get _category =>
      widget.categories.where((c) => c.id == _categoryId).firstOrNull;

  List<String> get _suggestions => mergeNoteSuggestions(
    history: _historyNotes,
    iconName: _category?.iconName,
    query: _ctrl.text,
  );

  void _confirm() {
    Navigator.of(context).pop(
      NotePickerResult(note: _ctrl.text.trim(), categoryId: _categoryId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final suggestions = _suggestions;
    final isSearching = _ctrl.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.x, size: 22),
          tooltip: 'Đóng',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Ghi chú', style: theme.textTheme.titleLarge?.copyWith(
          fontSize: 20,
        )),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _confirm,
            child: Text(
              'Xác nhận',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _confirm(),
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Nhập ghi chú…',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                suffixIcon: _ctrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(LucideIcons.x, size: 16),
                        tooltip: 'Xoá ghi chú',
                        onPressed: () => setState(_ctrl.clear),
                      ),
              ),
            ),
          ),
          if (widget.categories.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SpendoSectionHeader(label: 'Danh mục'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: widget.categories.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisExtent: 72,
                      mainAxisSpacing: 12,
                    ),
                itemBuilder: (_, i) {
                  final cat = widget.categories[i];
                  return SpendoCategoryTile(
                    label: cat.name,
                    color: cat.color,
                    iconName: cat.iconName,
                    selected: cat.id == _categoryId,
                    onTap: () => _onCategoryChanged(cat.id),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            Divider(height: 1, color: cs.outlineVariant),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SpendoSectionHeader(
              label: isSearching ? 'Kết quả tìm kiếm' : 'Gợi ý',
              padding: const EdgeInsets.only(top: 16, bottom: 10),
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
                ? SpendoEmptyState(
                    icon: LucideIcons.messageSquareDashed,
                    title: isSearching
                        ? 'Không tìm thấy gợi ý phù hợp'
                        : 'Chưa có gợi ý cho danh mục này',
                    message: isSearching
                        ? null
                        : 'Ghi chú bạn dùng sẽ xuất hiện ở đây.',
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final suggestion in suggestions)
                          _SuggestionChip(
                            label: suggestion,
                            onTap: () {
                              setState(() {
                                _ctrl.text = suggestion;
                                _ctrl.selection = TextSelection.collapsed(
                                  offset: suggestion.length,
                                );
                              });
                            },
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Filled pill — screen 02b's suggestion variant, per `02-components.md`.
class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainer,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width - 32,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
