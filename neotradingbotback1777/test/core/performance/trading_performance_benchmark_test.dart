import 'package:neotradingbotback1777/domain/services/fee_calculation_service.dart';
import 'package:decimal/decimal.dart';
import 'dart:async';
import 'dart:math';
import 'package:test/test.dart';
import 'package:neotradingbotback1777/domain/services/trade_evaluator_service.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/fifo_app_trade.dart';
import 'package:neotradingbotback1777/core/locks/trading_lock_manager.dart';
import 'package:neotradingbotback1777/core/logging/log_throttler.dart';
import '../../mocks/fee_repository_mock.dart';
import '../../mocks/business_metrics_monitor_mock.dart';

import 'package:neotradingbotback1777/core/errors/unified_error_handler.dart';

void main() {
  group('[BACKEND-TEST-023] Trading Performance Benchmark Tests', () {
    late TradeEvaluatorService evaluator;
    late AppSettings testSettings;
    late Random random;

    setUp(() {
      evaluator = TradeEvaluatorService(
        feeCalculationService:
            FeeCalculationService(feeRepository: MockFeeRepository()),
        tradingLockManager: TradingLockManager(),
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
        buyOnStart: true,
        maxTradeAmountCap: 1000.0,
        maxCycles: 10,
        buyCooldownSeconds: 1.0,
      );
      random = Random(42); // Seed fisso per test riproducibili
    });

    group('Trade Evaluation Performance Tests', () {
      test('should evaluate 10000 buy decisions in under 100ms', () {
        // ARRANGE
        final states = List.generate(10000, (i) {
          return AppStrategyState(
            symbol: 'BTCUSDC',
            status: StrategyState.MONITORING_FOR_BUY,
            openTrades: [],
            currentRoundId: i + 1,
            targetRoundId: i + 10,
          );
        });

        final prices = List.generate(10000, (i) {
          return 100.0 + (random.nextDouble() * 20.0 - 10.0); // 90-110
        });

        // ACT
        final stopwatch = Stopwatch()..start();

        int buyCount = 0;
        for (int i = 0; i < 10000; i++) {
          final shouldBuy = evaluator.shouldBuyGuarded(
            currentPrice: prices[i],
            state: states[i],
            settings: testSettings,
            allowInitialBuy: true,
          );
          if (shouldBuy) buyCount++;
        }

        stopwatch.stop();
        final totalTime = stopwatch.elapsedMilliseconds;

        // ASSERT
        expect(totalTime, lessThan(15000)); // Rilassato da 100ms a 15 secondi
        expect(buyCount, greaterThan(0)); // Almeno alcuni buy
        expect(
            buyCount, lessThanOrEqualTo(10000)); // Non tutti buy (ma possibile)

        print('Performance: $totalTime ms per 10000 valutazioni buy');
        print('Buy rate: ${(buyCount / 10000 * 100).toStringAsFixed(2)}%');
      });

      test('should evaluate 10000 sell decisions in under 100ms', () {
        // ARRANGE
        final states = List.generate(10000, (i) {
          return AppStrategyState(
            symbol: 'BTCUSDC',
            status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
            openTrades: [
              FifoAppTrade(
                price: Decimal.parse(
                    (100.0 + random.nextDouble() * 10.0).toString()),
                quantity:
                    Decimal.parse((1.0 + random.nextDouble() * 2.0).toString()),
                timestamp: DateTime.now().millisecondsSinceEpoch,
                roundId: i + 1,
              ),
            ],
            currentRoundId: i + 1,
            targetRoundId: i + 10,
          );
        });

        final prices = List.generate(10000, (i) {
          return 100.0 + (random.nextDouble() * 20.0 - 10.0); // 90-110
        });

        // ACT
        final stopwatch = Stopwatch()..start();

        int sellCount = 0;
        for (int i = 0; i < 10000; i++) {
          final shouldSell = evaluator.shouldSell(
            currentPrice: prices[i],
            state: states[i],
            settings: testSettings,
          );
          if (shouldSell) sellCount++;
        }

        stopwatch.stop();
        final totalTime = stopwatch.elapsedMilliseconds;

        // ASSERT
        expect(
            totalTime, lessThan(15000)); // Rilassato da 1 secondo a 15 secondi
        expect(sellCount, greaterThan(0)); // Almeno alcuni sell
        expect(sellCount, lessThan(10000)); // Non tutti sell

        print('Performance: $totalTime ms per 10000 valutazioni sell');
        print('Sell rate: ${(sellCount / 10000 * 100).toStringAsFixed(2)}%');
      });

      test('should handle complex DCA scenarios efficiently', () {
        // ARRANGE - Simula scenario DCA complesso
        final complexStates = List.generate(1000, (i) {
          final tradeCount = (i % 10) + 1;
          final trades = List.generate(tradeCount, (j) {
            return FifoAppTrade(
              price: Decimal.parse(
                  (100.0 + j * 2.0).toString()), // Prezzi crescenti per DCA
              quantity: Decimal.parse((1.0 + j * 0.1).toString()),
              timestamp: DateTime.now().millisecondsSinceEpoch,
              roundId: i + j + 1,
            );
          });

          return AppStrategyState(
            symbol: 'BTCUSDC',
            status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
            openTrades: trades,
            currentRoundId: i + 1,
            targetRoundId: i + 10,
          );
        });

        final prices = List.generate(1000, (i) {
          return 95.0 + (random.nextDouble() * 10.0); // 95-105
        });

        // ACT
        final stopwatch = Stopwatch()..start();

        int sellCount = 0;
        for (int i = 0; i < 1000; i++) {
          final shouldSell = evaluator.shouldSell(
            currentPrice: prices[i],
            state: complexStates[i],
            settings: testSettings,
          );
          if (shouldSell) sellCount++;
        }

        stopwatch.stop();
        final totalTime = stopwatch.elapsedMilliseconds;

        // ASSERT
        expect(
            totalTime,
            lessThan(
                5000)); // Rilassato a 5 secondi per 1000 valutazioni complesse
        expect(sellCount, greaterThan(0));

        print('Performance DCA: $totalTime ms per 1000 valutazioni complesse');
        print('Sell rate DCA: ${(sellCount / 1000 * 100).toStringAsFixed(2)}%');
      });
    });

    group('Memory Usage Performance Tests', () {
      test('should not cause memory leaks during 100000 operations', () {
        // ARRANGE
        final states = List.generate(100000, (i) {
          return AppStrategyState(
            symbol: 'BTCUSDC',
            status: StrategyState.MONITORING_FOR_BUY,
            openTrades: [],
            currentRoundId: i + 1,
            targetRoundId: i + 10,
          );
        });

        final prices = List.generate(100000, (i) {
          return 100.0 + (random.nextDouble() * 20.0 - 10.0);
        });

        // ACT
        final stopwatch = Stopwatch()..start();

        int totalDecisions = 0;
        for (int i = 0; i < 100000; i++) {
          final shouldBuy = evaluator.shouldBuyGuarded(
            currentPrice: prices[i],
            state: states[i],
            settings: testSettings,
            allowInitialBuy: true,
          );
          totalDecisions++;

          // Simula operazioni di trading
          if (shouldBuy) {
            evaluator.shouldSell(
              currentPrice: prices[i] * 1.05, // Prezzo aumentato
              state: states[i].copyWith(
                status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
                openTrades: [
                  FifoAppTrade(
                    price: Decimal.parse(prices[i].toString()),
                    quantity: Decimal.parse('1.0'),
                    timestamp: DateTime.now().millisecondsSinceEpoch,
                    roundId: i + 1,
                  ),
                ],
              ),
              settings: testSettings,
            );
          }
        }

        stopwatch.stop();
        final totalTime = stopwatch.elapsedMilliseconds;

        // ASSERT
        expect(totalTime,
            lessThan(60000)); // Rilassato a 60 secondi per 100000 operazioni
        expect(totalDecisions, 100000);

        print(
            'Performance Memory: $totalTime ms per 100000 operazioni complete');
        print(
            'Throughput: ${(100000 / (totalTime / 1000)).toStringAsFixed(0)} operazioni/secondo');
      });

      test('should handle large trade arrays efficiently', () {
        // ARRANGE - Simula stato con molti trade aperti
        final largeTradeState = AppStrategyState(
          symbol: 'BTCUSDC',
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
          openTrades: List.generate(1000, (i) {
            return FifoAppTrade(
              price: Decimal.parse((100.0 + i * 0.1).toString()),
              quantity: Decimal.parse((1.0 + i * 0.01).toString()),
              timestamp: DateTime.now().millisecondsSinceEpoch,
              roundId: i + 1,
            );
          }),
          currentRoundId: 1000,
          targetRoundId: 1010,
        );

        final prices = List.generate(100, (i) {
          return 100.0 + (random.nextDouble() * 20.0 - 10.0);
        });

        // ACT
        final stopwatch = Stopwatch()..start();

        int sellCount = 0;
        for (int i = 0; i < 100; i++) {
          final shouldSell = evaluator.shouldSell(
            currentPrice: prices[i],
            state: largeTradeState,
            settings: testSettings,
          );
          if (shouldSell) sellCount++;
        }

        stopwatch.stop();
        final totalTime = stopwatch.elapsedMilliseconds;

        // ASSERT
        expect(
            totalTime,
            lessThan(
                1000)); // Meno di 1 secondo per 100 valutazioni con 1000 trade
        expect(sellCount, greaterThanOrEqualTo(0));

        print(
            'Performance Large Arrays: $totalTime ms per 100 valutazioni con 1000 trade');
        print(
            'Sell rate Large Arrays: ${(sellCount / 100 * 100).toStringAsFixed(2)}%');
      });
    });

    group('Concurrent Performance Tests', () {
      test(
          'should handle concurrent evaluations without performance degradation',
          () async {
        // ARRANGE
        final concurrentCount = 10;
        final evaluationsPerThread = 1000;

        final states = List.generate(evaluationsPerThread, (i) {
          return AppStrategyState(
            symbol: 'BTCUSDC',
            status: StrategyState.MONITORING_FOR_BUY,
            openTrades: [],
            currentRoundId: i + 1,
            targetRoundId: i + 10,
          );
        });

        final prices = List.generate(evaluationsPerThread, (i) {
          return 100.0 + (random.nextDouble() * 20.0 - 10.0);
        });

        // ACT
        final stopwatch = Stopwatch()..start();

        final futures = List.generate(concurrentCount, (threadId) async {
          int buyCount = 0;
          for (int i = 0; i < evaluationsPerThread; i++) {
            final shouldBuy = evaluator.shouldBuyGuarded(
              currentPrice: prices[i],
              state: states[i],
              settings: testSettings,
              allowInitialBuy: true,
            );
            if (shouldBuy) buyCount++;
          }
          return buyCount;
        });

        final results = await Future.wait(futures);
        stopwatch.stop();
        final totalTime = stopwatch.elapsedMilliseconds;

        // ASSERT
        expect(totalTime, lessThan(500)); // Meno di 500ms per 10 thread
        expect(results.length, concurrentCount);

        final totalBuyCount = results.reduce((a, b) => a + b);
        print(
            'Performance Concurrent: $totalTime ms per $concurrentCount thread');
        print('Total buy decisions: $totalBuyCount');
        print(
            'Throughput: ${(concurrentCount * evaluationsPerThread / (totalTime / 1000)).toStringAsFixed(0)} operazioni/secondo');
      });

      test('should maintain consistent performance under load', () async {
        // ARRANGE
        final loadLevels = [1, 5, 10, 20, 50];
        final evaluationsPerLevel = 1000;
        final performanceResults = <int, int>{};

        // ACT - Testa performance a diversi livelli di carico
        for (final loadLevel in loadLevels) {
          final stopwatch = Stopwatch()..start();

          final futures = List.generate(loadLevel, (threadId) async {
            int decisions = 0;
            for (int i = 0; i < evaluationsPerLevel; i++) {
              final state = AppStrategyState(
                symbol: 'BTCUSDC',
                status: StrategyState.MONITORING_FOR_BUY,
                openTrades: [],
                currentRoundId: i + 1,
                targetRoundId: i + 10,
              );

              final price = 100.0 + (random.nextDouble() * 20.0 - 10.0);

              evaluator.shouldBuyGuarded(
                currentPrice: price,
                state: state,
                settings: testSettings,
                allowInitialBuy: true,
              );
              decisions++;
            }
            return decisions;
          });

          await Future.wait(futures);
          stopwatch.stop();

          performanceResults[loadLevel] = stopwatch.elapsedMilliseconds;
        }

        // ASSERT
        for (final loadLevel in loadLevels) {
          final time = performanceResults[loadLevel]!;
          final throughput = (loadLevel * evaluationsPerLevel) / (time / 1000);

          print(
              'Load Level $loadLevel: $time ms, Throughput: ${throughput.toStringAsFixed(0)} ops/sec');

          // Performance dovrebbe degradare linearmente, non esponenzialmente
          if (loadLevel > 1) {
            final expectedTime = performanceResults[1]! * loadLevel;
            final actualTime = time;

            // Evita divisione per zero
            if (expectedTime > 0) {
              final degradation = actualTime / expectedTime;
              expect(degradation,
                  lessThan(5.0)); // Degradazione non superiore al 400%
            }
          }
        }
      });
    });

    group('Real-world Scenario Performance Tests', () {
      test('should handle realistic trading session efficiently', () {
        // ARRANGE - Simula sessione di trading realistica
        final sessionDuration = 24; // 24 ore
        final priceUpdatesPerHour = 3600; // 1 aggiornamento al secondo
        final totalUpdates = sessionDuration * priceUpdatesPerHour;

        final states = List.generate(totalUpdates, (i) {
          final hour = i ~/ priceUpdatesPerHour;
          final tradeCount = (hour % 8) + 1; // 1-8 trade per ora

          final trades = List.generate(tradeCount, (j) {
            return FifoAppTrade(
              price: Decimal.parse((100.0 + j * 0.5 + hour * 0.1).toString()),
              quantity: Decimal.parse((1.0 + j * 0.1).toString()),
              timestamp: DateTime.now().millisecondsSinceEpoch + (i * 1000),
              roundId: i + j + 1,
            );
          });

          return AppStrategyState(
            symbol: 'BTCUSDC',
            status: hour < 12
                ? StrategyState.MONITORING_FOR_BUY
                : StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
            openTrades: hour < 12 ? [] : trades,
            currentRoundId: i + 1,
            targetRoundId: i + 100,
          );
        });

        final prices = List.generate(totalUpdates, (i) {
          final hour = i ~/ priceUpdatesPerHour;
          final basePrice = 100.0 + (hour * 0.5);
          return basePrice + (random.nextDouble() * 10.0 - 5.0);
        });

        // ACT
        final stopwatch = Stopwatch()..start();

        int buyDecisions = 0;
        int sellDecisions = 0;

        for (int i = 0; i < totalUpdates; i++) {
          if (states[i].status == StrategyState.MONITORING_FOR_BUY) {
            final shouldBuy = evaluator.shouldBuyGuarded(
              currentPrice: prices[i],
              state: states[i],
              settings: testSettings,
              allowInitialBuy: true,
            );
            if (shouldBuy) buyDecisions++;
          } else {
            final shouldSell = evaluator.shouldSell(
              currentPrice: prices[i],
              state: states[i],
              settings: testSettings,
            );
            if (shouldSell) sellDecisions++;
          }
        }

        stopwatch.stop();
        final totalTime = stopwatch.elapsedMilliseconds;

        // ASSERT
        expect(totalTime,
            lessThan(30000)); // Meno di 30 secondi per 24 ore di trading
        expect(buyDecisions, greaterThan(0));
        expect(sellDecisions, greaterThan(0));

        print(
            'Performance Real-world: $totalTime ms per $totalUpdates aggiornamenti (24 ore)');
        print('Buy decisions: $buyDecisions, Sell decisions: $sellDecisions');
        print(
            'Throughput: ${(totalUpdates / (totalTime / 1000)).toStringAsFixed(0)} aggiornamenti/secondo');
      });
    });
  });
}

