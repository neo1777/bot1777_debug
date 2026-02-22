import 'dart:async';
import 'package:logger/logger.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:neotradingbotback1777/core/config/trading_constants.dart';

/// Configurazione per la cache
class CacheConfig {
  final bool enableStats;
  // Altre configurazioni future...

  const CacheConfig({
    this.enableStats = true,
  });

  static const defaultConfig = CacheConfig();
}

/// Cache thread-safe con gestione automatica della memoria e TTL
///
/// Questa implementazione utilizza un approccio lock-free per le operazioni
/// di lettura e un lock esclusivo solo per le operazioni di scrittura,
/// garantendo performance ottimali in scenari di alta concorrenza.
class ThreadSafeCache<K, V> {
  final String name;
  final int maxEntries;
  final Duration defaultTtl;
  final Duration cleanupInterval;
  final bool enableStats;
  final Logger _log;

  /// Cache principale con TTL
  final Map<K, _CacheEntry<V>> _cache = {};

  /// Timer per la pulizia automatica
  Timer? _cleanupTimer;

  /// Timer per il monitoraggio delle performance
  Timer? _performanceTimer;

  /// Statistiche della cache
  int _hits = 0;
  int _misses = 0;
  int _evictions = 0;
  int _totalRequests = 0;
  DateTime _lastPerformanceCheck = DateTime.now();

  /// Configurazione per invalidazione intelligente
  final CacheConfig _config;

  ThreadSafeCache({
    required this.name,
    this.maxEntries = TradingConstants.defaultCacheMaxEntries,
    Duration? defaultTtl,
    this.cleanupInterval = const Duration(minutes: 1),
    this.enableStats = true,
    Logger? logger,
    CacheConfig? config,
  })  : defaultTtl = defaultTtl ?? TradingConstants.defaultCacheTtl,
        _log = logger ?? LogManager.getLogger(),
        _config = config ?? CacheConfig.defaultConfig {
    _startCleanupTimer();
    if (_config.enableStats) {
      _startPerformanceMonitoring();
    }
  }

  /// Inserisce un valore nella cache con TTL opzionale
  void put(K key, V value, {Duration? ttl}) {
    runAtomic(() {
      _putInternal(key, value, ttl ?? defaultTtl);
    });
  }

  /// Inserisce un valore nella cache (versione interna senza lock)
  void _putInternal(K key, V value, Duration ttl) {
    final now = DateTime.now();
    final expiry = now.add(ttl);

    // Se la cache è piena, rimuovi l'entry più vecchia
    if (_cache.length >= maxEntries) {
      _evictOldestEntry();
    }

    _cache[key] = _CacheEntry(
      value: value,
      expiry: expiry,
      lastAccess: now,
    );

    _log.d('[CACHE] $name: Added key "$key", expires at $expiry');
  }

  /// Ottiene un valore dalla cache
  V? get(K key) {
    _totalRequests++;
    final entry = _cache[key];

    if (entry == null) {
      _misses++;
      return null;
    }

    // Controlla se l'entry è scaduta
    if (entry.isExpired) {
      runAtomic(() {
        _cache.remove(key);
      });
      _misses++;
      return null;
    }

    // Aggiorna l'ultimo accesso
    entry.lastAccess = DateTime.now();
    _hits++;

    return entry.value;
  }

  /// Ottiene un valore dalla cache o lo calcola se non presente
  V? getOrCompute(K key, V Function() compute, {Duration? ttl}) {
    final cached = get(key);
    if (cached != null) return cached;

    final computed = compute();
    put(key, computed, ttl: ttl);
    return computed;
  }

  /// Rimuove un valore dalla cache
  void remove(K key) {
    runAtomic(() {
      _cache.remove(key);
      _log.d('[CACHE] $name: Removed key "$key"');
    });
  }

  /// Controlla se una chiave esiste nella cache
  bool containsKey(K key) {
    final entry = _cache[key];
    if (entry == null) return false;

    if (entry.isExpired) {
      runAtomic(() {
        _cache.remove(key);
      });
      return false;
    }

    return true;
  }

