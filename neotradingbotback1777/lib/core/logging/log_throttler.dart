import 'package:logger/logger.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:neotradingbotback1777/core/config/trading_constants.dart';

/// Log throttler for reducing log spam and improving performance
///
/// This class provides intelligent throttling of log messages to prevent
/// excessive logging that can impact system performance
class LogThrottler {
  final Map<String, _ThrottleInfo> _throttleMap = {};
  final Duration _defaultThrottleInterval;
  final int _maxMessagesPerInterval;
  final int _maxEntries;
  final Logger _logger;

  LogThrottler({
    Duration? throttleInterval,
    int? maxMessagesPerInterval,
    int maxEntries = 1000,
    Logger? logger,
  })  : _defaultThrottleInterval =
            throttleInterval ?? const Duration(seconds: 10),
        _maxMessagesPerInterval = maxMessagesPerInterval ?? 5,
        _maxEntries = maxEntries,
        _logger = logger ?? LogManager.getLogger();

  /// Check if a log message should be throttled
  ///
  /// Returns true if the message should be logged, false if it should be throttled
  bool shouldLog(String messageKey, {Duration? customInterval}) {
    final interval = customInterval ?? _defaultThrottleInterval;
    final now = DateTime.now();

    // Auto-eviction: se la mappa cresce oltre il limite, rimuovi le entry più vecchie
    if (_throttleMap.length >= _maxEntries) {
      cleanupOldEntries();
      // Se ancora troppo piena dopo cleanup, rimuovi la metà più vecchia
      if (_throttleMap.length >= _maxEntries) {
        final entries = _throttleMap.entries.toList()
          ..sort((a, b) => a.value.lastLogTime.compareTo(b.value.lastLogTime));
        final toRemove = entries.take(_throttleMap.length ~/ 2);
        for (final entry in toRemove) {
          _throttleMap.remove(entry.key);
        }
      }
    }

    if (!_throttleMap.containsKey(messageKey)) {
      _throttleMap[messageKey] = _ThrottleInfo(
        firstLogTime: now,
        lastLogTime: now,
        messageCount: 1,
      );
      return true;
    }

    final throttleInfo = _throttleMap[messageKey]!;

    // Reset if interval has passed
    if (now.difference(throttleInfo.firstLogTime) >= interval) {
      _throttleMap[messageKey] = _ThrottleInfo(
        firstLogTime: now,
        lastLogTime: now,
        messageCount: 1,
      );
      return true;
    }

    // Check if we've exceeded the message limit
    if (throttleInfo.messageCount >= _maxMessagesPerInterval) {
      // Log throttling message only once per interval
      if (throttleInfo.messageCount == _maxMessagesPerInterval) {
        _logger.w(
            'Log throttling activated for "$messageKey" - suppressing further messages for ${interval.inSeconds}s');
      }
      return false;
    }

    // Update throttle info
    _throttleMap[messageKey] = _ThrottleInfo(
      firstLogTime: throttleInfo.firstLogTime,
      lastLogTime: now,
      messageCount: throttleInfo.messageCount + 1,
    );

    return true;
  }

  /// Log a message with throttling
  void logThrottled(
    String messageKey,
    String message, {
    Duration? customInterval,
    Level level = Level.info,
  }) {
    if (shouldLog(messageKey, customInterval: customInterval)) {
      // Use appropriate logger method based on level
      switch (level) {
        case Level.debug:
          _logger.d(message);
          break;
        case Level.info:
          _logger.i(message);
          break;
        case Level.warning:
          _logger.w(message);
          break;
        case Level.error:
          _logger.e(message);
          break;
        default:
          _logger.i(message);
      }
    }
  }

  /// Log a warning with throttling
  void logWarningThrottled(
    String messageKey,
    String message, {
    Duration? customInterval,
  }) {
    logThrottled(messageKey, message,
        customInterval: customInterval, level: Level.warning);
  }

  /// Log an error with throttling
  void logErrorThrottled(
    String messageKey,
    String message, {
    Duration? customInterval,
  }) {
    logThrottled(messageKey, message,
        customInterval: customInterval, level: Level.error);
  }

  /// Log trading-specific messages with appropriate throttling
  void logTradingThrottled(
    String symbol,
    String operation,
    String message, {
    Level level = Level.info,
  }) {
    final messageKey = 'trading_${symbol}_$operation';
    logThrottled(messageKey, message, level: level);
  }

  /// Log DUST SELL attempts with specific throttling
  void logDustSellThrottled(String symbol, String message) {
    final messageKey = 'dust_sell_$symbol';
    logThrottled(
      messageKey,
      message,
      customInterval: TradingConstants.dustCooldown,
      level: Level.warning,
    );
  }

  /// Log latency alerts with throttling
  void logLatencyAlertThrottled(String operation, String message) {
    final messageKey = 'latency_alert_$operation';
    logThrottled(
      messageKey,
      message,
      customInterval: const Duration(minutes: 1),
      level: Level.warning,
    );
  }

  /// Log fee calculation messages with throttling
  void logFeeCalculationThrottled(String symbol, String message) {
    final messageKey = 'fee_calculation_$symbol';
    logThrottled(messageKey, message, level: Level.debug);
  }

  /// Clean up old throttle entries to prevent memory leaks
  void cleanupOldEntries() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 1));
    _throttleMap.removeWhere((key, info) => info.lastLogTime.isBefore(cutoff));
  }

  /// Get statistics about throttling
  Map<String, dynamic> getThrottleStats() {
    return {
      'totalThrottledKeys': _throttleMap.length,
      'throttleEntries': _throttleMap.map((key, info) => MapEntry(key, {
            'messageCount': info.messageCount,
            'firstLogTime': info.firstLogTime.toIso8601String(),
            'lastLogTime': info.lastLogTime.toIso8601String(),
            'isActive': DateTime.now().difference(info.firstLogTime) <
                _defaultThrottleInterval,
          })),
      'defaultThrottleInterval': _defaultThrottleInterval.inSeconds,
      'maxMessagesPerInterval': _maxMessagesPerInterval,
    };
  }

  /// Reset all throttle information
  void reset() {
    _throttleMap.clear();
    _logger.i('Log throttler reset - all throttle information cleared');
  }
}

/// Information about throttling for a specific message key
class _ThrottleInfo {
  final DateTime firstLogTime;
  final DateTime lastLogTime;
  final int messageCount;

  _ThrottleInfo({
    required this.firstLogTime,
    required this.lastLogTime,
    required this.messageCount,
  });
}

/// Global log throttler instance
class GlobalLogThrottler {
  static final LogThrottler _instance = LogThrottler();

  static LogThrottler get instance => _instance;

  /// Initialize the global log throttler with custom settings
  static void initialize({
    Duration? throttleInterval,
    int? maxMessagesPerInterval,
  }) {
    // The instance is already created, but we can log the initialization
    LogManager.getLogger().i(
        'Global log throttler initialized with interval: ${throttleInterval?.inSeconds ?? 10}s, max messages: ${maxMessagesPerInterval ?? 5}');
  }

  /// Clean up old entries periodically
  static void cleanup() {
    _instance.cleanupOldEntries();
  }

  /// Get throttle statistics
  static Map<String, dynamic> getStats() {
    return _instance.getThrottleStats();
  }
}
