import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../transactions/presentation/widgets/amount_input_controller.dart';
import '../../../transactions/presentation/widgets/numpad.dart';
import '../../data/budget_repository.dart';
import '../../domain/budget.dart';
import '../providers/budget_provider.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  final _amountCtrl = AmountInputController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill nếu đã có budget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final budget = ref.read(currentBudgetProvider).valueOrNull;
      if (budget != null) {
        _amountCtrl.prefill(budget.amount.toString());
      }
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_amountCtrl.hasValue) return;
    setState(() => _loading = true);

    final month = ref.read(selectedMonthProvider);
    final key = Budget.monthKey(month);

    await BudgetRepository().set(key, _amountCtrl.value);

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final month = ref.read(selectedMonthProvider);
    final key = Budget.monthKey(month);
    await BudgetRepository().delete(key);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(selectedMonthProvider);
    final hasBudget = ref.watch(currentBudgetProvider).valueOrNull != null;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hạn mức chi tiêu',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Tháng ${month.month}/${month.year}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                const Spacer(),
                if (hasBudget)
                  TextButton(
                    onPressed: _delete,
                    style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFE53935)),
                    child: const Text('Xoá', style: TextStyle(fontSize: 13)),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // amount display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ListenableBuilder(
                  listenable: _amountCtrl,
                  builder: (_, __) => Text(
                    _amountCtrl.formatted,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6C63FF),
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

          const Divider(height: 16, thickness: 0.5),

          // numpad
          ListenableBuilder(
            listenable: _amountCtrl,
            builder: (_, __) => Numpad(onKey: _amountCtrl.press),
          ),

          // save button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: ListenableBuilder(
              listenable: _amountCtrl,
              builder: (_, __) => FilledButton(
                onPressed:
                _amountCtrl.hasValue && !_loading ? _save : null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
                  hasBudget
                      ? 'Cập nhật hạn mức'
                      : 'Đặt hạn mức ${_amountCtrl.formatted} ₫',
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