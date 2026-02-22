import 'dart:async';
import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';

/// Stato del circuit breaker
enum CircuitBreakerState {
  /// Circuito chiuso - operazioni normali
  closed,

  /// Circuito aperto - tutte le richieste vengono rifiutate
  open,

  /// Circuito semi-aperto - test di una singola richiesta
  halfOpen
}

/// Risultato di un'operazione del circuit breaker
class CircuitBreakerResult<T> {
  final bool success;
  final T? result;
  final String? error;
  final bool rejectedByCircuitBreaker;

  CircuitBreakerResult._({
    required this.success,
    this.result,
    this.error,
    this.rejectedByCircuitBreaker = false,
  });

  factory CircuitBreakerResult.success(T result) {
    return CircuitBreakerResult._(success: true, result: result);
  }

  factory CircuitBreakerResult.failure(String error) {
    return CircuitBreakerResult._(success: false, error: error);
  }

  factory CircuitBreakerResult.rejected(String reason) {
    return CircuitBreakerResult._(
      success: false,
      error: reason,
      rejectedByCircuitBreaker: true,
    );
  }
}

/// Configuration per il circuit breaker
class CircuitBreakerConfig {
  /// Numero di fallimenti consecutivi prima di aprire il circuito
  final int failureThreshold;

  /// Durata per cui il circuito rimane aperto prima di tentare half-open
  final Duration timeout;

  /// Numero di successi consecutivi in half-open prima di chiudere il circuito
  final int successThreshold;

  /// Finestra temporale per calcolare la failure rate
  final Duration monitoringWindow;

  /// Percentuale di fallimenti per aprire il circuito (0.0 - 1.0)
  final double failureRateThreshold;

  /// FIX BUG #6: Limite massimo di call history per prevenire memory leak estremi
  final int maxHistorySize;

  const CircuitBreakerConfig({
    this.failureThreshold = 5,
    this.timeout = const Duration(minutes: 1),
    this.successThreshold = 3,
    this.monitoringWindow = const Duration(minutes: 5),
    this.failureRateThreshold = 0.5, // 50%
    this.maxHistorySize = 1000, // FIX BUG #6: Limite di sicurezza
  });

  /// Create a default CircuitBreakerConfig
  factory CircuitBreakerConfig.defaultConfig() {
    return const CircuitBreakerConfig(
      failureThreshold: 5,
      timeout: Duration(minutes: 1),
      successThreshold: 3,
      monitoringWindow: const Duration(minutes: 5),
      failureRateThreshold: 0.5,
      maxHistorySize: 1000,
    );
  }
}

/// Implementazione di un circuit breaker per proteggere il sistema da cascate di errori
class CircuitBreaker {
  final String name;
  final CircuitBreakerConfig config;
  final _log = LogManager.getLogger();

  CircuitBreakerState _state = CircuitBreakerState.closed;
  int _failureCount = 0;
  int _successCount = 0;
  DateTime? _lastFailureTime;
  DateTime? _stateChangeTime;
  final List<_CallRecord> _callHistory = [];
  Timer? _cleanupTimer; // FIX BUG #6: Timer per cleanup automatico

  CircuitBreaker({
    required this.name,
    this.config = const CircuitBreakerConfig(),
  }) {
    _stateChangeTime = DateTime.now();
    _initializePeriodicCleanup(); // FIX BUG #6: Avvia cleanup periodico
  }

  /// Stato corrente del circuit breaker
  CircuitBreakerState get state => _state;

  /// Numero di fallimenti consecutivi
  int get failureCount => _failureCount;

  /// Numero di successi consecutivi (in half-open)
  int get successCount => _successCount;

  /// Calcola la failure rate nella finestra di monitoraggio
  double get failureRate {
    _cleanupOldCalls();
    if (_callHistory.isEmpty) return 0.0;

    final failures = _callHistory.where((call) => !call.success).length;
    return failures / _callHistory.length;
  }

