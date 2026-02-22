import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Generic cache manager for optimizing data storage and retrieval
class CacheManager<K, V> {
  CacheManager({this.maxSize = 100, this.ttl = const Duration(minutes: 5)});

  final int maxSize;
  final Duration ttl;

  final Map<K, _CacheEntry<V>> _cache = {};

  /// Get cached value or null if not found/expired
  V? get(K key) {
    final entry = _cache[key];
    if (entry == null) return null;

    // Check if entry has expired
    if (DateTime.now().difference(entry.timestamp) > ttl) {
      _cache.remove(key);
      return null;
    }

    // Move to end (LRU)
    _cache.remove(key);
    _cache[key] = entry;

    return entry.value;
  }

  /// Put value in cache
  void put(K key, V value) {
    // Remove if already exists
    _cache.remove(key);

    // Add new entry
    _cache[key] = _CacheEntry(value, DateTime.now());

    // Evict oldest if over max size
    while (_cache.length > maxSize) {
      final firstKey = _cache.keys.first;
      _cache.remove(firstKey);
    }
  }

  /// Check if key exists and is not expired
  bool containsKey(K key) {
    return get(key) != null;
  }

  /// Remove specific key
  void remove(K key) {
    _cache.remove(key);
  }

  /// Clear all cache
  void clear() {
    _cache.clear();
  }

  /// Get cache statistics
  CacheStats get stats {
    final now = DateTime.now();
    int expired = 0;

    for (final entry in _cache.values) {
      if (now.difference(entry.timestamp) > ttl) {
        expired++;
      }
    }

    return CacheStats(
      size: _cache.length,
      maxSize: maxSize,
      expired: expired,
      hitRate: _hitCount / (_hitCount + _missCount),
    );
  }

  int _hitCount = 0;
  int _missCount = 0;

  /// Get with hit/miss tracking
  V? getWithStats(K key) {
    final value = get(key);
    if (value != null) {
      _hitCount++;
    } else {
      _missCount++;
    }
    return value;
  }

  /// Cleanup expired entries
  void cleanup() {
    final now = DateTime.now();
    _cache.removeWhere((key, entry) => now.difference(entry.timestamp) > ttl);
  }
}

class _CacheEntry<V> {
  final V value;
  final DateTime timestamp;

  _CacheEntry(this.value, this.timestamp);
}

class CacheStats {
  final int size;
  final int maxSize;
  final int expired;
  final double hitRate;

  const CacheStats({
    required this.size,
    required this.maxSize,
    required this.expired,
    required this.hitRate,
  });

  @override
  String toString() {
    return 'CacheStats(size: $size/$maxSize, expired: $expired, hitRate: ${(hitRate * 100).toStringAsFixed(1)}%)';
  }
}

/// Specialized cache for trading data
class TradingDataCache {
  static final _instance = TradingDataCache._internal();
  factory TradingDataCache() => _instance;
  TradingDataCache._internal();

  // Different caches for different data types with appropriate TTLs
  final priceCache = CacheManager<String, double>(
    maxSize: 200,
    ttl: const Duration(seconds: 5), // Price data expires quickly
  );

  final balanceCache = CacheManager<String, Map<String, dynamic>>(
    maxSize: 10,
    ttl: const Duration(seconds: 30), // Balance data medium expiry
  );

  final orderCache = CacheManager<String, List<Map<String, dynamic>>>(
    maxSize: 50,
    ttl: const Duration(seconds: 10), // Order data quick refresh
  );

  final tradeHistoryCache = CacheManager<String, List<Map<String, dynamic>>>(
    maxSize: 20,
    ttl: const Duration(minutes: 2), // Trade history longer expiry
  );

  /// Get comprehensive cache statistics
  Map<String, CacheStats> getAllStats() {
    return {
      'prices': priceCache.stats,
      'balances': balanceCache.stats,
      'orders': orderCache.stats,
      'tradeHistory': tradeHistoryCache.stats,
    };
  }

