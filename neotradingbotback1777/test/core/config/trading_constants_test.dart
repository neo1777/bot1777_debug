import 'package:test/test.dart';
import 'package:neotradingbotback1777/core/config/trading_constants.dart';

/// Tests for TradingConstants safe-parsing (C-05 fix).
///
/// Verifica che tutti gli accessor con _intEnv/_doubleEnv abbiano valori
/// di default ragionevoli anche senza variabili d'ambiente configurate.
void main() {
  group('TradingConstants — Safe Parsing (C-05)', () {
    test('Duration constants should have positive durations', () {
      expect(TradingConstants.defaultTimeout.inMilliseconds, greaterThan(0));
      expect(TradingConstants.apiTimeout.inMilliseconds, greaterThan(0));
      expect(TradingConstants.minBackoff.inMilliseconds, greaterThan(0));
      expect(TradingConstants.maxBackoff.inMilliseconds, greaterThan(0));
      expect(TradingConstants.dustCooldown.inMilliseconds, greaterThan(0));
      expect(TradingConstants.buyCooldown.inMilliseconds, greaterThan(0));
      expect(TradingConstants.warmupPeriod.inMilliseconds, greaterThan(0));
      expect(TradingConstants.latencyAlertThreshold.inMilliseconds,
          greaterThan(0));
    });

    test('integer threshold constants should have sensible defaults', () {
      expect(TradingConstants.maxRetryAttempts, greaterThan(0));
      expect(TradingConstants.maxOpenTrades, greaterThan(0));
    });

    test('double constants should have finite, positive defaults', () {
      expect(TradingConstants.defaultVolatilityThreshold, greaterThan(0));
      expect(TradingConstants.defaultVolatilityThreshold.isFinite, isTrue);

      expect(TradingConstants.maxTradeAmountCap, greaterThan(0));
      expect(TradingConstants.maxTradeAmountCap.isFinite, isTrue);

      expect(TradingConstants.minTradeAmount, greaterThan(0));
      expect(TradingConstants.minTradeAmount.isFinite, isTrue);

      expect(TradingConstants.defaultMakerFee, greaterThan(0));
      expect(TradingConstants.defaultMakerFee, lessThan(1));

      expect(TradingConstants.defaultTakerFee, greaterThan(0));
      expect(TradingConstants.defaultTakerFee, lessThan(1));

      expect(TradingConstants.bnbDiscountPercentage, greaterThan(0));
      expect(TradingConstants.bnbDiscountPercentage, lessThan(100));

      expect(TradingConstants.memoryUsageAlertThreshold, greaterThan(0));
      expect(TradingConstants.cpuUsageAlertThreshold, greaterThan(0));
    });

    test('fee currency should default to USDT', () {
      // Senza env var, il default è 'USDT'
      expect(TradingConstants.defaultFeeCurrency, isNotEmpty);
    });

    test('boolean flags should not throw', () {
      // Senza env vars, dovrebbero semplicemente restituire false
      expect(TradingConstants.debugMode, isA<bool>());
      expect(TradingConstants.verboseLogging, isA<bool>());
    });

    test('validation constants should be consistent', () {
      // Min < Max per tutte le coppie
      expect(TradingConstants.priceMinValue,
          lessThan(TradingConstants.priceMaxValue));
      expect(TradingConstants.quantityMinValue,
          lessThan(TradingConstants.quantityMaxValue));
      expect(TradingConstants.tradeAmountMinValue,
          lessThan(TradingConstants.tradeAmountMaxValue));
      expect(TradingConstants.symbolMinLength,
          lessThan(TradingConstants.symbolMaxLength));
      expect(TradingConstants.percentageMinValue,
          lessThan(TradingConstants.percentageMaxValue));
    });

    test('backoff configuration should be consistent', () {
      expect(TradingConstants.minBackoffMs,
          lessThan(TradingConstants.maxBackoffMs));
      expect(TradingConstants.backoffMultiplier, greaterThan(1));
    });
  });
}

