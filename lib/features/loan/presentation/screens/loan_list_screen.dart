import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/spendo_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/motion/motion.dart';
import '../../../../shared/widgets/spendo/spendo.dart';
import '../../domain/loan.dart';
import '../providers/loan_provider.dart';
import '../widgets/add_payment_sheet.dart';
import '../widgets/loan_form_sheet.dart';

/// Screen 11 of the redesign.
class LoanListScreen extends ConsumerStatefulWidget {
  const LoanListScreen({super.key, this.filterType});

  /// Seeds the segmented filter from the route's `?type=` parameter.
  final String? filterType;

  @override
  ConsumerState<LoanListScreen> createState() => _LoanListScreenState();
}

class _LoanListScreenState extends ConsumerState<LoanListScreen> {
  @override
  void initState() {
    super.initState();
    final seeded = LoanFilter.fromQuery(widget.filterType);
    if (seeded != LoanFilter.all) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(loanFilterProvider.notifier).state = seeded;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loansAsync = ref.watch(loansProvider);
    final paidAsync = ref.watch(paidByLoanProvider);
    final filter = ref.watch(loanFilterProvider);

    final hasInitialError = loansAsync.hasError && !loansAsync.hasValue;
    final isLoading = loansAsync.isLoading && !loansAsync.hasValue;
    final allLoans = loansAsync.valueOrNull ?? const <Loan>[];
    final paid = paidAsync.valueOrNull ?? const <String, int>{};

    final loans = allLoans.where(filter.matches).toList();
    final active = loans.where((l) => !l.isClosed).toList();
    final closed = loans.where((l) => l.isClosed).toList();

    return Scaffold(
      floatingActionButton: SpendoExtendedFab(
        heroTag: 'loans_fab',
        label: 'Thêm khoản vay',
        onPressed: () => showLoanFormSheet(
          context,
          initialType: switch (filter) {
            LoanFilter.borrowed => LoanType.borrowed,
            LoanFilter.lent => LoanType.lent,
            LoanFilter.all => null,
          },
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SpendoScreenHeader(title: 'Khoản vay'),
            Expanded(
              child: switch ((hasInitialError, isLoading)) {
                (true, _) => SpendoEmptyState(
                  icon: LucideIcons.circleAlert,
                  title: 'Không tải được khoản vay',
                  message: 'Kiểm tra kết nối rồi thử lại.',
                  actionLabel: 'Thử lại',
                  onAction: () => ref.invalidate(loansProvider),
                ),
                (_, true) => const Center(child: CircularProgressIndicator()),
                _ => ListView(
                  padding: const EdgeInsets.only(bottom: 96),
                  children: [
                    _TotalsCard(loans: allLoans, paid: paid),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: SpendoSegmented<LoanFilter>(
                        value: filter,
                        onChanged: (next) =>
                            ref.read(loanFilterProvider.notifier).state = next,
                        expand: true,
                        horizontalPadding: 12,
                        options: [
                          for (final value in LoanFilter.values)
                            (value: value, label: value.label),
                        ],
                      ),
                    ),
                    if (active.isEmpty && closed.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: SpendoEmptyState(
                          icon: LucideIcons.handCoins,
                          title: switch (filter) {
                            LoanFilter.borrowed => 'Chưa có khoản vay nào',
                            LoanFilter.lent => 'Chưa có khoản cho vay nào',
                            LoanFilter.all => 'Chưa có khoản vay nào',
                          },
                          message: 'Ghi lại khoản vay để theo dõi còn bao nhiêu.',
                          actionLabel: 'Thêm khoản vay',
                          onAction: () => showLoanFormSheet(context),
                        ),
                      ),
                    for (var i = 0; i < active.length; i++) ...[
                      if (i > 0) const _LoanDivider(),
                      _LoanTile(loan: active[i], paid: paid[active[i].id] ?? 0),
                    ],
                    if (closed.isNotEmpty) _ClosedSection(loans: closed),
                  ],
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LoanDivider extends StatelessWidget {
  const _LoanDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 72,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}

// ── Totals ───────────────────────────────────────────────────────────────────

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.loans, required this.paid});

  final List<Loan> loans;
  final Map<String, int> paid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    var borrowed = 0;
    var lent = 0;
    for (final loan in loans.where((l) => !l.isClosed)) {
      final remaining = remainingOf(loan, paid);
      if (loan.type == LoanType.borrowed) {
        borrowed += remaining;
      } else {
        lent += remaining;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SpendoCard(
        feature: true,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: IntrinsicHeight(
          child: Row(
            children: [
              _TotalCell(
                label: 'Đang nợ',
                value: borrowed,
                color: theme.spendo.expense,
              ),
              Container(
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              _TotalCell(
                label: 'Được nợ',
                value: lent,
                color: theme.spendo.income,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalCell extends StatelessWidget {
  const _TotalCell({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AnimatedMoneyText(
              value: value,
              formatter: (v) => formatVND(v.round()),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loan row ─────────────────────────────────────────────────────────────────

class _LoanTile extends StatelessWidget {
  const _LoanTile({required this.loan, required this.paid});

  final Loan loan;
  final int paid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isBorrowed = loan.type == LoanType.borrowed;
    final sideColor = isBorrowed ? theme.spendo.expense : theme.spendo.income;
    final remaining = remainingOf(loan, {loan.id: paid});
    final progress = loan.principal > 0 ? paid / loan.principal : 0.0;

    return PressableScale(
      deferTapToChild: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/loans/${loan.id}'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    SpendoIconTile(
                      icon: isBorrowed
                          ? LucideIcons.arrowDownLeft
                          : LucideIcons.arrowUpRight,
                      color: sideColor,
                      size: 44,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            loan.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 1),
                          _LoanSubtitle(loan: loan),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 140),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Còn lại',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: AnimatedMoneyText(
                              value: remaining,
                              formatter: (v) => formatVND(v.round()),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: sideColor,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 56, top: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: SpendoProgressBar(
                          value: progress,
                          height: 6,
                          // Repayment progress is good news; the 85% amber and
                          // over-limit red the budget bars use would read as a
                          // warning here.
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${(progress * 100).clamp(0, 100).round()}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurfaceVariant,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 10),
                      SpendoChip(
                        label: 'Trả',
                        onTap: () => showAddPaymentSheet(
                          context,
                          loan: loan,
                          remaining: remaining,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `Anh A · Hạn 30/8 · Còn 3 ngày` — the parts that exist, in that order.
class _LoanSubtitle extends StatelessWidget {
  const _LoanSubtitle({required this.loan});

  final Loan loan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final status = loan.status;
    final warn =
        status == LoanStatus.overdue || status == LoanStatus.upcoming;

    final parts = <String>[
      if (loan.contactName.isNotEmpty) loan.contactName,
      if (loan.dueDate != null)
        'Hạn ${loan.dueDate!.day}/${loan.dueDate!.month}'
      else
        'Không hạn',
      if (loanStatusLabel(loan) != null) loanStatusLabel(loan)!,
    ];

    return Text(
      parts.join(' · '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12,
        color: warn ? theme.spendo.warning : cs.onSurfaceVariant,
      ),
    );
  }
}

/// `Quá hạn` / `Còn N ngày`, or null when the loan needs no flag.
String? loanStatusLabel(Loan loan) {
  final due = loan.dueDate;
  if (due == null || loan.isClosed) return null;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final days = DateTime(due.year, due.month, due.day).difference(today).inDays;

  if (days < 0) return 'Quá hạn';
  if (days == 0) return 'Đến hạn hôm nay';
  if (days <= 7) return 'Còn $days ngày';
  return null;
}

// ── Closed ───────────────────────────────────────────────────────────────────

class _ClosedSection extends StatefulWidget {
  const _ClosedSection({required this.loans});

  final List<Loan> loans;

  @override
  State<_ClosedSection> createState() => _ClosedSectionState();
}

class _ClosedSectionState extends State<_ClosedSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final duration = appMotion.whenMotionAllowed(
      context,
      appMotion.listDuration,
    );

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: SpendoSectionHeader(
                    label: 'Đã tất toán (${widget.loans.length})',
                    padding: EdgeInsets.zero,
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: duration,
                  curve: appMotion.curveStandard,
                  child: Icon(
                    LucideIcons.chevronDown,
                    size: 16,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Column(
            children: [
              for (final loan in widget.loans) _ClosedTile(loan: loan),
            ],
          ),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: duration,
          sizeCurve: appMotion.curveLayout,
        ),
      ],
    );
  }
}

class _ClosedTile extends StatelessWidget {
  const _ClosedTile({required this.loan});

  final Loan loan;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PressableScale(
      deferTapToChild: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/loans/${loan.id}'),
          child: Container(
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Opacity(
                  opacity: 0.55,
                  child: SpendoIconTile(
                    icon: loan.type == LoanType.borrowed
                        ? LucideIcons.arrowDownLeft
                        : LucideIcons.arrowUpRight,
                    color: cs.onSurfaceVariant,
                    size: 44,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        loan.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'Đã tất toán · ${formatVND(loan.principal)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 17,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
