import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/spendo_colors.dart';
import '../../../../core/utils/category_matcher.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../shared/widgets/motion/motion.dart';
import '../../../../shared/widgets/spendo/spendo.dart';
import '../../../budget/presentation/providers/category_budget_provider.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../reminders/presentation/widgets/reminder_form_sheet.dart';
import '../../../wallets/data/wallet_repository.dart';
import '../../../wallets/domain/wallet.dart';
import '../../../wallets/presentation/providers/wallet_provider.dart';
import '../../data/transaction_repository.dart';
import '../../domain/note_suggestions.dart';
import '../../domain/transaction.dart';
import '../screens/note_picker_screen.dart';
import 'amount_input_controller.dart';

/// Opens the add/edit transaction sheet.
///
/// The single entry point for every caller — the FAB, the Home shortcuts and
/// the notification deep link — so the sheet's presentation stays in one
/// place instead of being re-specified at each call site.
Future<void> showAddTransactionSheet(
  BuildContext context, {
  Transaction? existing,
  String? preselectedCategoryId,
  String? preselectedWalletId,
  String? prefillNote,
  int? prefillAmount,
}) {
  return SpendoSheet.showModal<void>(
    context: context,
    builder: (_) => AddTransactionSheet(
      existing: existing,
      preselectedCategoryId: preselectedCategoryId,
      preselectedWalletId: preselectedWalletId,
      prefillNote: prefillNote,
      prefillAmount: prefillAmount,
    ),
  );
}

class AddTransactionSheet extends ConsumerStatefulWidget {
  final Transaction? existing;
  final String? preselectedCategoryId;

  /// Set when the sheet is opened from a wallet's own screen, so the entry
  /// lands in the wallet the user was already looking at.
  final String? preselectedWalletId;
  final String? prefillNote;
  final int? prefillAmount;

