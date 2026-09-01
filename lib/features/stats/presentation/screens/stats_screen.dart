import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/spendo_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../shared/domain/period.dart';
import '../../../../shared/providers/shell_tab_provider.dart';
import '../../../../shared/widgets/motion/motion.dart';
import '../../../../shared/widgets/spendo/spendo.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../transactions/domain/transaction_filter.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../providers/stats_provider.dart';

/// Which breakdown the screen is showing.
enum _StatsView { byCategory, byDay }

/// Screen 10 of the redesign.
class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  _StatsView _view = _StatsView.byCategory;

  /// Opens the transaction list already narrowed to [categoryId] over the
  /// period on screen.
  ///
  /// The audit found the legend inert: seeing that Ăn uống took 44% gave no
  /// way through to the entries behind it.
  void _drillDown(String categoryId) {
    final period = ref.read(statsPeriodProvider);
    final side = ref.read(statsSideProvider);

    ref.read(transactionsPeriodProvider.notifier).state = period;
    ref.read(transactionFilterProvider.notifier).state = TransactionFilter(
      type: side == StatsSide.expense
          ? TransactionTypeFilter.expense
          : TransactionTypeFilter.income,
      categoryIds: {categoryId},
    );
    ref.read(shellTabProvider.notifier).state = ShellTab.transactions;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final txsAsync = ref.watch(statsTransactionsProvider);
    final period = ref.watch(statsPeriodProvider);
    final side = ref.watch(statsSideProvider);
    final summary = ref.watch(statsSummaryProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final categoryMap = <String, Category>{for (final c in categories) c.id: c};

    final hasInitialError = txsAsync.hasError && !txsAsync.hasValue;
    final isLoading = txsAsync.isLoading && !txsAsync.hasValue;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              period: period,
              onPeriodChanged: (next) =>
                  ref.read(statsPeriodProvider.notifier).state = next,
            ),
            _SummaryRow(
              summary: summary,
              isLoading: isLoading,
              hasError: hasInitialError,
            ),
            _ControlRow(
              view: _view,
              side: side,
              onViewChanged: (next) => setState(() => _view = next),
              onSideChanged: (next) =>
                  ref.read(statsSideProvider.notifier).state = next,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: appMotion.whenMotionAllowed(
                  context,
                  appMotion.screenDuration,
                ),
                switchInCurve: appMotion.curveStandard,
                switchOutCurve: appMotion.curveStandard,
                child: switch ((hasInitialError, isLoading)) {
                  (true, _) => _LoadError(
                    key: const ValueKey('stats_error'),
                    onRetry: () => ref.invalidate(statsTransactionsProvider),
                  ),
                  (_, true) => const _ChartSkeleton(
                    key: ValueKey('stats_loading'),
                  ),
                  _ => switch (_view) {
                    _StatsView.byCategory => _CategoryView(
                      key: const ValueKey('stats_category'),
                      categoryMap: categoryMap,
                      onTapSlice: _drillDown,
                    ),
                    _StatsView.byDay => _DailyView(
                      key: const ValueKey('stats_daily'),
                      period: period,
                    ),
                  },
                },
              ),
            ),
          ],
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.period, required this.onPeriodChanged});

  final Period period;
  final ValueChanged<Period> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 52,
      child: Row(
        children: [
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              'Thống kê',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 23),
            ),
          ),
          const SizedBox(width: 8),
          const Spacer(),
          SpendoPeriodStepper(
            period: period,
            onChanged: onPeriodChanged,
            allowCustomRange: true,
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ── Summary ──────────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.summary,
    required this.isLoading,
    required this.hasError,
  });

  final ({int income, int expense, int balance}) summary;
  final bool isLoading;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (hasError) return const SizedBox(height: 12);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryCell(
            label: 'Thu',
            value: summary.income,
            sign: '+',
            color: theme.spendo.income,
            isLoading: isLoading,
          ),
          _SummaryCell(
            label: 'Chi',
            value: summary.expense,
            sign: '−',
            color: theme.spendo.expense,
            isLoading: isLoading,
          ),
          _SummaryCell(
            label: 'Ròng',
            value: summary.balance.abs(),
            sign: summary.balance < 0 ? '−' : '+',
            color: summary.balance < 0
                ? theme.spendo.expense
                : theme.colorScheme.onSurface,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.label,
    required this.value,
    required this.sign,
    required this.color,
    required this.isLoading,
  });

  final String label;
  final int value;
  final String sign;
  final Color color;
  final bool isLoading;

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
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          if (isLoading)
            const SkeletonBlock(width: 92, height: 20)
          else
            // Three totals share a 360dp row, so each scales down rather than
            // truncating — a partly-shown amount reads as a different number.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: AnimatedMoneyText(
                value: value,
                formatter: (v) => '$sign${formatVND(v.round(), withSymbol: false)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
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

