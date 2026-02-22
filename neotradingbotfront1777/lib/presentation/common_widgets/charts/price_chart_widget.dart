import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';
import 'package:neotradingbotfront1777/domain/entities/price_data.dart';
import 'package:neotradingbotfront1777/presentation/common_widgets/charts/chart_theme_utils.dart';

/// Solo Leveling themed price chart with real-time updates (fl_chart implementation)
class PriceChartWidget extends StatefulWidget {
  const PriceChartWidget({
    required this.priceHistory,
    super.key,
    this.height = 300,
    this.showVolume = true,
    this.timeframe = '1H',
  });

  final List<PriceData> priceHistory;
  final double height;
  final bool showVolume;
  final String timeframe;

  @override
  State<PriceChartWidget> createState() => _PriceChartWidgetState();
}

class _PriceChartWidgetState extends State<PriceChartWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.priceHistory.isEmpty) {
      return _buildEmptyChart();
    }

    return AnimatedBuilder(
      animation: _animation,
      builder:
          (context, child) => Container(
            height: widget.height,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                Expanded(child: _buildPriceChart()),
                if (widget.showVolume) ...[
                  const SizedBox(height: 8),
                  SizedBox(height: 120, child: _buildVolumeChart()),
                ],
              ],
            ),
          ),
    );
  }

  Widget _buildHeader() {
    final currentPrice = widget.priceHistory.last;
    final previousPrice =
        widget.priceHistory.length > 1
            ? widget.priceHistory[widget.priceHistory.length - 2]
            : currentPrice;

    final priceChange = currentPrice.price - previousPrice.price;
    final priceChangePercent = (priceChange / previousPrice.price) * 100;
    final isPositive = priceChange >= 0;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.timeframe,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${currentPrice.price.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color:
                      isPositive ? AppTheme.successColor : AppTheme.errorColor,
                  size: 16,
                ),
                Text(
                  '${isPositive ? '+' : ''}${priceChangePercent.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color:
                        isPositive
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceChart() {
    final colors = ChartColors.fromContext(
      context,
      containerBackground: AppTheme.cardColor,
    );

    final spots = <FlSpot>[];
    for (var i = 0; i < widget.priceHistory.length; i++) {
      spots.add(FlSpot(i.toDouble(), widget.priceHistory[i].price));
    }

    final prices = widget.priceHistory.map((p) => p.price).toList();
    final minY = prices.reduce(math.min);
    final maxY = prices.reduce(math.max);
    final range = maxY - minY;
    final padding = range * 0.1;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.12),
        ),
      ),
      padding: const EdgeInsets.only(right: 16, top: 8, bottom: 4),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: math.max(1, spots.length - 1).toDouble(),
          minY: minY - padding,
          maxY: maxY + padding,
          gridData: buildChartGrid(colors),
          borderData: buildChartBorder(colors),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  if (value == meta.min || value == meta.max) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      value.toStringAsFixed(2),
                      style: chartAxisTextStyle(colors),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.15,
              color: AppTheme.accentColor,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.accentColor.withValues(alpha: 0.15),
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
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      ),
    );
  }

  Widget _buildVolumeChart() {
    final colors = ChartColors.fromContext(
      context,
      containerBackground: AppTheme.cardColor,
    );

    final groups = <BarChartGroupData>[];
    for (var i = 0; i < widget.priceHistory.length; i++) {
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: widget.priceHistory[i].volume24h,
              color: AppTheme.primaryColor.withValues(alpha: 0.9),
              width: math.max(1, 200 / widget.priceHistory.length),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(2),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.12),
        ),
      ),
      padding: const EdgeInsets.only(right: 16, top: 8, bottom: 4),
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
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barTouchData: BarTouchData(enabled: false),
        ),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Container(
      height: widget.height,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 48,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'Nessun Dato Prezzo',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'I dati dei prezzi appariranno qui quando disponibili',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
