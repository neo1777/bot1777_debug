import 'dart:math';

/// Implementazione thread-safe (per isolato singolo) del Token Bucket Algorithm.
///
/// Permette di gestire il rate limiting consentendo brevi burst fino a [capacity],
/// mantenendo un rate medio di [refillRate] token al secondo.
class TokenBucket {
  /// Numero massimo di token accumulabili (dimensione del burst).
  final int capacity;

  /// Tasso di ricarica in token al secondo.
  final double refillRate;

  double _tokens;
  int _lastRefillTimestamp;

  /// Crea un TokenBucket.
  ///
  /// [capacity] - Capacità massima del bucket.
  /// [refillRate] - Token aggiunti al secondo.
  TokenBucket({
    required this.capacity,
    required this.refillRate,
  })  : _tokens = capacity.toDouble(),
        _lastRefillTimestamp = DateTime.now().millisecondsSinceEpoch;

  /// Tenta di consumare [cost] token.
  ///
  /// Restituisce `true` se c'erano abbastanza token, `false` altrimenti.
  bool tryConsume({int cost = 1}) {
    _refill();
    if (_tokens >= cost) {
      _tokens -= cost;
      return true;
    }
    return false;
  }

  /// Restituisce il numero corrente di token disponibili (dopo il refill).
  double get currentTokens {
    _refill();
    return _tokens;
  }

  void _refill() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsedSeconds = (now - _lastRefillTimestamp) / 1000.0;

    if (elapsedSeconds > 0) {
      final tokensToAdd = elapsedSeconds * refillRate;
      _tokens = min(capacity.toDouble(), _tokens + tokensToAdd);
      _lastRefillTimestamp = now;
    }
  }
}