// ── Control row ──────────────────────────────────────────────────────────────

class _ControlRow extends StatelessWidget {
  const _ControlRow({
    required this.view,
    required this.side,
    required this.onViewChanged,
    required this.onSideChanged,
  });

  final _StatsView view;
  final StatsSide side;
  final ValueChanged<_StatsView> onViewChanged;
  final ValueChanged<StatsSide> onSideChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          // Two segmented controls share this line; the wider one gives way
          // first, since 'Chi | Thu' is already at its minimum.
          Flexible(
            child: SpendoSegmented<_StatsView>(
              value: view,
              onChanged: onViewChanged,
              expand: true,
              height: 30,
              horizontalPadding: 10,
              options: const [
                (value: _StatsView.byCategory, label: 'Danh mục'),
                (value: _StatsView.byDay, label: 'Theo ngày'),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SpendoSegmented<StatsSide>(
            value: side,
            onChanged: onSideChanged,
            height: 30,
            horizontalPadding: 14,
            options: const [
              (value: StatsSide.expense, label: 'Chi'),
              (value: StatsSide.income, label: 'Thu'),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Category view ────────────────────────────────────────────────────────────

class _CategoryView extends ConsumerStatefulWidget {
  const _CategoryView({
    super.key,
    required this.categoryMap,
    required this.onTapSlice,
  });

  final Map<String, Category> categoryMap;
  final ValueChanged<String> onTapSlice;

  @override
  ConsumerState<_CategoryView> createState() => _CategoryViewState();
}

class _CategoryViewState extends ConsumerState<_CategoryView> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final slices = ref.watch(statsByCategoryProvider);
    final total = ref.watch(statsSideTotalProvider);
    final side = ref.watch(statsSideProvider);

    if (slices.isEmpty) {
      return SpendoEmptyState(
        icon: LucideIcons.chartPie,
        title: side == StatsSide.expense
            ? 'Chưa có khoản chi nào trong kỳ này'
            : 'Chưa có khoản thu nào trong kỳ này',
        message: 'Thêm giao dịch để xem thống kê.',
      );
    }

    Color colorOf(int index) =>
        widget.categoryMap[slices[index].categoryId]?.color ??
        cs.onSurfaceVariant;

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        SizedBox(
          height: 210,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 58,
                    startDegreeOffset: -90,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        final index =
                            response?.touchedSection?.touchedSectionIndex ?? -1;
                        if (event.isInterestedForInteractions &&
                            index >= 0 &&
                            index < slices.length) {
                          // Touching a wedge is the same gesture as tapping its
                          // legend row, so it lands in the same place.
                          if (event is FlTapUpEvent) {
                            widget.onTapSlice(slices[index].categoryId);
                          }
                        }
                        setState(() => _touchedIndex = index);
                      },
                    ),
                    sections: [
                      for (var i = 0; i < slices.length; i++)
                        PieChartSectionData(
                          value: slices[i].amount.toDouble(),
                          color: colorOf(i),
                          radius: i == _touchedIndex ? 34 : 26,
                          showTitle: false,
                        ),
                    ],
                  ),
                  swapAnimationDuration: appMotion.whenMotionAllowed(
                    context,
                    appMotion.screenDuration,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    side == StatsSide.expense ? 'Tổng chi' : 'Tổng thu',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  AnimatedMoneyText(
                    value: total,
                    formatter: (v) => formatVND(v.round()),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        for (var i = 0; i < slices.length; i++)
          _LegendRow(
            slice: slices[i],
            category: widget.categoryMap[slices[i].categoryId],
            color: colorOf(i),
            onTap: () => widget.onTapSlice(slices[i].categoryId),
          ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.slice,
    required this.category,
    required this.color,
    required this.onTap,
  });

  final StatsSlice slice;
  final Category? category;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PressableScale(
      deferTapToChild: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category?.name ?? 'Không rõ',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(slice.share * 100).round()}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      formatVND(slice.amount),
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
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

// ── Daily view ───────────────────────────────────────────────────────────────

class _DailyView extends ConsumerWidget {
  const _DailyView({super.key, required this.period});

  final Period period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final totals = ref.watch(statsDailyTotalsProvider);
    final side = ref.watch(statsSideProvider);

    if (totals.isEmpty) {
      return const SpendoEmptyState(
        icon: LucideIcons.chartColumn,
        title: 'Chưa có giao dịch trong kỳ này',
        message: 'Thêm giao dịch để xem thống kê.',
      );
    }

    int valueOf(({int income, int expense}) entry) =>
        side == StatsSide.expense ? entry.expense : entry.income;

    final days = totals.keys.toList()..sort();
    final barColor = side == StatsSide.expense
        ? theme.spendo.expense
        : theme.spendo.income;
    final maxValue = days
        .map((d) => valueOf(totals[d]!))
        .fold(0, (a, b) => a > b ? a : b);

    // Past a quarter the bars are thinner than the gaps between them, so the
    // chart stops earning its space and the table carries the period alone.
    final showChart = period.daySpan <= 92;

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        if (showChart && maxValue > 0) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SpendoSectionHeader(
              label: side == StatsSide.expense
                  ? 'Chi theo ngày'
                  : 'Thu theo ngày',
              padding: EdgeInsets.zero,
            ),
          ),
          SizedBox(
            height: 180,
            child: Padding(
              padding: const EdgeInsets.only(left: 8, right: 16),
              child: BarChart(
                BarChartData(
                  maxY: maxValue * 1.2,
                  alignment: BarChartAlignment.spaceAround,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxValue * 1.2 / 4,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: cs.outlineVariant, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= days.length) {
                            return const SizedBox.shrink();
                          }
                          final step = (days.length / 6).ceil();
                          if (index % step != 0) return const SizedBox.shrink();
                          final day = days[index];
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '${day.day}/${day.month}',
                              style: TextStyle(
                                fontSize: 10,
                                color: cs.onSurfaceVariant,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => cs.inverseSurface,
                      getTooltipItem: (group, _, rod, __) {
                        final day = days[group.x];
                        return BarTooltipItem(
                          '${day.day}/${day.month}\n${formatVND(rod.toY.round())}',
                          TextStyle(
                            color: cs.onInverseSurface,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < days.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: valueOf(totals[days[i]]!).toDouble(),
                            color: barColor,
                            width: days.length <= 15 ? 10 : 5,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: const SpendoSectionHeader(
            label: 'Chi tiết từng ngày',
            padding: EdgeInsets.zero,
          ),
        ),
        for (final day in days.reversed)
          _DailyRow(date: day, totals: totals[day]!),
      ],
    );
  }
}

class _DailyRow extends StatelessWidget {
  const _DailyRow({required this.date, required this.totals});

  final DateTime date;
  final ({int income, int expense}) totals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final net = totals.income - totals.expense;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              formatDayHeader(date),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 8),
          if (totals.income > 0)
            _DailyAmount(
              text: '+${formatVND(totals.income, withSymbol: false)}',
              color: theme.spendo.income,
            ),
          if (totals.income > 0 && totals.expense > 0)
            const SizedBox(width: 10),
          if (totals.expense > 0)
            _DailyAmount(
              text: '−${formatVND(totals.expense, withSymbol: false)}',
              color: theme.spendo.expense,
            ),
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                '${net < 0 ? '−' : '+'}${formatVND(net.abs())}',
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: net < 0 ? theme.spendo.expense : cs.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyAmount extends StatelessWidget {
  const _DailyAmount({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      softWrap: false,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

// ── Loading / error ──────────────────────────────────────────────────────────

class _LoadError extends StatelessWidget {
  const _LoadError({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SpendoEmptyState(
      icon: LucideIcons.circleAlert,
      title: 'Không tải được thống kê',
      message: 'Kiểm tra kết nối rồi thử lại.',
      actionLabel: 'Thử lại',
      onAction: onRetry,
    );
  }
}

class _ChartSkeleton extends StatelessWidget {
  const _ChartSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        const Center(
          child: SkeletonBlock(
            width: 190,
            height: 190,
            borderRadius: BorderRadius.all(Radius.circular(95)),
          ),
        ),
        const SizedBox(height: 24),
        for (var i = 0; i < 4; i++) ...[
          const Row(
            children: [
              SkeletonBlock(
                width: 12,
                height: 12,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              SizedBox(width: 12),
              Expanded(child: SkeletonBlock(height: 14)),
              SizedBox(width: 12),
              SkeletonBlock(width: 80, height: 14),
            ],
          ),
          if (i < 3) const SizedBox(height: 20),
        ],
      ],
    );
  }
}
