import 'dart:async';
import 'dart:collection';
import 'package:get_it/get_it.dart';
import 'package:neotradingbotback1777/core/config/trading_constants.dart';
import 'package:mutex/mutex.dart';

/// Trading-specific lock manager for coordinating atomic trading operations
///
/// This manager ensures that trading operations on the same symbol
/// are executed atomically, preventing race conditions and ensuring
/// data consistency in high-frequency trading scenarios
class TradingLockManager {
  final Map<String, DateTime> _lastOperationTimes = {};
  final Duration _operationCooldown;

  // Internal distributed lock implementation
  final Map<String, Mutex> _locks = HashMap<String, Mutex>();
  final Mutex _globalMutex = Mutex();

  TradingLockManager({
    Duration? operationCooldown,
  }) : _operationCooldown = operationCooldown ?? TradingConstants.buyCooldown;

  /// Execute a trading operation with distributed locking
  ///
  /// This method ensures that operations on the same symbol are
  /// executed atomically, preventing race conditions
  Future<T> executeTradingOperation<T>(
    String symbol,
    Future<T> Function() operation, {
    bool checkCooldown = true,
  }) async {
    if (checkCooldown && _isInCooldown(symbol)) {
      throw TradingLockException(
        'Symbol $symbol is in cooldown period. '
        'Last operation: ${_lastOperationTimes[symbol]}',
      );
    }

    return await _executeWithLock(symbol, () async {
      try {
        final result = await operation();
        _lastOperationTimes[symbol] = DateTime.now();
        return result;
      } catch (e) {
        // Update last operation time even on failure to prevent
        // immediate retry of failed operations
        _lastOperationTimes[symbol] = DateTime.now();
        rethrow;
      }
    });
  }

  /// Execute a synchronous trading operation with distributed locking
  Future<T> executeTradingOperationSync<T>(
    String symbol,
    T Function() operation, {
    bool checkCooldown = true,
  }) async {
    if (checkCooldown && _isInCooldown(symbol)) {
      throw TradingLockException(
        'Symbol $symbol is in cooldown period. '
        'Last operation: ${_lastOperationTimes[symbol]}',
      );
    }

    return await _executeWithLock(symbol, () async {
      try {
        final result = operation();
        _lastOperationTimes[symbol] = DateTime.now();
        return result;
      } catch (e) {
        _lastOperationTimes[symbol] = DateTime.now();
        rethrow;
      }
    });
  }

  /// Check if a symbol is currently in cooldown period
  bool _isInCooldown(String symbol) {
    final lastTime = _lastOperationTimes[symbol];
    if (lastTime == null) return false;

    return DateTime.now().difference(lastTime) < _operationCooldown;
  }

  /// Get the time until the next operation is allowed for a symbol
  Duration? getTimeUntilNextOperation(String symbol) {
    final lastTime = _lastOperationTimes[symbol];
    if (lastTime == null) return null;

    final elapsed = DateTime.now().difference(lastTime);
    if (elapsed >= _operationCooldown) return null;

    return _operationCooldown - elapsed;
  }

  /// Clean up old operation times to prevent memory leaks
  void cleanupOldOperationTimes() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 1));
    _lastOperationTimes.removeWhere((symbol, time) => time.isBefore(cutoff));

    // Also cleanup unused locks
    _cleanupUnusedLocks();
  }

  /// Get statistics about active locks and operations
  TradingLockStats getStats() {
    return TradingLockStats(
      activeLocksCount: _locks.length,
      trackedSymbolsCount: _lastOperationTimes.length,
      operationCooldown: _operationCooldown,
    );
  }

  // === Internal Locking Logic (Migrated from DistributedLock) ===

  /// Execute an operation with a distributed lock for the given key
  Future<T> _executeWithLock<T>(
      String key, Future<T> Function() operation) async {
    final lock = await _getOrCreateLock(key);
    return lock.protect(operation);
  }

  /// Get or create a mutex for the given key
  Future<Mutex> _getOrCreateLock(String key) async {
    return await _globalMutex.protect(() async {
      if (!_locks.containsKey(key)) {
        _locks[key] = Mutex();
      }
      return _locks[key]!;
    });
  }

  /// Clean up locks for keys that are no longer needed
  Future<void> _cleanupUnusedLocks() async {
    await _globalMutex.protect(() async {
      // Remove locks that are not currently in use
      _locks.removeWhere((key, mutex) {
        // Simple heuristic: if mutex is not locked, it's safe to remove
        return !mutex.isLocked;
      });
    });
  }
}

/// Exception thrown when trading lock operations fail
class TradingLockException implements Exception {
  final String message;

  const TradingLockException(this.message);

  @override
  String toString() => 'TradingLockException: $message';
}

/// Statistics about trading lock manager
class TradingLockStats {
  final int activeLocksCount;
  final int trackedSymbolsCount;
  final Duration operationCooldown;

  const TradingLockStats({
    required this.activeLocksCount,
    required this.trackedSymbolsCount,
    required this.operationCooldown,
  });

  @override
  String toString() => 'TradingLockStats(activeLocks: $activeLocksCount, '
      'trackedSymbols: $trackedSymbolsCount, '
      'cooldown: ${operationCooldown.inMilliseconds}ms)';
}

/// Dependency injection setup for trading lock manager
void registerTradingLockManager(GetIt getIt) {
  getIt.registerLazySingleton<TradingLockManager>(
    () => TradingLockManager(),
  );
}
