import 'dart:io';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';

/// Gestisce il rate limiting per le API Binance basato sugli header di risposta
class BinanceRateLimiter {
  final _log = LogManager.getLogger();

  // Limits tracking per diversi tipi di endpoint
  int _currentWeight = 0;
  int _maxWeight = 1200; // Default Binance limit (1m)
  DateTime _windowStart = DateTime.now();
  Duration _windowDuration = Duration(minutes: 1);

  int _orderCount = 0;
  int _maxOrderCount = 10; // Default per 10s
  DateTime _orderWindowStart = DateTime.now();
  Duration _orderWindowDuration = Duration(seconds: 10);

  bool _isLimited = false;
  DateTime? _limitResetTime;

  /// Costruttore predefinito con valori di default Binance (fallback)
  BinanceRateLimiter();

  /// Costruttore con override esplicito dei parametri
  BinanceRateLimiter.config({
    int? maxWeightPerMinute,
    Duration? weightWindow,
    int? maxOrdersPerWindow,
    Duration? orderWindow,
  }) {
    if (maxWeightPerMinute != null && maxWeightPerMinute > 0) {
      _maxWeight = maxWeightPerMinute;
    }
    if (weightWindow != null && weightWindow.inMilliseconds > 0) {
      _windowDuration = weightWindow;
    }
    if (maxOrdersPerWindow != null && maxOrdersPerWindow > 0) {
      _maxOrderCount = maxOrdersPerWindow;
    }
    if (orderWindow != null && orderWindow.inMilliseconds > 0) {
      _orderWindowDuration = orderWindow;
    }
  }

  /// Factory: legge override da variabili d'ambiente (se presenti)
  factory BinanceRateLimiter.fromEnv() {
    final env = Platform.environment;
    int? maxWeightPerMinute = int.tryParse(env['BINANCE_MAX_WEIGHT_1M'] ?? '');
    int? maxOrdersPer10s =
        int.tryParse(env['BINANCE_MAX_ORDER_COUNT_10S'] ?? '');
    int? weightWindowMinutes =
        int.tryParse(env['BINANCE_WEIGHT_WINDOW_MINUTES'] ?? '');
    int? orderWindowSeconds =
        int.tryParse(env['BINANCE_ORDER_WINDOW_SECONDS'] ?? '');

    return BinanceRateLimiter.config(
      maxWeightPerMinute: maxWeightPerMinute,
      weightWindow: weightWindowMinutes != null && weightWindowMinutes > 0
          ? Duration(minutes: weightWindowMinutes)
          : null,
      maxOrdersPerWindow: maxOrdersPer10s,
      orderWindow: orderWindowSeconds != null && orderWindowSeconds > 0
          ? Duration(seconds: orderWindowSeconds)
          : null,
    );
  }

