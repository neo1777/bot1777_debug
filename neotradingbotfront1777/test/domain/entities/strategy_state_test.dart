import 'package:test/test.dart';
import 'package:neotradingbotfront1777/domain/entities/strategy_state.dart';

void main() {
  group('StrategyState - Unit Tests', () {
    const String testSymbol = 'BTCUSDC';

    group('Constructor and Factory Methods', () {
      test('should create instance with required parameters', () {
        // ARRANGE & ACT
        const state = StrategyState(
          symbol: testSymbol,
          status: StrategyStatus.running,
          openTradesCount: 2,
          averagePrice: 50000.0,
          totalQuantity: 0.001,
          lastBuyPrice: 49000.0,
          currentRoundId: 5,
          cumulativeProfit: 100.0,
          successfulRounds: 3,
          failedRounds: 1,
        );

        // ASSERT
        expect(state.symbol, testSymbol);
        expect(state.status, StrategyStatus.running);
        expect(state.openTradesCount, 2);
        expect(state.averagePrice, 50000.0);
        expect(state.totalQuantity, 0.001);
        expect(state.lastBuyPrice, 49000.0);
        expect(state.currentRoundId, 5);
        expect(state.cumulativeProfit, 100.0);
        expect(state.successfulRounds, 3);
        expect(state.failedRounds, 1);
        expect(state.warningMessage, isNull);
      });

      test('should create initial state correctly', () {
        // ARRANGE & ACT
        final initialState = StrategyState.initial(symbol: testSymbol);

        // ASSERT
        expect(initialState.symbol, testSymbol);
        expect(initialState.status, StrategyStatus.idle);
        expect(initialState.openTradesCount, 0);
        expect(initialState.averagePrice, 0.0);
        expect(initialState.totalQuantity, 0.0);
        expect(initialState.lastBuyPrice, 0.0);
        expect(initialState.currentRoundId, 0);
        expect(initialState.cumulativeProfit, 0.0);
        expect(initialState.successfulRounds, 0);
        expect(initialState.failedRounds, 0);
        expect(initialState.warningMessage, isNull);
      });

      test('should handle optional warning message', () {
        // ARRANGE & ACT
        const stateWithWarning = StrategyState(
          symbol: testSymbol,
          status: StrategyStatus.running,
          openTradesCount: 1,
          averagePrice: 50000.0,
          totalQuantity: 0.001,
          lastBuyPrice: 50000.0,
          currentRoundId: 1,
          cumulativeProfit: 0.0,
          successfulRounds: 0,
          failedRounds: 0,
          warningMessage: 'Low balance warning',
        );

        // ASSERT
        expect(stateWithWarning.warningMessage, 'Low balance warning');
      });
    });

    group('Status Handling', () {
      test('should handle all strategy status values', () {
        // ARRANGE
        final allStatuses = StrategyStatus.values;

        // ACT & ASSERT
        for (final status in allStatuses) {
          final state = StrategyState(
            symbol: testSymbol,
            status: status,
            openTradesCount: 0,
            averagePrice: 0.0,
            totalQuantity: 0.0,
            lastBuyPrice: 0.0,
            currentRoundId: 0,
            cumulativeProfit: 0.0,
            successfulRounds: 0,
            failedRounds: 0,
          );

          expect(state.status, status);
        }
      });

      test('should handle idle status correctly', () {
        // ARRANGE & ACT
        const state = StrategyState(
          symbol: testSymbol,
          status: StrategyStatus.idle,
          openTradesCount: 0,
          averagePrice: 0.0,
          totalQuantity: 0.0,
          lastBuyPrice: 0.0,
          currentRoundId: 0,
          cumulativeProfit: 0.0,
          successfulRounds: 0,
          failedRounds: 0,
        );

        // ASSERT
        expect(state.status, StrategyStatus.idle);
        expect(state.openTradesCount, 0);
      });

      test('should handle running status correctly', () {
        // ARRANGE & ACT
        const state = StrategyState(
          symbol: testSymbol,
          status: StrategyStatus.running,
          openTradesCount: 2,
          averagePrice: 50000.0,
          totalQuantity: 0.001,
          lastBuyPrice: 50000.0,
          currentRoundId: 5,
          cumulativeProfit: 100.0,
          successfulRounds: 3,
          failedRounds: 1,
        );

        // ASSERT
        expect(state.status, StrategyStatus.running);
        expect(state.openTradesCount, 2);
        expect(state.currentRoundId, 5);
      });

      test('should handle paused status correctly', () {
        // ARRANGE & ACT
        const state = StrategyState(
          symbol: testSymbol,
          status: StrategyStatus.paused,
          openTradesCount: 1,
          averagePrice: 50000.0,
          totalQuantity: 0.001,
          lastBuyPrice: 50000.0,
          currentRoundId: 3,
          cumulativeProfit: 50.0,
          successfulRounds: 2,
          failedRounds: 0,
        );

        // ASSERT
        expect(state.status, StrategyStatus.paused);
        expect(state.openTradesCount, 1);
      });

      test('should handle error status correctly', () {
        // ARRANGE & ACT
        const state = StrategyState(
          symbol: testSymbol,
          status: StrategyStatus.error,
          openTradesCount: 0,
          averagePrice: 0.0,
          totalQuantity: 0.0,
          lastBuyPrice: 0.0,
          currentRoundId: 0,
          cumulativeProfit: 0.0,
          successfulRounds: 0,
          failedRounds: 0,
          warningMessage: 'Connection error',
        );

        // ASSERT
        expect(state.status, StrategyStatus.error);
        expect(state.warningMessage, 'Connection error');
      });

      test('should handle recovering status correctly', () {
        // ARRANGE & ACT
        const state = StrategyState(
          symbol: testSymbol,
          status: StrategyStatus.recovering,
          openTradesCount: 1,
          averagePrice: 50000.0,
          totalQuantity: 0.001,
          lastBuyPrice: 50000.0,
          currentRoundId: 3,
          cumulativeProfit: 50.0,
          successfulRounds: 2,
          failedRounds: 0,
        );

        // ASSERT
        expect(state.status, StrategyStatus.recovering);
      });

      test('should handle unspecified status correctly', () {
        // ARRANGE & ACT
        const state = StrategyState(
          symbol: testSymbol,
          status: StrategyStatus.unspecified,
          openTradesCount: 0,
          averagePrice: 0.0,
          totalQuantity: 0.0,
          lastBuyPrice: 0.0,
          currentRoundId: 0,
          cumulativeProfit: 0.0,
          successfulRounds: 0,
          failedRounds: 0,
        );

        // ASSERT
        expect(state.status, StrategyStatus.unspecified);
      });
    });

    group('Numeric Values', () {
      test('should handle zero values correctly', () {
        // ARRANGE & ACT
        const state = StrategyState(
          symbol: testSymbol,
          status: StrategyStatus.idle,
          openTradesCount: 0,
          averagePrice: 0.0,
          totalQuantity: 0.0,
          lastBuyPrice: 0.0,
          currentRoundId: 0,
          cumulativeProfit: 0.0,
          successfulRounds: 0,
          failedRounds: 0,
        );

        // ASSERT
        expect(state.openTradesCount, 0);
        expect(state.averagePrice, 0.0);
        expect(state.totalQuantity, 0.0);
        expect(state.lastBuyPrice, 0.0);
        expect(state.currentRoundId, 0);
        expect(state.cumulativeProfit, 0.0);
        expect(state.successfulRounds, 0);
        expect(state.failedRounds, 0);
      });

      test('should handle very small values correctly', () {
        // ARRANGE & ACT
        const state = StrategyState(
          symbol: testSymbol,
          status: StrategyStatus.running,
          openTradesCount: 1,
          averagePrice: 0.00000001,
          totalQuantity: 0.00000001,
          lastBuyPrice: 0.00000001,
          currentRoundId: 1,
          cumulativeProfit: 0.00000001,
          successfulRounds: 1,
          failedRounds: 0,
        );

        // ASSERT
        expect(state.averagePrice, 0.00000001);
        expect(state.totalQuantity, 0.00000001);
        expect(state.lastBuyPrice, 0.00000001);
        expect(state.cumulativeProfit, 0.00000001);
      });

      test('should handle very large values correctly', () {
        // ARRANGE & ACT
        const state = StrategyState(
          symbol: testSymbol,
          status: StrategyStatus.running,
          openTradesCount: 999999,
          averagePrice: 999999999.99,
          totalQuantity: 999999999.99,
          lastBuyPrice: 999999999.99,
          currentRoundId: 999999,
          cumulativeProfit: 999999999.99,
          successfulRounds: 999999,
          failedRounds: 999999,
        );

        // ASSERT
        expect(state.openTradesCount, 999999);
        expect(state.averagePrice, 999999999.99);
        expect(state.totalQuantity, 999999999.99);
        expect(state.lastBuyPrice, 999999999.99);
        expect(state.currentRoundId, 999999);
        expect(state.cumulativeProfit, 999999999.99);
        expect(state.successfulRounds, 999999);
        expect(state.failedRounds, 999999);
      });

      test('should handle negative values correctly', () {
        // ARRANGE & ACT
        const state = StrategyState(
          symbol: testSymbol,
          status: StrategyStatus.running,
          openTradesCount: 1,
          averagePrice: -100.0,
          totalQuantity: -0.001,
          lastBuyPrice: -100.0,
          currentRoundId: 1,
          cumulativeProfit: -100.0,
          successfulRounds: 0,
          failedRounds: 1,
        );

        // ASSERT
        expect(state.averagePrice, -100.0);
        expect(state.totalQuantity, -0.001);
        expect(state.lastBuyPrice, -100.0);
        expect(state.cumulativeProfit, -100.0);
      });
    });

    group('Edge Cases', () {
      test('should handle maximum integer values', () {
        // ARRANGE & ACT
        const state = StrategyState(
          symbol: testSymbol,
          status: StrategyStatus.running,
          openTradesCount: 2147483647, // Max int32
          averagePrice: 50000.0,
          totalQuantity: 0.001,
          lastBuyPrice: 50000.0,
          currentRoundId: 2147483647,
          cumulativeProfit: 100.0,
          successfulRounds: 2147483647,
          failedRounds: 2147483647,
        );

        // ASSERT
        expect(state.openTradesCount, 2147483647);
        expect(state.currentRoundId, 2147483647);
        expect(state.successfulRounds, 2147483647);
        expect(state.failedRounds, 2147483647);
      });

      test('should handle minimum integer values', () {
        // ARRANGE & ACT
        const state = StrategyState(
          symbol: testSymbol,
          status: StrategyStatus.running,
          openTradesCount: -2147483648, // Min int32
          averagePrice: 50000.0,
          totalQuantity: 0.001,
          lastBuyPrice: 50000.0,
          currentRoundId: -2147483648,
          cumulativeProfit: 100.0,
          successfulRounds: -2147483648,
          failedRounds: -2147483648,
        );

        // ASSERT
        expect(state.openTradesCount, -2147483648);
        expect(state.currentRoundId, -2147483648);
        expect(state.successfulRounds, -2147483648);
        expect(state.failedRounds, -2147483648);
      });

      test('should handle extreme double values', () {
        // ARRANGE & ACT
        const state = StrategyState(
          symbol: testSymbol,
          status: StrategyStatus.running,
          openTradesCount: 1,
          averagePrice: double.maxFinite,
          totalQuantity: double.maxFinite,
          lastBuyPrice: double.maxFinite,
          currentRoundId: 1,
          cumulativeProfit: double.maxFinite,
          successfulRounds: 1,
          failedRounds: 0,
        );

        // ASSERT
        expect(state.averagePrice, double.maxFinite);
        expect(state.totalQuantity, double.maxFinite);
        expect(state.lastBuyPrice, double.maxFinite);
        expect(state.cumulativeProfit, double.maxFinite);
      });

      test('should handle negative infinity values', () {
        // ARRANGE & ACT
        const state = StrategyState(
          symbol: testSymbol,
          status: StrategyStatus.running,
          openTradesCount: 1,
          averagePrice: double.negativeInfinity,
          totalQuantity: double.negativeInfinity,
          lastBuyPrice: double.negativeInfinity,
          currentRoundId: 1,
          cumulativeProfit: double.negativeInfinity,
          successfulRounds: 1,
          failedRounds: 0,
        );

        // ASSERT
        expect(state.averagePrice, double.negativeInfinity);
        expect(state.totalQuantity, double.negativeInfinity);
        expect(state.lastBuyPrice, double.negativeInfinity);
        expect(state.cumulativeProfit, double.negativeInfinity);
      });
    });

    group('Equality and Hash', () {
      test('should implement equality correctly', () {
        // ARRANGE
        const state1 = StrategyState(
          symbol: testSymbol,
          status: StrategyStatus.running,
          openTradesCount: 2,
          averagePrice: 50000.0,
          totalQuantity: 0.001,
          lastBuyPrice: 50000.0,
          currentRoundId: 5,
          cumulativeProfit: 100.0,
          successfulRounds: 3,
          failedRounds: 1,
        );

        const state2 = StrategyState(
          symbol: testSymbol,
          status: StrategyStatus.running,
          openTradesCount: 2,
          averagePrice: 50000.0,
          totalQuantity: 0.001,
          lastBuyPrice: 50000.0,
          currentRoundId: 5,
          cumulativeProfit: 100.0,
          successfulRounds: 3,
          failedRounds: 1,
        );

        const state3 = StrategyState(
          symbol: testSymbol,
          status: StrategyStatus.paused, // Different status
          openTradesCount: 2,
          averagePrice: 50000.0,
          totalQuantity: 0.001,
          lastBuyPrice: 50000.0,
          currentRoundId: 5,
          cumulativeProfit: 100.0,
          successfulRounds: 3,
          failedRounds: 1,
        );

        // ACT & ASSERT
        expect(state1, equals(state2));
        expect(state1, isNot(equals(state3)));
        expect(state1.hashCode, equals(state2.hashCode));
        expect(state1.hashCode, isNot(equals(state3.hashCode)));
      });

      test('should handle different parameter values in equality', () {
        // ARRANGE
        const baseState = StrategyState(
          symbol: testSymbol,
          status: StrategyStatus.running,
          openTradesCount: 2,
          averagePrice: 50000.0,
          totalQuantity: 0.001,
          lastBuyPrice: 50000.0,
          currentRoundId: 5,
          cumulativeProfit: 100.0,
          successfulRounds: 3,
          failedRounds: 1,
        );

        // ACT & ASSERT - Test different values
        final differentOpenTrades = StrategyState(
          symbol: testSymbol,
          status: StrategyStatus.running,
          openTradesCount: 3, // Different value
          averagePrice: 50000.0,
          totalQuantity: 0.001,
          lastBuyPrice: 50000.0,
          currentRoundId: 5,
          cumulativeProfit: 100.0,
          successfulRounds: 3,
          failedRounds: 1,
        );

        final differentAveragePrice = StrategyState(
          symbol: testSymbol,
          status: StrategyStatus.running,
          openTradesCount: 2,
          averagePrice: 60000.0, // Different value
          totalQuantity: 0.001,
          lastBuyPrice: 50000.0,
          currentRoundId: 5,
          cumulativeProfit: 100.0,
          successfulRounds: 3,
          failedRounds: 1,
        );

        expect(baseState, isNot(equals(differentOpenTrades)));
        expect(baseState, isNot(equals(differentAveragePrice)));
        expect(differentOpenTrades, isNot(equals(differentAveragePrice)));
      });

      test('should handle warning message in equality', () {
        // ARRANGE
        const stateWithoutWarning = StrategyState(
          symbol: testSymbol,
          status: StrategyStatus.running,
          openTradesCount: 1,
          averagePrice: 50000.0,
          totalQuantity: 0.001,
          lastBuyPrice: 50000.0,
          currentRoundId: 1,
          cumulativeProfit: 0.0,
          successfulRounds: 0,
          failedRounds: 0,
        );

        const stateWithWarning = StrategyState(
          symbol: testSymbol,
          status: StrategyStatus.running,
          openTradesCount: 1,
          averagePrice: 50000.0,
          totalQuantity: 0.001,
          lastBuyPrice: 50000.0,
          currentRoundId: 1,
          cumulativeProfit: 0.0,
          successfulRounds: 0,
          failedRounds: 0,
          warningMessage: 'Warning message',
        );

        // ACT & ASSERT
        expect(stateWithoutWarning, isNot(equals(stateWithWarning)));
        expect(
          stateWithoutWarning.hashCode,
          isNot(equals(stateWithWarning.hashCode)),
        );
      });
    });

    group('Props List', () {
      test('should include all properties in props list', () {
        // ARRANGE
        const state = StrategyState(
          symbol: testSymbol,
          status: StrategyStatus.running,
          openTradesCount: 2,
          averagePrice: 50000.0,
          totalQuantity: 0.001,
          lastBuyPrice: 50000.0,
          currentRoundId: 5,
          cumulativeProfit: 100.0,
          successfulRounds: 3,
          failedRounds: 1,
          warningMessage: 'Test warning',
        );

        // ACT
        final props = state.props;

        // ASSERT
        expect(
          props.length,
          12,
        ); // All properties including warningMessage and warnings
        expect(props.contains(testSymbol), isTrue);
        expect(props.contains(StrategyStatus.running), isTrue);
        expect(props.contains(2), isTrue);
        expect(props.contains(50000.0), isTrue);
        expect(props.contains(0.001), isTrue);
        expect(props.contains(50000.0), isTrue);
        expect(props.contains(5), isTrue);
        expect(props.contains(100.0), isTrue);
        expect(props.contains(3), isTrue);
        expect(props.contains(1), isTrue);
        expect(props.contains('Test warning'), isTrue);
      });
    });
  });
}
