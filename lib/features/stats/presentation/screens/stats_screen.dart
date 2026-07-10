import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/motion/motion.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../categories/domain/category.dart';
import 'package:collection/collection.dart';
import '../providers/stats_provider.dart';
import '../widgets/stats_time_selector.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(statsSummaryProvider);
    final transactionsAsync = ref.watch(statsTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const StatsTimeSelector(),
        bottom: TabBar(
          controller: _tab,
          tabs: const [Tab(text: 'Danh mục'), Tab(text: 'Theo ngày')],
          indicatorSize: TabBarIndicatorSize.label,
        ),
      ),
      body: Column(
        children: [
          _StatsSummaryRow(
            summary: summary,
            isLoading:
                transactionsAsync.isLoading && !transactionsAsync.hasValue,
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const [_CategoryTab(), _DailyTab()],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSummaryRow extends StatelessWidget {
  const _StatsSummaryRow({required this.summary, required this.isLoading});

  final ({int income, int expense, int balance}) summary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final duration = appMotion.whenMotionAllowed(
      context,
      appMotion.valueDuration,
    );

    return SizedBox(
      height: 76,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: appMotion.curveStandard,
        switchOutCurve: appMotion.curveLayout,
        child:
            isLoading
                ? const Padding(
                  key: ValueKey('stats-summary-loading'),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(child: SkeletonBlock(height: 48)),
                      SizedBox(width: 8),
                      Expanded(child: SkeletonBlock(height: 48)),
                      SizedBox(width: 8),
                      Expanded(child: SkeletonBlock(height: 48)),
                    ],
                  ),
                )
                : Padding(
                  key: const ValueKey('stats-summary-values'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatsSummaryValue(
                          label: 'Thu',
                          value: summary.income,
                          color: AppTheme.incomeColor,
                          prefix: '+',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatsSummaryValue(
                          label: 'Chi',
                          value: summary.expense,
                          color: AppTheme.expenseAltColor,
                          prefix: '-',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatsSummaryValue(
                          label: 'Ròng',
                          value: summary.balance,
                          color:
                              summary.balance >= 0
                                  ? AppTheme.incomeColor
                                  : AppTheme.expenseAltColor,
                          showPositiveSign: true,
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}

class _StatsSummaryValue extends StatelessWidget {
  const _StatsSummaryValue({
    required this.label,
    required this.value,
    required this.color,
    this.prefix = '',
    this.showPositiveSign = false,
  });

  final String label;
  final int value;
  final Color color;
  final String prefix;
  final bool showPositiveSign;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 2),
            AnimatedMoneyText(
              value: value,
              formatter: (animatedValue) {
                final rounded = animatedValue.round();
                final sign = showPositiveSign && rounded > 0 ? '+' : prefix;
                return '$sign${formatVND(rounded)}';
              },
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category pie chart ────────────────────────────────────────────────────────

class _CategoryTab extends ConsumerStatefulWidget {
  const _CategoryTab();

  @override
  ConsumerState<_CategoryTab> createState() => _CategoryTabState();
}

class _CategoryTabState extends ConsumerState<_CategoryTab> {
  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(statsTransactionsProvider);
    final byCategory = ref.watch(statsExpensesByCategoryProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final allCats = categoriesAsync.valueOrNull ?? [];
    final cs = Theme.of(context).colorScheme;

    final catMap = {for (final c in allCats) c.id: c};
    final total = byCategory.values.fold(0, (s, v) => s + v);
    final isLoading =
        (transactionsAsync.isLoading && !transactionsAsync.hasValue) ||
        (categoriesAsync.isLoading && !categoriesAsync.hasValue);

    if (isLoading) {
      return const _StatsStateTransition(
        stateKey: 'category-loading',
        child: _StatsChartLoading(),
      );
    }

    if (byCategory.isEmpty) {
      return const _StatsStateTransition(
        stateKey: 'category-empty',
        child: _EmptyStats(),
      );
    }

    final entries =
        byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return _StatsStateTransition(
      stateKey: 'category-data',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: _CategoryPieChart(
                entries: entries,
                categories: catMap,
                total: total,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Tổng chi: ',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                AnimatedMoneyText(
                  value: total,
                  formatter: (value) => formatVND(value.round()),
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...entries.map((entry) {
              final cat = catMap[entry.key];
              final pct = total > 0 ? (entry.value / total * 100) : 0.0;
              return _LegendRow(
                category: cat,
                amount: entry.value,
                percent: pct,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _CategoryPieChart extends StatefulWidget {
  const _CategoryPieChart({
    required this.entries,
    required this.categories,
    required this.total,
  });

  final List<MapEntry<String, int>> entries;
  final Map<String, Category> categories;
  final int total;

  @override
  State<_CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<_CategoryPieChart> {
  int _touchedIndex = -1;

  @override
  void didUpdateWidget(covariant _CategoryPieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_touchedIndex >= widget.entries.length) _touchedIndex = -1;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sections =
        widget.entries.asMap().entries.map((indexedEntry) {
          final index = indexedEntry.key;
          final entry = indexedEntry.value;
          final category = widget.categories[entry.key];
          final percent = widget.total > 0 ? entry.value / widget.total : 0.0;
          final isTouched = index == _touchedIndex;

          return PieChartSectionData(
            value: entry.value.toDouble(),
            color: category?.color ?? cs.outlineVariant,
            radius: isTouched ? 72 : 60,
            title:
                percent <= 0.05 ? '' : '${(percent * 100).toStringAsFixed(0)}%',
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          );
        }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 48,
        sectionsSpace: 2,
        pieTouchData: PieTouchData(
          touchCallback: (event, response) {
            final nextIndex =
                !event.isInterestedForInteractions ||
                        response?.touchedSection == null
                    ? -1
                    : response!.touchedSection!.touchedSectionIndex;
            if (nextIndex == _touchedIndex) return;
            setState(() => _touchedIndex = nextIndex);
          },
        ),
      ),
      swapAnimationDuration: appMotion.whenMotionAllowed(
        context,
        appMotion.chartDuration,
      ),
      swapAnimationCurve: appMotion.curveStandard,
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Category? category;
  final int amount;
  final double percent;

  const _LegendRow({
    required this.category,
    required this.amount,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = category?.color ?? cs.outlineVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              category?.name ?? 'Không rõ',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          // % luôn hiện (không nhạy cảm)
          Text(
            '${percent.toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          // Amount
          Text(
            formatVND(amount),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Daily bar chart ───────────────────────────────────────────────────────────

class _DailyTab extends ConsumerWidget {
  const _DailyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(statsTransactionsProvider);
    final dailyTotals = ref.watch(statsDailyTotalsProvider);
    final range = ref.watch(statsDateRangeProvider);
    final cs = Theme.of(context).colorScheme;
    final isLoading =
        transactionsAsync.isLoading && !transactionsAsync.hasValue;

    if (isLoading) {
      return const _StatsStateTransition(
        stateKey: 'daily-loading',
        child: _StatsChartLoading(),
      );
    }

    if (dailyTotals.isEmpty) {
      return const _StatsStateTransition(
        stateKey: 'daily-empty',
        child: _EmptyStats(),
      );
    }

    final daySpan = range.daySpan;

    return _StatsStateTransition(
      stateKey: 'daily-data',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Bar chart ──────────────────────────────────────────────
            if (daySpan <= 90) ...[
              Text(
                daySpan <= 31 ? 'Chi tiêu theo ngày' : 'Chi tiêu theo tuần',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child:
                    daySpan <= 31
                        ? _buildDailyBarChart(context, dailyTotals, range, cs)
                        : _buildWeeklyBarChart(context, dailyTotals, range, cs),
              ),
              const SizedBox(height: 24),
            ],

            // ── Daily detail list ──────────────────────────────────────
            Text(
              'Chi tiết từng ngày',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            ...dailyTotals.entries
                .toList()
                .sorted((a, b) => b.key.compareTo(a.key))
                .map((entry) {
                  return _DailyRow(
                    date: entry.key,
                    income: entry.value.income,
                    expense: entry.value.expense,
                  );
                }),
          ],
        ),
      ),
    );
  }

  /// Bar chart theo ngày — dùng khi range ≤ 31 ngày
  Widget _buildDailyBarChart(
    BuildContext context,
    Map<DateTime, ({int income, int expense})> dailyTotals,
    StatsDateRange range,
    ColorScheme cs,
  ) {
    final daySpan = range.daySpan;
    final gridColor = cs.outlineVariant;
    final labelColor = cs.onSurfaceVariant;

    final maxVal =
        dailyTotals.values
            .map((e) => e.expense > e.income ? e.expense : e.income)
            .fold(0, (a, b) => a > b ? a : b)
            .toDouble();

    return BarChart(
      BarChartData(
        maxY: maxVal * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxVal > 0 ? maxVal / 4 : 1,
          getDrawingHorizontalLine:
              (v) => FlLine(color: gridColor, strokeWidth: 0.5),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx < 0 || idx >= daySpan) return const SizedBox.shrink();
                final date = range.start.add(Duration(days: idx));
                // Hiện label mỗi 5 ngày hoặc ngày đầu
                if (idx % 5 != 0 && idx != 0) {
                  return const SizedBox.shrink();
                }
                return Text(
                  '${date.day}/${date.month}',
                  style: TextStyle(fontSize: 9, color: labelColor),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(daySpan, (i) {
          final date = range.start.add(Duration(days: i));
          final dateKey = DateTime(date.year, date.month, date.day);
          final data = dailyTotals[dateKey];
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: (data?.expense ?? 0).toDouble(),
                color: AppTheme.expenseAltColor.withValues(alpha: 0.8),
                width: daySpan <= 15 ? 8 : 5,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          );
        }),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => cs.inverseSurface,
            getTooltipItem: (group, _, rod, __) {
              final date = range.start.add(Duration(days: group.x));
              return BarTooltipItem(
                '${date.day}/${date.month}\n${formatVND(rod.toY.toInt())}',
                TextStyle(
                  color: cs.onInverseSurface,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
      ),
      swapAnimationDuration: appMotion.whenMotionAllowed(
        context,
        appMotion.chartDuration,
      ),
      swapAnimationCurve: appMotion.curveStandard,
    );
  }

  /// Bar chart gộp theo tuần — dùng khi 32 ≤ range ≤ 90 ngày
  Widget _buildWeeklyBarChart(
    BuildContext context,
    Map<DateTime, ({int income, int expense})> dailyTotals,
    StatsDateRange range,
    ColorScheme cs,
  ) {
    final gridColor = cs.outlineVariant;
    final labelColor = cs.onSurfaceVariant;

    // Gộp data theo tuần
    final weeks = <({DateTime start, DateTime end, int expense, int income})>[];
    var weekStart = range.start;
    while (weekStart.isBefore(range.end)) {
      var weekEnd = weekStart.add(const Duration(days: 7));
      if (weekEnd.isAfter(range.end)) weekEnd = range.end;

      int weekExpense = 0;
      int weekIncome = 0;
      for (
        var d = weekStart;
        d.isBefore(weekEnd);
        d = d.add(const Duration(days: 1))
      ) {
        final key = DateTime(d.year, d.month, d.day);
        final data = dailyTotals[key];
        weekExpense += data?.expense ?? 0;
        weekIncome += data?.income ?? 0;
      }

      weeks.add((
        start: weekStart,
        end: weekEnd.subtract(const Duration(days: 1)),
        expense: weekExpense,
        income: weekIncome,
      ));
      weekStart = weekEnd;
    }

    final maxVal =
        weeks
            .map((w) => w.expense > w.income ? w.expense : w.income)
            .fold(0, (a, b) => a > b ? a : b)
            .toDouble();

    return BarChart(
      BarChartData(
        maxY: maxVal * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxVal > 0 ? maxVal / 4 : 1,
          getDrawingHorizontalLine:
              (v) => FlLine(color: gridColor, strokeWidth: 0.5),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx < 0 || idx >= weeks.length) {
                  return const SizedBox.shrink();
                }
                final w = weeks[idx];
                return Text(
                  '${w.start.day}/${w.start.month}',
                  style: TextStyle(fontSize: 9, color: labelColor),
                );
              },
            ),
          ),
        ),
        barGroups:
            weeks.asMap().entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value.expense.toDouble(),
                    color: AppTheme.expenseAltColor.withValues(alpha: 0.8),
                    width: 10,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              );
            }).toList(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => cs.inverseSurface,
            getTooltipItem: (group, _, rod, __) {
              final w = weeks[group.x];
              return BarTooltipItem(
                '${w.start.day}/${w.start.month} – ${w.end.day}/${w.end.month}\n${formatVND(rod.toY.toInt())}',
                TextStyle(
                  color: cs.onInverseSurface,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
      ),
      swapAnimationDuration: appMotion.whenMotionAllowed(
        context,
        appMotion.chartDuration,
      ),
      swapAnimationCurve: appMotion.curveStandard,
    );
  }
}

class _DailyRow extends StatelessWidget {
  final DateTime date;
  final int income;
  final int expense;

  const _DailyRow({
    required this.date,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final net = income - expense;
    final isPos = net >= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              formatDayHeader(date),
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (income > 0)
                  Text(
                    '+${formatVND(income)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.incomeColor,
                    ),
                  ),
                if (expense > 0)
                  Text(
                    '-${formatVND(expense)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.expenseAltColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${isPos ? '+' : ''}${formatVND(net)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isPos ? AppTheme.incomeColor : AppTheme.expenseAltColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsStateTransition extends StatelessWidget {
  const _StatsStateTransition({required this.stateKey, required this.child});

  final String stateKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: appMotion.whenMotionAllowed(context, appMotion.chartDuration),
      switchInCurve: appMotion.curveStandard,
      switchOutCurve: appMotion.curveLayout,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.025),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: SizedBox.expand(key: ValueKey(stateKey), child: child),
    );
  }
}

class _StatsChartLoading extends StatelessWidget {
  const _StatsChartLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SkeletonBlock(
              width: 190,
              height: 170,
              borderRadius: BorderRadius.all(Radius.circular(28)),
            ),
            SizedBox(height: 20),
            SkeletonBlock(width: 150, height: 14),
            SizedBox(height: 12),
            SkeletonBlock(width: 220, height: 12),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyStats extends StatelessWidget {
  const _EmptyStats();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.chartPie, size: 48, color: cs.outlineVariant),
          const SizedBox(height: 12),
          Text('Chưa có dữ liệu', style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(
            'Thêm giao dịch để xem thống kê',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