  /// Aggiorna i limiti basandosi sugli header di risposta Binance
  void updateFromHeaders(Map<String, String> headers) {
    try {
      // Header peso utilizzato
      if (headers.containsKey('x-mbx-used-weight-1m')) {
        _currentWeight =
            int.tryParse(headers['x-mbx-used-weight-1m']!) ?? _currentWeight;
      }

      // Header ordini utilizzati
      if (headers.containsKey('x-mbx-order-count-10s')) {
        _orderCount =
            int.tryParse(headers['x-mbx-order-count-10s']!) ?? _orderCount;
      }
      // Header limiti massimi opzionali (se esposti dall'account)
      if (headers.containsKey('x-mbx-order-limit-10s')) {
        final v = int.tryParse(headers['x-mbx-order-limit-10s']!);
        if (v != null && v > 0) _maxOrderCount = v;
      }
      if (headers.containsKey('x-mbx-weight-limit-1m')) {
        final v = int.tryParse(headers['x-mbx-weight-limit-1m']!);
        if (v != null && v > 0) _maxWeight = v;
      }

      // Controllo se siamo vicini ai limiti
      if (_currentWeight > (_maxWeight * 0.8)) {
        _log.w(
            'Rate limit warning: Weight usage at $_currentWeight/$_maxWeight');
      }

      if (_orderCount > (_maxOrderCount * 0.8)) {
        _log.w(
            'Rate limit warning: Order count at $_orderCount/$_maxOrderCount');
      }

      // Reset automatico delle finestre temporali
      _resetWindowsIfNeeded();
    } catch (e, stackTrace) {
      _log.e('Error parsing rate limit headers: $e',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Controlla se possiamo fare una richiesta senza superare i limiti
  bool canMakeRequest({int weight = 1, bool isOrderRequest = false}) {
    _resetWindowsIfNeeded();

    // Se siamo limitati, controlla se il tempo è scaduto
    if (_isLimited && _limitResetTime != null) {
      if (DateTime.now().isAfter(_limitResetTime!)) {
        _isLimited = false;
        _limitResetTime = null;
        _log.i('Rate limit reset, resuming requests');
      } else {
        return false;
      }
    }

    // Controlla limiti di peso
    if (_currentWeight + weight > _maxWeight) {
      _log.w(
          'Rate limit exceeded for weight: ${_currentWeight + weight} > $_maxWeight');
      return false;
    }

    // Controlla limiti di ordini se è una richiesta di ordine
    if (isOrderRequest && _orderCount + 1 > _maxOrderCount) {
      _log.w(
          'Rate limit exceeded for orders: ${_orderCount + 1} > $_maxOrderCount');
      return false;
    }

    return true;
  }

  /// Registra una richiesta effettuata
  void recordRequest({int weight = 1, bool isOrderRequest = false}) {
    _currentWeight += weight;
    if (isOrderRequest) {
      _orderCount++;
    }
  }

  /// Gestisce il rate limiting quando riceviamo errore 429
  void handleRateLimitError({Duration? retryAfter}) {
    _isLimited = true;
    _limitResetTime = DateTime.now().add(retryAfter ?? Duration(minutes: 1));
    _log.w('Rate limited until $_limitResetTime');
  }

  /// Calcola il tempo di attesa consigliato prima della prossima richiesta
  Duration getRecommendedDelay() {
    if (_isLimited && _limitResetTime != null) {
      final remaining = _limitResetTime!.difference(DateTime.now());
      return remaining.isNegative ? Duration.zero : remaining;
    }

    // Calcola delay basato su uso corrente
    final weightRatio = _currentWeight / _maxWeight;
    final orderRatio = _orderCount / _maxOrderCount;
    final maxRatio = weightRatio > orderRatio ? weightRatio : orderRatio;

    if (maxRatio > 0.9) {
      return Duration(seconds: 5);
    } else if (maxRatio > 0.8) {
      return Duration(seconds: 2);
    } else if (maxRatio > 0.6) {
      return Duration(milliseconds: 500);
    }

    return Duration.zero;
  }

  void _resetWindowsIfNeeded() {
    final now = DateTime.now();

    // Reset finestra peso (1 minuto)
    if (now.difference(_windowStart) >= _windowDuration) {
      _currentWeight = 0;
      _windowStart = now;
    }

    // Reset finestra ordini (10 secondi)
    if (now.difference(_orderWindowStart) >= _orderWindowDuration) {
      _orderCount = 0;
      _orderWindowStart = now;
    }
  }

  /// Ottieni statistiche correnti per monitoring
  Map<String, dynamic> getStatistics() {
    return {
      'currentWeight': _currentWeight,
      'maxWeight': _maxWeight,
      'weightRatio': _currentWeight / _maxWeight,
      'currentOrderCount': _orderCount,
      'maxOrderCount': _maxOrderCount,
      'orderRatio': _orderCount / _maxOrderCount,
      'isLimited': _isLimited,
      'limitResetTime': _limitResetTime?.toIso8601String(),
      'recommendedDelay': getRecommendedDelay().inMilliseconds,
    };
  }
}
