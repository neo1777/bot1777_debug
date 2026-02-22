import 'package:neotradingbotback1777/core/locks/trading_lock_manager.dart';
import 'package:neotradingbotback1777/core/logging/log_throttler.dart';
import 'package:neotradingbotback1777/core/errors/unified_error_handler.dart';
import 'package:decimal/decimal.dart';
import 'package:neotradingbotback1777/domain/services/fee_calculation_service.dart';
import 'package:test/test.dart';
import 'package:neotradingbotback1777/domain/services/trade_evaluator_service.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/entities/fifo_app_trade.dart';
import 'package:neotradingbotback1777/domain/entities/strategy_state.dart';
import '../../mocks/fee_repository_mock.dart';
import '../../mocks/business_metrics_monitor_mock.dart';

/// Un'implementazione "Fake" di TradingLockManager per i test.
/// Esegue semplicemente l'operazione senza alcuna logica di lock.
class FakeTradingLockManager implements TradingLockManager {
  @override
  Future<T> executeTradingOperation<T>(
    String symbol,
    Future<T> Function() operation, {
    bool checkCooldown = true,
  }) async {
    return await operation();
  }

  // Implementa gli altri metodi con un comportamento vuoto o di default se necessario.
  @override
  Future<T> executeTradingOperationSync<T>(
      String symbol, T Function() operation,
      {bool checkCooldown = true}) {
    throw UnimplementedError();
  }

  @override
  void cleanupOldOperationTimes() {}

  @override
  TradingLockStats getStats() {
    throw UnimplementedError();
  }

  @override
  Duration? getTimeUntilNextOperation(String symbol) {
    return null;
  }
}

void main() {
  late TradeEvaluatorService service;
  late FakeTradingLockManager fakeTradingLockManager;
  const String symbol = 'BTCUSDC';

  setUp(() {
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

  // Helper per creare stato di test
  AppStrategyState createStateWithOpenPosition({
    double averagePrice = 100.0,
    double quantity = 1.0,
    StrategyState status = StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
  }) {
    final trades = [
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

  // Helper per creare impostazioni
  AppSettings createAppSettings({
    double profitTargetPercentage = 5.0,
    double stopLossPercentage = 10.0,
  }) {
    return AppSettings(
      tradeAmount: 100.0,
      profitTargetPercentage: profitTargetPercentage,
      stopLossPercentage: stopLossPercentage,
      dcaDecrementPercentage: 10.0,
      maxOpenTrades: 5,
      isTestMode: true,
    );
  }

  group('[BACKEND-TEST-001] Gestione Prezzi Oscillanti alla Soglia', () {
    test('should handle price oscillation at TP threshold without flip-flop',
        () {
      // ARRANGE
      final settings = createAppSettings(profitTargetPercentage: 5.0);
      final state = createStateWithOpenPosition(averagePrice: 100.0);

      // Sequenza di prezzi che oscilla intorno alla soglia TP
      final testPrices = [
        104.99,
        105.00,
        105.01,
        105.02,
        105.01,
        105.00,
        104.99
      ];
      final expectedResults = [false, true, true, true, true, true, false];

      // ACT & ASSERT
      for (int i = 0; i < testPrices.length; i++) {
        final result = service.shouldSell(
          currentPrice: testPrices[i],
          state: state,
          settings: settings,
        );

        expect(result, expectedResults[i],
            reason:
                'Prezzo ${testPrices[i]} dovrebbe restituire ${expectedResults[i]} per TP 5%');
      }
    });

    test('should handle price oscillation at SL threshold without flip-flop',
        () {
      // ARRANGE
      final settings = createAppSettings(stopLossPercentage: 10.0);
      final state = createStateWithOpenPosition(averagePrice: 100.0);

      // Sequenza di prezzi che oscilla intorno alla soglia SL
      final testPrices = [90.01, 90.00, 89.99, 89.98, 89.99, 90.00, 90.01];
      final expectedResults = [false, true, true, true, true, true, false];

      // ACT & ASSERT
      for (int i = 0; i < testPrices.length; i++) {
        final result = service.shouldSell(
          currentPrice: testPrices[i],
          state: state,
          settings: settings,
        );

        expect(result, expectedResults[i],
            reason:
                'Prezzo ${testPrices[i]} dovrebbe restituire ${expectedResults[i]} per SL 10%');
      }
    });

    test('should handle rapid price changes around thresholds', () {
      // ARRANGE
      final settings = createAppSettings(
        profitTargetPercentage: 2.0,
        stopLossPercentage: 5.0,
      );
      final state = createStateWithOpenPosition(averagePrice: 100.0);

      // Simulazione cambi di prezzo rapidi (alta volatilità)
      final rapidPriceChanges = [
        97.99, 98.00, 98.01, // Vicino SL
        99.99, 100.00, 100.01, // Vicino prezzo medio
        101.99, 102.00, 102.01, // Vicino TP
      ];

      // ACT & ASSERT
      for (final price in rapidPriceChanges) {
        final result = service.shouldSell(
          currentPrice: price,
          state: state,
          settings: settings,
        );

        // Verifica che non ci siano flip-flop inaspettati
        if (price <= 95.0) {
          expect(result, isTrue, reason: 'SL dovrebbe attivarsi a $price');
        } else if (price >= 102.0) {
          expect(result, isTrue, reason: 'TP dovrebbe attivarsi a $price');
        } else {
          expect(result, isFalse,
              reason: 'Nessuna condizione di vendita a $price');
        }
      }
    });

    test('should handle extreme precision thresholds without oscillation', () {
      // ARRANGE - Test con soglie molto precise (0.01%)
      final settings = createAppSettings(
        profitTargetPercentage: 0.01,
        stopLossPercentage: 0.01,
      );
      final state = createStateWithOpenPosition(averagePrice: 100.0);

      // Prezzi con precisione estrema
      final precisePrices = [
        99.9999,
        100.0000,
        100.0001,
        100.0099,
        100.0100,
        100.0101,
        99.9899,
        99.9900,
        99.9901
      ];

      // ACT & ASSERT
      for (final price in precisePrices) {
        final result = service.shouldSell(
          currentPrice: price,
          state: state,
          settings: settings,
        );

        // Verifica comportamento deterministico
        if (price >= 100.01) {
          expect(result, isTrue,
              reason: 'TP dovrebbe attivarsi a $price per soglia 0.01%');
        } else if (price <= 99.99) {
          expect(result, isTrue,
              reason: 'SL dovrebbe attivarsi a $price per soglia 0.01%');
        } else {
          expect(result, isFalse,
              reason: 'Nessuna condizione di vendita a $price');
        }
      }
    });

    test('should maintain consistency across multiple price evaluations', () {
      // ARRANGE
      final settings = createAppSettings(profitTargetPercentage: 3.0);
      final state = createStateWithOpenPosition(averagePrice: 100.0);

      // Simula valutazioni multiple dello stesso prezzo
      const testPrice = 103.0; // Esattamente alla soglia TP
      const iterations = 100;

      // ACT & ASSERT
      for (int i = 0; i < iterations; i++) {
        final result = service.shouldSell(
          currentPrice: testPrice,
          state: state,
          settings: settings,
        );

        // Il risultato deve essere sempre lo stesso per lo stesso input
        expect(result, isTrue,
            reason: 'Iterazione $i: TP dovrebbe sempre attivarsi a $testPrice');
      }
    });
  });
}
