import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/transaction_repository.dart';
import '../../domain/transaction.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../budget/presentation/providers/category_budget_provider.dart';
import 'numpad.dart';
import 'amount_input_controller.dart';
import '../../../../core/utils/category_matcher.dart';
import '../../../../core/utils/currency_formatter.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  final Transaction? existing;
  final String? preselectedCategoryId;
  final String? prefillNote;
  final int? prefillAmount;

  const AddTransactionSheet({
    super.key,
    this.existing,
    this.preselectedCategoryId,
    this.prefillNote,
    this.prefillAmount,
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
      _amountCtrl.prefill(tx.amount.toString());
      _noteCtrl.text = tx.note ?? '';
      _isExpense = tx.isExpense;
      _selectedCategoryId = tx.categoryId;
      _userPickedCategory = true;
    } else {
      _isExpense = true;
      if (widget.prefillNote != null) {
        _noteCtrl.text = widget.prefillNote!;
      }
      if (widget.prefillAmount != null && widget.prefillAmount! > 0) {
        _amountCtrl.prefill(widget.prefillAmount!.toString());
      }
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

    // ── Check category budget nếu là chi tiêu ───────────────────────────────
    if (_isExpense && !_isEditMode) {
      final shouldProceed = await _checkCategoryBudget();
      if (!shouldProceed) return;
    }

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

  /// Kiểm tra category budget, hỏi xác nhận nếu sẽ vượt hạn mức.
  /// Returns true nếu được tiếp tục, false nếu user cancel.
  Future<bool> _checkCategoryBudget() async {
    final catId = _selectedCategoryId!;
    final progressMap = ref.read(categoryBudgetProgressProvider);
    final progress = progressMap[catId];

    // Không có budget cho category này → cho qua
    if (progress == null) return true;

    final newAmount = _amountCtrl.value;
    final willExceed = (progress.spent + newAmount) > progress.budget;

    // Chưa vượt → cho qua
    if (!willExceed) return true;

    // Đã vượt sẵn rồi (isOver) hay sắp vượt → show dialog
    if (!mounted) return false;

    final allCats = ref.read(expenseCategoriesProvider);
    final catName = allCats
        .where((c) => c.id == catId)
        .firstOrNull
        ?.name ?? 'danh mục này';

    final remaining = progress.budget - progress.spent;
    final overAmount = (progress.spent + newAmount) - progress.budget;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _BudgetWarningDialog(
        categoryName: catName,
        budgetAmount: progress.budget,
        spentAmount: progress.spent,
        newAmount: newAmount,
        remaining: remaining,
        overAmount: overAmount,
        isAlreadyOver: progress.isOver,
      ),
    );

    return confirmed == true;
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

  void _switchType(bool toExpense) {
    if (_isExpense == toExpense) return;
    setState(() {
      _isExpense = toExpense;
      _selectedCategoryId = null;
      _userPickedCategory = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final allCategories = categoriesAsync.valueOrNull ?? [];
    final cats = _categories(allCategories);
    final cs = Theme.of(context).colorScheme;

    // Category budget progress map — chỉ relevant khi đang ở mode chi
    final budgetProgressMap = _isExpense
        ? ref.watch(categoryBudgetProgressProvider)
        : <String, ({int budget, int spent, double percent, bool isOver})>{};

    if (cats.isNotEmpty &&
        (_selectedCategoryId == null ||
            !cats.any((c) => c.id == _selectedCategoryId))) {
      _selectedCategoryId = cats.first.id;
    }

    final color = _isExpense
        ? const Color(0xFFE53935)
        : const Color(0xFF43A047);

    return Padding(
      padding:
      EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          if (_isEditMode)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Chỉnh sửa giao dịch',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),

          // Toggle + amount
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _TypeToggle(
                  label: 'Chi',
                  active: _isExpense,
                  color: const Color(0xFFE53935),
                  onTap: () => _switchType(true),
                ),
                const SizedBox(width: 8),
                _TypeToggle(
                  label: 'Thu',
                  active: !_isExpense,
                  color: const Color(0xFF43A047),
                  onTap: () => _switchType(false),
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
                        fontSize: 14, color: cs.onSurfaceVariant)),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Category chips
          SizedBox(
            height: 36,
            child: ListView.separated(
              controller: _categoryScrollCtrl,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: cats.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = cats[i];
                final selected = cat.id == _selectedCategoryId;
                _chipKeys.putIfAbsent(cat.id, () => GlobalKey());

                // ── Budget coloring ──────────────────────────────────
                final progress = budgetProgressMap[cat.id];
                final chipBgColor = _resolveChipBgColor(
                  progress: progress,
                  selected: selected,
                  baseColor: color,
                  cs: cs,
                );

                return ChoiceChip(
                  key: _chipKeys[cat.id],
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cat.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? color : cs.onSurfaceVariant,
                        ),
                      ),
                      // Auto-select indicator
                      if (selected && !_userPickedCategory) ...[
                        const SizedBox(width: 3),
                        Icon(Icons.auto_fix_high, size: 10, color: color),
                      ],
                      // Budget warning indicator khi không được select
                      if (!selected && progress != null) ...[
                        const SizedBox(width: 3),
                        _BudgetDot(percent: progress.percent, isOver: progress.isOver),
                      ],
                    ],
                  ),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    _selectedCategoryId = cat.id;
                    _userPickedCategory = true;
                  }),
                  selectedColor: color.withOpacity(0.15),
                  backgroundColor: chipBgColor,
                  side: BorderSide(
                    color: _resolveChipBorderColor(
                      progress: progress,
                      selected: selected,
                      baseColor: color,
                      cs: cs,
                    ),
                    width: 0.8,
                  ),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Note
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _noteCtrl,
              onChanged: (text) => _autoSelectCategory(text),
              style: TextStyle(fontSize: 13, color: cs.onSurface),
              decoration: InputDecoration(
                hintText: 'Ghi chú (tuỳ chọn)...',
                hintStyle:
                TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                border: InputBorder.none,
                isDense: true,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 4),
              ),
              maxLines: 1,
            ),
          ),

          const Divider(height: 12, thickness: 0.5),

          ListenableBuilder(
            listenable: _amountCtrl,
            builder: (_, __) => Numpad(onKey: _amountCtrl.press),
          ),

          // Confirm
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

  /// Màu background chip dựa trên % đã dùng budget
  Color _resolveChipBgColor({
    required ({int budget, int spent, double percent, bool isOver})? progress,
    required bool selected,
    required Color baseColor,
    required ColorScheme cs,
  }) {
    if (selected) return baseColor.withOpacity(0.15);
    if (progress == null) return Colors.transparent;

    if (progress.isOver) {
      return Colors.red.withOpacity(0.08);
    } else if (progress.percent >= 0.8) {
      return Colors.orange.withOpacity(0.08);
    } else if (progress.percent >= 0.5) {
      return Colors.amber.withOpacity(0.06);
    }
    return Colors.green.withOpacity(0.06);
  }

  Color _resolveChipBorderColor({
    required ({int budget, int spent, double percent, bool isOver})? progress,
    required bool selected,
    required Color baseColor,
    required ColorScheme cs,
  }) {
    if (selected) return baseColor;
    if (progress == null) return cs.outlineVariant;

    if (progress.isOver) return Colors.red.withOpacity(0.5);
    if (progress.percent >= 0.8) return Colors.orange.withOpacity(0.5);
    if (progress.percent >= 0.5) return Colors.amber.withOpacity(0.4);
    return Colors.green.withOpacity(0.4);
  }
}

