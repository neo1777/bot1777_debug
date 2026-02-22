import 'dart:async';
import 'package:logger/logger.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';

/// Sistema di monitoraggio delle performance per il trading bot
///
/// Questo sistema traccia metriche chiave come latenza, throughput,
/// utilizzo della memoria e identificazione di colli di bottiglia
/// per ottimizzare le performance del sistema.
class PerformanceMonitor {
  final Logger _log;
  final Map<String, _MetricCollector> _metrics = {};
  final Map<String, _PerformanceAlert> _alerts = {};
  Timer? _monitoringTimer;

  /// Configurazione del monitoraggio
  final MonitoringConfig _config;

  /// Callback per gli alert di performance
  final void Function(
      String alertType, String message, Map<String, dynamic> data)? _onAlert;

  PerformanceMonitor({
    MonitoringConfig? config,
    void Function(String alertType, String message, Map<String, dynamic> data)?
        onAlert,
    Logger? logger,
  })  : _config = config ?? const MonitoringConfig(),
        _onAlert = onAlert,
        _log = logger ?? LogManager.getLogger();

  /// Avvia il monitoraggio automatico
  void startMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(_config.monitoringInterval, (_) {
      _performMonitoring();
    });
    _log.i('[PERFORMANCE] Started performance monitoring');
  }

  /// Ferma il monitoraggio automatico
  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _log.i('[PERFORMANCE] Stopped performance monitoring');
  }

  /// Registra una metrica di latenza
  void recordLatency(String operation, String context, Duration duration) {
    final key = '${context}_$operation';
    final collector = _getMetricCollector(key);
    collector.recordLatency(duration);

    // Controlla se la latenza supera le soglie
    if (duration > _config.latencyThreshold) {
      _triggerAlert('HIGH_LATENCY', 'High latency detected', {
        'operation': operation,
        'context': context,
        'latency': duration.inMilliseconds,
        'threshold': _config.latencyThreshold.inMilliseconds,
      });
    }
  }

  /// Registra una metrica di throughput
  void recordThroughput(
      String operation, String context, int count, Duration period) {
    final key = '${context}_$operation';
    final collector = _getMetricCollector(key);
    collector.recordThroughput(count, period);

    // Controlla se il throughput è troppo basso
    final rate = count / period.inSeconds;
    if (rate < _config.minThroughput) {
      _triggerAlert('LOW_THROUGHPUT', 'Low throughput detected', {
        'operation': operation,
        'context': context,
        'rate': rate,
        'threshold': _config.minThroughput,
      });
    }
  }

  /// Registra l'utilizzo della memoria
  void recordMemoryUsage(String context, int bytesUsed, int bytesTotal) {
    final key = '${context}_memory';
    final collector = _getMetricCollector(key);
    collector.recordMemoryUsage(bytesUsed, bytesTotal);

    // Controlla se l'utilizzo della memoria è troppo alto
    final usagePercentage = (bytesUsed / bytesTotal) * 100;
    if (usagePercentage > _config.maxMemoryUsage) {
      _triggerAlert('HIGH_MEMORY_USAGE', 'High memory usage detected', {
        'context': context,
        'usagePercentage': usagePercentage,
        'bytesUsed': bytesUsed,
        'bytesTotal': bytesTotal,
        'threshold': _config.maxMemoryUsage,
      });
    }
  }

  /// Registra un errore
  void recordError(
      String operation, String context, String error, Duration? duration) {
    final key = '${context}_$operation';
    final collector = _getMetricCollector(key);
    collector.recordError(error, duration);

    // Controlla se il tasso di errore è troppo alto
    final errorRate = collector.errorRate;
    if (errorRate > _config.maxErrorRate) {
      _triggerAlert('HIGH_ERROR_RATE', 'High error rate detected', {
        'operation': operation,
        'context': context,
        'errorRate': errorRate,
        'threshold': _config.maxErrorRate,
      });
    }
  }

  /// Registra l'utilizzo della CPU
  void recordCpuUsage(String context, double cpuPercentage) {
    final key = '${context}_cpu';
    final collector = _getMetricCollector(key);
    collector.recordCpuUsage(cpuPercentage);

    // Controlla se l'utilizzo della CPU è troppo alto
    if (cpuPercentage > _config.maxCpuUsage) {
      _triggerAlert('HIGH_CPU_USAGE', 'High CPU usage detected', {
        'context': context,
        'cpuPercentage': cpuPercentage,
        'threshold': _config.maxCpuUsage,
      });
    }
  }

  /// Registra un'operazione di trading
  void recordTradingOperation(
      String symbol, String operation, Duration duration, bool success) {
    final key = 'trading_${symbol}_$operation';
    final collector = _getMetricCollector(key);

    if (success) {
      collector.recordSuccess(duration);
    } else {
      collector.recordFailure(duration);
    }

    // Controlla se la latenza di trading è troppo alta
    if (duration > _config.tradingLatencyThreshold) {
      _triggerAlert('TRADING_LATENCY', 'High trading latency detected', {
        'symbol': symbol,
        'operation': operation,
        'latency': duration.inMilliseconds,
        'threshold': _config.tradingLatencyThreshold.inMilliseconds,
      });
    }
  }

  /// Ottiene le statistiche per un contesto specifico
  Map<String, dynamic> getStats(String context) {
    final stats = <String, dynamic>{};

    for (final entry in _metrics.entries) {
      if (entry.key.startsWith(context)) {
        stats[entry.key] = entry.value.getStats();
      }
    }

    return stats;
  }

  /// Ottiene tutte le statistiche
  Map<String, dynamic> getAllStats() {
    final stats = <String, dynamic>{};

    for (final entry in _metrics.entries) {
      stats[entry.key] = entry.value.getStats();
    }

    return stats;
  }

  /// Ottiene le statistiche degli alert
  Map<String, dynamic> getAlertStats() {
    final stats = <String, dynamic>{};

    for (final entry in _alerts.entries) {
      stats[entry.key] = entry.value.getStats();
    }

    return stats;
  }

  /// Resetta le statistiche per un contesto
  void resetStats(String context) {
    final keysToRemove = <String>[];

    for (final entry in _metrics.entries) {
      if (entry.key.startsWith(context)) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      _metrics.remove(key);
    }

    _log.i('[PERFORMANCE] Reset stats for $context');
  }

  /// Esegue il monitoraggio periodico
  void _performMonitoring() {
    try {
      // Analizza le metriche per identificare trend
      _analyzeTrends();

      // Controlla la salute del sistema
      _checkSystemHealth();

      // Pulisci le metriche vecchie
      _cleanupOldMetrics();
    } catch (e) {
      _log.e('[PERFORMANCE] Monitoring failed: $e');
    }
  }

  /// Analizza i trend delle metriche
  void _analyzeTrends() {
    for (final entry in _metrics.entries) {
      final collector = entry.value;
      final stats = collector.getStats();

      // Identifica trend di degradazione
      final latencyTrend = stats['latency_trend'] as String?;
      final latencyAvg = stats['latency_avg'] as double?;
      if (latencyTrend == 'increasing' &&
          latencyAvg != null &&
          latencyAvg > _config.latencyThreshold.inMilliseconds) {
        _triggerAlert('LATENCY_DEGRADATION', 'Latency degradation detected', {
          'context': entry.key,
          'currentLatency': latencyAvg,
          'trend': latencyTrend,
        });
      }

      // Identifica trend di errori
      final errorRate = stats['error_rate'] as double? ?? 0.0;
      if (errorRate > _config.maxErrorRate * 0.8) {
        _triggerAlert(
            'ERROR_RATE_WARNING', 'Error rate approaching threshold', {
          'context': entry.key,
          'errorRate': errorRate,
          'threshold': _config.maxErrorRate,
        });
      }
    }
  }

  /// Controlla la salute generale del sistema
  void _checkSystemHealth() {
    final allStats = getAllStats();
    int criticalIssues = 0;

    for (final entry in allStats.entries) {
      final stats = entry.value as Map<String, dynamic>;

      final errorRate = stats['error_rate'] as double? ?? 0.0;
      if (errorRate > _config.maxErrorRate) {
        criticalIssues++;
      }

      final latencyAvg = stats['latency_avg'] as double?;
      if (latencyAvg != null &&
          latencyAvg > _config.latencyThreshold.inMilliseconds) {
        criticalIssues++;
      }
    }

    if (criticalIssues > _config.maxCriticalIssues) {
      _triggerAlert(
          'SYSTEM_CRITICAL', 'System has critical performance issues', {
        'criticalIssues': criticalIssues,
        'maxAllowed': _config.maxCriticalIssues,
      });
    }
  }

  /// Pulisce le metriche vecchie
  void _cleanupOldMetrics() {
    final cutoff = DateTime.now().subtract(_config.metricsRetention);

    for (final entry in _metrics.entries) {
      if (entry.value.lastUpdate.isBefore(cutoff)) {
        _metrics.remove(entry.key);
      }
    }
  }

  /// Attiva un alert
  void _triggerAlert(
      String alertType, String message, Map<String, dynamic> data) {
    final alert = _PerformanceAlert(
      type: alertType,
      message: message,
      data: data,
      timestamp: DateTime.now(),
    );

    _alerts[alertType] = alert;

    _log.w('[PERFORMANCE] Alert: $alertType - $message');
    _onAlert?.call(alertType, message, data);
  }

  /// Ottiene il collector di metriche per una chiave
  _MetricCollector _getMetricCollector(String key) {
    return _metrics.putIfAbsent(key, () => _MetricCollector());
  }

  /// Chiude il monitor di performance
  void dispose() {
    stopMonitoring();
    _metrics.clear();
    _alerts.clear();
    _log.i('[PERFORMANCE] Performance monitor disposed');
  }
}

