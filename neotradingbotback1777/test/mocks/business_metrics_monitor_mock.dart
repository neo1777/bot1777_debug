import 'package:neotradingbotback1777/core/monitoring/business_metrics_monitor.dart';
import 'package:neotradingbotback1777/core/monitoring/metrics_dtos.dart';

/// Un'implementazione "Fake" di BusinessMetricsMonitor per i test.
/// Esegue semplicemente le operazioni senza logica reale o timer.
class FakeBusinessMetricsMonitor implements BusinessMetricsMonitor {
  @override
  void recordTradingMetric(
    String symbol,
    TradingMetricType type,
    double value, {
    Map<String, dynamic>? metadata,
  }) {}

  @override
  void recordPerformanceMetric(
    String operation,
    PerformanceMetricType type,
    Duration duration, {
    Map<String, dynamic>? metadata,
  }) {}

  @override
  void recordErrorMetric(
    String operation,
    ErrorMetricType type,
    String error, {
    Map<String, dynamic>? metadata,
  }) {}

  @override
  void recordTradeCompleted(TradeCompletionInfo info) {}

  @override
  void recordTradeFailed(String symbol, String reason) {}

  @override
  void recordTradingDecision(
      String symbol, String decision, double confidence) {}

  @override
  void recordOperationDuration(String operation, Duration duration) {}

  @override
  void recordMemoryUsage(int bytesUsed) {}

  @override
  void recordCpuUsage(double percentage) {}

  @override
  void recordNetworkError(String operation, String error) {}

  @override
  void recordValidationError(String operation, String error) {}

  @override
  void recordBusinessError(String operation, String error) {}

  @override
  TradingMetrics? getTradingMetrics(String symbol) => null;

  @override
  PerformanceMetrics? getPerformanceMetrics(String operation) => null;

  @override
  ErrorMetrics? getErrorMetrics(String operation) => null;

  @override
  Map<String, dynamic> getMetricsSummary() => {};

  @override
  Map<String, dynamic> getRealTimeMetrics() => {};

  @override
  void dispose() {}
}