  const AddTransactionSheet({
    super.key,
    this.existing,
    this.preselectedCategoryId,
    this.preselectedWalletId,
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

  /// When the transaction happened. Editable through the date chip; defaults
  /// to now for a new entry and to the stored stamp when editing.
  late DateTime _createdAt;

  String? _selectedCategoryId;
  bool _userPickedCategory = false;

  bool _trackWallet = false;
  String? _selectedWalletId;
  bool _isSubmitting = false;

  /// Suggestions for the selected category, shown as chips under the note.
  List<String> _noteHistory = const [];
  String? _historyCategoryId;

  bool get _isEditMode => widget.existing != null;

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

    if (widget.preselectedWalletId != null) {
      _trackWallet = true;
      _selectedWalletId = widget.preselectedWalletId;
    }

    if (tx != null) {
      _amountCtrl.prefill(tx.amount.toString());
      _noteCtrl.text = tx.note ?? '';
      _isExpense = tx.isExpense;
      _createdAt = tx.createdAt;
      _selectedCategoryId = tx.categoryId;
      _userPickedCategory = true;
      if (tx.walletId != null) {
        _trackWallet = true;
        _selectedWalletId = tx.walletId;
      }
    } else {
      _isExpense = true;
      _createdAt = DateTime.now();
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
    super.dispose();
  }

  List<Category> _categories(List<Category> all) =>
      all.where((c) => c.isIncome == !_isExpense).toList();

  Category? _selectedCategory(List<Category> cats) =>
      cats.where((c) => c.id == _selectedCategoryId).firstOrNull;

  // ── Note suggestions ──────────────────────────────────────────────────────

  /// Reloads the chips when the category changes, once per category.
  void _syncNoteHistory() {
    final categoryId = _selectedCategoryId;
    if (categoryId == null || categoryId == _historyCategoryId) return;
    _historyCategoryId = categoryId;
    loadNoteHistory(categoryId).then((history) {
      if (!mounted || _historyCategoryId != categoryId) return;
      setState(() => _noteHistory = history);
    });
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_isSubmitting || !_amountCtrl.hasValue || _selectedCategoryId == null) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (_isExpense && !_isEditMode) {
        final shouldProceed = await _checkCategoryBudget();
        if (!shouldProceed) return;
      }

      if (_trackWallet &&
          _selectedWalletId != null &&
          _isExpense &&
          !_isEditMode) {
        final shouldProceed = await _checkWalletBalance();
        if (!shouldProceed) return;
      }

      final repo = TransactionRepository();
      final note = _noteCtrl.text.trim();

      if (_isEditMode) {
        await repo.update(
          Transaction(
            id: widget.existing!.id,
            amount: _amountCtrl.value,
            type: _isExpense ? 'expense' : 'income',
            categoryId: _selectedCategoryId!,
            note: note.isEmpty ? null : note,
            createdAt: _createdAt,
            walletId: _trackWallet ? _selectedWalletId : null,
            source: widget.existing!.source,
          ),
        );
      } else {
        await repo.add(
          amount: _amountCtrl.value,
          type: _isExpense ? 'expense' : 'income',
          categoryId: _selectedCategoryId!,
          note: note.isEmpty ? null : note,
          createdAt: _createdAt,
          walletId: _trackWallet ? _selectedWalletId : null,
        );
      }

      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không lưu được giao dịch. Thử lại.')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<bool> _checkCategoryBudget() async {
    final catId = _selectedCategoryId!;
    final progress = ref.read(categoryBudgetProgressProvider)[catId];
    if (progress == null) return true;

    final newAmount = _amountCtrl.value;
    if ((progress.spent + newAmount) <= progress.budget) return true;
    if (!mounted) return false;

    final catName =
        ref
            .read(expenseCategoriesProvider)
            .where((c) => c.id == catId)
            .firstOrNull
            ?.name ??
        'danh mục này';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _WarningDialog(
        title: progress.isOver ? 'Đã vượt hạn mức!' : 'Sắp vượt hạn mức',
        message: progress.isOver
            ? 'Danh mục này đã vượt hạn mức. Thêm khoản này sẽ làm tăng thêm số tiền vượt hạn.'
            : 'Thêm khoản chi này sẽ khiến danh mục "$catName" vượt hạn mức.',
        rows: [
          (label: 'Danh mục', value: catName, emphasis: _Emphasis.none),
          (
            label: 'Hạn mức',
            value: formatVND(progress.budget),
            emphasis: _Emphasis.none,
          ),
          (
            label: 'Đã chi',
            value: formatVND(progress.spent),
            emphasis: _Emphasis.warning,
          ),
          (
            label: 'Khoản này',
            value: formatVND(newAmount),
            emphasis: _Emphasis.danger,
          ),
          (
            label: 'Vượt hạn',
            value: '+${formatVND((progress.spent + newAmount) - progress.budget)}',
            emphasis: _Emphasis.total,
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<bool> _checkWalletBalance() async {
    final wallets = ref.read(walletsProvider).valueOrNull ?? const <Wallet>[];
    final wallet = wallets.where((w) => w.id == _selectedWalletId).firstOrNull;
    if (wallet == null) return true;

    final balance = await WalletRepository().calculateBalance(wallet.id);
    final newAmount = _amountCtrl.value;
    if (balance - newAmount >= 0) return true;
    if (!mounted) return false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _WarningDialog(
        title: balance < 0 ? 'Ví đang âm!' : 'Số dư không đủ',
        message: 'Số dư ví sẽ bị âm sau giao dịch này.',
        rows: [
          (label: 'Ví', value: wallet.name, emphasis: _Emphasis.none),
          (
            label: 'Số dư hiện tại',
            value: formatVND(balance),
            emphasis: balance < 0 ? _Emphasis.danger : _Emphasis.warning,
          ),
          (
            label: 'Khoản chi',
            value: formatVND(newAmount),
            emphasis: _Emphasis.danger,
          ),
          (
            label: 'Thiếu',
            value: formatVND((balance - newAmount).abs()),
            emphasis: _Emphasis.total,
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  // ── Field actions ─────────────────────────────────────────────────────────

  void _autoSelectCategory(String note) {
    setState(() {});
    if (_userPickedCategory) return;
    final iconName = matchCategory(note);
    if (iconName == null) return;
    final cats = _categories(ref.read(categoriesProvider).valueOrNull ?? []);
    final matched = cats.where((c) => c.iconName == iconName).firstOrNull;
    if (matched != null && matched.id != _selectedCategoryId) {
      setState(() => _selectedCategoryId = matched.id);
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

  void _pickCategory(String id) {
    setState(() {
      _selectedCategoryId = id;
      _userPickedCategory = true;
    });
  }

  Future<void> _openNotePicker() async {
    final cats = _categories(ref.read(categoriesProvider).valueOrNull ?? []);
    final result = await Navigator.of(context).push<NotePickerResult>(
      MaterialPageRoute(
        builder: (_) => NotePickerScreen(
          initialNote: _noteCtrl.text,
          initialCategoryId: _selectedCategoryId,
          categories: cats,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _noteCtrl.text = result.note;
      if (result.categoryId != null &&
          result.categoryId != _selectedCategoryId) {
        _selectedCategoryId = result.categoryId;
        _userPickedCategory = true;
      }
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _createdAt,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_createdAt),
    );
    if (!mounted) return;

    setState(() {
      _createdAt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? _createdAt.hour,
        time?.minute ?? _createdAt.minute,
      );
    });
  }

  void _openWalletPicker(List<Wallet> wallets) {
    SpendoSheet.showModal<void>(
      context: context,
      builder: (ctx) => _WalletPickerSheet(
        wallets: wallets,
        selectedId: _selectedWalletId,
        onSelect: (id) {
          setState(() {
            _trackWallet = true;
            _selectedWalletId = id;
          });
          Navigator.pop(ctx);
        },
        onClear: () {
          setState(() => _trackWallet = false);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  /// Turns the entry being typed into a recurring reminder, pre-filled with
  /// what has been entered so far.
  void _createReminder(List<Category> cats) {
    final note = _noteCtrl.text.trim();
    final category = _selectedCategory(cats);
    showReminderFormSheet(
      context,
      preselectedCategoryId: _selectedCategoryId,
      prefillTitle: note.isNotEmpty ? note : category?.name,
      prefillAmount: _amountCtrl.hasValue ? _amountCtrl.value : null,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final allCategories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final cats = _categories(allCategories);
    final wallets = ref.watch(walletsProvider).valueOrNull ?? const <Wallet>[];
    final isKeyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    if (cats.isNotEmpty &&
        (_selectedCategoryId == null ||
            !cats.any((c) => c.id == _selectedCategoryId))) {
      _selectedCategoryId = cats.first.id;
    }
    _syncNoteHistory();

    if (_trackWallet && _selectedWalletId == null && wallets.isNotEmpty) {
      _selectedWalletId = wallets.first.id;
    }

    final amountColor = _isExpense ? theme.spendo.expense : theme.spendo.income;

    return SpendoSheet(
      padding: EdgeInsets.zero,
      header: _Header(
        isExpense: _isExpense,
        onSwitchType: _switchType,
        onCancel: () => Navigator.of(context).pop(),
        onSave: !_isSubmitting &&
                _amountCtrl.hasValue &&
                _selectedCategoryId != null
            ? _submit
            : null,
        busy: _isSubmitting,
        saveLabel: _isEditMode ? 'Lưu' : 'Lưu',
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: ListenableBuilder(
                listenable: _amountCtrl,
                builder: (_, __) => AnimatedMoneyText(
                  value: _amountCtrl.value,
                  formatter: (value) => formatVND(value.round()),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: amountColor,
                  ),
                ),
              ),
            ),
            _CategoryGrid(
              categories: cats,
              selectedId: _selectedCategoryId,
              onPick: _pickCategory,
            ),
            _NoteField(
              controller: _noteCtrl,
              onChanged: _autoSelectCategory,
              onSearch: _openNotePicker,
              suggestions: mergeNoteSuggestions(
                history: _noteHistory,
                iconName: _selectedCategory(cats)?.iconName,
              ),
              onSuggestionTap: (note) {
                setState(() {
                  _noteCtrl.text = note;
                  _noteCtrl.selection = TextSelection.collapsed(
                    offset: note.length,
                  );
                });
              },
            ),
            _MetaChips(
              createdAt: _createdAt,
              onPickDate: _pickDate,
              wallet: _trackWallet
                  ? wallets.where((w) => w.id == _selectedWalletId).firstOrNull
                  : null,
              hasWallets: wallets.isNotEmpty,
              onPickWallet: () => _openWalletPicker(wallets),
              onRepeat: () => _createReminder(cats),
            ),
            if (cats.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  _isExpense
                      ? 'Chưa có danh mục chi nào. Thêm danh mục trong Cài đặt.'
                      : 'Chưa có danh mục thu nào. Thêm danh mục trong Cài đặt.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
              ),
            if (!isKeyboardVisible)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                child: SpendoNumpad(
                  onKey: _amountCtrl.press,
                  onLongPressDelete: _amountCtrl.reset,
                ),
              )
            else
              const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Header: Huỷ · Chi|Thu · Lưu ──────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.isExpense,
    required this.onSwitchType,
    required this.onCancel,
    required this.onSave,
    required this.busy,
    required this.saveLabel,
  });

  final bool isExpense;
  final ValueChanged<bool> onSwitchType;
  final VoidCallback onCancel;
  final VoidCallback? onSave;
  final bool busy;
  final String saveLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: onCancel,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                'Huỷ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              // Narrow phones leave the pill barely enough room; let it
              // shrink rather than overflow the header row.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SpendoSegmented<bool>(
                  options: const [
                    (value: true, label: 'Chi'),
                    (value: false, label: 'Thu'),
                  ],
                  value: isExpense,
                  onChanged: onSwitchType,
                ),
              ),
            ),
          ),
          _SaveButton(label: saveLabel, onPressed: onSave, busy: busy),
        ],
      ),
    );
  }
}

/// Compact pill so the header stays one row — [SpendoButton] is 48 tall and
/// would push the segmented control out of alignment.
class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.label,
    required this.onPressed,
    required this.busy,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = onPressed != null && !busy;

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: PressableScale(
        deferTapToChild: true,
        child: Material(
          color: cs.primary,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            child: Container(
              height: 38,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: busy
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onPrimary,
                      ),
                    )
                  : Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onPrimary,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Category grid ────────────────────────────────────────────────────────────

/// Four-column grid of category tiles.
///
/// Replaces the horizontal chip strip: the whole set is visible at once, and
/// each cell carries the category's own icon and colour like everywhere else
/// in the app.
class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.selectedId,
    required this.onPick,
  });

  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String> onPick;

  /// Cap the grid at two rows; the rest scrolls with the sheet body.
  static const _perRow = 4;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _perRow,
          mainAxisExtent: 72,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (_, i) {
          final cat = categories[i];
          return SpendoCategoryTile(
            label: cat.name,
            color: cat.color,
            iconName: cat.iconName,
            selected: cat.id == selectedId,
            onTap: () => onPick(cat.id),
          );
        },
      ),
    );
  }
}

// ── Note field + inline suggestions ──────────────────────────────────────────

class _NoteField extends StatelessWidget {
  const _NoteField({
    required this.controller,
    required this.onChanged,
    required this.onSearch,
    required this.suggestions,
    required this.onSuggestionTap,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSearch;
  final List<String> suggestions;
  final ValueChanged<String> onSuggestionTap;

  /// Only the handful that fits without pushing the numpad off-screen; the
  /// full list lives one tap away behind the search icon.
  static const _inlineCount = 3;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inline = suggestions.take(_inlineCount).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 46,
            padding: const EdgeInsets.only(left: 14, right: 6),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(AppTheme.radiusInput),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'Ghi chú (tuỳ chọn)',
                      hintStyle: TextStyle(
                        fontSize: 15,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Gợi ý ghi chú',
                  child: GestureDetector(
                    key: const ValueKey('add_note_search'),
                    onTap: onSearch,
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(
                        LucideIcons.search,
                        size: 19,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (inline.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                itemCount: inline.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => SpendoChip.suggestion(
                  label: inline[i],
                  onTap: () => onSuggestionTap(inline[i]),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Meta chips: date · wallet · repeat ───────────────────────────────────────

class _MetaChips extends StatelessWidget {
  const _MetaChips({
    required this.createdAt,
    required this.onPickDate,
    required this.wallet,
    required this.hasWallets,
    required this.onPickWallet,
    required this.onRepeat,
  });

  final DateTime createdAt;
  final VoidCallback onPickDate;
  final Wallet? wallet;
  final bool hasWallets;
  final VoidCallback onPickWallet;
  final VoidCallback onRepeat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            SpendoChip.meta(
              key: const ValueKey('add_date_chip'),
              label: '${formatDayHeader(createdAt)}, ${formatTime(createdAt)}',
              icon: LucideIcons.calendar,
              onTap: onPickDate,
            ),
            if (hasWallets) ...[
              const SizedBox(width: 8),
              SpendoChip.meta(
                key: const ValueKey('add_wallet_chip'),
                label: wallet?.name ?? 'Chọn ví',
                icon: wallet == null ? LucideIcons.wallet : null,
                leading: wallet == null
                    ? null
                    : Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: wallet!.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                onTap: onPickWallet,
              ),
            ],
            const SizedBox(width: 8),
            SpendoChip.meta(
              key: const ValueKey('add_repeat_chip'),
              label: 'Lặp lại',
              icon: LucideIcons.repeat,
              onTap: onRepeat,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Wallet picker ────────────────────────────────────────────────────────────

class _WalletPickerSheet extends StatelessWidget {
  const _WalletPickerSheet({
    required this.wallets,
    required this.selectedId,
    required this.onSelect,
    required this.onClear,
  });

  final List<Wallet> wallets;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SpendoSheet(
      header: const SpendoSheetHeader(title: 'Chọn nguồn tiền'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SpendoSettingsGroup(
            children: [
              for (final wallet in wallets)
                SpendoSettingsRow(
                  icon: LucideIcons.wallet,
                  label: wallet.name,
                  trailingText: wallet.type.label,
                  trailing: wallet.id == selectedId
                      ? Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(
                            LucideIcons.check,
                            size: 18,
                            color: cs.primary,
                          ),
                        )
                      : null,
                  onTap: () => onSelect(wallet.id),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SpendoButton.outline(
            label: 'Không ghi vào ví nào',
            expand: true,
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}

// ── Warning dialogs ──────────────────────────────────────────────────────────

enum _Emphasis { none, warning, danger, total }

typedef _DialogRow = ({String label, String value, _Emphasis emphasis});

/// One dialog shape for both the budget and the wallet warning — they showed
/// the same "here are the numbers, continue anyway?" question in two layouts.
class _WarningDialog extends StatelessWidget {
  const _WarningDialog({
    required this.title,
    required this.message,
    required this.rows,
  });

  final String title;
  final String message;
  final List<_DialogRow> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Color colorFor(_Emphasis emphasis) => switch (emphasis) {
      _Emphasis.none => cs.onSurface,
      _Emphasis.warning => theme.spendo.warning,
      _Emphasis.danger || _Emphasis.total => cs.error,
    };

    return AlertDialog(
      icon: Icon(LucideIcons.triangleAlert, size: 28, color: cs.error),
      title: Text(title, textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final row in rows) ...[
            if (row.emphasis == _Emphasis.total) const Divider(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    row.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: row.emphasis == _Emphasis.total
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  Text(
                    row.value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: row.emphasis == _Emphasis.total
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: colorFor(row.emphasis),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Huỷ', style: TextStyle(color: cs.onSurfaceVariant)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: cs.error),
          child: const Text('Vẫn thêm'),
        ),
      ],
    );
  }
}
