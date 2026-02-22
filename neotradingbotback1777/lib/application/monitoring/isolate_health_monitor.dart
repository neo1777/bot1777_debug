import 'dart:async';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';

/// Stato di salute di un isolate
enum IsolateHealthStatus {
  healthy,
  degraded,
  unhealthy,
  unresponsive,
  terminated
}

/// Informazioni di salute di un isolate
class IsolateHealthInfo {
  final String symbol;
  final IsolateHealthStatus status;
  final DateTime lastHeartbeat;
  final DateTime createdAt;
  final int totalRequests;
  final int failedRequests;
  final Duration avgResponseTime;
  final String? lastError;
  final Map<String, dynamic> metrics;

  IsolateHealthInfo({
    required this.symbol,
    required this.status,
    required this.lastHeartbeat,
    required this.createdAt,
    required this.totalRequests,
    required this.failedRequests,
    required this.avgResponseTime,
    this.lastError,
    this.metrics = const {},
  });

  double get successRate =>
      totalRequests > 0 ? 1.0 - (failedRequests / totalRequests) : 1.0;
  Duration get uptime => DateTime.now().difference(createdAt);
  bool get isHealthy => status == IsolateHealthStatus.healthy;

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'status': status.name,
        'lastHeartbeat': lastHeartbeat.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'totalRequests': totalRequests,
        'failedRequests': failedRequests,
        'successRate': successRate,
        'avgResponseTime': avgResponseTime.inMilliseconds,
        'uptime': uptime.inMilliseconds,
        'lastError': lastError,
        'metrics': metrics,
      };
}

/// Messaggio di heartbeat inviato dagli isolates
class HeartbeatMessage {
  final String symbol;
  final DateTime timestamp;
  final Map<String, dynamic> metrics;
  final String? error;

  HeartbeatMessage({
    required this.symbol,
    required this.timestamp,
    this.metrics = const {},
    this.error,
  });
}

/// Monitora la salute degli isolates di trading
class IsolateHealthMonitor {
  final _log = LogManager.getLogger();
  final Map<String, IsolateHealthInfo> _healthStatus = {};
  final Map<String, Timer> _heartbeatTimers = {};
  final Map<String, DateTime> _lastActivity = {};
  final Map<String, List<Duration>> _responseTimes = {};

  final Duration _heartbeatInterval = Duration(seconds: 30);
  final Duration _heartbeatTimeout = Duration(seconds: 90);
  final Duration _healthCheckInterval = Duration(seconds: 60);

  Timer? _healthCheckTimer;
  StreamController<Map<String, IsolateHealthInfo>> _healthStreamController =
      StreamController<Map<String, IsolateHealthInfo>>.broadcast();

  Stream<Map<String, IsolateHealthInfo>> get healthStream =>
      _healthStreamController.stream;

  void start() {
    _log.i('Starting isolate health monitor');
    // If previously stopped, recreate the stream controller (one-shot safety)
    if (_healthStreamController.isClosed) {
      _healthStreamController =
          StreamController<Map<String, IsolateHealthInfo>>.broadcast();
    }
    _healthCheckTimer =
        Timer.periodic(_healthCheckInterval, (_) => _performHealthCheck());
  }

  void stop() {
    _log.i('Stopping isolate health monitor');
    _healthCheckTimer?.cancel();
    for (final timer in _heartbeatTimers.values) {
      timer.cancel();
    }
    _heartbeatTimers.clear();
    // Nota: il controller stream è pensato come one-shot per semplicità.
    // I consumer dovrebbero ri-sottoscriversi dopo uno stop().
    // Il controller verrà ricreato da start() se necessario.
    if (!_healthStreamController.isClosed) {
      _healthStreamController.close();
    }
  }

  /// Registra un nuovo isolate per il monitoraggio
  void registerIsolate(String symbol) {
    _log.i('Registering isolate for monitoring: $symbol');

    final now = DateTime.now();
    _healthStatus[symbol] = IsolateHealthInfo(
      symbol: symbol,
      status: IsolateHealthStatus.healthy,
      lastHeartbeat: now,
      createdAt: now,
      totalRequests: 0,
      failedRequests: 0,
      avgResponseTime: Duration.zero,
    );

    _lastActivity[symbol] = now;
    _responseTimes[symbol] = [];

    // Start heartbeat monitoring
    _heartbeatTimers[symbol] = Timer.periodic(_heartbeatInterval, (timer) {
      _checkHeartbeat(symbol);
    });
  }

