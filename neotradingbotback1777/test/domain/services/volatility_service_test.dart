import 'package:test/test.dart';
import 'package:neotradingbotback1777/domain/services/volatility_service.dart';

void main() {
  group('VolatilityService', () {
    late VolatilityService volatilityService;

    setUp(() {
      volatilityService = VolatilityService();
    });

    group('calculateVolatility', () {
      test('should return 0.0 for empty price list', () {
        final volatility = volatilityService.calculateVolatility([]);
        expect(volatility, equals(0.0));
      });

      test('should return 0.0 for single price', () {
        final volatility = volatilityService.calculateVolatility([100.0]);
        expect(volatility, equals(0.0));
      });

      test('should detect stable prices correctly', () {
        // Prezzi stabili con variazioni minime
        final stablePrices = [100.0, 100.1, 99.9, 100.2, 99.8];
        final volatility = volatilityService.calculateVolatility(stablePrices);

        expect(volatility, lessThan(0.02)); // < 2%
        expect(volatility, greaterThan(0.0));
      });

      test('should detect moderate volatility correctly', () {
        // Prezzi con volatilità moderata
        final moderatePrices = [100.0, 98.0, 102.0, 97.0, 103.0];
        final volatility =
            volatilityService.calculateVolatility(moderatePrices);

        expect(volatility, greaterThan(0.02)); // > 2%
        expect(volatility, lessThan(0.10)); // < 10%
      });

      test('should detect extreme volatility correctly', () {
        // Prezzi molto volatili
        final volatilePrices = [100.0, 90.0, 110.0, 80.0, 120.0];
        final volatility =
            volatilityService.calculateVolatility(volatilePrices);

        expect(volatility, greaterThan(0.10)); // > 10%
        expect(volatility, lessThan(1.0)); // < 100%
      });

      test('should handle window size correctly', () {
        // Lista di 30 prezzi, ma calcola solo su ultimi 20
        final manyPrices = List.generate(30, (i) => 100.0 + (i % 10) * 0.1);
        final volatility = volatilityService.calculateVolatility(manyPrices);

        expect(volatility, greaterThan(0.0));
        expect(volatility, lessThan(1.0));
      });

      test('should normalize volatility correctly', () {
        // Prezzi con volatilità molto alta
        final highVolPrices = [100.0, 50.0, 150.0, 25.0, 175.0];
        final volatility = volatilityService.calculateVolatility(highVolPrices);

        // La volatilità dovrebbe essere normalizzata tra 0.0 e 1.0
        expect(volatility, greaterThan(0.5));
        expect(volatility, lessThanOrEqualTo(1.0));
      });
    });

    group('shouldFreezePrice', () {
      test('should freeze price when volatility exceeds threshold', () {
        final shouldFreeze = volatilityService.shouldFreezePrice(
          volatilityLevel: 0.08, // 8% > 5% threshold
          isCurrentlyFrozen: false,
        );

        expect(shouldFreeze, isTrue);
      });

      test('should not freeze price when volatility is below threshold', () {
        final shouldFreeze = volatilityService.shouldFreezePrice(
          volatilityLevel: 0.01, // 1% < 2% default threshold
          isCurrentlyFrozen: false,
        );

        expect(shouldFreeze, isFalse);
      });

      test('should maintain freeze when volatility is still high', () {
        final shouldFreeze = volatilityService.shouldFreezePrice(
          volatilityLevel: 0.06, // 6% > 5% threshold
          isCurrentlyFrozen: true,
          lastFreezeTime: DateTime.now().subtract(const Duration(seconds: 10)),
        );

        expect(shouldFreeze, isTrue);
      });

      test('should allow unfreeze when volatility drops and time passes', () {
        final shouldFreeze = volatilityService.shouldFreezePrice(
          volatilityLevel: 0.005, // 0.5% well below unfreeze threshold
          isCurrentlyFrozen: true,
          lastFreezeTime:
              DateTime.now().subtract(const Duration(minutes: 2)), // > 30s
        );

        expect(shouldFreeze, isFalse);
      });

      test('should not unfreeze too quickly even if volatility drops', () {
        final shouldFreeze = volatilityService.shouldFreezePrice(
          volatilityLevel: 0.01, // 1% < 3% unfreeze threshold
          isCurrentlyFrozen: true,
          lastFreezeTime:
              DateTime.now().subtract(const Duration(seconds: 10)), // < 30s
        );

        expect(shouldFreeze, isTrue);
      });
    });

    group('edge cases and boundary conditions', () {
      test('should handle zero prices correctly', () {
        final volatility =
            volatilityService.calculateVolatility([0.0, 0.0, 0.0]);
        expect(volatility, equals(0.0));
      });

      test('should handle negative prices correctly', () {
        final volatility =
            volatilityService.calculateVolatility([-100.0, -98.0, -102.0]);
        expect(volatility, greaterThanOrEqualTo(0.0));
      });

      test('should handle very large price variations', () {
        final volatility =
            volatilityService.calculateVolatility([1.0, 1000000.0, 1.0]);
        expect(volatility, greaterThan(0.9));
        expect(volatility, lessThanOrEqualTo(1.0));
      });

      test('should handle very small price variations', () {
        final volatility =
            volatilityService.calculateVolatility([100.0, 100.0001, 99.9999]);
        expect(volatility, greaterThan(0.0));
        expect(volatility, lessThan(0.001));
      });
    });

    group('performance tests', () {
      test('should handle large price lists efficiently', () {
        final largePriceList =
            List.generate(1000, (i) => 100.0 + (i % 100) * 0.01);

        final stopwatch = Stopwatch()..start();
        final volatility =
            volatilityService.calculateVolatility(largePriceList);
        stopwatch.stop();

        expect(volatility, greaterThan(0.0));
        expect(volatility, lessThan(1.0));
        expect(stopwatch.elapsedMilliseconds,
            lessThan(100)); // Should complete in < 100ms
      });

      test('should handle repeated calculations efficiently', () {
        final prices = [100.0, 98.0, 102.0, 97.0, 103.0];

        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < 1000; i++) {
          volatilityService.calculateVolatility(prices);
        }
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds,
            lessThan(1000)); // Should complete in < 1s
      });
    });

    group('integration scenarios', () {
      test('should handle realistic trading scenario', () {
        // Simula un giorno di trading con prezzi realistici
        final tradingDayPrices = [
          100.00, // Apertura
          100.50, // +0.5%
          99.80, // -0.7%
          101.20, // +1.4%
          100.90, // -0.3%
          102.50, // +1.6%
          101.80, // -0.7%
          103.20, // +1.4%
          102.50, // -0.7%
          104.00, // +1.5%
        ];

        final volatility =
            volatilityService.calculateVolatility(tradingDayPrices);

        // La volatilità dovrebbe essere moderata per questo scenario
        expect(volatility, greaterThan(0.01));
        expect(volatility, lessThan(0.05));
      });

      test('should detect market crash scenario', () {
        // Simula un crash di mercato
        final crashPrices = [
          100.00, // Pre-crash
          95.00, // -5%
          85.00, // -15%
          75.00, // -25%
          65.00, // -35%
          55.00, // -45%
        ];

        final volatility = volatilityService.calculateVolatility(crashPrices);

        // La volatilità dovrebbe essere alta
        expect(volatility, greaterThan(0.15));
        expect(volatility, lessThan(1.0));

        // Dovrebbe attivare il freeze
        final shouldFreeze = volatilityService.shouldFreezePrice(
          volatilityLevel: volatility,
          isCurrentlyFrozen: false,
        );

        expect(shouldFreeze, isTrue);
      });

      test('should handle recovery scenario', () {
        // Simula un recupero dopo un crash
        final recoveryPrices = [
          55.00, // Bottom
          60.00, // +9%
          70.00, // +27%
          80.00, // +45%
          90.00, // +64%
          95.00, // +73%
        ];

        final volatility =
            volatilityService.calculateVolatility(recoveryPrices);

        // La volatilità dovrebbe essere alta ma in diminuzione
        expect(volatility, greaterThan(0.15));

        // Dovrebbe mantenere il freeze inizialmente
        final shouldFreeze = volatilityService.shouldFreezePrice(
          volatilityLevel: volatility,
          isCurrentlyFrozen: true,
          lastFreezeTime: DateTime.now().subtract(const Duration(seconds: 10)),
        );

        expect(shouldFreeze, isTrue);
      });
    });
  });
}