/// Configurazione del monitoraggio
class MonitoringConfig {
  final Duration monitoringInterval;
  final Duration metricsRetention;
  final Duration latencyThreshold;
  final Duration tradingLatencyThreshold;
  final double minThroughput;
  final double maxMemoryUsage;
  final double maxCpuUsage;
  final double maxErrorRate;
  final int maxCriticalIssues;

  const MonitoringConfig({
    this.monitoringInterval = const Duration(seconds: 30),
    this.metricsRetention = const Duration(hours: 24),
    this.latencyThreshold = const Duration(milliseconds: 100),
    this.tradingLatencyThreshold = const Duration(milliseconds: 500),
    this.minThroughput = 1.0,
    this.maxMemoryUsage = 80.0,
    this.maxCpuUsage = 90.0,
    this.maxErrorRate = 0.1,
    this.maxCriticalIssues = 5,
  });
}

/// Collector per le metriche
class _MetricCollector {
  final List<_LatencySample> _latencySamples = [];
  final List<_ThroughputSample> _throughputSamples = [];
  final List<_ErrorSample> _errorSamples = [];
  final List<_MemorySample> _memorySamples = [];
  final List<_CpuSample> _cpuSamples = [];

  int _successCount = 0;
  int _failureCount = 0;
  DateTime _lastUpdate = DateTime.now();

