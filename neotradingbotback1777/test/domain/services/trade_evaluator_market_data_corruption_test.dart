import 'package:neotradingbotback1777/domain/services/fee_calculation_service.dart';
import 'package:decimal/decimal.dart';
import 'package:test/test.dart';
import 'package:neotradingbotback1777/domain/services/trade_evaluator_service.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/entities/fifo_app_trade.dart';
import 'package:neotradingbotback1777/domain/entities/strategy_state.dart';
import '../../mocks/fee_repository_mock.dart';
import '../../mocks/trading_lock_manager_mock.dart';
import '../../mocks/business_metrics_monitor_mock.dart';
import 'dart:math';
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

  group('[BACKEND-TEST-005] Gestione Dati di Mercato Corrotti', () {
    group('Validazione Prezzi di Mercato', () {
      test('should handle corrupted market price data gracefully', () {
        // ARRANGE
        final settings = createAppSettings();
        final state = createStateWithOpenPosition(averagePrice: 100.0);

        // Prezzi di mercato corrotti che potrebbero arrivare da feed esterni
        final corruptedPrices = [
          double.nan,
          double.infinity,
          -1.0,
          0.0,
          double.maxFinite,
          double.minPositive,
          1e308,
          1e-308,
        ];

        // ACT & ASSERT
        for (final price in corruptedPrices) {
          expect(
            () => service.shouldSell(
              currentPrice: price,
              state: state,
              settings: settings,
            ),
            returnsNormally,
            reason: 'Dovrebbe gestire prezzo corrotto $price senza crashare',
          );

          final result = service.shouldSell(
            currentPrice: price,
            state: state,
            settings: settings,
          );

          // Tutti i prezzi corrotti dovrebbero restituire false
          expect(result, isFalse,
              reason: 'Prezzo corrotto $price dovrebbe restituire false');
        }
      });

      test('should handle mixed valid and corrupted market data', () {
        // ARRANGE
        final settings = createAppSettings();
        final state = createStateWithOpenPosition(averagePrice: 100.0);

        // Mix di prezzi validi e corrotti
        final mixedPrices = [
          95.0, // Prezzo valido sotto SL
          double.nan, // Prezzo corrotto
          105.0, // Prezzo valido sopra TP
          double.infinity, // Prezzo corrotto
          100.0, // Prezzo valido al prezzo medio
          -1.0, // Prezzo corrotto
        ];

        // ACT & ASSERT
        int validResults = 0;
        int corruptedResults = 0;

        for (final price in mixedPrices) {
          final result = service.shouldSell(
            currentPrice: price,
            state: state,
            settings: settings,
          );

          if (price.isFinite && price > 0) {
            validResults++;
            // I prezzi validi dovrebbero restituire risultati logici
            if (price <= 90.0 || price >= 105.0) {
              expect(result, isTrue,
                  reason: 'Prezzo valido $price dovrebbe attivare vendita');
            } else {
              expect(result, isFalse,
                  reason: 'Prezzo valido $price non dovrebbe attivare vendita');
            }
          } else {
            corruptedResults++;
            expect(result, isFalse,
                reason: 'Prezzo corrotto $price dovrebbe restituire false');
          }
        }

        expect(validResults, greaterThan(0),
            reason: 'Dovrebbe processare alcuni prezzi validi');
        expect(corruptedResults, greaterThan(0),
            reason: 'Dovrebbe processare alcuni prezzi corrotti');
      });
    });

    group('Test di Stress con Dati Corrotti', () {
      test(
          'should handle high-frequency corrupted market data without crashing',
          () {
        // ARRANGE
        final settings = createAppSettings();
        final state = createStateWithOpenPosition(averagePrice: 100.0);

        // Genera array di prezzi con corruzione intermittente
        final random = Random(42); // Seed fisso per test deterministico
        final stressTestPrices = List.generate(1000, (index) {
          if (random.nextDouble() < 0.15) {
            // 15% di dati corrotti
            return [double.nan, double.infinity, -1.0, 0.0][random.nextInt(4)];
          }
          return 90.0 + random.nextDouble() * 20.0; // Prezzi validi tra 90-110
        });

        // ACT & ASSERT
        int validResults = 0;
        int corruptedResults = 0;
        int totalEvaluations = 0;

        for (final price in stressTestPrices) {
          expect(
            () {
              final result = service.shouldSell(
                currentPrice: price,
                state: state,
                settings: settings,
              );

              totalEvaluations++;

              if (price.isFinite && price > 0) {
                validResults++;
                expect(result, isA<bool>(),
                    reason: 'Prezzo valido $price dovrebbe restituire bool');
              } else {
                corruptedResults++;
                expect(result, isFalse,
                    reason: 'Prezzo corrotto $price dovrebbe restituire false');
              }
            },
            returnsNormally,
            reason: 'Dovrebbe gestire prezzo $price senza crashare',
          );
        }

        // Verifica statistiche finali
        expect(totalEvaluations, equals(1000));
        expect(validResults, greaterThan(800)); // Almeno 80% di prezzi validi
        expect(corruptedResults,
            greaterThan(100)); // Almeno 10% di prezzi corrotti
        expect(validResults + corruptedResults, equals(1000));
      });

      test('should maintain performance under corrupted data load', () {
        // ARRANGE
        final settings = createAppSettings();
        final state = createStateWithOpenPosition(averagePrice: 100.0);

        // Test di performance con 10000 valutazioni
        const iterations = 10000;
        final startTime = DateTime.now();

        // ACT
        for (int i = 0; i < iterations; i++) {
          final price =
              i % 10 == 0 ? double.nan : 95.0 + (i % 20); // 10% di corruzione

          expect(
            () => service.shouldSell(
              currentPrice: price,
              state: state,
              settings: settings,
            ),
            returnsNormally,
            reason:
                'Iterazione $i: dovrebbe gestire prezzo $price senza crashare',
          );
        }

        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        // ASSERT - Verifica che le performance siano accettabili
        expect(duration.inMilliseconds, lessThan(5000),
            reason:
                '10000 valutazioni dovrebbero completarsi in meno di 5 secondi');
      });
    });

    group('Validazione Robustezza Calcoli', () {
      test('should handle edge case calculations with corrupted data', () {
        // ARRANGE
        final settings = createAppSettings(
          profitTargetPercentage: 0.01, // Soglia molto bassa
          stopLossPercentage: 0.01,
        );
        final state = createStateWithOpenPosition(averagePrice: 100.0);

        // Prezzi molto vicini alle soglie con alcuni corrotti
        final edgeCasePrices = [
          99.99, 100.00, 100.01, // Vicino al prezzo medio
          99.9899, 99.9900, 99.9901, // Vicino alla soglia SL
          100.0099, 100.0100, 100.0101, // Vicino alla soglia TP
          double.nan, // Prezzo corrotto
          99.99, 100.00, 100.01, // Prezzi validi dopo corruzione
        ];

        // ACT & ASSERT
        for (final price in edgeCasePrices) {
          expect(
            () => service.shouldSell(
              currentPrice: price,
              state: state,
              settings: settings,
            ),
            returnsNormally,
            reason: 'Dovrebbe gestire prezzo edge case $price senza crashare',
          );

          final result = service.shouldSell(
            currentPrice: price,
            state: state,
            settings: settings,
          );

          if (price.isFinite && price > 0 /* && price != double.maxFinite */) {
            // maxFinite is technically finite but causes issues
            // Fix: double.maxFinite is considered "Finite" in Dart but may break Decimal conversion or logic
            if (price == double.maxFinite) {
              expect(result, isFalse);
            } else {
              expect(result, isA<bool>(),
                  reason: 'Prezzo edge case $price dovrebbe restituire bool');
            }
          } else {
            expect(result, isFalse,
                reason: 'Prezzo corrotto $price dovrebbe restituire false');
          }
        }
      });

      test('should handle mathematical operations with corrupted values', () {
        // ARRANGE
        final settings = createAppSettings();
        final state = createStateWithOpenPosition(averagePrice: 100.0);

        // Test con valori che potrebbero causare problemi matematici
        final mathematicalTestPrices = [
          double.maxFinite, // Valore molto grande
          double.minPositive, // Valore molto piccolo
          1e-15, // Valore estremamente piccolo
          1e15, // Valore estremamente grande
          double.nan, // Not a Number
          double.infinity, // Infinito
          -double.infinity, // Infinito negativo
        ];

        // ACT & ASSERT
        for (final price in mathematicalTestPrices) {
          expect(
            () => service.shouldSell(
              currentPrice: price,
              state: state,
              settings: settings,
            ),
            returnsNormally,
            reason:
                'Dovrebbe gestire operazioni matematiche con prezzo $price senza crashare',
          );

          final result = service.shouldSell(
            currentPrice: price,
            state: state,
            settings: settings,
          );

          // Tutti i valori problematici dovrebbero restituire false
          expect(result, isFalse,
              reason: 'Prezzo problematico $price dovrebbe restituire false');
        }
      });
    });

    group('Recovery da Stati Corrotti', () {
      test('should recover gracefully after processing corrupted data', () {
        // ARRANGE
        final settings = createAppSettings();
        final state = createStateWithOpenPosition(averagePrice: 100.0);

        // Sequenza: dati corrotti seguiti da dati validi
        final recoverySequence = [
          double.nan, // Dato corrotto
          double.infinity, // Dato corrotto
          -1.0, // Dato corrotto
          95.0, // Dato valido sotto SL
          100.0, // Dato valido al prezzo medio
          105.0, // Dato valido sopra TP
        ];

        // ACT & ASSERT
        for (int i = 0; i < recoverySequence.length; i++) {
          final price = recoverySequence[i];

          expect(
            () => service.shouldSell(
              currentPrice: price,
              state: state,
              settings: settings,
            ),
            returnsNormally,
            reason:
                'Iterazione $i: dovrebbe gestire prezzo $price senza crashare',
          );

          final result = service.shouldSell(
            currentPrice: price,
            state: state,
            settings: settings,
          );

          if (price.isFinite && price > 0) {
            // I dati validi dovrebbero funzionare normalmente dopo i dati corrotti
            if (price <= 90.0 || price >= 105.0) {
              expect(result, isTrue,
                  reason:
                      'Prezzo valido $price dovrebbe attivare vendita dopo recovery');
            } else {
              expect(result, isFalse,
                  reason:
                      'Prezzo valido $price non dovrebbe attivare vendita dopo recovery');
            }
          } else {
            expect(result, isFalse,
                reason: 'Prezzo corrotto $price dovrebbe restituire false');
          }
        }
      });

      test('should maintain deterministic behavior after corruption', () {
        // ARRANGE
        final settings = createAppSettings();
        final state = createStateWithOpenPosition(averagePrice: 100.0);

        // Test con prezzo valido prima e dopo corruzione
        const validPrice = 105.0; // Prezzo sopra TP

        // ACT & ASSERT
        // Prima valutazione (pulita)
        final firstResult = service.shouldSell(
          currentPrice: validPrice,
          state: state,
          settings: settings,
        );
        expect(firstResult, isTrue,
            reason: 'Prima valutazione dovrebbe attivare vendita');

        // Valutazione con dati corrotti
        final corruptedResult = service.shouldSell(
          currentPrice: double.nan,
          state: state,
          settings: settings,
        );
        expect(corruptedResult, isFalse,
            reason: 'Dato corrotto dovrebbe restituire false');

        // Seconda valutazione (pulita) - dovrebbe essere identica alla prima
        final secondResult = service.shouldSell(
          currentPrice: validPrice,
          state: state,
          settings: settings,
        );
        expect(secondResult, isTrue,
            reason: 'Seconda valutazione dovrebbe attivare vendita');
        expect(secondResult, equals(firstResult),
            reason: 'Risultati dovrebbero essere identici dopo corruzione');
      });
    });
  });
}
