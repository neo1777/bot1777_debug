import 'package:test/test.dart';
import 'package:neotradingbotfront1777/domain/entities/app_settings.dart';

void main() {
  group('AppSettings - Unit Tests', () {
    group('Constructor and Default Values', () {
      test('should create instance with required parameters', () {
        // ARRANGE & ACT
        const settings = AppSettings(
          tradeAmount: 100.0,
          profitTargetPercentage: 5.0,
          stopLossPercentage: 3.0,
          dcaDecrementPercentage: 2.0,
          maxOpenTrades: 10,
          isTestMode: true,
        );

        // ASSERT
        expect(settings.tradeAmount, 100.0);
        expect(settings.profitTargetPercentage, 5.0);
        expect(settings.stopLossPercentage, 3.0);
        expect(settings.dcaDecrementPercentage, 2.0);
        expect(settings.maxOpenTrades, 10);
        expect(settings.isTestMode, isTrue);
      });

      test('should use default values for optional parameters', () {
        // ARRANGE & ACT
        const settings = AppSettings(
          tradeAmount: 100.0,
          profitTargetPercentage: 5.0,
          stopLossPercentage: 3.0,
          dcaDecrementPercentage: 2.0,
          maxOpenTrades: 10,
          isTestMode: false,
        );

        // ASSERT
        expect(settings.buyOnStart, isFalse); // Default value
        expect(settings.initialWarmupTicks, 1);
        expect(settings.initialWarmupSeconds, 0.0);
        expect(settings.initialSignalThresholdPct, 0.0);
        expect(settings.dcaCooldownSeconds, 3.0);
        expect(settings.dustRetryCooldownSeconds, 15.0);
        expect(settings.maxTradeAmountCap, 100.0);
        expect(settings.maxBuyOveragePct, 0.03);
        expect(settings.strictBudget, isFalse);
        expect(settings.buyOnStartRespectWarmup, isTrue);
        expect(settings.buyCooldownSeconds, 2.0);
        expect(settings.dcaCompareAgainstAverage, isFalse);

        expect(settings.maxCycles, 0);
      });

      test('should create settings with default values correctly', () {
        // ARRANGE & ACT
        const settings = AppSettings(
          tradeAmount: 10.0,
          profitTargetPercentage: 1.0,
          stopLossPercentage: 5.0,
          dcaDecrementPercentage: 1.0,
          maxOpenTrades: 10,
          isTestMode: false,
        );

        // ASSERT
        expect(settings.tradeAmount, 10.0);
        expect(settings.profitTargetPercentage, 1.0);
        expect(settings.stopLossPercentage, 5.0);
        expect(settings.dcaDecrementPercentage, 1.0);
        expect(settings.maxOpenTrades, 10);
        expect(settings.isTestMode, isFalse);
        expect(settings.buyOnStart, isFalse); // Default value from constructor
        expect(settings.initialWarmupTicks, 1); // Default value
        expect(settings.initialWarmupSeconds, 0.0); // Default value
        expect(settings.initialSignalThresholdPct, 0.0); // Default value
        expect(settings.dcaCooldownSeconds, 3.0); // Default value
        expect(settings.dustRetryCooldownSeconds, 15.0); // Default value
        expect(settings.maxTradeAmountCap, 100.0); // Default value
        expect(settings.maxBuyOveragePct, 0.03); // Default value
        expect(settings.strictBudget, isFalse); // Default value
        expect(settings.buyOnStartRespectWarmup, isTrue); // Default value
        expect(settings.buyCooldownSeconds, 2.0); // Default value
        expect(settings.maxCycles, 0); // Default value
        expect(settings.enableFeeAwareTrading, isTrue); // Default value
      });

      test('should create settings with fee-aware trading enabled', () {
        // ARRANGE & ACT
        const settings = AppSettings(
          tradeAmount: 10.0,
          profitTargetPercentage: 1.0,
          stopLossPercentage: 5.0,
          dcaDecrementPercentage: 1.0,
          maxOpenTrades: 10,
          isTestMode: false,
          enableFeeAwareTrading: true,
        );

        // ASSERT
        expect(settings.enableFeeAwareTrading, isTrue);
        expect(settings.tradeAmount, 10.0);
        expect(settings.profitTargetPercentage, 1.0);
      });

      test('should use copyWith method correctly', () {
        // ARRANGE
        const originalSettings = AppSettings(
          tradeAmount: 10.0,
          profitTargetPercentage: 1.0,
          stopLossPercentage: 5.0,
          dcaDecrementPercentage: 1.0,
          maxOpenTrades: 10,
          isTestMode: false,
          enableFeeAwareTrading: false,
        );

        // ACT
        final updatedSettings = originalSettings.copyWith(
          enableFeeAwareTrading: true,
          profitTargetPercentage: 2.0,
        );

        // ASSERT
        expect(updatedSettings.enableFeeAwareTrading, isTrue);
        expect(updatedSettings.profitTargetPercentage, 2.0);
        expect(updatedSettings.tradeAmount, 10.0); // Unchanged
        expect(updatedSettings.stopLossPercentage, 5.0); // Unchanged
      });
    });

    group('Parameter Validation', () {
      test('should handle zero values correctly', () {
        // ARRANGE & ACT
        const settings = AppSettings(
          tradeAmount: 0.0,
          profitTargetPercentage: 0.0,
          stopLossPercentage: 0.0,
          dcaDecrementPercentage: 0.0,
          maxOpenTrades: 0,
          isTestMode: false,
        );

        // ASSERT
        expect(settings.tradeAmount, 0.0);
        expect(settings.profitTargetPercentage, 0.0);
        expect(settings.stopLossPercentage, 0.0);
        expect(settings.dcaDecrementPercentage, 0.0);
        expect(settings.maxOpenTrades, 0);
      });

      test('should handle very small values correctly', () {
        // ARRANGE & ACT
        const settings = AppSettings(
          tradeAmount: 0.000001,
          profitTargetPercentage: 0.001,
          stopLossPercentage: 0.001,
          dcaDecrementPercentage: 0.001,
          maxOpenTrades: 1,
          isTestMode: false,
        );

        // ASSERT
        expect(settings.tradeAmount, 0.000001);
        expect(settings.profitTargetPercentage, 0.001);
        expect(settings.stopLossPercentage, 0.001);
        expect(settings.dcaDecrementPercentage, 0.001);
        expect(settings.maxOpenTrades, 1);
      });

      test('should handle very large values correctly', () {
        // ARRANGE & ACT
        const settings = AppSettings(
          tradeAmount: 999999999.99,
          profitTargetPercentage: 1000.0,
          stopLossPercentage: 1000.0,
          dcaDecrementPercentage: 1000.0,
          maxOpenTrades: 999999,
          isTestMode: false,
        );

        // ASSERT
        expect(settings.tradeAmount, 999999999.99);
        expect(settings.profitTargetPercentage, 1000.0);
        expect(settings.stopLossPercentage, 1000.0);
        expect(settings.dcaDecrementPercentage, 1000.0);
        expect(settings.maxOpenTrades, 999999);
      });

      test('should handle negative values correctly', () {
        // ARRANGE & ACT
        const settings = AppSettings(
          tradeAmount: -100.0,
          profitTargetPercentage: -5.0,
          stopLossPercentage: -3.0,
          dcaDecrementPercentage: -2.0,
          maxOpenTrades: -10,
          isTestMode: false,
        );

        // ASSERT
        expect(settings.tradeAmount, -100.0);
        expect(settings.profitTargetPercentage, -5.0);
        expect(settings.stopLossPercentage, -3.0);
        expect(settings.dcaDecrementPercentage, -2.0);
        expect(settings.maxOpenTrades, -10);
      });
    });

    group('Boolean Flags', () {
      test('should handle all boolean combinations correctly', () {
        // ARRANGE & ACT
        const settings = AppSettings(
          tradeAmount: 100.0,
          profitTargetPercentage: 5.0,
          stopLossPercentage: 3.0,
          dcaDecrementPercentage: 2.0,
          maxOpenTrades: 10,
          isTestMode: true,
          buyOnStart: true,
          strictBudget: true,
          buyOnStartRespectWarmup: true,
          dcaCompareAgainstAverage: true,
        );

        // ASSERT
        expect(settings.isTestMode, isTrue);
        expect(settings.buyOnStart, isTrue);
        expect(settings.strictBudget, isTrue);
        expect(settings.buyOnStartRespectWarmup, isTrue);
        expect(settings.dcaCompareAgainstAverage, isTrue);
      });

      test('should handle mixed boolean values correctly', () {
        // ARRANGE & ACT
        const settings = AppSettings(
          tradeAmount: 100.0,
          profitTargetPercentage: 5.0,
          stopLossPercentage: 3.0,
          dcaDecrementPercentage: 2.0,
          maxOpenTrades: 10,
          isTestMode: false,
          buyOnStart: true,
          strictBudget: false,
          buyOnStartRespectWarmup: true,
          dcaCompareAgainstAverage: false,
        );

        // ASSERT
        expect(settings.isTestMode, isFalse);
        expect(settings.buyOnStart, isTrue);
        expect(settings.strictBudget, isFalse);
        expect(settings.buyOnStartRespectWarmup, isTrue);
        expect(settings.dcaCompareAgainstAverage, isFalse);
      });
    });

    group('Numeric Parameters', () {
      test('should handle cooldown parameters correctly', () {
        // ARRANGE & ACT
        const settings = AppSettings(
          tradeAmount: 100.0,
          profitTargetPercentage: 5.0,
          stopLossPercentage: 3.0,
          dcaDecrementPercentage: 2.0,
          maxOpenTrades: 10,
          isTestMode: false,
          dcaCooldownSeconds: 5.5,
          dustRetryCooldownSeconds: 20.7,
          buyCooldownSeconds: 3.3,
        );

        // ASSERT
        expect(settings.dcaCooldownSeconds, 5.5);
        expect(settings.dustRetryCooldownSeconds, 20.7);
        expect(settings.buyCooldownSeconds, 3.3);
      });

      test('should handle threshold parameters correctly', () {
        // ARRANGE & ACT
        const settings = AppSettings(
          tradeAmount: 100.0,
          profitTargetPercentage: 5.0,
          stopLossPercentage: 3.0,
          dcaDecrementPercentage: 2.0,
          maxOpenTrades: 10,
          isTestMode: false,
          initialWarmupTicks: 5,
          initialWarmupSeconds: 30.5,
          initialSignalThresholdPct: 1.5,
        );

        // ASSERT
        expect(settings.initialWarmupTicks, 5);
        expect(settings.initialWarmupSeconds, 30.5);
        expect(settings.initialSignalThresholdPct, 1.5);
      });

      test('should handle cap and overage parameters correctly', () {
        // ARRANGE & ACT
        const settings = AppSettings(
          tradeAmount: 100.0,
          profitTargetPercentage: 5.0,
          stopLossPercentage: 3.0,
          dcaDecrementPercentage: 2.0,
          maxOpenTrades: 10,
          isTestMode: false,
          maxTradeAmountCap: 500000.0,
          maxBuyOveragePct: 0.05,
        );

        // ASSERT
        expect(settings.maxTradeAmountCap, 500000.0);
        expect(settings.maxBuyOveragePct, 0.05);
      });

      test('should handle fraction parameters correctly', () {
        // ARRANGE & ACT
        const settings = AppSettings(
          tradeAmount: 100.0,
          profitTargetPercentage: 5.0,
          stopLossPercentage: 3.0,
          dcaDecrementPercentage: 2.0,
          maxOpenTrades: 10,
          isTestMode: false,

          maxCycles: 100,
        );

        // ASSERT

        expect(settings.maxCycles, 100);
      });
    });

    group('Edge Cases', () {
      test('should handle maximum integer values', () {
        // ARRANGE & ACT
        const settings = AppSettings(
          tradeAmount: 100.0,
          profitTargetPercentage: 5.0,
          stopLossPercentage: 3.0,
          dcaDecrementPercentage: 2.0,
          maxOpenTrades: 2147483647, // Max int32
          isTestMode: false,
          maxCycles: 2147483647,
        );

        // ASSERT
        expect(settings.maxOpenTrades, 2147483647);
        expect(settings.maxCycles, 2147483647);
      });

      test('should handle minimum integer values', () {
        // ARRANGE & ACT
        const settings = AppSettings(
          tradeAmount: 100.0,
          profitTargetPercentage: 5.0,
          stopLossPercentage: 3.0,
          dcaDecrementPercentage: 2.0,
          maxOpenTrades: -2147483648, // Min int32
          isTestMode: false,
          maxCycles: -2147483648,
        );

        // ASSERT
        expect(settings.maxOpenTrades, -2147483648);
        expect(settings.maxCycles, -2147483648);
      });

      test('should handle extreme double values', () {
        // ARRANGE & ACT
        const settings = AppSettings(
          tradeAmount: double.maxFinite,
          profitTargetPercentage: double.maxFinite,
          stopLossPercentage: double.maxFinite,
          dcaDecrementPercentage: double.maxFinite,
          maxOpenTrades: 10,
          isTestMode: false,
          maxTradeAmountCap: double.maxFinite,
          maxBuyOveragePct: double.maxFinite,
        );

        // ASSERT
        expect(settings.tradeAmount, double.maxFinite);
        expect(settings.profitTargetPercentage, double.maxFinite);
        expect(settings.stopLossPercentage, double.maxFinite);
        expect(settings.dcaDecrementPercentage, double.maxFinite);
        expect(settings.maxTradeAmountCap, double.maxFinite);
        expect(settings.maxBuyOveragePct, double.maxFinite);
      });

      test('should handle negative infinity values', () {
        // ARRANGE & ACT
        const settings = AppSettings(
          tradeAmount: double.negativeInfinity,
          profitTargetPercentage: double.negativeInfinity,
          stopLossPercentage: double.negativeInfinity,
          dcaDecrementPercentage: double.negativeInfinity,
          maxOpenTrades: 10,
          isTestMode: false,
        );

        // ASSERT
        expect(settings.tradeAmount, double.negativeInfinity);
        expect(settings.profitTargetPercentage, double.negativeInfinity);
        expect(settings.stopLossPercentage, double.negativeInfinity);
        expect(settings.dcaDecrementPercentage, double.negativeInfinity);
      });
    });

    group('Equality and Hash', () {
      test('should implement equality correctly', () {
        // ARRANGE
        const settings1 = AppSettings(
          tradeAmount: 100.0,
          profitTargetPercentage: 5.0,
          stopLossPercentage: 3.0,
          dcaDecrementPercentage: 2.0,
          maxOpenTrades: 10,
          isTestMode: true,
        );

        const settings2 = AppSettings(
          tradeAmount: 100.0,
          profitTargetPercentage: 5.0,
          stopLossPercentage: 3.0,
          dcaDecrementPercentage: 2.0,
          maxOpenTrades: 10,
          isTestMode: true,
        );

        const settings3 = AppSettings(
          tradeAmount: 200.0, // Different value
          profitTargetPercentage: 5.0,
          stopLossPercentage: 3.0,
          dcaDecrementPercentage: 2.0,
          maxOpenTrades: 10,
          isTestMode: true,
        );

        // ACT & ASSERT
        expect(settings1, equals(settings2));
        expect(settings1, isNot(equals(settings3)));
        expect(settings1.hashCode, equals(settings2.hashCode));
        expect(settings1.hashCode, isNot(equals(settings3.hashCode)));
      });

      test('should handle different parameter values in equality', () {
        // ARRANGE
        const settings1 = AppSettings(
          tradeAmount: 100.0,
          profitTargetPercentage: 5.0,
          stopLossPercentage: 3.0,
          dcaDecrementPercentage: 2.0,
          maxOpenTrades: 10,
          isTestMode: false,
        );

        const settings2 = AppSettings(
          tradeAmount: 200.0, // Different value
          profitTargetPercentage: 5.0,
          stopLossPercentage: 3.0,
          dcaDecrementPercentage: 2.0,
          maxOpenTrades: 10,
          isTestMode: false,
        );

        const settings3 = AppSettings(
          tradeAmount: 100.0,
          profitTargetPercentage: 10.0, // Different value
          stopLossPercentage: 3.0,
          dcaDecrementPercentage: 2.0,
          maxOpenTrades: 10,
          isTestMode: false,
        );

        // ACT & ASSERT
        expect(settings1, isNot(equals(settings2)));
        expect(settings1, isNot(equals(settings3)));
        expect(settings2, isNot(equals(settings3)));
      });
    });
  });
}
