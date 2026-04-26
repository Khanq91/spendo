import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/transaction_repository.dart';
import '../../domain/transaction.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import 'numpad.dart';
import 'amount_input_controller.dart';
import '../../../../core/utils/category_matcher.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  final Transaction? existing;
  final String? preselectedCategoryId;

  const AddTransactionSheet({
    super.key,
    this.existing,
    this.preselectedCategoryId,
  });

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  late final AmountInputController _amountCtrl;
  late final TextEditingController _noteCtrl;
  late bool _isExpense;
  String? _selectedCategoryId;
  bool _userPickedCategory = false;
  bool get _isEditMode => widget.existing != null;
  final _categoryScrollCtrl = ScrollController();
  final Map<String, GlobalKey> _chipKeys = {};

  @override
  void initState() {
    super.initState();
    final tx = widget.existing;
    _amountCtrl = AmountInputController();
    _noteCtrl = TextEditingController();

    if (widget.preselectedCategoryId != null) {
      _selectedCategoryId = widget.preselectedCategoryId;
      _userPickedCategory = true;
    }

    if (tx != null) {
      // pre-fill từ existing transaction
      _amountCtrl.prefill(tx.amount.toString());
      _noteCtrl.text = tx.note ?? '';
      _isExpense = tx.isExpense;
      _selectedCategoryId = tx.categoryId;
    } else {
      _isExpense = true;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _categoryScrollCtrl.dispose();
    super.dispose();
  }

  List<Category> _categories(List<Category> all) =>
      all.where((c) => c.isIncome == !_isExpense).toList();

  Future<void> _submit() async {
    if (!_amountCtrl.hasValue || _selectedCategoryId == null) return;

    final repo = TransactionRepository();

    if (_isEditMode) {
      final updated = Transaction(
        id: widget.existing!.id,
        amount: _amountCtrl.value,
        type: _isExpense ? 'expense' : 'income',
        categoryId: _selectedCategoryId!,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        createdAt: widget.existing!.createdAt,
      );
      await repo.update(updated);
    } else {
      await repo.add(
        amount: _amountCtrl.value,
        type: _isExpense ? 'expense' : 'income',
        categoryId: _selectedCategoryId!,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  void _autoSelectCategory(String note) {
    if (_userPickedCategory) return;

    final iconName = matchCategory(note);
    if (iconName == null) return;

    final allCats = ref.read(categoriesProvider).valueOrNull ?? [];
    final cats = _categories(allCats);
    final matched = cats.where((c) => c.iconName == iconName).firstOrNull;

    if (matched != null && matched.id != _selectedCategoryId) {
      setState(() => _selectedCategoryId = matched.id);

      // Scroll tới chip sau khi setState xong
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final key = _chipKeys[matched.id];
        if (key?.currentContext != null) {
          Scrollable.ensureVisible(
            key!.currentContext!,
            alignment: 0.3,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final allCategories = categoriesAsync.valueOrNull ?? [];
    final cats = _categories(allCategories);

    if (cats.isNotEmpty &&
        (_selectedCategoryId == null ||
            !cats.any((c) => c.id == _selectedCategoryId))) {
      _selectedCategoryId = cats.first.id;
    }

    final color =
    _isExpense ? const Color(0xFFE53935) : const Color(0xFF43A047);

    return Padding(
      padding:
      EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // title khi edit
          if (_isEditMode)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Chỉnh sửa giao dịch',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
            ),

          // toggle + amount
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _TypeToggle(
                  label: 'Chi',
                  active: _isExpense,
                  color: const Color(0xFFE53935),
                  onTap: () => setState(() {
                    _isExpense = true;
                    _selectedCategoryId = null;
                    _userPickedCategory = false;
                  }),
                ),
                const SizedBox(width: 8),
                _TypeToggle(
                  label: 'Thu',
                  active: !_isExpense,
                  color: const Color(0xFF43A047),
                  onTap: () => setState(() {
                    _isExpense = false;
                    _selectedCategoryId = null;
                    _userPickedCategory = false;
                  }),
                ),
                const Spacer(),
                ListenableBuilder(
                  listenable: _amountCtrl,
                  builder: (_, __) => Text(
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
                Text('₫',
                    style: TextStyle(
                        fontSize: 14, color: Colors.grey.shade500)),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // category chips
          SizedBox(
            height: 36,
            child: ListView.separated(
              controller: _categoryScrollCtrl, // thêm
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: cats.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = cats[i];
                final selected = cat.id == _selectedCategoryId;

                // Tạo key cho chip nếu chưa có
                _chipKeys.putIfAbsent(cat.id, () => GlobalKey());

                return ChoiceChip(
                  key: _chipKeys[cat.id], // gắn key vào đây
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cat.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? color : Colors.grey.shade600,
                        ),
                      ),
                      if (selected && !_userPickedCategory) ...[
                        const SizedBox(width: 3),
                        Icon(Icons.auto_fix_high, size: 10, color: color),
                      ],
                    ],
                  ),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    _selectedCategoryId = cat.id;
                    _userPickedCategory = true;
                  }),
                  selectedColor: color.withOpacity(0.15),
                  side: BorderSide(
                    color: selected ? color : Colors.grey.shade300,
                    width: 0.5,
                  ),
                  backgroundColor: Colors.transparent,
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // note
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _noteCtrl,
              onChanged: (text) => _autoSelectCategory(text),
              decoration: InputDecoration(
                hintText: 'Ghi chú (tuỳ chọn)...',
                hintStyle: TextStyle(
                    fontSize: 13, color: Colors.grey.shade400),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
              ),
              style: const TextStyle(fontSize: 13),
              maxLines: 1,
            ),
          ),

          const Divider(height: 12, thickness: 0.5),

          // numpad
          ListenableBuilder(
            listenable: _amountCtrl,
            builder: (_, __) => Numpad(onKey: _amountCtrl.press),
          ),

          // confirm
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: ListenableBuilder(
              listenable: _amountCtrl,
              builder: (_, __) => FilledButton(
                onPressed:
                _amountCtrl.hasValue && _selectedCategoryId != null
                    ? _submit
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isEditMode
                      ? 'Lưu thay đổi'
                      : (_isExpense
                      ? 'Chi ${_amountCtrl.formatted} ₫'
                      : 'Thu ${_amountCtrl.formatted} ₫'),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _TypeToggle({
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color:
          active ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? color : Colors.grey.shade300,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? color : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}