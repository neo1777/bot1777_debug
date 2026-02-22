import 'package:neotradingbotback1777/domain/services/fee_calculation_service.dart';
import 'package:decimal/decimal.dart';
import 'package:neotradingbotback1777/domain/entities/fifo_app_trade.dart';
import 'package:test/test.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotback1777/domain/services/trade_evaluator_service.dart';
import '../../mocks/fee_repository_mock.dart';
import '../../mocks/trading_lock_manager_mock.dart';
import '../../mocks/business_metrics_monitor_mock.dart';
import '../../helpers/mockito_dummy_registrations.dart';

import 'package:neotradingbotback1777/core/logging/log_throttler.dart';
import 'package:neotradingbotback1777/core/errors/unified_error_handler.dart';

void main() {
  late TradeEvaluatorService service;
  late FakeTradingLockManager fakeTradingLockManager;
  const String symbol = 'BTCUSDC';

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
  });

  // Helper per creare uno stato di test con una posizione aperta
  AppStrategyState createStateWithOpenPosition({
    double averagePrice = 100.0,
    double quantity = 1.0,
    StrategyState status = StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
    List<FifoAppTrade>? openTrades,
  }) {
    final trades = openTrades ??
        [
          FifoAppTrade(
            price: Decimal.parse(averagePrice.toString()),
            quantity: Decimal.parse(quantity.toString()),
            timestamp: DateTime.now().millisecondsSinceEpoch,
            roundId: 1,
          )
        ];

    return AppStrategyState(
      symbol: symbol,
      status: status,
      openTrades: trades,
    );
  }

  // Helper per creare impostazioni di test
  AppSettings createAppSettings({
    double profitTargetPercentage = 5.0,
    double stopLossPercentage = 10.0,
    double dcaDecrementPercentage = 10.0,
    int maxOpenTrades = 5,
  }) {
    return AppSettings(
      tradeAmount: 100.0,
      profitTargetPercentage: profitTargetPercentage,
      stopLossPercentage: stopLossPercentage,
      dcaDecrementPercentage: dcaDecrementPercentage,
      maxOpenTrades: maxOpenTrades,
      isTestMode: true,
    );
  }

  group('TradeEvaluatorService Edge Cases Tests', () {
    group('Edge Cases - Prezzi Oscillanti alla Soglia', () {
      test(
          '[BACKEND-TEST-001] should handle price exactly at TP threshold without flip-flop',
          () {
        // ARRANGE
        final settings = createAppSettings(profitTargetPercentage: 5.0);
        final state = createStateWithOpenPosition(averagePrice: 100.0);

        // Test con prezzi esattamente alla soglia e leggermente sopra/sotto
        final testPrices = [104.99, 105.00, 105.01, 105.02];
        final expectedResults = [
          false,
          true,
          true,
          true
        ]; // TP attivato a 105.00

        // ACT & ASSERT
        for (int i = 0; i < testPrices.length; i++) {
          final result = service.shouldSell(
            currentPrice: testPrices[i],
            state: state,
            settings: settings,
          );
          expect(result, expectedResults[i],
              reason:
                  'Prezzo ${testPrices[i]} dovrebbe restituire ${expectedResults[i]}');
        }
      });

      test(
          '[BACKEND-TEST-001] should handle price exactly at SL threshold without flip-flop',
          () {
        // ARRANGE
        final settings = createAppSettings(stopLossPercentage: 10.0);
        final state = createStateWithOpenPosition(averagePrice: 100.0);

        // Test con prezzi esattamente alla soglia SL
        final testPrices = [90.01, 90.00, 89.99, 89.98];
        final expectedResults = [
          false,
          true,
          true,
          true
        ]; // SL attivato a 90.00

        // ACT & ASSERT
        for (int i = 0; i < testPrices.length; i++) {
          final result = service.shouldSell(
            currentPrice: testPrices[i],
            state: state,
            settings: settings,
          );
          expect(result, expectedResults[i],
              reason:
                  'Prezzo ${testPrices[i]} dovrebbe restituire ${expectedResults[i]}');
        }
      });

      test(
          '[BACKEND-TEST-001] should handle price exactly at DCA threshold without flip-flop',
          () {
        // ARRANGE
        final settings = createAppSettings(dcaDecrementPercentage: 10.0);
        final state = createStateWithOpenPosition(
          averagePrice: 100.0,
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
        );

        // Test con prezzi esattamente alla soglia DCA
        final testPrices = [90.01, 90.00, 89.99, 89.98];
        final expectedResults = [
          false,
          true,
          true,
          true
        ]; // DCA attivato a 90.00

        // ACT & ASSERT
        for (int i = 0; i < testPrices.length; i++) {
          final result = service.shouldDcaBuy(
            currentPrice: testPrices[i],
            state: state,
            settings: settings,
          );
          expect(result, expectedResults[i],
              reason:
                  'Prezzo ${testPrices[i]} dovrebbe restituire ${expectedResults[i]} per DCA');
        }
      });
    });

    group('Edge Cases - Parametri di Strategia Estremi', () {
      test(
          '[BACKEND-TEST-003] should handle extremely low profit target percentage',
          () {
        // ARRANGE
        final settings =
            createAppSettings(profitTargetPercentage: 0.01); // 0.01%
        final state = createStateWithOpenPosition(averagePrice: 100.0);

        // ACT & ASSERT
        // Per TP 0.01%, il prezzo deve essere 100.01 (0.01% sopra 100.00)
        expect(
            service.shouldSell(
              currentPrice: 100.01, // Prezzo che attiva 0.01% di profitto
              state: state,
              settings: settings,
            ),
            isTrue,
            reason: 'Dovrebbe attivare TP con 0.01% di profitto');
      });

      test(
          '[BACKEND-TEST-003] should handle extremely high stop loss percentage',
          () {
        // ARRANGE
        final settings = createAppSettings(stopLossPercentage: 99.9); // 99.9%
        final state = createStateWithOpenPosition(averagePrice: 100.0);

        // ACT & ASSERT
        expect(
            service.shouldSell(
              currentPrice: 0.1, // Prezzo molto basso
              state: state,
              settings: settings,
            ),
            isTrue,
            reason: 'Dovrebbe attivare SL con 99.9% di perdita');
      });

      test('[BACKEND-TEST-003] should handle extremely low DCA percentage', () {
        // ARRANGE
        final settings = createAppSettings(dcaDecrementPercentage: 0.1); // 0.1%
        final state = createStateWithOpenPosition(
          averagePrice: 100.0,
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
        );

        // ACT & ASSERT
        expect(
            service.shouldDcaBuy(
              currentPrice: 99.9, // Prezzo appena sotto la soglia
              state: state,
              settings: settings,
            ),
            isTrue,
            reason: 'Dovrebbe attivare DCA con 0.1% di decremento');
      });
    });

    group('Edge Cases - Quantità Minime e Massime', () {
      test('[BACKEND-TEST-004] should handle minimum quantity trades', () {
        // ARRANGE
        createAppSettings(maxOpenTrades: 1);
        final state = createStateWithOpenPosition(
          averagePrice: 100.0,
          quantity: 0.001, // Quantità minima BTC
        );

        // ACT & ASSERT
        expect(state.totalQuantity, equals(Decimal.parse('0.001')),
            reason: 'Dovrebbe gestire quantità minime correttamente');
        expect(state.totalInvested, 0.1,
            reason: 'Investimento totale dovrebbe essere 0.1 USDC');
      });

      test('[BACKEND-TEST-004] should handle maximum open trades limit', () {
        // ARRANGE
        final settings = createAppSettings(maxOpenTrades: 3);
        final trades = List.generate(
            3,
            (index) => FifoAppTrade(
                  price: Decimal.parse((100.0 + index).toString()),
                  quantity: Decimal.parse('1.0'),
                  timestamp: DateTime.now().millisecondsSinceEpoch,
                  roundId: index + 1,
                ));

        final state = AppStrategyState(
          symbol: symbol,
          status: StrategyState.MONITORING_FOR_BUY,
          openTrades: trades,
        );

        // ACT & ASSERT
        expect(
            service.shouldBuyNonInitial(
              currentPrice: 95.0,
              state: state,
              settings: settings,
            ),
            isFalse,
            reason: 'Dovrebbe rifiutare acquisti al limite maxOpenTrades');
      });
    });
  });
}

