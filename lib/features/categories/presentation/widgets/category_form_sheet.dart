import 'package:flutter/material.dart';
import '../../../../core/utils/category_icons.dart';
import '../../data/category_repository.dart';
import '../../domain/category.dart';

const _kColors = [
  '#FF6B6B', '#FF8E53', '#FFA726', '#FFEAA7',
  '#96CEB4', '#4ECDC4', '#45B7D1', '#42A5F5',
  '#6C63FF', '#9C8FFF', '#DDA0DD', '#EC407A',
  '#66BB6A', '#B0BEC5',
];

const _kIconNames = [
  'restaurant', 'directions_car', 'school', 'sports_esports',
  'favorite', 'shopping_bag', 'work', 'laptop', 'storefront',
  'card_giftcard', 'home', 'flight', 'movie', 'fitness_center',
  'pets', 'more_horiz',
];

class CategoryFormSheet extends StatefulWidget {
  final Category? existing;
  final bool isIncome;

  const CategoryFormSheet({
    super.key,
    this.existing,
    required this.isIncome,
  });

  @override
  State<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<CategoryFormSheet> {
  final _nameCtrl = TextEditingController();
  late String _selectedColor;
  late String _selectedIcon;
  bool _loading = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _nameCtrl.text = widget.existing!.name;
      _selectedColor = widget.existing!.colorHex;
      _selectedIcon = widget.existing!.iconName;
    } else {
      _selectedColor = _kColors.first;
      _selectedIcon = _kIconNames.first;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _loading = true);
    try {
      final repo = CategoryRepository();
      if (_isEdit) {
        final updated = Category(
          id: widget.existing!.id,
          name: name,
          colorHex: _selectedColor,
          iconName: _selectedIcon,
          isDefault: widget.existing!.isDefault,
          isIncome: widget.existing!.isIncome,
          sortOrder: widget.existing!.sortOrder,
        );
        await repo.update(updated);
      } else {
        await repo.add(
          name: name,
          colorHex: _selectedColor,
          iconName: _selectedIcon,
          isIncome: widget.isIncome,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Color(
      int.parse('FF${_selectedColor.replaceAll('#', '')}', radix: 16),
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            _isEdit ? 'Chỉnh sửa danh mục' : 'Thêm danh mục',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          // name field
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Tên danh mục',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 16),

          // color picker
          const Text('Màu sắc',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _kColors.map((hex) {
              final color = Color(
                int.parse('FF${hex.replaceAll('#', '')}', radix: 16),
              );
              final selected = hex == _selectedColor;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = hex),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                    boxShadow: selected
                        ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)]
                        : null,
                  ),
                  child: selected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // icon picker
          const Text('Icon',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          // Thay đoạn Wrap icon picker cũ bằng:
          const Text('Icon',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _kIconNames.map((name) {
              final selected = name == _selectedIcon;
              final color = Color(
                int.parse('FF${_selectedColor.replaceAll('#', '')}', radix: 16),
              );
              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = name),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withOpacity(0.15)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: selected
                        ? Border.all(color: color, width: 1.5)
                        : null,
                  ),
                  child: Icon(
                    categoryIcon(name),
                    size: 20,
                    color: selected ? color : Colors.grey.shade500,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // submit button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: accentColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : Text(
                _isEdit ? 'Lưu thay đổi' : 'Thêm danh mục',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}