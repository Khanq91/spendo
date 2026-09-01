import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../shared/widgets/spendo/spendo.dart';
import '../../data/category_repository.dart';
import '../../domain/category.dart';

const _kIconNames = [
  'restaurant',
  'directions_car',
  'school',
  'sports_esports',
  'favorite',
  'shopping_bag',
  'work',
  'laptop',
  'storefront',
  'card_giftcard',
  'home',
  'flight',
  'movie',
  'fitness_center',
  'pets',
  'more_horiz',
];

/// Opens the category form. The one place the sheet is presented, so every
/// caller gets the same configuration.
///
/// Pass [existing] to edit; [isIncome] picks the side for a new category and
/// is ignored when editing (the type of an existing category cannot change).
Future<void> showCategoryFormSheet(
  BuildContext context, {
  Category? existing,
  bool isIncome = false,
}) {
  return SpendoSheet.showModal<void>(
    context: context,
    builder: (_) => CategoryFormSheet(
      existing: existing,
      isIncome: existing?.isIncome ?? isIncome,
    ),
  );
}

/// Screen 15 of the redesign.
class CategoryFormSheet extends StatefulWidget {
  const CategoryFormSheet({super.key, this.existing, required this.isIncome});

  final Category? existing;
  final bool isIncome;

  @override
  State<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<CategoryFormSheet> {
  final _nameCtrl = TextEditingController();
  final _nameFocus = FocusNode();
  late String _selectedColor;
  late String _selectedIcon;
  bool _loading = false;

  /// Inline error under the name field. The old form returned silently on an
  /// empty name and surfaced a duplicate through a snackbar that the sheet
  /// itself covered (`21-category-form-sheet.md` §F).
  String? _nameError;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _nameCtrl.text = existing.name;
      _selectedColor = existing.colorHex;
      _selectedIcon = existing.iconName;
    } else {
      _selectedColor = AppColors.palette.first;
      _selectedIcon = _kIconNames.first;
    }
    _nameCtrl.addListener(_clearNameError);
  }

  void _clearNameError() {
    if (_nameError != null && _nameCtrl.text.trim().isNotEmpty) {
      setState(() => _nameError = null);
    }
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_clearNameError);
    _nameCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Đặt tên cho danh mục này');
      _nameFocus.requestFocus();
      return;
    }

    setState(() => _loading = true);
    final navigator = Navigator.of(context);

    try {
      final repo = CategoryRepository();
      if (_isEdit) {
        await repo.update(
          Category(
            id: widget.existing!.id,
            name: name,
            colorHex: _selectedColor,
            iconName: _selectedIcon,
            isDefault: widget.existing!.isDefault,
            isIncome: widget.existing!.isIncome,
            sortOrder: widget.existing!.sortOrder,
          ),
        );
      } else {
        await repo.add(
          name: name,
          colorHex: _selectedColor,
          iconName: _selectedIcon,
          isIncome: widget.isIncome,
        );
      }
      navigator.pop();
    } on DuplicateCategoryException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _nameError = '"$name" đã tồn tại trong danh mục '
            '${widget.isIncome ? 'thu' : 'chi'}.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _nameError = 'Không lưu được danh mục. Thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final side = widget.isIncome ? 'thu' : 'chi';

    return SpendoSheet(
      header: SpendoSheetHeader(
        // The old sheet never said which side it was creating for
        // (`21-category-form-sheet.md` §L).
        title: _isEdit ? 'Sửa danh mục $side' : 'Thêm danh mục $side',
        onCancel: () => Navigator.of(context).pop(),
        action: SpendoButton(label: 'Lưu', busy: _loading, onPressed: _submit),
      ),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      // Scrolls, unlike the old Column: with the keyboard up the swatches and
      // icon grid pushed the name field off the top of the screen.
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 8),
        children: [
          TextField(
            controller: _nameCtrl,
            focusNode: _nameFocus,
            autofocus: !_isEdit,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: 'Tên danh mục',
              hintText: 'Ăn uống, Lương…',
              errorText: _nameError,
            ),
          ),
          const SpendoSectionHeader(label: 'Màu', padding: _labelPad),
          _ColorSwatches(
            selected: _selectedColor,
            onSelected: (hex) => setState(() => _selectedColor = hex),
          ),
          const SpendoSectionHeader(label: 'Icon', padding: _labelPad),
          _IconGrid(
            selected: _selectedIcon,
            color: AppColors.fromHex(_selectedColor),
            onSelected: (name) => setState(() => _selectedIcon = name),
          ),
        ],
      ),
    );
  }
}

const _labelPad = EdgeInsets.only(top: 16, bottom: 8);

class _ColorSwatches extends StatelessWidget {
  const _ColorSwatches({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final hex in AppColors.palette)
          Semantics(
            button: true,
            selected: hex == selected,
            label: 'Màu $hex',
            child: GestureDetector(
              onTap: () => onSelected(hex),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.fromHex(hex),
                  shape: BoxShape.circle,
                  border: hex == selected
                      ? Border.all(color: cs.surfaceContainerLowest, width: 2)
                      : null,
                  boxShadow: hex == selected
                      ? [BoxShadow(color: cs.primary, spreadRadius: 2)]
                      : null,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _IconGrid extends StatelessWidget {
  const _IconGrid({
    required this.selected,
    required this.color,
    required this.onSelected,
  });

  final String selected;
  final Color color;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1,
      children: [
        for (final name in _kIconNames)
          Semantics(
            button: true,
            selected: name == selected,
            child: GestureDetector(
              onTap: () => onSelected(name),
              behavior: HitTestBehavior.opaque,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: name == selected
                      ? color.withValues(alpha: 0.16)
                      : cs.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: name == selected
                      ? Border.all(color: color, width: 2)
                      : null,
                ),
                child: Icon(
                  categoryIcon(name),
                  size: 20,
                  color: name == selected ? color : cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
