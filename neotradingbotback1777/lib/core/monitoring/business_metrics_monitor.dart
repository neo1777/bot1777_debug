import 'dart:async';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:neotradingbotback1777/core/config/trading_constants.dart';
import 'package:logger/logger.dart';
import 'package:neotradingbotback1777/core/monitoring/metrics_dtos.dart';

/// Monitoraggio avanzato per metriche business-critical del sistema di trading
class BusinessMetricsMonitor {
  final Logger _log = LogManager.getLogger();

  // Metriche di trading
  final Map<String, TradingMetrics> _tradingMetrics = {};
  final Map<String, PerformanceMetrics> _performanceMetrics = {};
  final Map<String, ErrorMetrics> _errorMetrics = {};

  // Timer per il monitoraggio periodico
  Timer? _monitoringTimer;
  Timer? _cleanupTimer;

  // Configurazione
  final Duration _monitoringInterval =
      TradingConstants.metricsCollectionInterval;
  final Duration _cleanupInterval = TradingConstants.metricsCleanupInterval;

  BusinessMetricsMonitor() : _startTime = DateTime.now() {
    _startMonitoring();
    _startCleanup();
  }

  final DateTime _startTime;

  /// Avvia il monitoraggio periodico
  void _startMonitoring() {
    _monitoringTimer = Timer.periodic(_monitoringInterval, (_) {
      _collectMetrics();
      _analyzeMetrics();
    });
    _log.i('Business metrics monitoring started');
  }

