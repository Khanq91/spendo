import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/transaction_repository.dart';
import '../../domain/transaction.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../budget/presentation/providers/category_budget_provider.dart';
import '../../../wallets/domain/wallet.dart';
import '../../../wallets/presentation/providers/wallet_provider.dart';
import '../../../wallets/data/wallet_repository.dart';
import 'numpad.dart';
import 'amount_input_controller.dart';
import '../../../../core/utils/category_matcher.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/theme/app_theme.dart';

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

  // Wallet state
  bool _trackWallet = false;
  String? _selectedWalletId;

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
      if (tx.walletId != null) {
        _trackWallet = true;
        _selectedWalletId = tx.walletId;
      }
    } else {
      _isExpense = true;
      if (widget.prefillNote != null) _noteCtrl.text = widget.prefillNote!;
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

    // Check budget
    if (_isExpense && !_isEditMode) {
      final shouldProceed = await _checkCategoryBudget();
      if (!shouldProceed) return;
    }

    // Check wallet balance
    if (_trackWallet &&
        _selectedWalletId != null &&
        _isExpense &&
        !_isEditMode) {
      final shouldProceed = await _checkWalletBalance();
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
        walletId: _trackWallet ? _selectedWalletId : null,
      );
      await repo.update(updated);
    } else {
      await repo.add(
        amount: _amountCtrl.value,
        type: _isExpense ? 'expense' : 'income',
        categoryId: _selectedCategoryId!,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        walletId: _trackWallet ? _selectedWalletId : null,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<bool> _checkCategoryBudget() async {
    final catId = _selectedCategoryId!;
    final progressMap = ref.read(categoryBudgetProgressProvider);
    final progress = progressMap[catId];
    if (progress == null) return true;

    final newAmount = _amountCtrl.value;
    final willExceed = (progress.spent + newAmount) > progress.budget;
    if (!willExceed) return true;
    if (!mounted) return false;

    final allCats = ref.read(expenseCategoriesProvider);
    final catName =
        allCats.where((c) => c.id == catId).firstOrNull?.name ?? 'danh mục này';
    final remaining = progress.budget - progress.spent;
    final overAmount = (progress.spent + newAmount) - progress.budget;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => _BudgetWarningDialog(
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

  Future<bool> _checkWalletBalance() async {
    final walletId = _selectedWalletId!;
    final balance = await WalletRepository().calculateBalance(walletId);
    final newAmount = _amountCtrl.value;
    if (balance - newAmount >= 0) return true;
    if (!mounted) return false;

    final wallets = ref.read(walletsProvider).valueOrNull ?? [];
    final wallet = wallets.where((w) => w.id == walletId).firstOrNull;
    final walletName = wallet?.name ?? 'ví này';
    final overAmount = newAmount - balance;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            icon: const Text('⚠️', style: TextStyle(fontSize: 28)),
            title: Text(
              balance < 0 ? 'Ví đang âm!' : 'Số dư không đủ',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _InfoRow(
                  label: 'Ví',
                  value: walletName,
                  color: Theme.of(ctx).colorScheme.onSurface,
                ),
                _InfoRow(
                  label: 'Số dư hiện tại',
                  value: formatVND(balance),
                  color: balance < 0 ? AppTheme.expenseAltColor : Colors.orange,
                ),
                _InfoRow(
                  label: 'Khoản chi',
                  value: formatVND(newAmount),
                  color: AppTheme.expenseAltColor,
                ),
                const Divider(height: 16),
                _InfoRow(
                  label: 'Thiếu',
                  value: formatVND(overAmount),
                  color: AppTheme.expenseAltColor,
                  bold: true,
                ),
                const SizedBox(height: 8),
                Text(
                  'Số dư ví sẽ bị âm sau giao dịch này.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Huỷ',
                  style: TextStyle(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                ),
                child: const Text('Vẫn thêm'),
              ),
            ],
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

  void _openWalletPicker(List<Wallet> wallets) {
    showModalBottomSheet(
      context: context,
      builder:
          (ctx) => _WalletPickerSheet(
            wallets: wallets,
            selectedId: _selectedWalletId,
            onSelect: (id) {
              setState(() => _selectedWalletId = id);
              Navigator.pop(ctx);
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final allCategories = categoriesAsync.valueOrNull ?? [];
    final cats = _categories(allCategories);
    final cs = Theme.of(context).colorScheme;
    final wallets = ref.watch(walletsProvider).valueOrNull ?? [];

    final budgetProgressMap =
        _isExpense
            ? ref.watch(categoryBudgetProgressProvider)
            : <
              String,
              ({int budget, int spent, double percent, bool isOver})
            >{};

    if (cats.isNotEmpty &&
        (_selectedCategoryId == null ||
            !cats.any((c) => c.id == _selectedCategoryId))) {
      _selectedCategoryId = cats.first.id;
    }

    // Auto-select wallet đầu tiên nếu user bật trackWallet nhưng chưa chọn
    if (_trackWallet && _selectedWalletId == null && wallets.isNotEmpty) {
      _selectedWalletId = wallets.first.id;
    }

    final color =
        _isExpense ? const Color(0xFFE53935) : const Color(0xFF43A047);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                  builder:
                      (_, __) => Text(
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
                Text(
                  '₫',
                  style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Category chips
          SizedBox(
            height:
                _selectedCategoryId != null &&
                        budgetProgressMap.containsKey(_selectedCategoryId)
                    ? 48
                    : 36,
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

                final progress = budgetProgressMap[cat.id];
                final chipBgColor = _resolveChipBgColor(
                  progress: progress,
                  selected: selected,
                  baseColor: color,
                  cs: cs,
                );
                final chipSelectedColor =
                    progress != null
                        ? _resolveSelectedColor(progress)
                        : color.withOpacity(0.15);

                return ChoiceChip(
                  key: _chipKeys[cat.id],
                  label: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                          if (selected && !_userPickedCategory) ...[
                            const SizedBox(width: 3),
                            Icon(Icons.auto_fix_high, size: 10, color: color),
                          ],
                          if (!selected && progress != null) ...[
                            const SizedBox(width: 3),
                            _BudgetDot(
                              percent: progress.percent,
                              isOver: progress.isOver,
                            ),
                          ],
                        ],
                      ),
                      if (selected && progress != null) ...[
                        const SizedBox(height: 3),
                        _MiniProgressBar(
                          percent: progress.percent,
                          isOver: progress.isOver,
                        ),
                      ],
                    ],
                  ),
                  selected: selected,
                  onSelected:
                      (_) => setState(() {
                        _selectedCategoryId = cat.id;
                        _userPickedCategory = true;
                      }),
                  selectedColor: chipSelectedColor,
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
              onChanged: _autoSelectCategory,
              style: TextStyle(fontSize: 13, color: cs.onSurface),
              decoration: InputDecoration(
                hintText: 'Ghi chú (tuỳ chọn)...',
                hintStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
              ),
              maxLines: 1,
            ),
          ),

          // Wallet picker row
          if (wallets.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    height: 24,
                    child: Checkbox(
                      value: _trackWallet,
                      onChanged:
                          (val) => setState(() => _trackWallet = val ?? false),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Ghi vào nguồn tiền',
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                  if (_trackWallet && _selectedWalletId != null) ...[
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _openWalletPicker(wallets),
                      child: _SelectedWalletChip(
                        wallet:
                            wallets
                                .where((w) => w.id == _selectedWalletId)
                                .firstOrNull,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const Divider(height: 12, thickness: 0.5),

          ListenableBuilder(
            listenable: _amountCtrl,
            builder: (_, __) => Numpad(onKey: _amountCtrl.press),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: ListenableBuilder(
              listenable: _amountCtrl,
              builder:
                  (_, __) => FilledButton(
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
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Color _resolveChipBgColor({
    required ({int budget, int spent, double percent, bool isOver})? progress,
    required bool selected,
    required Color baseColor,
    required ColorScheme cs,
  }) {
    if (selected) return baseColor.withOpacity(0.15);
    if (progress == null) return Colors.transparent;
    if (progress.isOver) return Colors.red.withOpacity(0.08);
    if (progress.percent >= 0.8) return Colors.orange.withOpacity(0.08);
    if (progress.percent >= 0.5) return Colors.amber.withOpacity(0.06);
    return Colors.green.withOpacity(0.06);
  }

  Color _resolveSelectedColor(
    ({int budget, int spent, double percent, bool isOver}) progress,
  ) {
    if (progress.isOver) return Colors.red.withOpacity(0.12);
    if (progress.percent >= 0.8) return Colors.orange.withOpacity(0.12);
    if (progress.percent >= 0.5) return Colors.amber.withOpacity(0.10);
    return Colors.green.withOpacity(0.10);
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

// ── Wallet chip hiển thị wallet đang chọn ────────────────────────────────────

class _SelectedWalletChip extends StatelessWidget {
  final Wallet? wallet;
  const _SelectedWalletChip({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (wallet == null) return const SizedBox.shrink();
    final color = wallet!.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(categoryIcon(wallet!.type.iconName), size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            wallet!.name,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.arrow_drop_down, size: 14, color: color),
        ],
      ),
    );
  }
}

// ── Wallet picker sheet ───────────────────────────────────────────────────────

class _WalletPickerSheet extends StatelessWidget {
  final List<Wallet> wallets;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const _WalletPickerSheet({
    required this.wallets,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: cs.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Chọn nguồn tiền',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const Divider(height: 1),
        ...wallets.map((w) {
          final selected = w.id == selectedId;
          final color = w.color;
          return ListTile(
            onTap: () => onSelect(w.id),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                categoryIcon(w.type.iconName),
                size: 18,
                color: color,
              ),
            ),
            title: Text(w.name, style: const TextStyle(fontSize: 14)),
            subtitle: Text(
              w.type.label,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            trailing:
                selected
                    ? Icon(Icons.check, color: cs.primary, size: 18)
                    : null,
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Shared sub-widgets (giống file gốc) ──────────────────────────────────────

class _BudgetDot extends StatelessWidget {
  final double percent;
  final bool isOver;
  const _BudgetDot({required this.percent, required this.isOver});

  @override
  Widget build(BuildContext context) {
    final color =
        isOver
            ? Colors.red
            : percent >= 0.8
            ? Colors.orange
            : Colors.green;
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _MiniProgressBar extends StatelessWidget {
  final double percent;
  final bool isOver;
  const _MiniProgressBar({required this.percent, required this.isOver});

  @override
  Widget build(BuildContext context) {
    final barColor =
        isOver
            ? Colors.red
            : percent >= 0.8
            ? Colors.orange
            : Colors.green;
    final displayPercent = (percent * 100).clamp(0, 999).toInt();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 48,
          height: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: percent.clamp(0.0, 1.0),
              backgroundColor: barColor.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(barColor),
              minHeight: 3,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$displayPercent%',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: barColor,
            height: 1,
          ),
        ),
      ],
    );
  }
}

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
                : 'Thêm khoản chi này sẽ khiến danh mục "$categoryName" vượt hạn mức.',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Huỷ bỏ', style: TextStyle(color: cs.onSurfaceVariant)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
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
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: color,
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
