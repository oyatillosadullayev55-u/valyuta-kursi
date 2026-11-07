import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';
import '../utils/formatter.dart';
import '../utils/app_theme.dart';

class ChartCard extends StatefulWidget {
  const ChartCard({super.key});

  @override
  State<ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<ChartCard> {
  String _period = '1K';
  String _code = 'USD';
  final _periods = ['1S', '1K', '1O', '1Y'];

  @override
  Widget build(BuildContext context) {
    final p = context.watch<CurrencyProvider>();
    final data = p.chartData(_code);
    final currency = p.findByCode(_code);
    final isDark = p.isDark;

    final spots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    final minY = data.isEmpty
        ? 0.0
        : data.reduce((a, b) => a < b ? a : b) * 0.999;
    final maxY = data.isEmpty
        ? 1.0
        : data.reduce((a, b) => a > b ? a : b) * 1.001;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.trending_up,
                      color: AppTheme.primary, size: 18),
                ),
                const SizedBox(width: 10),
                const Text('Kurs dinamikasi',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const Spacer(),
                // Period buttons
                Row(
                  children: _periods
                      .map((period) => Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: _PeriodBtn(
                              label: period,
                              isActive: _period == period,
                              onTap: () =>
                                  setState(() => _period = period),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Currency selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['USD', 'EUR', 'RUB', 'GBP', 'JPY']
                    .map((code) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () => setState(() => _code = code),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _code == code
                                    ? AppTheme.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _code == code
                                      ? AppTheme.primary
                                      : AppTheme.borderLight,
                                ),
                              ),
                              child: Text(
                                code,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _code == code
                                      ? Colors.white
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Chart
            SizedBox(
              height: 180,
              child: spots.isEmpty
                  ? const Center(
                      child: Text('Ma\'lumot yo\'q',
                          style: TextStyle(color: Colors.grey)))
                  : LineChart(
                      LineChartData(
                        minY: minY,
                        maxY: maxY,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: (maxY - minY) / 4,
                          getDrawingHorizontalLine: (v) => FlLine(
                            color: isDark
                                ? AppTheme.borderDark
                                : AppTheme.borderLight,
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 60,
                              getTitlesWidget: (v, m) => Text(
                                Formatter.amount(v),
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.grey),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (v, m) {
                                final labels = [
                                  '09:00', '11:00', '13:00',
                                  '15:00', '17:00', '19:00',
                                  '21:00', '23:00'
                                ];
                                final idx = v.toInt();
                                if (idx < 0 || idx >= labels.length) {
                                  return const SizedBox.shrink();
                                }
                                return Text(labels[idx],
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.grey));
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            curveSmoothness: 0.3,
                            color: AppTheme.primary,
                            barWidth: 2.5,
                            dotData: FlDotData(
                              show: true,
                              checkToShowDot: (spot, barData) =>
                                  spot == spots.last,
                              getDotPainter: (spot, percent, barData, index) =>
                                  FlDotCirclePainter(
                                radius: 5,
                                color: AppTheme.primary,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppTheme.primary.withOpacity(0.2),
                                  AppTheme.primary.withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (spots) => spots
                                .map((s) => LineTooltipItem(
                                      Formatter.amount(s.y),
                                      const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13),
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
                    ),
            ),

            // Bottom stat
            if (currency != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.lightbulb_outline,
                        size: 16, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${Formatter.percent(currency.changePercent)} '
                        '${_code} kurs o\'sishi',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary),
                      ),
                      const Text("So'nggi 7 kun",
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PeriodBtn extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _PeriodBtn(
      {required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }
}