  /// Rimuove un isolate dal monitoraggio
  void unregisterIsolate(String symbol) {
    _log.i('Unregistering isolate from monitoring: $symbol');

    _heartbeatTimers[symbol]?.cancel();
    _heartbeatTimers.remove(symbol);

    // Mark as terminated
    final currentInfo = _healthStatus[symbol];
    if (currentInfo != null) {
      _healthStatus[symbol] = IsolateHealthInfo(
        symbol: symbol,
        status: IsolateHealthStatus.terminated,
        lastHeartbeat: currentInfo.lastHeartbeat,
        createdAt: currentInfo.createdAt,
        totalRequests: currentInfo.totalRequests,
        failedRequests: currentInfo.failedRequests,
        avgResponseTime: currentInfo.avgResponseTime,
        lastError: 'Isolate terminated',
        metrics: currentInfo.metrics,
      );
    }

    _lastActivity.remove(symbol);
    _responseTimes.remove(symbol);
  }

  /// Processa un heartbeat ricevuto da un isolate
  void processHeartbeat(HeartbeatMessage heartbeat) {
    final symbol = heartbeat.symbol;
    final now = DateTime.now();

    _lastActivity[symbol] = now;

    final currentInfo = _healthStatus[symbol];
    if (currentInfo == null) return;

    // Calculate response time if we have previous activity
    if (_responseTimes.containsKey(symbol)) {
      final responseTime = now.difference(currentInfo.lastHeartbeat);
      _responseTimes[symbol]!.add(responseTime);

      // Keep only last 10 response times for average calculation
      if (_responseTimes[symbol]!.length > 10) {
        _responseTimes[symbol]!.removeAt(0);
      }
    }

    // Calculate average response time
    final avgResponseTime = _calculateAverageResponseTime(symbol);

    // Determine status based on metrics and error
    IsolateHealthStatus status;
    if (heartbeat.error != null) {
      status = IsolateHealthStatus.degraded;
    } else if (avgResponseTime > Duration(seconds: 30)) {
      status = IsolateHealthStatus.degraded;
    } else {
      status = IsolateHealthStatus.healthy;
    }

    // Update health info
    _healthStatus[symbol] = IsolateHealthInfo(
      symbol: symbol,
      status: status,
      lastHeartbeat: now,
      createdAt: currentInfo.createdAt,
      totalRequests: currentInfo.totalRequests + 1,
      failedRequests: heartbeat.error != null
          ? currentInfo.failedRequests + 1
          : currentInfo.failedRequests,
      avgResponseTime: avgResponseTime,
      lastError: heartbeat.error,
      metrics: Map.from(heartbeat.metrics),
    );

    _log.d('Heartbeat processed for $symbol: $status');
  }

  /// Registra un'operazione di trading completata
  void recordTradingOperation(String symbol,
      {bool success = true, String? error}) {
    final currentInfo = _healthStatus[symbol];
    if (currentInfo == null) return;

    _healthStatus[symbol] = IsolateHealthInfo(
      symbol: symbol,
      status: currentInfo.status,
      lastHeartbeat: currentInfo.lastHeartbeat,
      createdAt: currentInfo.createdAt,
      totalRequests: currentInfo.totalRequests + 1,
      failedRequests:
          success ? currentInfo.failedRequests : currentInfo.failedRequests + 1,
      avgResponseTime: currentInfo.avgResponseTime,
      lastError: error ?? currentInfo.lastError,
      metrics: currentInfo.metrics,
    );
  }

