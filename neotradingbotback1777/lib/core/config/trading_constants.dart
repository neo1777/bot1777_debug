import 'dart:io';

/// Centralized trading constants and configuration values.
///
/// All environment variable parsing uses `tryParse` with safe fallback
/// defaults to prevent application crashes on invalid `.env` values.
class TradingConstants {
  TradingConstants._();

  // === SAFE PARSE HELPERS ===
  static int _intEnv(String key, int fallback) =>
      int.tryParse(Platform.environment[key] ?? '') ?? fallback;

  static double _doubleEnv(String key, double fallback) =>
      double.tryParse(Platform.environment[key] ?? '') ?? fallback;

  // TIMEOUTS AND INTERVALS
  static Duration get defaultTimeout =>
      Duration(seconds: _intEnv('TRADING_TIMEOUT', 30));

  static Duration get apiTimeout =>
      Duration(seconds: _intEnv('API_TIMEOUT', 10));

  static Duration get minBackoff => Duration(milliseconds: minBackoffMs);

  static Duration get maxBackoff => Duration(milliseconds: maxBackoffMs);

  static Duration get dustCooldown =>
      Duration(minutes: _intEnv('DUST_COOLDOWN_MINUTES', 5));

  static Duration get buyCooldown =>
      Duration(milliseconds: _intEnv('BUY_COOLDOWN_MS', 1000));

  static Duration get warmupPeriod =>
      Duration(minutes: _intEnv('WARMUP_MINUTES', 5));

  // THRESHOLDS AND LIMITS
  static double get defaultVolatilityThreshold =>
      _doubleEnv('VOLATILITY_THRESHOLD', 0.02);

  static int get maxRetryAttempts => _intEnv('MAX_RETRY_ATTEMPTS', 3);

  static int get maxOpenTrades => _intEnv('MAX_OPEN_TRADES', 10);

  static double get maxTradeAmountCap =>
      _doubleEnv('MAX_TRADE_AMOUNT_CAP', 10000.0);

  static double get minTradeAmount => _doubleEnv('MIN_TRADE_AMOUNT', 10.0);

  // FEE CONSTANTS
  static double get defaultMakerFee => _doubleEnv('DEFAULT_MAKER_FEE', 0.001);

  static double get defaultTakerFee => _doubleEnv('DEFAULT_TAKER_FEE', 0.001);

  static String get defaultFeeCurrency =>
      Platform.environment['DEFAULT_FEE_CURRENCY'] ?? 'USDT';

  static double get bnbDiscountPercentage =>
      _doubleEnv('BNB_DISCOUNT_PERCENTAGE', 0.25);

  // PERFORMANCE
  static Duration get latencyAlertThreshold =>
      Duration(milliseconds: _intEnv('LATENCY_ALERT_THRESHOLD', 1000));

  static double get memoryUsageAlertThreshold =>
      _doubleEnv('MEMORY_USAGE_ALERT_THRESHOLD', 80.0);

  static double get cpuUsageAlertThreshold =>
      _doubleEnv('CPU_USAGE_ALERT_THRESHOLD', 80.0);

  // VALIDATION CONSTANTS
  static const int symbolMinLength = 3;
  static const int symbolMaxLength = 12;
  static const double priceMaxValue = 100000000.0; // 100M
  static const double priceMinValue = 0.00000001;
  static const double quantityMaxValue = 1000000.0; // 1M
  static const double quantityMinValue = 0.00000001;
  static const double percentageMinValue = -100.0;
  static const double percentageMaxValue = 10000.0; // 10,000%
  static const double tradeAmountMaxValue = 10000000.0; // 10M
  static const double tradeAmountMinValue = 1.0;
  static const int maxTradesMaxValue = 1000;
  static const int timeoutMaxValue = 3600; // 1 hour
  static const double percentageBoundary = 100.0;
  static const int internalServerErrorCode = 500;
  static const int maxLatencyThresholdMs = 9999;
  static const int minBackoffMs = 300;
  static const int maxBackoffMs = 4000;
  static const int backoffMultiplier = 2;
  static const double maxDcaDecrementPercentage = 50.0;

  // DEVELOPMENT
  // MONITORING CONSTANTS
  static const Duration metricsCollectionInterval = Duration(seconds: 30);
  static const Duration metricsCleanupInterval = Duration(minutes: 5);
  static const Duration metricsRetentionPeriod = Duration(hours: 24);
  static const double excessiveLossThreshold = 1000.0; // E.g., in USD
  static const int minMetricsForAnalysis = 10;
  static const double anomalousVolumeMultiplier = 5.0;
  static const double excessiveLatencyThresholdMs = 2000.0;
  static const int excessiveMemoryThresholdBytes = 500 * 1024 * 1024; // 500 MB
  static const double highErrorRateThreshold = 0.1; // 10%

  // CACHE CONSTANTS
  static const int defaultCacheMaxEntries = 1000;
  static Duration get defaultCacheTtl => Duration(minutes: 15);
  static Duration get tickerCacheTtl => Duration(minutes: 1);

  // LOGGING CONSTANTS
  static const int defaultPriceLogEveryN = 10;
  static Duration get defaultPriceLogEverySeconds => Duration(seconds: 30);
  static const int stateLogEveryN = 5;
  static Duration get stateLogEverySeconds => Duration(seconds: 60);

  // HTTP STATUS CODES
  static const int httpStatusBadRequest = 400;
  static const int httpStatusUnauthorized = 401;
  static const int httpStatusForbidden = 403;
  static const int httpStatusNotFound = 404;
  static const int httpStatusRequestTimeout = 408;
  static const int httpStatusConflict = 409;
  static const int httpStatusTooManyRequests = 429;
  static const int httpStatusServiceUnavailable = 503;

  // DEFAULT VALUES
  static const double defaultDoubleValue = 0.0;

  static bool get debugMode =>
      Platform.environment['DEBUG_MODE']?.toLowerCase() == 'true';

  static bool get verboseLogging =>
      Platform.environment['VERBOSE_LOGGING']?.toLowerCase() == 'true';
}