  /// Esegue un'operazione protetta dal circuit breaker
  Future<CircuitBreakerResult<T>> execute<T>(
    Future<T> Function() operation,
  ) async {
    // Controlla se il circuito permette l'esecuzione
    if (!_canExecute()) {
      final reason = 'Circuit breaker [$name] is OPEN - rejecting call';
      _log.w(reason);
      return CircuitBreakerResult.rejected(reason);
    }

    // Esegui l'operazione
    try {
      final result = await operation();

      // Rendi il Circuit Breaker "Either-aware" per la programmazione funzionale.
      if (result is Either) {
        if (result.isLeft()) {
          _onFailure();
        } else {
          _onSuccess();
        }
      } else {
        // Comportamento standard per risultati non-Either.
        _onSuccess();
      }

      return CircuitBreakerResult.success(result);
    } catch (e, s) {
      _log.e('Circuit breaker [$name] caught exception: $e', stackTrace: s);
      _onFailure();
      return CircuitBreakerResult.failure(e.toString());
    }
  }

  /// Controlla se il circuito può eseguire l'operazione
  bool _canExecute() {
    switch (_state) {
      case CircuitBreakerState.closed:
        return true;

      case CircuitBreakerState.open:
        // Controlla se è tempo di tentare half-open
        if (_shouldAttemptReset()) {
          _transitionTo(CircuitBreakerState.halfOpen);
          return true;
        }
        return false;

      case CircuitBreakerState.halfOpen:
        return true;
    }
  }

  /// Gestisce un successo
  void _onSuccess() {
    _recordCall(success: true);

    switch (_state) {
      case CircuitBreakerState.closed:
        _failureCount = 0;
        break;

      case CircuitBreakerState.halfOpen:
        _successCount++;
        if (_successCount >= config.successThreshold) {
          _transitionTo(CircuitBreakerState.closed);
        }
        break;

      case CircuitBreakerState.open:
        // Non dovrebbe succedere
        break;
    }
  }

  /// Gestisce un fallimento
  void _onFailure() {
    _recordCall(success: false);
    _lastFailureTime = DateTime.now();

    switch (_state) {
      case CircuitBreakerState.closed:
        _failureCount++;
        if (_shouldOpenCircuit()) {
          _transitionTo(CircuitBreakerState.open);
        }
        break;

      case CircuitBreakerState.halfOpen:
        _transitionTo(CircuitBreakerState.open);
        break;

      case CircuitBreakerState.open:
        // Rimane aperto
        break;
    }
  }

  /// Determina se il circuito dovrebbe aprirsi
  bool _shouldOpenCircuit() {
    // Controllo basato su numero di fallimenti consecutivi
    if (_failureCount >= config.failureThreshold) {
      return true;
    }

    // Controllo basato sulla failure rate
    _cleanupOldCalls();
    if (failureRate >= config.failureRateThreshold &&
        _callHistory.length >= config.failureThreshold) {
      return true;
    }

    return false;
  }

  /// Determina se dovrebbe tentare di passare a half-open
  bool _shouldAttemptReset() {
    if (_stateChangeTime == null) return false;
    return DateTime.now().difference(_stateChangeTime!) >= config.timeout;
  }

  /// Transizione a un nuovo stato
  void _transitionTo(CircuitBreakerState newState) {
    final oldState = _state;
    _state = newState;
    _stateChangeTime = DateTime.now();

    switch (newState) {
      case CircuitBreakerState.closed:
        _failureCount = 0;
        _successCount = 0;
        _log.i('Circuit breaker [$name]: $oldState -> CLOSED');
        break;

      case CircuitBreakerState.open:
        _successCount = 0;
        _log.w(
            'Circuit breaker [$name]: $oldState -> OPEN (failures: $_failureCount, rate: ${(failureRate * 100).toStringAsFixed(1)}%)');
        break;

      case CircuitBreakerState.halfOpen:
        _log.i(
            'Circuit breaker [$name]: $oldState -> HALF_OPEN (attempting reset)');
        break;
    }
  }

  /// Registra una chiamata per il monitoraggio
  void _recordCall({required bool success}) {
    _callHistory.add(_CallRecord(
      timestamp: DateTime.now(),
      success: success,
    ));

    // Mantieni solo le chiamate nella finestra di monitoraggio
    _cleanupOldCalls();
  }