  /// Cleanup all caches
  void cleanupAll() {
    priceCache.cleanup();
    balanceCache.cleanup();
    orderCache.cleanup();
    tradeHistoryCache.cleanup();
  }

  /// Clear all caches
  void clearAll() {
    priceCache.clear();
    balanceCache.clear();
    orderCache.clear();
    tradeHistoryCache.clear();
  }
}

/// Widget that automatically manages cache cleanup
class CacheCleanupWidget extends StatefulWidget {
  const CacheCleanupWidget({
    required this.child,
    super.key,
    this.cleanupInterval = const Duration(minutes: 1),
  });

  final Widget child;
  final Duration cleanupInterval;

  @override
  State<CacheCleanupWidget> createState() => _CacheCleanupWidgetState();
}

class _CacheCleanupWidgetState extends State<CacheCleanupWidget> {
  Timer? _cleanupTimer;

  @override
  void initState() {
    super.initState();
    _startCleanupTimer();
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel();
    super.dispose();
  }

  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(widget.cleanupInterval, (_) {
      TradingDataCache().cleanupAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Mixin for widgets that need cache functionality
mixin CacheMixin<T extends StatefulWidget> on State<T> {
  final TradingDataCache _cache = TradingDataCache();

  /// Get cached price data
  double? getCachedPrice(String symbol) {
    return _cache.priceCache.getWithStats(symbol);
  }

  /// Cache price data
  void cachePrice(String symbol, double price) {
    _cache.priceCache.put(symbol, price);
  }

  /// Get cached balance data
  Map<String, dynamic>? getCachedBalance(String asset) {
    return _cache.balanceCache.getWithStats(asset);
  }

  /// Cache balance data
  void cacheBalance(String asset, Map<String, dynamic> balance) {
    _cache.balanceCache.put(asset, balance);
  }

  /// Check cache performance in debug builds
  void logCacheStats() {
    if (kDebugMode) {
      final stats = _cache.getAllStats();
      for (final entry in stats.entries) {
        debugPrint('Cache ${entry.key}: ${entry.value}');
      }
    }
  }
}

/// Performance monitoring for widgets and operations
class PerformanceMonitor {
  static final Map<String, _PerformanceMetric> _metrics = {};

  /// Start timing an operation
  static void startTiming(String operationName) {
    _metrics[operationName] = _PerformanceMetric(
      startTime: DateTime.now(),
      operationName: operationName,
    );
  }

  /// End timing and log if slow
  static void endTiming(String operationName, {int warnThresholdMs = 16}) {
    final metric = _metrics.remove(operationName);
    if (metric == null) return;

    final duration = DateTime.now().difference(metric.startTime);
    metric.duration = duration;

    if (duration.inMilliseconds > warnThresholdMs && kDebugMode) {
      developer.log(
        'Slow operation: $operationName took ${duration.inMilliseconds}ms',
        name: 'Performance',
        level: 900, // Warning level
      );
    }
  }

  /// Time a future operation
  static Future<T> timeAsync<T>(
    String operationName,
    Future<T> Function() operation, {
    int warnThresholdMs = 100,
  }) async {
    startTiming(operationName);
    try {
      final result = await operation();
      endTiming(operationName, warnThresholdMs: warnThresholdMs);
      return result;
    } catch (e) {
      endTiming(operationName, warnThresholdMs: warnThresholdMs);
      rethrow;
    }
  }

  /// Time a synchronous operation
  static T timeSync<T>(
    String operationName,
    T Function() operation, {
    int warnThresholdMs = 16,
  }) {
    startTiming(operationName);
    try {
      final result = operation();
      endTiming(operationName, warnThresholdMs: warnThresholdMs);
      return result;
    } catch (e) {
      endTiming(operationName, warnThresholdMs: warnThresholdMs);
      rethrow;
    }
  }
}

class _PerformanceMetric {
  final DateTime startTime;
  final String operationName;
  Duration? duration;

  _PerformanceMetric({required this.startTime, required this.operationName});
}