  /// Esegue il controllo di salute periodico
  void _performHealthCheck() {
    final now = DateTime.now();
    bool healthChanged = false;

    for (final symbol in _healthStatus.keys.toList()) {
      final currentInfo = _healthStatus[symbol]!;
      final lastActivity = _lastActivity[symbol];

      if (lastActivity == null) continue;

      final timeSinceLastActivity = now.difference(lastActivity);
      IsolateHealthStatus newStatus = currentInfo.status;

      // Check if isolate is unresponsive
      if (timeSinceLastActivity > _heartbeatTimeout) {
        newStatus = IsolateHealthStatus.unresponsive;
        _log.w(
            'Isolate $symbol is unresponsive (last activity: ${timeSinceLastActivity.inSeconds}s ago)');
      }
      // Check success rate
      else if (currentInfo.successRate < 0.8) {
        newStatus = IsolateHealthStatus.unhealthy;
        _log.w(
            'Isolate $symbol has low success rate: ${(currentInfo.successRate * 100).toStringAsFixed(1)}%');
      }
      // Check average response time
      else if (currentInfo.avgResponseTime > Duration(seconds: 60)) {
        newStatus = IsolateHealthStatus.degraded;
        _log.w(
            'Isolate $symbol has high response time: ${currentInfo.avgResponseTime.inSeconds}s');
      }

      if (newStatus != currentInfo.status) {
        _healthStatus[symbol] = IsolateHealthInfo(
          symbol: symbol,
          status: newStatus,
          lastHeartbeat: currentInfo.lastHeartbeat,
          createdAt: currentInfo.createdAt,
          totalRequests: currentInfo.totalRequests,
          failedRequests: currentInfo.failedRequests,
          avgResponseTime: currentInfo.avgResponseTime,
          lastError: currentInfo.lastError,
          metrics: currentInfo.metrics,
        );
        healthChanged = true;
      }
    }

    if (healthChanged) {
      _healthStreamController.add(Map.from(_healthStatus));
    }
  }

  void _checkHeartbeat(String symbol) {
    final lastActivity = _lastActivity[symbol];
    if (lastActivity == null) return;

    final timeSinceLastActivity = DateTime.now().difference(lastActivity);
    if (timeSinceLastActivity > _heartbeatTimeout) {
      _log.w('Missed heartbeat for isolate $symbol');
    }
  }

  Duration _calculateAverageResponseTime(String symbol) {
    final responseTimes = _responseTimes[symbol];
    if (responseTimes == null || responseTimes.isEmpty) {
      return Duration.zero;
    }

    final totalMs = responseTimes.fold<int>(
        0, (sum, duration) => sum + duration.inMilliseconds);
    return Duration(milliseconds: (totalMs / responseTimes.length).round());
  }

  /// Ottieni informazioni di salute per un isolate specifico
  IsolateHealthInfo? getHealthInfo(String symbol) => _healthStatus[symbol];

  /// Ottieni informazioni di salute per tutti gli isolates
  Map<String, IsolateHealthInfo> getAllHealthInfo() => Map.from(_healthStatus);

  /// Ottieni solo gli isolates non salutari
  Map<String, IsolateHealthInfo> getUnhealthyIsolates() {
    return Map.fromEntries(
        _healthStatus.entries.where((entry) => !entry.value.isHealthy));
  }

  /// Genera un report di salute completo
  Map<String, dynamic> generateHealthReport() {
    final total = _healthStatus.length;
    final healthy = _healthStatus.values
        .where((info) => info.status == IsolateHealthStatus.healthy)
        .length;
    final degraded = _healthStatus.values
        .where((info) => info.status == IsolateHealthStatus.degraded)
        .length;
    final unhealthy = _healthStatus.values
        .where((info) => info.status == IsolateHealthStatus.unhealthy)
        .length;
    final unresponsive = _healthStatus.values
        .where((info) => info.status == IsolateHealthStatus.unresponsive)
        .length;

    return {
      'timestamp': DateTime.now().toIso8601String(),
      'summary': {
        'total': total,
        'healthy': healthy,
        'degraded': degraded,
        'unhealthy': unhealthy,
        'unresponsive': unresponsive,
        'healthyPercentage':
            total > 0 ? (healthy / total * 100).toStringAsFixed(1) : '0.0',
      },
      'isolates':
          _healthStatus.map((symbol, info) => MapEntry(symbol, info.toJson())),
    };
  }
}
