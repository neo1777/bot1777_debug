import 'package:flutter/material.dart';
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';
import 'package:neotradingbotfront1777/domain/entities/price_data.dart';
import 'package:neotradingbotfront1777/domain/entities/trade_history.dart';

/// Simple chart widget without external dependencies for immediate visualization
class SimpleChartWidget extends StatefulWidget {
  const SimpleChartWidget({
    super.key,
    this.priceData,
    this.tradeHistory,
    this.height = 200,
    this.title = 'Chart',
    this.chartType = ChartType.line,
  });

  final List<PriceData>? priceData;
  final List<TradeHistory>? tradeHistory;
  final double height;
  final String title;
  final ChartType chartType;

  @override
  State<SimpleChartWidget> createState() => _SimpleChartWidgetState();
}

class _SimpleChartWidgetState extends State<SimpleChartWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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
    return AnimatedBuilder(
      animation: _animation,
      builder:
          (context, child) => Container(
            height: widget.height,
            margin: const EdgeInsets.all(8),
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  Expanded(child: _buildChart()),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildHeader() {
    String subtitle = '';
    if (widget.priceData != null && widget.priceData!.isNotEmpty) {
      final latest = widget.priceData!.last;
      subtitle =
          '\$${latest.price.toStringAsFixed(2)} (${latest.priceChange24h >= 0 ? '+' : ''}${latest.priceChange24h.toStringAsFixed(2)}%)';
    } else if (widget.tradeHistory != null && widget.tradeHistory!.isNotEmpty) {
      final totalProfit = widget.tradeHistory!
          .where((t) => t.profit != null)
          .fold<double>(0.0, (sum, trade) => sum + trade.profit!);
      subtitle =
          'Profit: \$${totalProfit.toStringAsFixed(2)} (${widget.tradeHistory!.length} trades)';
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_getChartIcon(), color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    if (widget.priceData != null && widget.priceData!.isNotEmpty) {
      return _buildPriceChart();
    } else if (widget.tradeHistory != null && widget.tradeHistory!.isNotEmpty) {
      return _buildProfitChart();
    } else {
      return _buildEmptyChart();
    }
  }

  Widget _buildPriceChart() {
    final data = widget.priceData!;
    if (data.isEmpty) return _buildEmptyChart();

    final minPrice = data.map((p) => p.price).reduce((a, b) => a < b ? a : b);
    final maxPrice = data.map((p) => p.price).reduce((a, b) => a > b ? a : b);
    final priceRange = maxPrice - minPrice;

    return CustomPaint(
      painter: LineChartPainter(
        dataPoints: data.map((p) => p.price).toList(),
        minValue: minPrice - (priceRange * 0.1),
        maxValue: maxPrice + (priceRange * 0.1),
        color: Colors.white,
        fillColor: Colors.white.withValues(alpha: 0.3),
        animation: _animation.value,
      ),
      child: Container(),
    );
  }

  Widget _buildProfitChart() {
    final trades = widget.tradeHistory!;
    if (trades.isEmpty) return _buildEmptyChart();

    final profitData = <double>[];
    double cumulativeProfit = 0;

    for (final trade in trades) {
      if (trade.profit != null) {
        cumulativeProfit += trade.profit!;
      }
      profitData.add(cumulativeProfit);
    }

    if (profitData.isEmpty) return _buildEmptyChart();

    final minProfit = profitData.reduce((a, b) => a < b ? a : b);
    final maxProfit = profitData.reduce((a, b) => a > b ? a : b);
    final range = maxProfit - minProfit;

    final chartColor =
        cumulativeProfit >= 0 ? AppTheme.successColor : AppTheme.errorColor;

    return CustomPaint(
      painter: LineChartPainter(
        dataPoints: profitData,
        minValue: minProfit - (range * 0.1),
        maxValue: maxProfit + (range * 0.1),
        color: chartColor,
        fillColor: chartColor.withValues(alpha: 0.3),
        animation: _animation.value,
      ),
      child: Container(),
    );
  }

  Widget _buildEmptyChart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 32,
            color: Colors.white.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 8),
          Text(
            'Nessun dato disponibile',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getChartIcon() {
    switch (widget.chartType) {
      case ChartType.line:
        return Icons.show_chart;
      case ChartType.bar:
        return Icons.bar_chart;
      case ChartType.profit:
        return Icons.trending_up;
    }
  }
}

enum ChartType { line, bar, profit }

/// Custom painter for simple line charts
class LineChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final double minValue;
  final double maxValue;
  final Color color;
  final Color fillColor;
  final double animation;

  LineChartPainter({
    required this.dataPoints,
    required this.minValue,
    required this.maxValue,
    required this.color,
    required this.fillColor,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final fillPaint =
        Paint()
          ..color = fillColor
          ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final animatedLength = (dataPoints.length * animation).round();
    final visibleDataPoints = dataPoints.take(animatedLength).toList();

    if (visibleDataPoints.isEmpty) return;

    // Calculate points
    final points = <Offset>[];
    for (int i = 0; i < visibleDataPoints.length; i++) {
      final x = (i / (dataPoints.length - 1)) * size.width;
      final normalizedY =
          (visibleDataPoints[i] - minValue) / (maxValue - minValue);
      final y = size.height - (normalizedY * size.height);
      points.add(Offset(x, y));
    }

    if (points.isEmpty) return;

    // Create line path
    path.moveTo(points.first.dx, points.first.dy);
    fillPath.moveTo(points.first.dx, size.height);
    fillPath.lineTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
      fillPath.lineTo(points[i].dx, points[i].dy);
    }

    // Complete fill path
    if (points.isNotEmpty) {
      fillPath.lineTo(points.last.dx, size.height);
      fillPath.close();
    }

    // Draw fill area
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    canvas.drawPath(path, paint);

    // Draw points
    final pointPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    for (final point in points) {
      canvas.drawCircle(point, 3, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

/// Simple performance metrics widget
class PerformanceMetricsWidget extends StatelessWidget {
  const PerformanceMetricsWidget({
    super.key,
    this.trades = const [],
    this.priceData,
  });

  final List<TradeHistory> trades;
  final PriceData? priceData;

  @override
  Widget build(BuildContext context) {
    final totalProfit = trades
        .where((t) => t.profit != null)
        .fold<double>(0.0, (sum, trade) => sum + trade.profit!);

    final profitable =
        trades.where((t) => t.profit != null && t.profit! > 0).length;

    final winRate =
        trades.isNotEmpty ? (profitable / trades.length) * 100 : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Metriche Performance',
            style: TextStyle(
              color: AppTheme.textColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetric(
                  'Profitto Totale',
                  '\$${totalProfit.toStringAsFixed(2)}',
                  totalProfit >= 0
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetric(
                  'Win Rate',
                  '${winRate.toStringAsFixed(1)}%',
                  winRate >= 60 ? AppTheme.successColor : AppTheme.warningColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetric(
                  'Totale Trade',
                  '${trades.length}',
                  AppTheme.accentColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetric(
                  'Prezzo Corrente',
                  priceData != null
                      ? '\$${priceData!.price.toStringAsFixed(2)}'
                      : '--',
                  AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.mutedTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
