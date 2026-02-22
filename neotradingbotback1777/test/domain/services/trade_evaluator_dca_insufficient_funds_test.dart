import 'package:neotradingbotback1777/domain/services/fee_calculation_service.dart';
import 'package:decimal/decimal.dart';
import 'package:test/test.dart';
import 'package:neotradingbotback1777/domain/services/trade_evaluator_service.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/fifo_app_trade.dart';
import 'package:neotradingbotback1777/domain/entities/strategy_state.dart';
import '../../mocks/fee_repository_mock.dart';
import '../../mocks/trading_lock_manager_mock.dart';
import '../../mocks/business_metrics_monitor_mock.dart';
import '../../helpers/mockito_dummy_registrations.dart';

import 'package:neotradingbotback1777/core/logging/log_throttler.dart';
import 'package:neotradingbotback1777/core/errors/unified_error_handler.dart';

void main() {
  group('[BACKEND-TEST-012] TradeEvaluator - Fondi Insufficienti DCA', () {
    late TradeEvaluatorService service;
    late FakeTradingLockManager fakeTradingLockManager;
    late AppSettings testSettings;
    late AppStrategyState testState;

    setUp(() {
      registerMockitoDummies();
      fakeTradingLockManager = FakeTradingLockManager();
      service = TradeEvaluatorService(
        feeCalculationService:
            FeeCalculationService(feeRepository: MockFeeRepository()),
        tradingLockManager: fakeTradingLockManager,
        logThrottler: LogThrottler(),
        errorHandler: UnifiedErrorHandler(),
        businessMetricsMonitor: FakeBusinessMetricsMonitor(),
      );
      testSettings = AppSettings(
        tradeAmount: 100.0,
        profitTargetPercentage: 5.0,
        stopLossPercentage: 3.0,
        dcaDecrementPercentage: 10.0,
        maxOpenTrades: 5,
        isTestMode: true,
      );

      testState = AppStrategyState(
        symbol: 'BTCUSDC',
        status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
        openTrades: [
          FifoAppTrade(
            price: Decimal.parse('100.0'),
            quantity: Decimal.parse('1.0'),
            timestamp: DateTime.now().millisecondsSinceEpoch - 60000,
            roundId: 1,
          ),
          FifoAppTrade(
            price: Decimal.parse('95.0'),
            quantity: Decimal.parse('1.0'),
            timestamp: DateTime.now().millisecondsSinceEpoch - 30000,
            roundId: 1,
          ),
        ],
      );
    });

    test(
      'should return true for DCA trigger even with potential insufficient funds',
      () {
        // ARRANGE
        final currentPrice = 85.5; // -12% sotto media → trigger DCA

        // ACT
        final shouldDca = service.shouldDcaBuy(
          currentPrice: currentPrice,
          state: testState,
          settings: testSettings,
        );

        // ASSERT
        expect(shouldDca, isTrue,
            reason:
                'DCA dovrebbe essere triggerato dal decremento percentuale');
        expect(testState.averagePrice, 97.5,
            reason: 'Prezzo medio calcolato correttamente');
        expect(currentPrice / testState.averagePrice, lessThan(0.9),
            reason: 'Decremento > 10% verificato');
      },
    );

    test(
      'should handle edge case: exactly at DCA threshold',
      () {
        // ARRANGE
        final exactThresholdPrice = testState.averagePrice * 0.9; // Esatto -10%

        // ACT
        final shouldDca = service.shouldDcaBuy(
          currentPrice: exactThresholdPrice,
          state: testState,
          settings: testSettings,
          compareAgainstAverage: true,
        );

        // ASSERT
        expect(shouldDca, isTrue,
            reason:
                'DCA dovrebbe attivarsi esattamente alla soglia (o con tolleranza float)');
      },
    );

    test(
      'should validate state consistency before DCA decision',
      () {
        // ARRANGE
        final invalidState = testState.copyWith(
          status: StrategyState.IDLE, // Stato non valido per DCA
        );

        // ACT
        final shouldDca = service.shouldDcaBuy(
          currentPrice: 85.0,
          state: invalidState,
          settings: testSettings,
        );

        // ASSERT
        expect(shouldDca, isFalse,
            reason: 'DCA non dovrebbe essere possibile in stato IDLE');
      },
    );

    test(
      'should handle DCA with maximum open trades limit',
      () {
        // ARRANGE
        final maxTradesState = testState.copyWith(
          openTrades: List.generate(
              5,
              (index) => FifoAppTrade(
                    price: Decimal.parse((100.0 - index * 2.0).toString()),
                    quantity: Decimal.parse('1.0'),
                    timestamp:
                        DateTime.now().millisecondsSinceEpoch - (index * 30000),
                    roundId: 1,
                  )),
        );

        // ACT
        final shouldDca = service.shouldDcaBuy(
          currentPrice: 85.0,
          state: maxTradesState,
          settings: testSettings,
        );

        // ASSERT
        expect(shouldDca, isFalse,
            reason:
                'DCA non dovrebbe essere possibile con maxOpenTrades raggiunto');
      },
    );

    test(
      'should compare DCA against average vs last buy price correctly',
      () {
        // ARRANGE
        final currentPrice =
            88.0; // -9.5% sotto media, -7.4% sotto ultimo acquisto

        // ACT - DCA contro prezzo medio
        final shouldDcaAgainstAverage = service.shouldDcaBuy(
          currentPrice: currentPrice,
          state: testState,
          settings: testSettings,
          compareAgainstAverage: true,
        );

        // ACT - DCA contro ultimo prezzo acquisto
        final shouldDcaAgainstLastBuy = service.shouldDcaBuy(
          currentPrice: currentPrice,
          state: testState,
          settings: testSettings,
          compareAgainstAverage: false,
        );

        // ASSERT
        expect(shouldDcaAgainstAverage, isFalse,
            reason: 'DCA contro media non dovrebbe attivarsi a -9.5%');
        expect(shouldDcaAgainstLastBuy, isFalse,
            reason:
                'DCA contro ultimo acquisto non dovrebbe attivarsi a -7.4% con soglia 10%');
      },
    );

    test(
      'should handle DCA with zero or negative prices',
      () {
        // ARRANGE
        final invalidPrices = [0.0, -1.0, double.negativeInfinity, double.nan];

        // ACT & ASSERT
        for (final price in invalidPrices) {
          final shouldDca = service.shouldDcaBuy(
            currentPrice: price,
            state: testState,
            settings: testSettings,
          );

          expect(shouldDca, isFalse,
              reason:
                  'DCA non dovrebbe essere possibile con prezzo invalido: $price');
        }
      },
    );

    test(
      'should handle DCA with corrupted state data',
      () {
        // ARRANGE
        final corruptedState = testState.copyWith(
          openTrades: [
            FifoAppTrade(
              price: Decimal.parse('0.0'), // Prezzo corrotto
              quantity: Decimal.parse('1.0'),
              timestamp: DateTime.now().millisecondsSinceEpoch,
              roundId: 1,
            ),
          ],
        );

        // ACT
        final shouldDca = service.shouldDcaBuy(
          currentPrice: 85.0,
          state: corruptedState,
          settings: testSettings,
        );

        // ASSERT
        expect(shouldDca, isFalse,
            reason:
                'DCA non dovrebbe essere possibile con dati di stato corrotti');
      },
    );
  });
}
