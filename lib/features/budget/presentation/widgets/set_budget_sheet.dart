import 'package:flutter/material.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/spendo/spendo.dart';
import '../../../transactions/presentation/widgets/amount_input_controller.dart';

/// The keypad sheet behind every limit on the `/budget` page — the month total
/// and each category alike.
///
/// The audit found three near-identical amount sheets (`23-budget-screen.md`,
/// `24-category-budget-screen.md`); this is the one they collapse into. It
/// returns the amount, leaving the page to decide what to write.
class SetBudgetSheet extends StatefulWidget {
  const SetBudgetSheet({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.existingAmount,
    this.spent,
  });

  final String title;

  /// Line under the title — the category name, or the month being set.
  final String? subtitle;

  /// Icon tile for a category limit.
  final Widget? leading;

  /// Prefills the keypad and switches the button to "Cập nhật".
  final int? existingAmount;

  /// Already spent in this period, shown so the limit is not chosen blind —
  /// the old sheet asked for a number with no idea of the month's spending.
  final int? spent;

  /// Opens the sheet; resolves to the chosen amount, or null if dismissed.
  static Future<int?> show({
    required BuildContext context,
    required String title,
    String? subtitle,
    Widget? leading,
    int? existingAmount,
    int? spent,
  }) {
    return SpendoSheet.showModal<int>(
      context: context,
      builder: (_) => SetBudgetSheet(
        title: title,
        subtitle: subtitle,
        leading: leading,
        existingAmount: existingAmount,
        spent: spent,
      ),
    );
  }

  @override
  State<SetBudgetSheet> createState() => _SetBudgetSheetState();
}

class _SetBudgetSheetState extends State<SetBudgetSheet> {
  final _amountCtrl = AmountInputController();

  bool get _isEdit => widget.existingAmount != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingAmount;
    if (existing != null && existing > 0) {
      _amountCtrl.prefill(existing.toString());
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final spent = widget.spent;

    return SpendoSheet(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
        child: Row(
          children: [
            if (widget.leading != null) ...[
              widget.leading!,
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.title, style: theme.textTheme.titleMedium),
                  if (widget.subtitle != null)
                    Text(
                      widget.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (spent != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Đã chi ${formatVND(spent)} trong kỳ này',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          const SizedBox(height: 8),
          ListenableBuilder(
            listenable: _amountCtrl,
            builder: (_, __) => Text(
              '${_amountCtrl.formatted} ₫',
              textAlign: TextAlign.right,
              style: theme.textTheme.displaySmall?.copyWith(fontSize: 32),
            ),
          ),
          const SizedBox(height: 12),
          SpendoNumpad(
            onKey: _amountCtrl.press,
            onLongPressDelete: _amountCtrl.reset,
          ),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: _amountCtrl,
            builder: (_, __) => SpendoButton(
              expand: true,
              label: _isEdit
                  ? 'Cập nhật hạn mức'
                  : 'Đặt hạn mức ${_amountCtrl.formatted} ₫',
              onPressed: _amountCtrl.hasValue
                  ? () => Navigator.of(context).pop(_amountCtrl.value)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
