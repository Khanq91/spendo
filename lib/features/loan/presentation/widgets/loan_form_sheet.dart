import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../transactions/presentation/widgets/amount_input_controller.dart';
import '../../../transactions/presentation/widgets/numpad.dart';
import '../../data/loan_repository.dart';
import '../../domain/loan.dart';

class LoanFormSheet extends StatefulWidget {
  final Loan? existing;

  const LoanFormSheet({super.key, this.existing});

  @override
  State<LoanFormSheet> createState() => _LoanFormSheetState();
}

class _LoanFormSheetState extends State<LoanFormSheet> {
  final _titleCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  late final AmountInputController _amountCtrl;

  late LoanType _type;
  late String _colorHex;
  DateTime? _dueDate;
  bool _loading = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _amountCtrl = AmountInputController();

    if (_isEdit) {
      final l = widget.existing!;
      _titleCtrl.text = l.title;
      _contactCtrl.text = l.contactName;
      _noteCtrl.text = l.note ?? '';
      _type = l.type;
      _colorHex = l.colorHex;
      _dueDate = l.dueDate;
      _amountCtrl.prefill(l.principal.toString());
    } else {
      _type = LoanType.borrowed;
      _colorHex = AppColors.palette[0]; // đỏ — vay nợ
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contactCtrl.dispose();
    _noteCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty || !_amountCtrl.hasValue) return;

    setState(() => _loading = true);
    try {
      final repo = LoanRepository();
      final loan = Loan(
        id: widget.existing?.id ?? '',
        title: title,
        type: _type,
        principal: _amountCtrl.value,
        contactName: _contactCtrl.text.trim(),
        startDate: widget.existing?.startDate ?? DateTime.now(),
        dueDate: _dueDate,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        colorHex: _colorHex,
        isClosed: widget.existing?.isClosed ?? false,
      );

      if (_isEdit) {
        await repo.update(loan);
      } else {
        await repo.add(loan);
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accentColor = AppColors.fromHex(_colorHex);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 12 + MediaQuery.of(context).padding.top,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                Expanded(
                  child: Text(
                    _isEdit ? 'Chỉnh sửa khoản vay' : 'Thêm khoản vay',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
            const SizedBox(height: 16),

            // Loại
            Row(
              children: LoanType.values.map((t) {
                final selected = t == _type;
                final color = t == LoanType.borrowed
                    ? Colors.red.shade400
                    : Colors.green.shade500;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: t == LoanType.borrowed ? 6 : 0,
                    ),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _type = t;
                        _colorHex = t == LoanType.borrowed
                            ? AppColors.palette[0]
                            : AppColors.palette[12];
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? color.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected ? color : cs.outlineVariant,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          t.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected ? color : cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Tên khoản vay
            TextField(
              controller: _titleCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Tên khoản vay (vd: Vay mua xe)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Tên người liên quan
            TextField(
              controller: _contactCtrl,
              decoration: InputDecoration(
                labelText: 'Người ${_type == LoanType.borrowed ? 'cho vay' : 'vay'}',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Ngày hết hạn
            GestureDetector(
              onTap: _pickDueDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outline, width: 0.8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _dueDate == null
                          ? 'Ngày hết hạn (tuỳ chọn)'
                          : 'Hạn: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                      style: TextStyle(
                        fontSize: 13,
                        color: _dueDate == null
                            ? cs.onSurfaceVariant
                            : cs.onSurface,
                      ),
                    ),
                    const Spacer(),
                    if (_dueDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _dueDate = null),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Ghi chú
            TextField(
              controller: _noteCtrl,
              decoration: InputDecoration(
                labelText: 'Ghi chú (tuỳ chọn)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Số tiền
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ListenableBuilder(
                  listenable: _amountCtrl,
                  builder: (_, __) => Text(
                    _amountCtrl.formatted,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text('₫', style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
              ],
            ),
            const Divider(height: 12, thickness: 0.5),

            ListenableBuilder(
              listenable: _amountCtrl,
              builder: (_, __) => Numpad(onKey: _amountCtrl.press),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
              child: ListenableBuilder(
                listenable: _amountCtrl,
                builder: (_, __) => SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed:
                    _loading || !_amountCtrl.hasValue || _titleCtrl.text.trim().isEmpty
                        ? null
                        : _submit,
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
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : Text(
                      _isEdit ? 'Lưu thay đổi' : 'Thêm khoản vay',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}