  /// Registra una metrica di latenza
  void recordLatency(Duration duration) {
    _latencySamples.add(_LatencySample(duration, DateTime.now()));
    _lastUpdate = DateTime.now();
  }

  /// Registra una metrica di throughput
  void recordThroughput(int count, Duration period) {
    _throughputSamples.add(_ThroughputSample(count, period, DateTime.now()));
    _lastUpdate = DateTime.now();
  }

  /// Registra un errore
  void recordError(String error, Duration? duration) {
    _errorSamples.add(_ErrorSample(error, duration, DateTime.now()));
    _failureCount++;
    _lastUpdate = DateTime.now();
  }

  /// Registra un successo
  void recordSuccess(Duration duration) {
    _successCount++;
    _lastUpdate = DateTime.now();
  }

  /// Registra un fallimento
  void recordFailure(Duration duration) {
    _failureCount++;
    _lastUpdate = DateTime.now();
  }

  /// Registra l'utilizzo della memoria
  void recordMemoryUsage(int bytesUsed, int bytesTotal) {
    _memorySamples.add(_MemorySample(bytesUsed, bytesTotal, DateTime.now()));
    _lastUpdate = DateTime.now();
  }

  /// Registra l'utilizzo della CPU
  void recordCpuUsage(double cpuPercentage) {
    _cpuSamples.add(_CpuSample(cpuPercentage, DateTime.now()));
    _lastUpdate = DateTime.now();
  }