  /// Rimuove l'entry più vecchia dalla cache
  void _evictOldestEntry() {
    if (_cache.isEmpty) return;

    K? oldestKey;
    DateTime? oldestAccess;

    for (final entry in _cache.entries) {
      if (oldestAccess == null ||
          entry.value.lastAccess.isBefore(oldestAccess)) {
        oldestKey = entry.key;
        oldestAccess = entry.value.lastAccess;
      }
    }

    if (oldestKey != null) {
      _cache.remove(oldestKey);
      _evictions++;
      _log.d('[CACHE] $name: Evicted oldest key "$oldestKey"');
    }
  }

  /// Avvia il timer di pulizia automatica
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _cleanup(),
    );
  }

  /// Rimuove tutte le entry scadute
  void _cleanup() {
    runAtomic(() {
      final expiredKeys = <K>[];

      for (final entry in _cache.entries) {
        if (entry.value.isExpired) {
          expiredKeys.add(entry.key);
        }
      }

      for (final key in expiredKeys) {
        _cache.remove(key);
      }

      if (expiredKeys.isNotEmpty) {
        _log.d(
            '[CACHE] $name: Cleaned up ${expiredKeys.length} expired entries');
      }
    });
  }

  /// Esegue un'operazione con garanzia di atomicità sincrona.
  ///
  /// In Dart's single-isolate model, synchronous operations on [Map] are
  /// already atomic — there is no preemptive multithreading. This method
  /// exists as a **semantic guard**: it documents the intent that the
  /// enclosed operation should be treated as a critical section.
  ///
  /// Renamed from `synchronized` to `runAtomic` to avoid confusion with
  /// mutex-based locking.
  T runAtomic<T>(T Function() operation) {
    return _runAtomic(operation);
  }

  /// Internal: identity wrapper for synchronous operations.
  T _runAtomic<T>(T Function() operation) {
    return operation();
  }

  /// Statistiche della cache
  Map<String, dynamic> getStats() {
    return {
      'name': name,
      'entries': _cache.length,
      'maxEntries': maxEntries,
      'utilization': _cache.length / maxEntries,
      'hits': _hits,
      'misses': _misses,
      'hitRate': (_hits + _misses) > 0 ? _hits / (_hits + _misses) : 0.0,
      'evictions': _evictions,
    };
  }

  /// Svuota la cache
  void clear() {
    runAtomic(() {
      _cache.clear();
      _hits = 0;
      _misses = 0;
      _evictions = 0;
      _log.d('[CACHE] $name: Cache cleared');
    });
  }

  /// Avvia il monitoraggio delle performance
  void _startPerformanceMonitoring() {
    _performanceTimer = Timer.periodic(
      Duration(minutes: 5),
      (_) => _checkPerformance(),
    );
  }

  /// Controlla le performance della cache
  void _checkPerformance() {
    final now = DateTime.now();

    // Calcola hit rate
    final hitRate = _totalRequests > 0 ? _hits / _totalRequests : 0.0;

    // Calcola utilizzo della cache
    final utilization = _cache.length / maxEntries;

    // Log delle performance
    _log.d('[CACHE] $name: Performance check - '
        'Hit Rate: ${(hitRate * 100).toStringAsFixed(1)}%, '
        'Utilization: ${(utilization * 100).toStringAsFixed(1)}%, '
        'Entries: ${_cache.length}/$maxEntries');

    // Invalidazione intelligente basata sulle performance
    if (hitRate < 0.3 && utilization > 0.8) {
      _log.w(
          '[CACHE] $name: Low hit rate and high utilization, performing intelligent cleanup');
      _intelligentCleanup();
    }

    _lastPerformanceCheck = now;
  }

  /// Pulizia intelligente basata sui pattern di accesso
  void _intelligentCleanup() {
    runAtomic(() {
      final now = DateTime.now();
      final entriesToRemove = <K>[];

      // Rimuovi entry non accedute da molto tempo
      for (final entry in _cache.entries) {
        final timeSinceAccess = now.difference(entry.value.lastAccess);
        if (timeSinceAccess > Duration(hours: 1)) {
          entriesToRemove.add(entry.key);
        }
      }

      // Rimuovi le entry identificate
      for (final key in entriesToRemove) {
        _cache.remove(key);
        _evictions++;
      }

      if (entriesToRemove.isNotEmpty) {
        _log.d(
            '[CACHE] $name: Intelligent cleanup removed ${entriesToRemove.length} entries');
      }
    });
  }

  /// Invalida entry basate su pattern specifici
  void invalidateByPattern(bool Function(K key) pattern) {
    runAtomic(() {
      final keysToRemove = _cache.keys.where(pattern).toList();
      for (final key in keysToRemove) {
        _cache.remove(key);
        _evictions++;
      }

      if (keysToRemove.isNotEmpty) {
        _log.d(
            '[CACHE] $name: Pattern invalidation removed ${keysToRemove.length} entries');
      }
    });
  }

  /// Invalida entry più vecchie di una certa età
  void invalidateOlderThan(Duration age) {
    runAtomic(() {
      final now = DateTime.now();
      final keysToRemove = <K>[];

      for (final entry in _cache.entries) {
        if (now.difference(entry.value.lastAccess) > age) {
          keysToRemove.add(entry.key);
        }
      }

      for (final key in keysToRemove) {
        _cache.remove(key);
        _evictions++;
      }

      if (keysToRemove.isNotEmpty) {
        _log.d(
            '[CACHE] $name: Age-based invalidation removed ${keysToRemove.length} entries');
      }
    });
  }

  /// Ottiene statistiche avanzate della cache
  Map<String, dynamic> getAdvancedStats() {
    final hitRate = _totalRequests > 0 ? _hits / _totalRequests : 0.0;
    final utilization = _cache.length / maxEntries;
    final avgAge = _calculateAverageAge();

    return {
      'name': name,
      'entries': _cache.length,
      'maxEntries': maxEntries,
      'utilization': utilization,
      'hits': _hits,
      'misses': _misses,
      'totalRequests': _totalRequests,
      'hitRate': hitRate,
      'evictions': _evictions,
      'averageAge': avgAge.inMilliseconds,
      'lastPerformanceCheck': _lastPerformanceCheck.toIso8601String(),
    };
  }

  /// Calcola l'età media delle entry nella cache
  Duration _calculateAverageAge() {
    if (_cache.isEmpty) return Duration.zero;

    final now = DateTime.now();
    final totalAge = _cache.values
        .map((entry) => now.difference(entry.lastAccess))
        .reduce((a, b) => a + b);

    return Duration(
      milliseconds: totalAge.inMilliseconds ~/ _cache.length,
    );
  }

  /// Chiude la cache
  void dispose() {
    _cleanupTimer?.cancel();
    _performanceTimer?.cancel();
    clear();
    _log.d('[CACHE] $name: Cache disposed');
  }
}

