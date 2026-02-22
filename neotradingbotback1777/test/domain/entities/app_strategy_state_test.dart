import 'package:test/test.dart';
import 'package:decimal/decimal.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/fifo_app_trade.dart';
import 'package:neotradingbotback1777/domain/entities/strategy_state.dart';

void main() {
  group('AppStrategyState - Unit Tests', () {
    const String testSymbol = 'BTCUSDC';

    group('State Transitions', () {
      test('[TEST-009] should allow valid state transitions', () {
        // ARRANGE
        final initialState = AppStrategyState(
          symbol: testSymbol,
          status: StrategyState.IDLE,
        );

        // ACT & ASSERT
        // Transizione valida: IDLE -> MONITORING_FOR_BUY
        final monitoringState = initialState.copyWith(
          status: StrategyState.MONITORING_FOR_BUY,
        );
        expect(monitoringState.status, StrategyState.MONITORING_FOR_BUY);

        // Transizione valida: MONITORING_FOR_BUY -> BUY_ORDER_PLACED
        final buyPlacedState = monitoringState.copyWith(
          status: StrategyState.BUY_ORDER_PLACED,
        );
        expect(buyPlacedState.status, StrategyState.BUY_ORDER_PLACED);

        // Transizione valida: BUY_ORDER_PLACED -> POSITION_OPEN_MONITORING_FOR_SELL
        final positionOpenState = buyPlacedState.copyWith(
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
          openTrades: [
            FifoAppTrade(
              price: Decimal.parse('50000.0'),
              quantity: Decimal.parse('0.001'),
              timestamp: DateTime.now().millisecondsSinceEpoch,
              roundId: 1,
            ),
          ],
        );
        expect(positionOpenState.status,
            StrategyState.POSITION_OPEN_MONITORING_FOR_SELL);
        expect(positionOpenState.openTrades.length, 1);
      });

      test('should maintain state consistency during transitions', () {
        // ARRANGE
        final initialState = AppStrategyState(
          symbol: testSymbol,
          status: StrategyState.IDLE,
          currentRoundId: 1,
        );

        // ACT
        final newState = initialState.copyWith(
          status: StrategyState.MONITORING_FOR_BUY,
          currentRoundId: 2,
        );

        // ASSERT
        expect(newState.symbol, testSymbol); // Immutabile
        expect(newState.status, StrategyState.MONITORING_FOR_BUY);
        expect(newState.currentRoundId, 2);
        expect(initialState.status,
            StrategyState.IDLE); // Originale non modificato
        expect(initialState.currentRoundId, 1);
      });

      test('should handle all strategy states correctly', () {
        // ARRANGE
        final allStates = StrategyState.values;

        // ACT & ASSERT
        for (final state in allStates) {
          final appState = AppStrategyState(
            symbol: testSymbol,
            status: state,
          );
          expect(appState.status, state);
        }
      });
    });

    group('Calculated Properties', () {
      test('should calculate average price correctly', () {
        // ARRANGE
        final trades = [
          FifoAppTrade(
              price: Decimal.parse('100.0'),
              quantity: Decimal.parse('1.0'),
              timestamp: 1000,
              roundId: 1),
          FifoAppTrade(
              price: Decimal.parse('200.0'),
              quantity: Decimal.parse('1.0'),
              timestamp: 2000,
              roundId: 1),
        ];

        final state = AppStrategyState(
          symbol: testSymbol,
          openTrades: trades,
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
        );

        // ACT & ASSERT
        // Prezzo medio: (100*1 + 200*1) / (1+1) = 150
        expect(state.averagePrice, 150.0);
      });

      test('should calculate total quantity correctly', () {
        // ARRANGE
        final trades = [
          FifoAppTrade(
              price: Decimal.parse('100.0'),
              quantity: Decimal.parse('0.5'),
              timestamp: 1000,
              roundId: 1),
          FifoAppTrade(
              price: Decimal.parse('200.0'),
              quantity: Decimal.parse('0.3'),
              timestamp: 2000,
              roundId: 1),
        ];

        final state = AppStrategyState(
          symbol: testSymbol,
          openTrades: trades,
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
        );

        // ACT & ASSERT
        expect(state.totalQuantity.toDouble(), 0.8);
      });

      test('should identify initial state correctly', () {
        // ARRANGE
        final emptyState = AppStrategyState(symbol: testSymbol);
        final stateWithTrades = AppStrategyState(
          symbol: testSymbol,
          openTrades: [
            FifoAppTrade(
                price: Decimal.parse('100.0'),
                quantity: Decimal.parse('1.0'),
                timestamp: 1000,
                roundId: 1),
          ],
        );

        // ACT & ASSERT
        expect(emptyState.isInitialState, isTrue);
        expect(stateWithTrades.isInitialState, isFalse);
      });

      test('should calculate last valid buy price correctly', () {
        // ARRANGE
        final trades = [
          FifoAppTrade(
              price: Decimal.parse('100.0'),
              quantity: Decimal.parse('1.0'),
              timestamp: 1000,
              roundId: 1),
          FifoAppTrade(
              price: Decimal.parse('95.0'),
              quantity: Decimal.parse('1.0'),
              timestamp: 2000,
              roundId: 1),
        ];

        final state = AppStrategyState(
          symbol: testSymbol,
          openTrades: trades,
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
        );

        // ACT & ASSERT
        expect(state.lastValidBuyPrice, 95.0); // Ultimo trade
      });

      test('should calculate validated average price correctly', () {
        // ARRANGE
        final trades = [
          FifoAppTrade(
              price: Decimal.parse('100.0'),
              quantity: Decimal.parse('1.0'),
              timestamp: 1000,
              roundId: 1),
          FifoAppTrade(
              price: Decimal.parse('95.0'),
              quantity: Decimal.parse('1.0'),
              timestamp: 2000,
              roundId: 1),
        ];

        final state = AppStrategyState(
          symbol: testSymbol,
          openTrades: trades,
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
        );

        // ACT & ASSERT
        expect(state.validatedAveragePrice, 97.5); // (100+95)/2
      });

      test('should calculate total invested correctly', () {
        // ARRANGE
        final trades = [
          FifoAppTrade(
              price: Decimal.parse('100.0'),
              quantity: Decimal.parse('1.0'),
              timestamp: 1000,
              roundId: 1),
          FifoAppTrade(
              price: Decimal.parse('95.0'),
              quantity: Decimal.parse('1.0'),
              timestamp: 2000,
              roundId: 1),
        ];

        final state = AppStrategyState(
          symbol: testSymbol,
          openTrades: trades,
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
        );

        // ACT & ASSERT
        expect(state.totalInvested, 195.0); // 100*1 + 95*1
      });

      test('should identify valid DCA state correctly', () {
        // ARRANGE
        final validTrades = [
          FifoAppTrade(
            price: Decimal.parse('100.0'),
            quantity: Decimal.parse('1.0'),
            timestamp: 1000,
            roundId: 1,
            orderStatus: 'FILLED',
            isExecuted: true,
          ),
        ];

        final invalidTrades = [
          FifoAppTrade(
            price: Decimal.parse('100.0'),
            quantity: Decimal.parse('1.0'),
            timestamp: 1000,
            roundId: 1,
            orderStatus: 'PENDING',
            isExecuted: false,
          ),
        ];

        final validState = AppStrategyState(
          symbol: testSymbol,
          openTrades: validTrades,
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
        );

        final invalidState = AppStrategyState(
          symbol: testSymbol,
          openTrades: invalidTrades,
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
        );

        // ACT & ASSERT
        expect(validState.isValidForDca, isTrue);
        expect(invalidState.isValidForDca, isFalse);
      });
    });

    group('Edge Cases', () {
      test('should handle empty trades list', () {
        // ARRANGE
        final emptyState = AppStrategyState(
          symbol: testSymbol,
          openTrades: [],
        );

        // ACT & ASSERT
        expect(emptyState.averagePrice, 0.0);
        expect(emptyState.totalQuantity.toDouble(), 0.0);
        expect(emptyState.isInitialState, isTrue);
        expect(emptyState.lastValidBuyPrice, 0.0);
        expect(emptyState.validatedAveragePrice, 0.0);
        expect(emptyState.totalInvested, 0.0);
      });

      test('should handle single trade correctly', () {
        // ARRANGE
        final singleTrade = FifoAppTrade(
          price: Decimal.parse('50000.0'),
          quantity: Decimal.parse('0.001'),
          timestamp: 1000,
          roundId: 1,
        );

        final state = AppStrategyState(
          symbol: testSymbol,
          openTrades: [singleTrade],
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
        );

        // ACT & ASSERT
        expect(state.averagePrice, 50000.0);
        expect(state.totalQuantity.toDouble(), 0.001);
        expect(state.isInitialState, isFalse);
        expect(state.lastValidBuyPrice, 50000.0);
        expect(state.validatedAveragePrice, 50000.0);
        expect(state.totalInvested, 50.0); // 50000 * 0.001
      });

      test('should handle trades with different quantities', () {
        // ARRANGE
        final trades = [
          FifoAppTrade(
              price: Decimal.parse('100.0'),
              quantity: Decimal.parse('2.0'),
              timestamp: 1000,
              roundId: 1),
          FifoAppTrade(
              price: Decimal.parse('200.0'),
              quantity: Decimal.parse('1.0'),
              timestamp: 2000,
              roundId: 1),
        ];

        final state = AppStrategyState(
          symbol: testSymbol,
          openTrades: trades,
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
        );

        // ACT & ASSERT
        // Prezzo medio ponderato: (100*2 + 200*1) / (2+1) = 400/3 ≈ 133.33
        expect(state.averagePrice, closeTo(133.33, 0.01));
        expect(state.totalQuantity.toDouble(), 3.0);
        expect(state.totalInvested, 400.0); // 100*2 + 200*1
      });

      test('should handle very small quantities correctly', () {
        // ARRANGE
        final trades = [
          FifoAppTrade(
              price: Decimal.parse('50000.0'),
              quantity: Decimal.parse('0.00000001'),
              timestamp: 1000,
              roundId: 1),
          FifoAppTrade(
              price: Decimal.parse('50000.0'),
              quantity: Decimal.parse('0.00000001'),
              timestamp: 2000,
              roundId: 1),
        ];

        final state = AppStrategyState(
          symbol: testSymbol,
          openTrades: trades,
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
        );

        // ACT & ASSERT
        expect(state.averagePrice, 50000.0);
        expect(state.totalQuantity.toDouble(), closeTo(0.00000002, 1e-12));
        expect(state.totalInvested, 0.001); // 50000 * 0.00000002
      });

      test('should handle very large prices correctly', () {
        // ARRANGE
        final trades = [
          FifoAppTrade(
              price: Decimal.parse('999999999.99'),
              quantity: Decimal.parse('1.0'),
              timestamp: 1000,
              roundId: 1),
        ];

        final state = AppStrategyState(
          symbol: testSymbol,
          openTrades: trades,
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
        );

        // ACT & ASSERT
        expect(state.averagePrice, 999999999.99);
        expect(state.totalQuantity.toDouble(), 1.0);
        expect(state.totalInvested, 999999999.99);
      });
    });

    group('State Validation', () {
      test('should validate state consistency correctly', () {
        // ARRANGE
        final validState = AppStrategyState(
          symbol: testSymbol,
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
          openTrades: [
            FifoAppTrade(
              price: Decimal.parse('100.0'),
              quantity: Decimal.parse('1.0'),
              timestamp: 1000,
              roundId: 1,
              orderStatus: 'FILLED',
              isExecuted: true,
            ),
          ],
        );

        final invalidState = AppStrategyState(
          symbol: testSymbol,
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
          openTrades: [
            FifoAppTrade(
              price: Decimal.parse('100.0'),
              quantity: Decimal.parse('1.0'),
              timestamp: 1000,
              roundId: 1,
              orderStatus: 'PENDING',
              isExecuted: false,
            ),
          ],
        );

        // ACT & ASSERT
        expect(validState.hasInconsistencies, isFalse);
        expect(invalidState.hasInconsistencies, isTrue);
      });

      test('should count valid and invalid trades correctly', () {
        // ARRANGE
        final trades = [
          FifoAppTrade(
            price: Decimal.parse('100.0'),
            quantity: Decimal.parse('1.0'),
            timestamp: 1000,
            roundId: 1,
            orderStatus: 'FILLED',
            isExecuted: true,
          ),
          FifoAppTrade(
            price: Decimal.parse('95.0'),
            quantity: Decimal.parse('1.0'),
            timestamp: 2000,
            roundId: 1,
            orderStatus: 'PENDING',
            isExecuted: false,
          ),
        ];

        final state = AppStrategyState(
          symbol: testSymbol,
          openTrades: trades,
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
        );

        // ACT & ASSERT
        expect(state.validTradesCount, 1);
        expect(state.invalidTradesCount, 1);
        expect(state.openTrades.length, 2);
      });
    });

    group('Round Management', () {
      test('should increment round ID correctly', () {
        // ARRANGE
        final initialState = AppStrategyState(
          symbol: testSymbol,
          currentRoundId: 1,
        );

        // ACT
        final nextRoundState = initialState.copyWith(
          currentRoundId: 2,
          openTrades: [], // Chiude il round precedente
        );

        // ASSERT
        expect(initialState.currentRoundId, 1);
        expect(nextRoundState.currentRoundId, 2);
      });

      test('should handle target round ID correctly', () {
        // ARRANGE
        final stateWithTarget = AppStrategyState(
          symbol: testSymbol,
          currentRoundId: 5,
          targetRoundId: 10,
        );

        final stateWithoutTarget = AppStrategyState(
          symbol: testSymbol,
          currentRoundId: 5,
        );

        // ACT & ASSERT
        expect(stateWithTarget.targetRoundId, 10);
        expect(stateWithoutTarget.targetRoundId, isNull);
      });

      test('should track successful and failed rounds', () {
        // ARRANGE
        final state = AppStrategyState(
          symbol: testSymbol,
          successfulRounds: 3,
          failedRounds: 1,
        );

        // ACT
        final updatedState = state.copyWith(
          successfulRounds: 4,
          failedRounds: 2,
        );

        // ASSERT
        expect(state.successfulRounds, 3);
        expect(state.failedRounds, 1);
        expect(updatedState.successfulRounds, 4);
        expect(updatedState.failedRounds, 2);
      });
    });

    group('Copy Operations', () {
      test('should create independent copies', () {
        // ARRANGE
        final originalState = AppStrategyState(
          symbol: testSymbol,
          status: StrategyState.IDLE,
          currentRoundId: 1,
        );

        // ACT
        final copiedState = originalState.copyWith(
          status: StrategyState.MONITORING_FOR_BUY,
          currentRoundId: 2,
        );

        // ASSERT
        expect(originalState.status, StrategyState.IDLE);
        expect(originalState.currentRoundId, 1);
        expect(copiedState.status, StrategyState.MONITORING_FOR_BUY);
        expect(copiedState.currentRoundId, 2);
        expect(identical(originalState, copiedState), isFalse);
      });

      test('should preserve unchanged values', () {
        // ARRANGE
        final originalState = AppStrategyState(
          symbol: testSymbol,
          status: StrategyState.IDLE,
          currentRoundId: 1,
          cumulativeProfit: 100.0,
        );

        // ACT
        final copiedState = originalState.copyWith(
          status: StrategyState.MONITORING_FOR_BUY,
        );

        // ASSERT
        expect(copiedState.symbol, testSymbol);
        expect(copiedState.currentRoundId, 1);
        expect(copiedState.cumulativeProfit, 100.0);
        expect(copiedState.status, StrategyState.MONITORING_FOR_BUY);
      });
    });

    group('Equality and Hash', () {
      test('should implement equality correctly', () {
        // ARRANGE
        final state1 = AppStrategyState(
          symbol: testSymbol,
          status: StrategyState.IDLE,
          currentRoundId: 1,
        );

        final state2 = AppStrategyState(
          symbol: testSymbol,
          status: StrategyState.IDLE,
          currentRoundId: 1,
        );

        final state3 = AppStrategyState(
          symbol: testSymbol,
          status: StrategyState.MONITORING_FOR_BUY,
          currentRoundId: 1,
        );

        // ACT & ASSERT
        expect(state1, equals(state2));
        expect(state1, isNot(equals(state3)));
        expect(state1.hashCode, equals(state2.hashCode));
        expect(state1.hashCode, isNot(equals(state3.hashCode)));
      });

      test('should handle different trade lists correctly', () {
        // ARRANGE
        final state1 = AppStrategyState(
          symbol: testSymbol,
          openTrades: [
            FifoAppTrade(
                price: Decimal.parse('100.0'),
                quantity: Decimal.parse('1.0'),
                timestamp: 1000,
                roundId: 1),
          ],
        );

        final state2 = AppStrategyState(
          symbol: testSymbol,
          openTrades: [
            FifoAppTrade(
                price: Decimal.parse('100.0'),
                quantity: Decimal.parse('1.0'),
                timestamp: 1000,
                roundId: 1),
          ],
        );

        final state3 = AppStrategyState(
          symbol: testSymbol,
          openTrades: [
            FifoAppTrade(
                price: Decimal.parse('200.0'),
                quantity: Decimal.parse('1.0'),
                timestamp: 1000,
                roundId: 1),
          ],
        );

        // ACT & ASSERT
        expect(state1, equals(state2));
        expect(state1, isNot(equals(state3)));
      });
    });
  });
}