  /// Calcola il tasso di errore
  double get errorRate {
    final total = _successCount + _failureCount;
    return total > 0 ? _failureCount / total : 0.0;
  }

  /// Ottiene le statistiche
  Map<String, dynamic> getStats() {
    return {
      'latency_avg': _calculateAverageLatency(),
      'latency_trend': _calculateLatencyTrend(),
      'throughput_avg': _calculateAverageThroughput(),
      'error_rate': errorRate,
      'success_count': _successCount,
      'failure_count': _failureCount,
      'memory_usage_avg': _calculateAverageMemoryUsage(),
      'cpu_usage_avg': _calculateAverageCpuUsage(),
      'last_update': _lastUpdate.toIso8601String(),
    };
  }

  /// Calcola la latenza media
  double? _calculateAverageLatency() {
    if (_latencySamples.isEmpty) return null;

    final totalMs = _latencySamples
        .map((s) => s.duration.inMicroseconds)
        .reduce((a, b) => a + b);

    return totalMs /
        _latencySamples.length /
        1000.0; // Converti in millisecondi
  }

  /// Calcola il trend della latenza
  String _calculateLatencyTrend() {
    if (_latencySamples.length < 2) return 'stable';

    final recent =
        _latencySamples.take(5).map((s) => s.duration.inMicroseconds).toList();
    final older = _latencySamples
        .skip(5)
        .take(5)
        .map((s) => s.duration.inMicroseconds)
        .toList();

    if (recent.isEmpty || older.isEmpty) return 'stable';

    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final olderAvg = older.reduce((a, b) => a + b) / older.length;

    if (recentAvg > olderAvg * 1.1) return 'increasing';
    if (recentAvg < olderAvg * 0.9) return 'decreasing';
    return 'stable';
  }

  /// Calcola il throughput medio
  double? _calculateAverageThroughput() {
    if (_throughputSamples.isEmpty) return null;

    final totalRate = _throughputSamples
        .map((s) => s.count / s.period.inSeconds)
        .reduce((a, b) => a + b);

    return totalRate / _throughputSamples.length;
  }

  /// Calcola l'utilizzo medio della memoria
  double? _calculateAverageMemoryUsage() {
    if (_memorySamples.isEmpty) return null;

    final totalUsage = _memorySamples
        .map((s) => (s.bytesUsed / s.bytesTotal) * 100)
        .reduce((a, b) => a + b);

    return totalUsage / _memorySamples.length;
  }

  /// Calcola l'utilizzo medio della CPU
  double? _calculateAverageCpuUsage() {
    if (_cpuSamples.isEmpty) return null;

    final totalUsage =
        _cpuSamples.map((s) => s.cpuPercentage).reduce((a, b) => a + b);

    return totalUsage / _cpuSamples.length;
  }

  DateTime get lastUpdate => _lastUpdate;
}

/// Campioni per le metriche
class _LatencySample {
  final Duration duration;
  final DateTime timestamp;

  _LatencySample(this.duration, this.timestamp);
}

class _ThroughputSample {
  final int count;
  final Duration period;
  final DateTime timestamp;

  _ThroughputSample(this.count, this.period, this.timestamp);
}

class _ErrorSample {
  final String error;
  final Duration? duration;
  final DateTime timestamp;

  _ErrorSample(this.error, this.duration, this.timestamp);
}

class _MemorySample {
  final int bytesUsed;
  final int bytesTotal;
  final DateTime timestamp;

  _MemorySample(this.bytesUsed, this.bytesTotal, this.timestamp);
}

class _CpuSample {
  final double cpuPercentage;
  final DateTime timestamp;

  _CpuSample(this.cpuPercentage, this.timestamp);
}

/// Alert di performance
class _PerformanceAlert {
  final String type;
  final String message;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  _PerformanceAlert({
    required this.type,
    required this.message,
    required this.data,
    required this.timestamp,
  });

  Map<String, dynamic> getStats() {
    return {
      'type': type,
      'message': message,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
