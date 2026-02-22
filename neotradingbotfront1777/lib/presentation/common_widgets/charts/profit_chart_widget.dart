import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';
import 'package:neotradingbotfront1777/domain/entities/app_trade.dart';
import 'package:neotradingbotfront1777/presentation/common_widgets/charts/chart_theme_utils.dart';

/// Solo Leveling themed profit/loss chart (fl_chart implementation)
class ProfitChartWidget extends StatefulWidget {
  ProfitChartWidget({
    required this.trades,
    super.key,
    this.height = 250,
    this.showCumulative = true,
  });

  final List<AppTrade> trades;
  final double height;
  final bool showCumulative;

  @override
  State<ProfitChartWidget> createState() => _ProfitChartWidgetState();
}

class _ProfitChartWidgetState extends State<ProfitChartWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.trades.isEmpty) {
      return _buildEmptyChart();
    }

    return Container(
      height: widget.height,
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          Expanded(child: _buildChart()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final totalProfit = widget.trades
        .where((t) => t.profit != null)
        .fold<double>(0.0, (sum, trade) => sum + trade.profit!);

    final profitableTrades =
        widget.trades.where((t) => t.profit != null && t.profit! > 0).length;

    final winRate =
        widget.trades.isNotEmpty
            ? (profitableTrades / widget.trades.length) * 100
            : 0.0;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accentColor,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentColor.withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'PROFIT/LOSS ANALYSIS',
                    style: TextStyle(
                      color: AppTheme.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Win Rate: ${winRate.toStringAsFixed(1)}%',
                style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 12),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${totalProfit.toStringAsFixed(2)}',
              style: TextStyle(
                color:
                    totalProfit >= 0
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${widget.trades.length} trades',
              style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChart() {
    final colors = ChartColors.fromContext(
      context,
      containerBackground: AppTheme.cardColor,
    );

    if (widget.showCumulative) {
      return _buildCumulativeLineChart(colors);
    } else {
      return _buildProfitBarChart(colors);
    }
  }

  Widget _buildCumulativeLineChart(ChartColors colors) {
    final tradesOrdered = [...widget.trades]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    double cumulative = 0.0;
    final spots = <FlSpot>[];

    for (var i = 0; i < tradesOrdered.length; i++) {
      final t = tradesOrdered[i];
      if (!t.isBuy && t.profit != null) {
        cumulative += t.profit!;
      }
      spots.add(FlSpot(i.toDouble(), cumulative));
    }

    // Calcolo bounds con padding
    final values = spots.map((s) => s.y).toList();
    double yMin = values.isEmpty ? 0 : values.reduce((a, b) => a < b ? a : b);
    double yMax = values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);
    final pad = ((yMax - yMin).abs() * 0.15).clamp(0.5, 10.0);
    yMin = (yMin > 0 ? 0 : yMin) - pad;
    yMax = (yMax < 0 ? 0 : yMax) + pad;
    if ((yMax - yMin).abs() < 1.0) {
      yMin = -1.0;
      yMax = 1.0;
    }

    final lineColor =
        cumulative >= 0 ? AppTheme.successColor : AppTheme.errorColor;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.12),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: LineChart(
        LineChartData(
          minY: yMin,
          maxY: yMax,
          gridData: buildChartGrid(colors),
          borderData: buildChartBorder(colors),
          titlesData: const FlTitlesData(
            show: true,
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 44),
            ),
          ),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: 0,
                color: Colors.white.withValues(alpha: 0.5),
                strokeWidth: 1,
              ),
            ],
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.15,
              color: lineColor,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: lineColor.withValues(alpha: 0.15),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '\$${spot.y.toStringAsFixed(2)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOut,
      ),
    );
  }

  Widget _buildProfitBarChart(ChartColors colors) {
    final tradesOrdered = [...widget.trades]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final sellTrades =
        tradesOrdered.where((t) => !t.isBuy && t.profit != null).toList();

    if (sellTrades.isEmpty) return _buildEmptyChart();

    final groups = <BarChartGroupData>[];
    for (var i = 0; i < sellTrades.length; i++) {
      final profit = sellTrades[i].profit!;
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: profit,
              color: profit >= 0 ? AppTheme.successColor : AppTheme.errorColor,
              width: 8,
              borderRadius: BorderRadius.vertical(
                top: profit >= 0 ? const Radius.circular(2) : Radius.zero,
                bottom: profit < 0 ? const Radius.circular(2) : Radius.zero,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.12),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: BarChart(
        BarChartData(
          barGroups: groups,
          gridData: buildChartGrid(colors),
          borderData: buildChartBorder(colors),
          titlesData: const FlTitlesData(
            show: true,
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 44),
            ),
          ),
          barTouchData: BarTouchData(enabled: true),
        ),
        duration: const Duration(milliseconds: 1000),
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Container(
      height: widget.height,
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.trending_up,
            size: 48,
            color: AppTheme.mutedTextColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'NESSUN DATO PROFIT',
            style: TextStyle(
              color: AppTheme.textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'I dati di profitto appariranno qui quando disponibili',
            style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
