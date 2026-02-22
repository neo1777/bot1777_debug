import 'package:neotradingbotback1777/domain/entities/kline.dart';
import 'package:test/test.dart';

void main() {
  group('Kline Validation Tests', () {
    test('should create valid Kline', () {
      final kline = Kline(
        openTime: 1000,
        open: 100.0,
        high: 110.0,
        low: 90.0,
        close: 105.0,
        volume: 10.0,
        closeTime: 2000,
        quoteAssetVolume: 1000.0,
        numberOfTrades: 50,
        takerBuyBaseAssetVolume: 5.0,
        takerBuyQuoteAssetVolume: 500.0,
      );

      expect(kline.openTime, 1000);
      expect(kline.closeTime, 2000);
    });

    test('should throw ArgumentError if openTime >= closeTime', () {
      expect(
        () => Kline(
          openTime: 2000,
          open: 100.0,
          high: 110.0,
          low: 90.0,
          close: 105.0,
          volume: 10.0,
          closeTime: 1000, // Invalid
          quoteAssetVolume: 1000.0,
          numberOfTrades: 50,
          takerBuyBaseAssetVolume: 5.0,
          takerBuyQuoteAssetVolume: 500.0,
        ),
        throwsArgumentError,
      );
    });

    test('should throw ArgumentError if high < low', () {
      expect(
        () => Kline(
          openTime: 1000,
          open: 100.0,
          high: 80.0, // Invalid: < low
          low: 90.0,
          close: 105.0,
          volume: 10.0,
          closeTime: 2000,
          quoteAssetVolume: 1000.0,
          numberOfTrades: 50,
          takerBuyBaseAssetVolume: 5.0,
          takerBuyQuoteAssetVolume: 500.0,
        ),
        throwsArgumentError,
      );
    });

    test('should throw ArgumentError if high < open', () {
      expect(
        () => Kline(
          openTime: 1000,
          open: 110.0, // Open > High
          high: 100.0,
          low: 90.0,
          close: 105.0,
          volume: 10.0,
          closeTime: 2000,
          quoteAssetVolume: 1000.0,
          numberOfTrades: 50,
          takerBuyBaseAssetVolume: 5.0,
          takerBuyQuoteAssetVolume: 500.0,
        ),
        throwsArgumentError,
      );
    });

    test('should throw ArgumentError if low > open', () {
      expect(
        () => Kline(
          openTime: 1000,
          open: 80.0, // Open < Low
          high: 110.0,
          low: 90.0,
          close: 105.0,
          volume: 10.0,
          closeTime: 2000,
          quoteAssetVolume: 1000.0,
          numberOfTrades: 50,
          takerBuyBaseAssetVolume: 5.0,
          takerBuyQuoteAssetVolume: 500.0,
        ),
        throwsArgumentError,
      );
    });

    test('should throw ArgumentError if volume is negative', () {
      expect(
        () => Kline(
          openTime: 1000,
          open: 100.0,
          high: 110.0,
          low: 90.0,
          close: 105.0,
          volume: -10.0, // Invalid
          closeTime: 2000,
          quoteAssetVolume: 1000.0,
          numberOfTrades: 50,
          takerBuyBaseAssetVolume: 5.0,
          takerBuyQuoteAssetVolume: 500.0,
        ),
        throwsArgumentError,
      );
    });
  });
}

