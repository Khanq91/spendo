import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../core/theme/app_theme.dart';
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
      body: TabBarView(
        controller: _tab,
        children: const [_CategoryTab(), _DailyTab()],
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
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final byCategory = ref.watch(statsExpensesByCategoryProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final allCats = categoriesAsync.valueOrNull ?? [];
    final cs = Theme.of(context).colorScheme;

    final catMap = {for (final c in allCats) c.id: c};
    final total = byCategory.values.fold(0, (s, v) => s + v);

    if (byCategory.isEmpty) return const _EmptyStats();

    final entries =
        byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final sections =
        entries.asMap().entries.map((e) {
          final i = e.key;
          final entry = e.value;
          final cat = catMap[entry.key];
          final pct = total > 0 ? entry.value / total : 0.0;
          final isTouched = i == _touchedIndex;

          return PieChartSectionData(
            value: entry.value.toDouble(),
            color: cat?.color ?? cs.outlineVariant,
            radius: isTouched ? 72 : 60,
            // Ẩn label % trên chart
            title:
                (pct <= 0.05)
                    ? ''
                    : '${(pct * 100).toStringAsFixed(0)}%',
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          );
        }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 48,
                sectionsSpace: 2,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response?.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex =
                          response!.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tổng chi: ${formatVND(total)}',
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
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
    final dailyTotals = ref.watch(statsDailyTotalsProvider);
    final range = ref.watch(statsDateRangeProvider);
    final cs = Theme.of(context).colorScheme;

    if (dailyTotals.isEmpty) return const _EmptyStats();

    final daySpan = range.daySpan;

    return SingleChildScrollView(
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
              child: daySpan <= 31
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

    final maxVal = dailyTotals.values
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
                color: AppTheme.expenseAltColor.withOpacity(0.8),
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
      for (var d = weekStart; d.isBefore(weekEnd); d = d.add(const Duration(days: 1))) {
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

    final maxVal = weeks
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
        barGroups: weeks.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.expense.toDouble(),
                color: AppTheme.expenseAltColor.withOpacity(0.8),
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