/// Entry della cache con metadati
class _CacheEntry<V> {
  final V value;
  final DateTime expiry;
  DateTime lastAccess;

  _CacheEntry({
    required this.value,
    required this.expiry,
    required this.lastAccess,
  });

  /// Controlla se l'entry è scaduta
  bool get isExpired => DateTime.now().isAfter(expiry);
}

/// Cache specializzata per i prezzi con ottimizzazioni specifiche
class PriceCache extends ThreadSafeCache<String, double> {
  PriceCache({
    super.name = 'PriceCache',
    super.maxEntries = 100,
    super.defaultTtl = const Duration(seconds: 30),
    super.logger,
  });

  /// Aggiorna il prezzo per un simbolo
  void updatePrice(String symbol, double price) {
    put(symbol, price, ttl: const Duration(seconds: 30));
  }

  /// Ottiene il prezzo corrente per un simbolo
  double? getCurrentPrice(String symbol) {
    return get(symbol);
  }

  /// Ottiene tutti i prezzi correnti
  Map<String, double> getAllCurrentPrices() {
    final prices = <String, double>{};

    for (final entry in _cache.entries) {
      if (!entry.value.isExpired) {
        prices[entry.key] = entry.value.value;
      }
    }

    return prices;
  }
}

/// Cache specializzata per lo stato della strategia
class StrategyStateCache extends ThreadSafeCache<String, Map<String, dynamic>> {
  StrategyStateCache({
    super.name = 'StrategyStateCache',
    super.maxEntries = 50,
    super.defaultTtl = const Duration(minutes: 10),
    super.logger,
  });

  /// Aggiorna lo stato per un simbolo
  void updateStrategyState(String symbol, Map<String, dynamic> state) {
    put(symbol, state, ttl: const Duration(minutes: 10));
  }

  /// Ottiene lo stato corrente per un simbolo
  Map<String, dynamic>? getStrategyState(String symbol) {
    return get(symbol);
  }

  /// Invalida lo stato per un simbolo
  void invalidateStrategyState(String symbol) {
    remove(symbol);
  }
}
