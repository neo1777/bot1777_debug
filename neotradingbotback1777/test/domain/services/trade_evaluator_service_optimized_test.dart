import 'package:neotradingbotback1777/domain/services/fee_calculation_service.dart';
import 'package:decimal/decimal.dart';
import 'package:test/test.dart';
import 'package:neotradingbotback1777/domain/services/trade_evaluator_service.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/fifo_app_trade.dart';
import '../../mocks/fee_repository_mock.dart';
import '../../mocks/trading_lock_manager_mock.dart';
import '../../mocks/business_metrics_monitor_mock.dart';
import '../../helpers/mockito_dummy_registrations.dart';

import 'package:neotradingbotback1777/core/logging/log_throttler.dart';
import 'package:neotradingbotback1777/core/errors/unified_error_handler.dart';

void main() {
  group('TradeEvaluatorService - Test Ottimizzazioni', () {
    late TradeEvaluatorService tradeEvaluator;
    late FakeTradingLockManager fakeTradingLockManager;
    late AppSettings testSettings;
    late AppStrategyState initialState;
    late AppStrategyState positionOpenState;

    setUp(() {
      registerMockitoDummies();
      fakeTradingLockManager = FakeTradingLockManager();
      tradeEvaluator = TradeEvaluatorService(
        feeCalculationService:
            FeeCalculationService(feeRepository: MockFeeRepository()),
        tradingLockManager: fakeTradingLockManager,
        logThrottler: LogThrottler(),
        errorHandler: UnifiedErrorHandler(),
        businessMetricsMonitor: FakeBusinessMetricsMonitor(),
      );

      testSettings = AppSettings(
        tradeAmount: 100.0,
        profitTargetPercentage: 2.0,
        stopLossPercentage: 5.0,
        dcaDecrementPercentage: 3.0,
        maxOpenTrades: 5,
        isTestMode: true,
      );

      initialState = AppStrategyState(
        symbol: 'BTCUSDC',
        status: StrategyState.MONITORING_FOR_BUY,
        openTrades: [],
      );

      positionOpenState = AppStrategyState(
        symbol: 'BTCUSDC',
        status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
        openTrades: [
          FifoAppTrade(
            price: Decimal.parse('50000.0'),
            quantity: Decimal.parse('0.002'),
            timestamp: DateTime.now().millisecondsSinceEpoch,
            roundId: 1,
          ),
        ],
      );
    });

    group('Sistema di Priorità delle Decisioni', () {
      test('dovrebbe dare priorità massima alla vendita (TP)', () {
        // Prezzo sopra il take profit
        final currentPrice = 51000.0; // +2% sopra 50000

        final decision = tradeEvaluator.evaluateTradingDecisions(
          currentPrice: currentPrice,
          state: positionOpenState,
          settings: testSettings,
          allowInitialBuy: false,
        );

        expect(decision, isNotNull);
        expect(decision!.action, equals(TradingAction.sell));
        expect(decision.priority, equals(TradingDecisionPriority.sell));
        expect(decision.reason, contains('Take Profit'));
      });

      test('dovrebbe dare priorità massima alla vendita (SL)', () {
        // Prezzo sotto lo stop loss
        final currentPrice = 47500.0; // -5% sotto 50000

        final decision = tradeEvaluator.evaluateTradingDecisions(
          currentPrice: currentPrice,
          state: positionOpenState,
          settings: testSettings,
          allowInitialBuy: false,
        );

        expect(decision, isNotNull);
        expect(decision!.action, equals(TradingAction.sell));
        expect(decision.priority, equals(TradingDecisionPriority.sell));
        expect(decision.reason, contains('Stop Loss'));
      });

      test('dovrebbe dare priorità media al DCA quando non c\'è vendita', () {
        // Prezzo sotto la soglia DCA ma sopra lo stop loss
        final currentPrice = 48500.0; // -3% sotto 50000 (soglia DCA)

        final decision = tradeEvaluator.evaluateTradingDecisions(
          currentPrice: currentPrice,
          state: positionOpenState,
          settings: testSettings,
          allowInitialBuy: false,
        );

        expect(decision, isNotNull);
        expect(decision!.action, equals(TradingAction.dcaBuy));
        expect(decision.priority, equals(TradingDecisionPriority.dca));
        expect(decision.reason, contains('DCA triggered'));
      });

      test('dovrebbe dare priorità minima all\'acquisto iniziale', () {
        // Condizioni per acquisto iniziale
        final decision = tradeEvaluator.evaluateTradingDecisions(
          currentPrice: 50000.0,
          state: initialState,
          settings: testSettings,
          allowInitialBuy: true,
        );

        expect(decision, isNotNull);
        expect(decision!.action, equals(TradingAction.initialBuy));
        expect(decision.priority, equals(TradingDecisionPriority.initialBuy));
        expect(decision.reason, equals('Initial buy conditions met'));
      });

      test('dovrebbe restituire null quando nessuna azione è richiesta', () {
        // Prezzo normale, nessuna condizione soddisfatta
        final currentPrice = 50000.0;

        final decision = tradeEvaluator.evaluateTradingDecisions(
          currentPrice: currentPrice,
          state: positionOpenState,
          settings: testSettings,
          allowInitialBuy: false,
        );

        expect(decision, isNull);
      });
    });

    group('Prevenzione Decisioni Contraddittorie', () {
      test('dovrebbe prevenire DCA quando è richiesta vendita', () {
        // Prezzo sopra take profit E sotto soglia DCA
        final currentPrice = 51000.0; // +2% (TP) e -3% (DCA)

        final decision = tradeEvaluator.evaluateTradingDecisions(
          currentPrice: currentPrice,
          state: positionOpenState,
          settings: testSettings,
          allowInitialBuy: false,
        );

        // Dovrebbe eseguire solo la vendita, non il DCA
        expect(decision, isNotNull);
        expect(decision!.action, equals(TradingAction.sell));
        expect(decision.priority, equals(TradingDecisionPriority.sell));
      });

      test('dovrebbe prevenire acquisto iniziale quando è richiesta vendita',
          () {
        // Stato con trade aperti ma prezzo sopra TP
        final stateWithTrades = AppStrategyState(
          symbol: 'BTCUSDC',
          status: StrategyState.MONITORING_FOR_BUY, // Stato inconsistente
          openTrades: [
            FifoAppTrade(
              price: Decimal.parse('50000.0'),
              quantity: Decimal.parse('0.002'),
              timestamp: DateTime.now().millisecondsSinceEpoch,
              roundId: 1,
            ),
          ],
        );

        final currentPrice = 51000.0; // +2% sopra 50000

        final decision = tradeEvaluator.evaluateTradingDecisions(
          currentPrice: currentPrice,
          state: stateWithTrades,
          settings: testSettings,
          allowInitialBuy: true,
        );

        // Dovrebbe restituire null perché lo stato è inconsistente
        expect(decision, isNull);
      });
    });

    group('Validazione Input e Gestione Errori', () {
      test('dovrebbe gestire prezzi non validi', () {
        final decision = tradeEvaluator.evaluateTradingDecisions(
          currentPrice: double.nan,
          state: positionOpenState,
          settings: testSettings,
          allowInitialBuy: false,
        );

        expect(decision, isNull);
      });

      test('dovrebbe gestire prezzi negativi', () {
        final decision = tradeEvaluator.evaluateTradingDecisions(
          currentPrice: -100.0,
          state: positionOpenState,
          settings: testSettings,
          allowInitialBuy: false,
        );

        expect(decision, isNull);
      });

      test('dovrebbe gestire prezzi zero', () {
        final decision = tradeEvaluator.evaluateTradingDecisions(
          currentPrice: 0.0,
          state: positionOpenState,
          settings: testSettings,
          allowInitialBuy: false,
        );

        expect(decision, isNull);
      });
    });

    group('Performance e Scalabilità', () {
      test('dovrebbe gestire molti trade aperti senza degradazione', () {
        // Crea uno stato con molti trade aperti
        final manyTrades = List.generate(
            100,
            (index) => FifoAppTrade(
                  price: Decimal.parse((50000.0 + index * 10.0).toString()),
                  quantity: Decimal.parse('0.001'),
                  timestamp: DateTime.now().millisecondsSinceEpoch,
                  roundId: 1,
                ));

        final stateWithManyTrades = AppStrategyState(
          symbol: 'BTCUSDC',
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
          openTrades: manyTrades,
        );

        final stopwatch = Stopwatch()..start();

        final decision = tradeEvaluator.evaluateTradingDecisions(
          currentPrice: 52000.0,
          state: stateWithManyTrades,
          settings: testSettings,
          allowInitialBuy: false,
        );

        stopwatch.stop();

        // L'operazione dovrebbe completarsi in tempi ragionevoli (alzato limiti per CI)
        expect(stopwatch.elapsed.inMilliseconds, lessThan(100));
        expect(decision, isNotNull);
        expect(decision!.action, equals(TradingAction.sell));
      });
    });
  });
}