  /// Avvia la pulizia periodica delle metriche vecchie
  void _startCleanup() {
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) {
      _cleanupOldMetrics();
    });
    _log.i('Business metrics cleanup started');
  }

  /// Registra una metrica di trading
  void recordTradingMetric(
    String symbol,
    TradingMetricType type,
    double value, {
    Map<String, dynamic>? metadata,
  }) {
    final metrics =
        _tradingMetrics.putIfAbsent(symbol, () => TradingMetrics(symbol));
    metrics.recordMetric(type, value, metadata: metadata);
  }

  /// Registra una metrica di performance
  void recordPerformanceMetric(
    String operation,
    PerformanceMetricType type,
    Duration duration, {
    Map<String, dynamic>? metadata,
  }) {
    final metrics = _performanceMetrics.putIfAbsent(
        operation, () => PerformanceMetrics(operation));
    metrics.recordMetric(type, duration, metadata: metadata);
  }

  /// Registra una metrica di errore
  void recordErrorMetric(
    String operation,
    ErrorMetricType type,
    String error, {
    Map<String, dynamic>? metadata,
  }) {
    final metrics =
        _errorMetrics.putIfAbsent(operation, () => ErrorMetrics(operation));
    metrics.recordMetric(type, error, metadata: metadata);
  }

  /// Registra un trade completato
  void recordTradeCompleted(TradeCompletionInfo info) {
    recordTradingMetric(
        info.symbol, TradingMetricType.tradeCompleted, info.profit,
        metadata: info.toMetadata());
  }

  /// Registra un trade fallito
  void recordTradeFailed(String symbol, String reason) {
    recordTradingMetric(symbol, TradingMetricType.tradeFailed, 0.0, metadata: {
      'reason': reason,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Registra una decisione di trading
  void recordTradingDecision(
      String symbol, String decision, double confidence) {
    recordTradingMetric(symbol, TradingMetricType.tradingDecision, confidence,
        metadata: {
          'decision': decision,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
  }

  /// Registra il tempo di esecuzione di un'operazione
  void recordOperationDuration(String operation, Duration duration) {
    recordPerformanceMetric(
        operation, PerformanceMetricType.operationDuration, duration);
  }

  /// Registra l'utilizzo della memoria
  void recordMemoryUsage(int bytesUsed) {
    recordPerformanceMetric('memory', PerformanceMetricType.memoryUsage,
        Duration(milliseconds: bytesUsed));
  }

  /// Registra l'utilizzo della CPU
  void recordCpuUsage(double percentage) {
    recordPerformanceMetric('cpu', PerformanceMetricType.cpuUsage,
        Duration(milliseconds: (percentage * 1000).round()));
  }

  /// Registra un errore di rete
  void recordNetworkError(String operation, String error) {
    recordErrorMetric(operation, ErrorMetricType.networkError, error);
  }

  /// Registra un errore di validazione
  void recordValidationError(String operation, String error) {
    recordErrorMetric(operation, ErrorMetricType.validationError, error);
  }

  /// Registra un errore di business logic
  void recordBusinessError(String operation, String error) {
    recordErrorMetric(operation, ErrorMetricType.businessError, error);
  }

  /// Raccoglie le metriche correnti
  void _collectMetrics() {
    final now = DateTime.now();

    // Raccoglie metriche di sistema
    _collectSystemMetrics();

    // Raccoglie metriche di trading
    _collectTradingMetrics();

    _log.d('Metrics collected at ${now.toIso8601String()}');
  }

  /// Raccoglie le metriche di sistema
  void _collectSystemMetrics() {
    // Uptime del processo
    final uptime = DateTime.now().difference(_startTime);
    recordPerformanceMetric(
      'system',
      PerformanceMetricType.operationDuration,
      uptime,
      metadata: {'metric': 'uptime_seconds', 'value': uptime.inSeconds},
    );

    // Numero di simboli attivi monitorati
    recordPerformanceMetric(
      'system',
      PerformanceMetricType.operationDuration,
      Duration.zero,
      metadata: {
        'metric': 'active_symbols_count',
        'value': _tradingMetrics.length,
      },
    );
  }

  /// Raccoglie le metriche di trading aggregate
  void _collectTradingMetrics() {
    for (final entry in _tradingMetrics.entries) {
      final symbol = entry.key;
      final metrics = entry.value;

      // Aggregazioni per simbolo usando l'API pubblica di TradingMetrics
      final totalTrades = metrics.getTotalTrades();
      final lossRate = metrics.getLossRate();
      final volume = metrics.getVolume();

      _log.t(
        'Trading metrics for $symbol: '
        'trades=$totalTrades, '
        'lossRate=${lossRate.toStringAsFixed(1)}%, '
        'volume=${volume.toStringAsFixed(4)}',
      );
    }
  }

  /// Analizza le metriche per identificare anomalie
  void _analyzeMetrics() {
    _analyzeTradingAnomalies();
    _analyzePerformanceAnomalies();
    _analyzeErrorPatterns();
  }

  /// Analizza anomalie nelle metriche di trading
  void _analyzeTradingAnomalies() {
    for (final entry in _tradingMetrics.entries) {
      final symbol = entry.key;
      final metrics = entry.value;

      // Controlla per perdite eccessive
      if (metrics.hasExcessiveLosses()) {
        _log.w(
            'Excessive losses detected for $symbol: ${metrics.getLossRate()}%');
        _triggerAlert('EXCESSIVE_LOSSES', symbol, metrics.getLossRate());
      }

      // Controlla per volumi anomali
      if (metrics.hasAnomalousVolume()) {
        _log.w('Anomalous trading volume detected for $symbol');
        _triggerAlert('ANOMALOUS_VOLUME', symbol, metrics.getVolume());
      }
    }
  }

  /// Analizza anomalie nelle metriche di performance
  void _analyzePerformanceAnomalies() {
    for (final entry in _performanceMetrics.entries) {
      final operation = entry.key;
      final metrics = entry.value;

      // Controlla per latenza eccessiva
      if (metrics.hasExcessiveLatency()) {
        _log.w(
            'Excessive latency detected for $operation: ${metrics.getAverageLatency()}');
        _triggerAlert(
            'EXCESSIVE_LATENCY', operation, metrics.getAverageLatency());
      }

      // Controlla per utilizzo eccessivo di memoria
      if (metrics.hasExcessiveMemoryUsage()) {
        _log.w('Excessive memory usage detected for $operation');
        _triggerAlert('EXCESSIVE_MEMORY', operation, metrics.getMemoryUsage());
      }
    }
  }

  /// Analizza pattern di errori
  void _analyzeErrorPatterns() {
    for (final entry in _errorMetrics.entries) {
      final operation = entry.key;
      final metrics = entry.value;

      // Controlla per tasso di errore elevato
      if (metrics.hasHighErrorRate()) {
        _log.w(
            'High error rate detected for $operation: ${metrics.getErrorRate()}%');
        _triggerAlert('HIGH_ERROR_RATE', operation, metrics.getErrorRate());
      }

      // Controlla per errori critici
      if (metrics.hasCriticalErrors()) {
        _log.w('Critical errors detected for $operation');
        _triggerAlert(
            'CRITICAL_ERRORS', operation, metrics.getCriticalErrorCount());
      }
    }
  }

  /// Attiva un alert
  void _triggerAlert(String type, String context, dynamic value) {
    _log.e('BUSINESS_ALERT: $type in $context - Value: $value');

    // Qui si potrebbe inviare l'alert a un sistema di notifiche esterno
    // (email, Slack, PagerDuty, etc.)
  }

  /// Pulisce le metriche vecchie
  void _cleanupOldMetrics() {
    final cutoff =
        DateTime.now().subtract(TradingConstants.metricsRetentionPeriod);

    for (final metrics in _tradingMetrics.values) {
      metrics.cleanupOldData(cutoff);
    }

    for (final metrics in _performanceMetrics.values) {
      metrics.cleanupOldData(cutoff);
    }

    for (final metrics in _errorMetrics.values) {
      metrics.cleanupOldData(cutoff);
    }

    _log.d('Old metrics cleaned up');
  }

  /// Ottiene le metriche per un simbolo
  TradingMetrics? getTradingMetrics(String symbol) {
    return _tradingMetrics[symbol];
  }

  /// Ottiene le metriche di performance per un'operazione
  PerformanceMetrics? getPerformanceMetrics(String operation) {
    return _performanceMetrics[operation];
  }

  /// Ottiene le metriche di errore per un'operazione
  ErrorMetrics? getErrorMetrics(String operation) {
    return _errorMetrics[operation];
  }

  /// Ottiene un riepilogo delle metriche
  Map<String, dynamic> getMetricsSummary() {
    return {
      'tradingMetrics':
          _tradingMetrics.map((k, v) => MapEntry(k, v.getSummary())),
      'performanceMetrics':
          _performanceMetrics.map((k, v) => MapEntry(k, v.getSummary())),
      'errorMetrics': _errorMetrics.map((k, v) => MapEntry(k, v.getSummary())),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Ottiene le metriche in tempo reale
  Map<String, dynamic> getRealTimeMetrics() {
    return {
      'activeSymbols': _tradingMetrics.keys.toList(),
      'activeOperations': _performanceMetrics.keys.toList(),
      'totalTrades':
          _tradingMetrics.values.fold(0, (sum, m) => sum + m.getTotalTrades()),
      'totalErrors':
          _errorMetrics.values.fold(0, (sum, m) => sum + m.getTotalErrors()),
      'averageLatency': _performanceMetrics.values
              .fold(0.0, (sum, m) => sum + m.getAverageLatency()) /
          _performanceMetrics.length,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Dispone del monitoraggio
  void dispose() {
    _monitoringTimer?.cancel();
    _cleanupTimer?.cancel();
    _tradingMetrics.clear();
    _performanceMetrics.clear();
    _errorMetrics.clear();
    _log.i('Business metrics monitoring disposed');
  }
}

/// Tipi di metriche di trading
enum TradingMetricType {
  tradeCompleted,
  tradeFailed,
  tradingDecision,
  profitLoss,
  volume,
  volatility,
}

/// Tipi di metriche di performance
enum PerformanceMetricType {
  operationDuration,
  memoryUsage,
  cpuUsage,
  networkLatency,
  cacheHitRate,
}

/// Tipi di metriche di errore
enum ErrorMetricType {
  networkError,
  validationError,
  businessError,
  systemError,
  timeoutError,
}

/// Severità degli alert
enum AlertSeverity {
  low,
  medium,
  high,
  critical,
}

/// Alert di business
class BusinessAlert {
  final String type;
  final String context;
  final dynamic value;
  final DateTime timestamp;
  final AlertSeverity severity;

  BusinessAlert({
    required this.type,
    required this.context,
    required this.value,
    required this.timestamp,
    required this.severity,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'context': context,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
      'severity': severity.name,
    };
  }
}

/// Metriche di trading per un simbolo
class TradingMetrics {
  final String symbol;
  final List<TradingMetric> _metrics = [];
  final DateTime _createdAt = DateTime.now();

  TradingMetrics(this.symbol);

  void recordMetric(TradingMetricType type, double value,
      {Map<String, dynamic>? metadata}) {
    _metrics.add(TradingMetric(
      type: type,
      value: value,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    ));
  }

  bool hasExcessiveLosses() {
    final losses = _metrics
        .where((m) => m.type == TradingMetricType.profitLoss && m.value < 0)
        .toList();
    return losses.length > 10 &&
        losses.fold(0.0, (sum, m) => sum + m.value.abs()) >
            TradingConstants.excessiveLossThreshold;
  }

  bool hasAnomalousVolume() {
    final volumes =
        _metrics.where((m) => m.type == TradingMetricType.volume).toList();
    if (volumes.length < TradingConstants.minMetricsForAnalysis) return false;

    final avgVolume =
        volumes.fold(0.0, (sum, m) => sum + m.value) / volumes.length;
    final lastVolume = volumes.last.value;

    return lastVolume >
            avgVolume * TradingConstants.anomalousVolumeMultiplier ||
        lastVolume < avgVolume * 0.3;
  }

  double getLossRate() {
    final totalTrades = _metrics
        .where((m) => m.type == TradingMetricType.tradeCompleted)
        .length;
    final losingTrades = _metrics
        .where((m) => m.type == TradingMetricType.tradeCompleted && m.value < 0)
        .length;

    return totalTrades > 0 ? (losingTrades / totalTrades) * 100 : 0.0;
  }

  double getVolume() {
    final volumes =
        _metrics.where((m) => m.type == TradingMetricType.volume).toList();
    return volumes.fold(0.0, (sum, m) => sum + m.value);
  }

  int getTotalTrades() {
    return _metrics
        .where((m) => m.type == TradingMetricType.tradeCompleted)
        .length;
  }

  void cleanupOldData(DateTime cutoff) {
    _metrics.removeWhere((m) => m.timestamp.isBefore(cutoff));
  }

  Map<String, dynamic> getSummary() {
    return {
      'symbol': symbol,
      'totalMetrics': _metrics.length,
      'totalTrades': getTotalTrades(),
      'lossRate': getLossRate(),
      'volume': getVolume(),
      'createdAt': _createdAt.toIso8601String(),
    };
  }
}

/// Metriche di performance per un'operazione
class PerformanceMetrics {
  final String operation;
  final List<PerformanceMetric> _metrics = [];
  final DateTime _createdAt = DateTime.now();

  PerformanceMetrics(this.operation);

  void recordMetric(PerformanceMetricType type, Duration duration,
      {Map<String, dynamic>? metadata}) {
    _metrics.add(PerformanceMetric(
      type: type,
      duration: duration,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    ));
  }

  bool hasExcessiveLatency() {
    final latencies = _metrics
        .where((m) => m.type == PerformanceMetricType.operationDuration)
        .toList();
    if (latencies.length < TradingConstants.minMetricsForAnalysis) return false;

    final avgLatency =
        latencies.fold(0.0, (sum, m) => sum + m.duration.inMilliseconds) /
            latencies.length;
    return avgLatency > TradingConstants.excessiveLatencyThresholdMs;
  }

  bool hasExcessiveMemoryUsage() {
    final memoryUsages = _metrics
        .where((m) => m.type == PerformanceMetricType.memoryUsage)
        .toList();
    if (memoryUsages.isEmpty) return false;

    final lastUsage = memoryUsages.last.duration.inMilliseconds;
    return lastUsage > TradingConstants.excessiveMemoryThresholdBytes;
  }

  double getAverageLatency() {
    final latencies = _metrics
        .where((m) => m.type == PerformanceMetricType.operationDuration)
        .toList();
    if (latencies.isEmpty) return 0.0;

    return latencies.fold(0.0, (sum, m) => sum + m.duration.inMilliseconds) /
        latencies.length;
  }

  int getMemoryUsage() {
    final memoryUsages = _metrics
        .where((m) => m.type == PerformanceMetricType.memoryUsage)
        .toList();
    return memoryUsages.isEmpty ? 0 : memoryUsages.last.duration.inMilliseconds;
  }

  void cleanupOldData(DateTime cutoff) {
    _metrics.removeWhere((m) => m.timestamp.isBefore(cutoff));
  }

  Map<String, dynamic> getSummary() {
    return {
      'operation': operation,
      'totalMetrics': _metrics.length,
      'averageLatency': getAverageLatency(),
      'memoryUsage': getMemoryUsage(),
      'createdAt': _createdAt.toIso8601String(),
    };
  }
}

/// Metriche di errore per un'operazione
class ErrorMetrics {
  final String operation;
  final List<ErrorMetric> _metrics = [];
  final DateTime _createdAt = DateTime.now();

  ErrorMetrics(this.operation);

  void recordMetric(ErrorMetricType type, String error,
      {Map<String, dynamic>? metadata}) {
    _metrics.add(ErrorMetric(
      type: type,
      error: error,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    ));
  }

  bool hasHighErrorRate() {
    final totalOperations = _metrics.length;
    final errors =
        _metrics.where((m) => m.type != ErrorMetricType.systemError).length;

    return totalOperations > 10 &&
        (errors / totalOperations) > TradingConstants.highErrorRateThreshold;
  }

  bool hasCriticalErrors() {
    return _metrics
        .where((m) => m.type == ErrorMetricType.systemError)
        .isNotEmpty;
  }

  double getErrorRate() {
    final totalOperations = _metrics.length;
    if (totalOperations == 0) return 0.0;

    final errors =
        _metrics.where((m) => m.type != ErrorMetricType.systemError).length;
    return (errors / totalOperations) * 100;
  }

  int getCriticalErrorCount() {
    return _metrics.where((m) => m.type == ErrorMetricType.systemError).length;
  }

  int getTotalErrors() {
    return _metrics.length;
  }

  void cleanupOldData(DateTime cutoff) {
    _metrics.removeWhere((m) => m.timestamp.isBefore(cutoff));
  }

  Map<String, dynamic> getSummary() {
    return {
      'operation': operation,
      'totalErrors': _metrics.length,
      'errorRate': getErrorRate(),
      'criticalErrors': getCriticalErrorCount(),
      'createdAt': _createdAt.toIso8601String(),
    };
  }
}

/// Metrica di trading
class TradingMetric {
  final TradingMetricType type;
  final double value;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  TradingMetric({
    required this.type,
    required this.value,
    required this.timestamp,
    required this.metadata,
  });
}

/// Metrica di performance
class PerformanceMetric {
  final PerformanceMetricType type;
  final Duration duration;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  PerformanceMetric({
    required this.type,
    required this.duration,
    required this.timestamp,
    required this.metadata,
  });
}

/// Metrica di errore
class ErrorMetric {
  final ErrorMetricType type;
  final String error;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  ErrorMetric({
    required this.type,
    required this.error,
    required this.timestamp,
    required this.metadata,
  });
}
