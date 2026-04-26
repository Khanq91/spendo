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
import '../../../transactions/presentation/providers/transaction_provider.dart';

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
    final month = ref.watch(selectedMonthProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          formatMonthYear(month),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Danh mục'),
            Tab(text: 'Theo ngày'),
          ],
          indicatorSize: TabBarIndicatorSize.label,
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _CategoryTab(),
          _DailyTab(),
        ],
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
    final byCategory = ref.watch(expensesByCategoryProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final allCats = categoriesAsync.valueOrNull ?? [];
    final cs = Theme.of(context).colorScheme;

    final catMap = {for (final c in allCats) c.id: c};
    final total = byCategory.values.fold(0, (s, v) => s + v);

    if (byCategory.isEmpty) return const _EmptyStats();

    final entries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sections = entries.asMap().entries.map((e) {
      final i = e.key;
      final entry = e.value;
      final cat = catMap[entry.key];
      final pct = total > 0 ? entry.value / total : 0.0;
      final isTouched = i == _touchedIndex;

      return PieChartSectionData(
        value: entry.value.toDouble(),
        color: cat?.color ?? cs.outlineVariant,
        radius: isTouched ? 72 : 60,
        title: pct > 0.05 ? '${(pct * 100).toStringAsFixed(0)}%' : '',
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
                      _touchedIndex = response!
                          .touchedSection!.touchedSectionIndex;
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
            final pct =
            total > 0 ? (entry.value / total * 100) : 0.0;
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
            decoration:
            BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              category?.name ?? 'Không rõ',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Text(
            '${percent.toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Text(
            formatVND(amount),
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600),
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
    final dailyTotals = ref.watch(dailyTotalsProvider);
    final month = ref.watch(selectedMonthProvider);
    final cs = Theme.of(context).colorScheme;

    if (dailyTotals.isEmpty) return const _EmptyStats();

    final daysInMonth =
    DateUtils.getDaysInMonth(month.year, month.month);
    final maxVal = dailyTotals.values
        .map((e) => e.expense > e.income ? e.expense : e.income)
        .fold(0, (a, b) => a > b ? a : b)
        .toDouble();

    // Grid line color adapts to theme
    final gridColor = cs.outlineVariant;
    final labelColor = cs.onSurfaceVariant;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chi tiêu theo ngày',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxVal * 1.2,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxVal / 4,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: gridColor,
                    strokeWidth: 0.5,
                  ),
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
                        final day = val.toInt();
                        if (day % 5 != 0 && day != 1) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          '$day',
                          style: TextStyle(
                              fontSize: 10, color: labelColor),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(daysInMonth, (i) {
                  final day = i + 1;
                  final data = dailyTotals[day];
                  return BarChartGroupData(
                    x: day,
                    barRods: [
                      BarChartRodData(
                        toY: (data?.expense ?? 0).toDouble(),
                        color: AppTheme.expenseAltColor.withOpacity(0.8),
                        width: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  );
                }),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => cs.inverseSurface,
                    getTooltipItem: (group, _, rod, __) =>
                        BarTooltipItem(
                          'Ngày ${group.x}\n${formatVND(rod.toY.toInt())}',
                          TextStyle(
                            color: cs.onInverseSurface,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

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
            final day = entry.key;
            final data = entry.value;
            final date = DateTime(month.year, month.month, day);
            return _DailyRow(
              date: date,
              income: data.income,
              expense: data.expense,
            );
          }),
        ],
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
                        fontSize: 12, color: AppTheme.incomeColor),
                  ),
                if (expense > 0)
                  Text(
                    '-${formatVND(expense)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.expenseAltColor),
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
          Text('Chưa có dữ liệu',
              style: TextStyle(color: cs.onSurfaceVariant)),
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