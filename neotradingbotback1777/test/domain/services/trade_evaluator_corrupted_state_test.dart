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

import 'package:neotradingbotback1777/core/logging/log_throttler.dart';
import 'package:neotradingbotback1777/core/errors/unified_error_handler.dart';

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

  group('[BACKEND-TEST-002] Recovery da Stati Corrotti', () {
    group('Gestione Prezzi Invalidi', () {
      test('should handle NaN prices gracefully', () {
        // ARRANGE
        final settings = createAppSettings();
        final state = AppStrategyState(
          symbol: symbol,
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
          openTrades: [
            FifoAppTrade(
              price: Decimal.parse('100.0'),
              quantity: Decimal.parse('1.0'),
              timestamp: DateTime.now().millisecondsSinceEpoch,
              roundId: 1,
            )
          ],
        );

        // ACT & ASSERT
        final result = service.shouldSell(
            currentPrice: double.nan,
            state: state,
            settings: settings,
          );
          expect(result, isFalse, reason: 'Dovrebbe restituire false per prezzo non valido');
      });

      test('should handle infinite prices gracefully', () {
        // ARRANGE
        final settings = createAppSettings();
        final state = AppStrategyState(
          symbol: symbol,
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
          openTrades: [
            FifoAppTrade(
              price: Decimal.parse('100.0'),
              quantity: Decimal.parse('1.0'),
              timestamp: DateTime.now().millisecondsSinceEpoch,
              roundId: 1,
            )
          ],
        );

        // ACT & ASSERT
        final result = service.shouldSell(
            currentPrice: double.infinity,
            state: state,
            settings: settings,
          );
          expect(result, isFalse, reason: 'Dovrebbe restituire false per prezzo non valido');
      });

      test('should handle negative prices gracefully', () {
        // ARRANGE
        final settings = createAppSettings();
        final state = AppStrategyState(
          symbol: symbol,
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
          openTrades: [
            FifoAppTrade(
              price: Decimal.parse('100.0'),
              quantity: Decimal.parse('1.0'),
              timestamp: DateTime.now().millisecondsSinceEpoch,
              roundId: 1,
            )
          ],
        );

        // ACT & ASSERT
        final result = service.shouldSell(
            currentPrice: -50.0,
            state: state,
            settings: settings,
          );
          expect(result, isFalse, reason: 'Dovrebbe restituire false per prezzo non valido');
      });

      test('should handle zero prices gracefully', () {
        // ARRANGE
        final settings = createAppSettings();
        final state = AppStrategyState(
          symbol: symbol,
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
          openTrades: [
            FifoAppTrade(
              price: Decimal.parse('100.0'),
              quantity: Decimal.parse('1.0'),
              timestamp: DateTime.now().millisecondsSinceEpoch,
              roundId: 1,
            )
          ],
        );

        // ACT & ASSERT
        final result = service.shouldSell(
            currentPrice: 0.0,
            state: state,
            settings: settings,
          );
          expect(result, isFalse, reason: 'Dovrebbe restituire false per prezzo non valido');
      });
    });

    group('Gestione Stati Inconsistenti', () {
      test('should handle state with corrupted average price', () {
        // ARRANGE - Stato con prezzo medio corrotto
        final settings = createAppSettings();
        final corruptedState = AppStrategyState(
          symbol: symbol,
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
          openTrades: [
            FifoAppTrade(
              price: Decimal.parse(
                  '0'), // Was double.nan - Decimal doesn't support NaN // Prezzo corrotto
              quantity: Decimal.parse('1.0'),
              timestamp: DateTime.now().millisecondsSinceEpoch,
              roundId: 1,
            )
          ],
        );

        // ACT & ASSERT
        expect(
          () => service.shouldSell(
            currentPrice: 105.0,
            state: corruptedState,
            settings: settings,
          ),
          throwsA(isA<FormatException>()),
          reason: 'Stato corrotto dovrebbe lanciare FormatException',
        );
      });

      test('should handle state with corrupted quantity', () {
        // ARRANGE - Stato con quantità corrotte
        final settings = createAppSettings();
        final corruptedState = AppStrategyState(
          symbol: symbol,
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
          openTrades: [
            FifoAppTrade(
              price: Decimal.parse('100.0'),
              quantity: Decimal.parse(
                  '0'), // Was double.nan - Decimal doesn't support NaN // Quantità corrotta
              timestamp: DateTime.now().millisecondsSinceEpoch,
              roundId: 1,
            )
          ],
        );

        // ACT & ASSERT
        expect(
          () => service.shouldSell(
            currentPrice: 105.0,
            state: corruptedState,
            settings: settings,
          ),
          throwsA(isA<FormatException>()),
          reason: 'Quantità corrotte dovrebbero lanciare FormatException',
        );
      });

      test('should handle state with mixed corrupted and valid data', () {
        // ARRANGE - Stato con mix di dati validi e corrotti
        final settings = createAppSettings();
        final mixedState = AppStrategyState(
          symbol: symbol,
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
          openTrades: [
            FifoAppTrade(
              price: Decimal.parse('100.0'),
              quantity: Decimal.parse('1.0'),
              timestamp: DateTime.now().millisecondsSinceEpoch,
              roundId: 1,
            ),
            FifoAppTrade(
              price: Decimal.parse('0'), // Was double.nan // Trade corrotto
              quantity: Decimal.parse('999999999'), // Was double.infinity
              timestamp: DateTime.now().millisecondsSinceEpoch,
              roundId: 2,
            ),
          ],
        );

        // ACT & ASSERT
        expect(
          () => service.shouldSell(
            currentPrice: 105.0,
            state: mixedState,
            settings: settings,
          ),
          throwsA(isA<FormatException>()),
          reason:
              'Mix di dati validi e corrotti dovrebbe lanciare FormatException',
        );
      });
    });

    group('Gestione Parametri di Strategia Corrotti', () {
      test('should handle corrupted profit target percentage', () {
        // ARRANGE - Impostazioni con percentuale TP corrotta
        final corruptedSettings = AppSettings(
          tradeAmount: 100.0,
          profitTargetPercentage: double.nan,
          stopLossPercentage: 10.0,
          dcaDecrementPercentage: 10.0,
          maxOpenTrades: 5,
          isTestMode: true,
        );

        final state = AppStrategyState(
          symbol: symbol,
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
          openTrades: [
            FifoAppTrade(
              price: Decimal.parse('100.0'),
              quantity: Decimal.parse('1.0'),
              timestamp: DateTime.now().millisecondsSinceEpoch,
              roundId: 1,
            )
          ],
        );

        // ACT & ASSERT
        expect(
          () => service.shouldSell(
            currentPrice: 105.0,
            state: state,
            settings: corruptedSettings,
          ),
          returnsNormally,
          reason: 'Dovrebbe gestire percentuale TP corrotta senza crashare',
        );

        final result = service.shouldSell(
          currentPrice: 105.0,
          state: state,
          settings: corruptedSettings,
        );
        expect(result, isFalse,
            reason: 'Impostazioni corrotte dovrebbero restituire false');
      });

      test('should handle corrupted stop loss percentage', () {
        // ARRANGE - Impostazioni con percentuale SL corrotta
        final corruptedSettings = AppSettings(
          tradeAmount: 100.0,
          profitTargetPercentage: 5.0,
          stopLossPercentage: double.infinity,
          dcaDecrementPercentage: 10.0,
          maxOpenTrades: 5,
          isTestMode: true,
        );

        final state = AppStrategyState(
          symbol: symbol,
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
          openTrades: [
            FifoAppTrade(
              price: Decimal.parse('100.0'),
              quantity: Decimal.parse('1.0'),
              timestamp: DateTime.now().millisecondsSinceEpoch,
              roundId: 1,
            )
          ],
        );

        // ACT & ASSERT
        expect(
          () => service.shouldSell(
            currentPrice: 95.0,
            state: state,
            settings: corruptedSettings,
          ),
          returnsNormally,
          reason: 'Dovrebbe gestire percentuale SL corrotta senza crashare',
        );

        final result = service.shouldSell(
          currentPrice: 95.0,
          state: state,
          settings: corruptedSettings,
        );
        expect(result, isFalse,
            reason: 'Impostazioni corrotte dovrebbero restituire false');
      });
    });

    group('Test di Stress con Dati Corrotti', () {
      test('should handle high-frequency corrupted data without crashing', () {
        // ARRANGE
        final settings = createAppSettings();
        final state = AppStrategyState(
          symbol: symbol,
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
          openTrades: [
            FifoAppTrade(
              price: Decimal.parse('100.0'),
              quantity: Decimal.parse('1.0'),
              timestamp: DateTime.now().millisecondsSinceEpoch,
              roundId: 1,
            )
          ],
        );

        // Genera array di prezzi con alcuni corrotti
        final random = Random(42); // Seed fisso per test deterministico
        final corruptedPrices = List.generate(1000, (index) {
          if (random.nextDouble() < 0.1) {
            // 10% di dati corrotti
            return [double.nan, double.infinity, -1.0, 0.0][random.nextInt(4)];
          }
          return 95.0 + random.nextDouble() * 20.0; // Prezzi validi tra 95-115
        });

        // ACT & ASSERT
        int validResults = 0;
        int corruptedResults = 0;

        for (final price in corruptedPrices) {
          if (price.isFinite && price > 0.00000001 && price < 1000000000000.0) {
            expect(
              () {
                final result = service.shouldSell(
                  currentPrice: price,
                  state: state,
                  settings: settings,
                );
                validResults++;
                expect(result, isA<bool>());
              },
              returnsNormally,
            );
          } else {
            final result = service.shouldSell(
                currentPrice: price,
                state: state,
                settings: settings,
              );
              expect(result, isFalse);
            corruptedResults++;
          }
        }

        expect(validResults, greaterThan(0),
            reason: 'Dovrebbe processare alcuni prezzi validi');
        expect(corruptedResults, greaterThan(0),
            reason: 'Dovrebbe processare alcuni prezzi corrotti');
      });
    });
  });
}
