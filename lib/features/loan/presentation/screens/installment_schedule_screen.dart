import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/spendo_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/notice/notice.dart';
import '../../../../shared/widgets/motion/motion.dart';
import '../../../../shared/widgets/spendo/spendo.dart';
import '../../../transactions/presentation/widgets/amount_input_controller.dart';
import '../../domain/installment_generator.dart';
import '../../domain/loan.dart';
import '../providers/loan_provider.dart';

/// Pushes the schedule screen — the single place it is opened from.
///
/// Returns true when a schedule was saved, so a caller that opened it right
/// after creating a loan can tell whether the user followed through.
Future<bool> openInstallmentSchedule(
  BuildContext context, {
  required Loan loan,
  required int target,
  List<LoanInstallment> existing = const [],
}) async {
  final saved = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => InstallmentScheduleScreen(
        loan: loan,
        target: target,
        existing: existing,
      ),
    ),
  );
  return saved ?? false;
}

/// Builds and edits a loan's repayment schedule.
///
/// A full screen rather than a sheet: a schedule can run to a hundred rows,
/// which a bottom sheet has nowhere to put.
class InstallmentScheduleScreen extends ConsumerStatefulWidget {
  const InstallmentScheduleScreen({
    super.key,
    required this.loan,
    required this.target,
    this.existing = const [],
  });

  final Loan loan;

  /// What the schedule should add up to — the principal for a new loan, what is
  /// still owed when a schedule is built partway through (PLAN §2.1).
  final int target;

  /// The schedule being edited, empty when generating a first one.
  final List<LoanInstallment> existing;

  @override
  ConsumerState<InstallmentScheduleScreen> createState() =>
      _InstallmentScheduleScreenState();
}