  /// Rimuove le chiamate fuori dalla finestra di monitoraggio
  /// FIX BUG #6: Implementa cleanup basato su tempo E dimensione massima
  void _cleanupOldCalls() {
    final cutoff = DateTime.now().subtract(config.monitoringWindow);
    final sizeBefore = _callHistory.length;

    // 1. Rimuovi le chiamate vecchie (basato su tempo)
    _callHistory.removeWhere((call) => call.timestamp.isBefore(cutoff));

    // 2. Se ancora troppo grande, rimuovi le più vecchie (basato su dimensione)
    if (_callHistory.length > config.maxHistorySize) {
      // Ordina per timestamp e mantieni solo le più recenti
      _callHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _callHistory.removeRange(config.maxHistorySize, _callHistory.length);

      _log.w(
          'Circuit breaker [$name]: History size exceeded limit, truncated to ${config.maxHistorySize} most recent calls');
    }

    final sizeAfter = _callHistory.length;
    if (sizeBefore != sizeAfter) {
      _log.d(
          'Circuit breaker [$name]: Cleanup removed ${sizeBefore - sizeAfter} calls ($sizeBefore -> $sizeAfter)');
    }
  }

  /// FIX BUG #6: Inizializza il cleanup periodico automatico
  void _initializePeriodicCleanup() {
    // Esegui cleanup ogni metà della finestra di monitoraggio per essere sicuri
    final cleanupInterval =
        Duration(milliseconds: config.monitoringWindow.inMilliseconds ~/ 2);

    _cleanupTimer = Timer.periodic(cleanupInterval, (_) {
      final oldSize = _callHistory.length;
      _cleanupOldCalls();
      final newSize = _callHistory.length;

      if (oldSize != newSize) {
        _log.d(
            'Circuit breaker [$name]: Periodic cleanup removed ${oldSize - newSize} old call records');
      }
    });

    _log.d(
        'Circuit breaker [$name]: Periodic cleanup initialized (interval: ${cleanupInterval.inMinutes}min)');
  }

  /// Resetta manualmente il circuit breaker
  void reset() {
    _log.i('Circuit breaker [$name]: Manual reset to CLOSED');
    _transitionTo(CircuitBreakerState.closed);
  }

  /// FIX BUG #6: Pulisce le risorse e ferma il timer
  void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _callHistory.clear();
    _log.d(
        'Circuit breaker [$name]: Disposed - timer stopped and history cleared');
  }

  /// Ottieni statistiche del circuit breaker
  Map<String, dynamic> getStats() {
    _cleanupOldCalls();

    return {
      'name': name,
      'state': _state.name,
      'failureCount': _failureCount,
      'successCount': _successCount,
      'failureRate': failureRate,
      'totalCalls': _callHistory.length,
      'successfulCalls': _callHistory.where((call) => call.success).length,
      'failedCalls': _callHistory.where((call) => !call.success).length,
      'lastFailureTime': _lastFailureTime?.toIso8601String(),
      'stateChangeTime': _stateChangeTime?.toIso8601String(),
      'config': {
        'failureThreshold': config.failureThreshold,
        'timeout': config.timeout.inMilliseconds,
        'successThreshold': config.successThreshold,
        'monitoringWindow': config.monitoringWindow.inMilliseconds,
        'failureRateThreshold': config.failureRateThreshold,
        'maxHistorySize': config.maxHistorySize, // FIX BUG #6
      },
      // FIX BUG #6: Aggiungi informazioni sul cleanup automatico
      'memoryManagement': {
        'callHistorySize': _callHistory.length,
        'cleanupTimerActive': _cleanupTimer?.isActive ?? false,
        'oldestCallAge': _callHistory.isEmpty
            ? null
            : DateTime.now().difference(_callHistory.first.timestamp).inMinutes,
      },
    };
  }
}

/// Record di una chiamata per il monitoraggio
class _CallRecord {
  final DateTime timestamp;
  final bool success;

  _CallRecord({
    required this.timestamp,
    required this.success,
  });
}