// ── Budget dot indicator ──────────────────────────────────────────────────────

class _BudgetDot extends StatelessWidget {
  final double percent;
  final bool isOver;

  const _BudgetDot({required this.percent, required this.isOver});

  @override
  Widget build(BuildContext context) {
    final color = isOver
        ? Colors.red
        : percent >= 0.8
        ? Colors.orange
        : Colors.green;

    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ── Budget warning dialog ─────────────────────────────────────────────────────

class _BudgetWarningDialog extends StatelessWidget {
  final String categoryName;
  final int budgetAmount;
  final int spentAmount;
  final int newAmount;
  final int remaining;
  final int overAmount;
  final bool isAlreadyOver;

  const _BudgetWarningDialog({
    required this.categoryName,
    required this.budgetAmount,
    required this.spentAmount,
    required this.newAmount,
    required this.remaining,
    required this.overAmount,
    required this.isAlreadyOver,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: const Text('⚠️', style: TextStyle(fontSize: 32)),
      title: Text(
        isAlreadyOver ? 'Đã vượt hạn mức!' : 'Sắp vượt hạn mức',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Danh mục: $categoryName',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            label: 'Hạn mức',
            value: formatVND(budgetAmount),
            color: cs.onSurface,
          ),
          _InfoRow(
            label: 'Đã chi',
            value: formatVND(spentAmount),
            color: Colors.orange,
          ),
          _InfoRow(
            label: 'Khoản này',
            value: formatVND(newAmount),
            color: Colors.red,
          ),
          const Divider(height: 16),
          _InfoRow(
            label: 'Vượt hạn',
            value: '+${formatVND(overAmount)}',
            color: Colors.red,
            bold: true,
          ),
          const SizedBox(height: 8),
          Text(
            isAlreadyOver
                ? 'Danh mục này đã vượt hạn mức. Thêm khoản này sẽ làm tăng thêm số tiền vượt hạn.'
                : 'Thêm khoản chi này sẽ khiến danh mục "$categoryName" vượt hạn mức đặt ra.',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Huỷ bỏ',
              style: TextStyle(color: cs.onSurfaceVariant)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style:
          FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
          child: const Text('Vẫn thêm'),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                  bold ? FontWeight.w600 : FontWeight.w400)),
          Text(value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: color,
              )),
        ],
      ),
    );
  }
}

// ── Type toggle ───────────────────────────────────────────────────────────────

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
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? color : cs.outlineVariant,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? color : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}