class _InstallmentScheduleScreenState
    extends ConsumerState<InstallmentScheduleScreen> {
  late List<LoanInstallment> _rows;
  final _inputCtrl = TextEditingController();

  GeneratorMode _mode = GeneratorMode.byCount;
  late DateTime _firstDue;
  InstallmentCycle _cycle = InstallmentCycle.monthly;
  bool _saving = false;
  String? _inputError;

  /// Collapses the schedule to the first few rows until asked for the rest — a
  /// hundred-row list is not something to scroll past on the way to the total.
  bool _showAll = false;
  static const _collapsedRows = 6;

  @override
  void initState() {
    super.initState();
    _rows = resequence(widget.existing);
    _firstDue = _rows.isNotEmpty ? _rows.first.dueDate : _defaultFirstDue();
    if (_rows.isEmpty) _inputCtrl.text = '12';
  }

  /// The loan's own due date when it is still ahead, a month out otherwise.
  DateTime _defaultFirstDue() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = widget.loan.dueDate;
    if (due != null) {
      final date = DateTime(due.year, due.month, due.day);
      if (!date.isBefore(today)) return date;
    }
    return installmentDate(today, InstallmentCycle.monthly, 1);
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  int get _total => _rows.fold(0, (sum, r) => sum + r.amount);
  int get _difference => _total - widget.target;

  void _generate() {
    final raw = int.tryParse(_inputCtrl.text.replaceAll('.', '').trim()) ?? 0;
    if (raw <= 0) {
      setState(() => _inputError = 'Nhập một số lớn hơn 0');
      return;
    }
    if (_mode == GeneratorMode.byCount && raw > kMaxInstallments) {
      setState(() => _inputError = 'Tối đa $kMaxInstallments đợt');
      return;
    }

    final generated = generateInstallments(
      loanId: widget.loan.id,
      total: widget.target,
      mode: _mode,
      input: raw,
      firstDueDate: _firstDue,
      cycle: _cycle,
    );
    if (generated.isEmpty) {
      setState(() {
        // Entering a small per-instalment amount is the way to blow past the
        // cap, and the count it would produce is not obvious while typing.
        _inputError = _mode == GeneratorMode.byAmount
            ? 'Số tiền quá nhỏ — vượt quá $kMaxInstallments đợt'
            : 'Không tạo được lịch với số này';
      });
      return;
    }
    setState(() {
      _rows = generated;
      _inputError = null;
      _showAll = false;
    });
  }

  Future<void> _pickFirstDue() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _firstDue,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 20),
    );
    if (picked != null) {
      setState(
        () => _firstDue = DateTime(picked.year, picked.month, picked.day),
      );
    }
  }

  Future<void> _editRow(LoanInstallment row) async {
    final edited = await showInstallmentEditor(context, row);
    if (edited == null) return;
    setState(() {
      _rows = resequence([
        for (final r in _rows)
          if (r.id == row.id) edited else r,
      ]);
    });
  }

  void _deleteRow(LoanInstallment row) {
    setState(() {
      _rows = resequence(_rows.where((r) => r.id != row.id).toList());
    });
  }

  Future<void> _addRow() async {
    final last = _rows.isNotEmpty ? _rows.last : null;
    final seed = LoanInstallment(
      id: 'new_${DateTime.now().microsecondsSinceEpoch}',
      loanId: widget.loan.id,
      seq: (last?.seq ?? 0) + 1,
      amount: last?.amount ?? 0,
      dueDate: last != null
          ? installmentDate(last.dueDate, _cycle, 1)
          : _firstDue,
    );
    final added = await showInstallmentEditor(context, seed, isNew: true);
    if (added == null) return;
    setState(() {
      _rows = resequence([..._rows, added]);
      _showAll = true;
    });
  }

  void _absorb() {
    setState(() => _rows = absorbIntoLast(_rows, widget.target));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(loanRepoProvider)
          .replaceInstallments(widget.loan.id, _rows);
      navigator.pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppNotice.error('Không lưu được lịch trả. Thử lại.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final visible = _showAll ? _rows : _rows.take(_collapsedRows).toList();
    final hidden = _rows.length - visible.length;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SpendoScreenHeader(
              title: widget.existing.isEmpty ? 'Tạo lịch trả' : 'Sửa lịch trả',
            ),
            Expanded(
              child: RevealScope(
                child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  _GeneratorCard(
                    mode: _mode,
                    onModeChanged: (next) => setState(() {
                      _mode = next;
                      _inputError = null;
                      _inputCtrl.text = next == GeneratorMode.byCount
                          ? '12'
                          : '';
                    }),
                    controller: _inputCtrl,
                    errorText: _inputError,
                    firstDue: _firstDue,
                    onPickFirstDue: _pickFirstDue,
                    cycle: _cycle,
                    onCycleChanged: (next) => setState(() => _cycle = next),
                    onGenerate: _generate,
                    target: widget.target,
                  ),
                  const SizedBox(height: 16),
                  if (_rows.isEmpty)
                    const SpendoEmptyState(
                      icon: LucideIcons.calendarRange,
                      title: 'Chưa có đợt nào',
                      message: 'Chọn cách chia rồi bấm Tạo lịch.',
                    )
                  else ...[
                    SpendoSectionHeader(
                      label: 'Các đợt (${_rows.length})',
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 4),
                    for (final row in visible)
                      RevealItem(
                        id: row.id,
                        child: _InstallmentRow(
                          installment: row,
                          onEdit: () => _editRow(row),
                          onDelete: () => _deleteRow(row),
                        ),
                      ),
                    if (hidden > 0)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => setState(() => _showAll = true),
                          icon: const Icon(LucideIcons.chevronDown, size: 16),
                          label: Text('Xem tất cả ($hidden đợt nữa)'),
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: SpendoChip.meta(
                          label: 'Thêm đợt',
                          icon: LucideIcons.plus,
                          onTap: _addRow,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _TotalRow(
                      count: _rows.length,
                      total: _total,
                      difference: _difference,
                      onAbsorb: _absorb,
                    ),
                  ],
                ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                12 + MediaQuery.paddingOf(context).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_difference != 0 && _rows.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        // Saving a schedule that does not add up is allowed on
                        // purpose: it is a plan, and what is left to pay always
                        // comes from the principal, so no money can go wrong.
                        'Lưu được cả khi lệch — đợt chỉ là kế hoạch.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  SpendoButton(
                    expand: true,
                    label: 'Lưu lịch trả',
                    busy: _saving,
                    onPressed: _rows.isEmpty ? null : _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Generator ────────────────────────────────────────────────────────────────

class _GeneratorCard extends StatelessWidget {
  const _GeneratorCard({
    required this.mode,
    required this.onModeChanged,
    required this.controller,
    required this.errorText,
    required this.firstDue,
    required this.onPickFirstDue,
    required this.cycle,
    required this.onCycleChanged,
    required this.onGenerate,
    required this.target,
  });

  final GeneratorMode mode;
  final ValueChanged<GeneratorMode> onModeChanged;
  final TextEditingController controller;
  final String? errorText;
  final DateTime firstDue;
  final VoidCallback onPickFirstDue;
  final InstallmentCycle cycle;
  final ValueChanged<InstallmentCycle> onCycleChanged;
  final VoidCallback onGenerate;
  final int target;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SpendoCard(
      feature: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SpendoSegmented<GeneratorMode>(
            value: mode,
            onChanged: onModeChanged,
            expand: true,
            height: 34,
            options: const [
              (value: GeneratorMode.byCount, label: 'Chia đều'),
              (value: GeneratorMode.byAmount, label: 'Theo số tiền'),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
            decoration: InputDecoration(
              labelText: mode == GeneratorMode.byCount
                  ? 'Số đợt'
                  : 'Tiền mỗi đợt',
              errorText: errorText,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SpendoChip.meta(
                label: 'Đợt đầu: ${_dateLabel(firstDue)}',
                icon: LucideIcons.calendar,
                onTap: onPickFirstDue,
              ),
              for (final option in InstallmentCycle.values)
                SpendoChip(
                  label: option.label,
                  selected: option == cycle,
                  onTap: () => onCycleChanged(option),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Chia ${formatVND(target)}',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 8),
          SpendoButton.secondary(
            expand: true,
            label: 'Tạo lịch',
            icon: LucideIcons.listPlus,
            onPressed: onGenerate,
          ),
        ],
      ),
    );
  }
}

// ── Rows ─────────────────────────────────────────────────────────────────────

class _InstallmentRow extends StatelessWidget {
  const _InstallmentRow({
    required this.installment,
    required this.onEdit,
    required this.onDelete,
  });

  final LoanInstallment installment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 50,
              child: Text(
                'Đợt ${installment.seq}',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ),
            SizedBox(
              width: 84,
              child: Text(
                _dateLabel(installment.dueDate),
                style: TextStyle(
                  fontSize: 12.5,
                  color: cs.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            Expanded(
              child: Text(
                formatVND(installment.amount, withSymbol: false),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            IconButton(
              onPressed: onEdit,
              tooltip: 'Sửa đợt ${installment.seq}',
              icon: Icon(
                LucideIcons.pencil,
                size: 16,
                color: cs.onSurfaceVariant,
              ),
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: onDelete,
              tooltip: 'Xoá đợt ${installment.seq}',
              icon: Icon(LucideIcons.trash2, size: 16, color: cs.error),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.count,
    required this.total,
    required this.difference,
    required this.onAbsorb,
  });

  final int count;
  final int total;
  final int difference;
  final VoidCallback onAbsorb;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final matches = difference == 0;

    return SpendoCard(
      color: cs.surfaceContainerLowest,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tổng $count đợt',
                  style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
                ),
              ),
              Text(
                formatVND(total),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                matches ? LucideIcons.check : LucideIcons.triangleAlert,
                size: 16,
                color: matches ? theme.spendo.income : theme.spendo.warning,
              ),
            ],
          ),
          if (!matches) ...[
            const SizedBox(height: 6),
            Text(
              difference > 0
                  ? 'Tổng các đợt thừa ${formatVND(difference)}'
                  : 'Tổng các đợt thiếu ${formatVND(-difference)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.spendo.warning,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: SpendoChip.meta(
                label: 'Dồn vào đợt cuối',
                icon: LucideIcons.wandSparkles,
                onTap: onAbsorb,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Row editor ───────────────────────────────────────────────────────────────

/// Edits one instalment's amount and date. Also used by the detail screen when
/// a single row needs correcting without opening the whole schedule.
Future<LoanInstallment?> showInstallmentEditor(
  BuildContext context,
  LoanInstallment installment, {
  bool isNew = false,
}) {
  return SpendoSheet.showModal<LoanInstallment>(
    context: context,
    builder: (_) =>
        _InstallmentEditorSheet(installment: installment, isNew: isNew),
  );
}

class _InstallmentEditorSheet extends StatefulWidget {
  const _InstallmentEditorSheet({
    required this.installment,
    required this.isNew,
  });

  final LoanInstallment installment;
  final bool isNew;

  @override
  State<_InstallmentEditorSheet> createState() =>
      _InstallmentEditorSheetState();
}

class _InstallmentEditorSheetState extends State<_InstallmentEditorSheet> {
  final _amountCtrl = AmountInputController();
  late DateTime _dueDate;

  @override
  void initState() {
    super.initState();
    _dueDate = widget.installment.dueDate;
    if (widget.installment.amount > 0) {
      _amountCtrl.prefill(widget.installment.amount.toString());
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 20),
    );
    if (picked != null) {
      setState(
        () => _dueDate = DateTime(picked.year, picked.month, picked.day),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SpendoSheet(
      header: SpendoSheetHeader(
        title: widget.isNew ? 'Thêm đợt' : 'Đợt ${widget.installment.seq}',
        onCancel: () => Navigator.of(context).pop(),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListenableBuilder(
            listenable: _amountCtrl,
            builder: (_, __) => Text(
              '${_amountCtrl.formatted} ₫',
              textAlign: TextAlign.right,
              style: theme.textTheme.displaySmall?.copyWith(fontSize: 32),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: SpendoChip.meta(
              label: 'Hạn: ${_dateLabel(_dueDate)}',
              icon: LucideIcons.calendar,
              onTap: _pickDate,
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
              label: 'Xong',
              onPressed: _amountCtrl.hasValue
                  ? () => Navigator.of(context).pop(
                      widget.installment.copyWith(
                        amount: _amountCtrl.value,
                        dueDate: _dueDate,
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

String _dateLabel(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';
