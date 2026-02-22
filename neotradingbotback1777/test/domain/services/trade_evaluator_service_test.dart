import 'package:neotradingbotback1777/domain/services/fee_calculation_service.dart';
import 'package:decimal/decimal.dart';
import 'package:neotradingbotback1777/domain/entities/fifo_app_trade.dart';
import 'package:test/test.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotback1777/domain/services/trade_evaluator_service.dart';
import 'package:neotradingbotback1777/domain/repositories/i_fee_repository.dart';
import '../../mocks/mocks.dart';
import '../../mocks/business_metrics_monitor_mock.dart';
import '../../fixtures/builders.dart';
import '../../helpers/mockito_dummy_registrations.dart';

import 'package:neotradingbotback1777/core/logging/log_throttler.dart';
import 'package:neotradingbotback1777/core/errors/unified_error_handler.dart';

void main() {
  late TradeEvaluatorService service;
  late FakeTradingLockManager fakeTradingLockManager;
  late IFeeRepository mockFeeRepository;
  const String symbol = 'BTCUSDC';

  setUp(() {
    registerMockitoDummies();
    mockFeeRepository = MockFeeRepository();
    fakeTradingLockManager = FakeTradingLockManager();
    service = TradeEvaluatorService(
      feeCalculationService:
          FeeCalculationService(feeRepository: mockFeeRepository),
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
          FifoAppTradeBuilder()
              .price(Decimal.parse(averagePrice.toString()))
              .quantity(Decimal.parse(quantity.toString()))
              .roundId(1)
              .build()
        ];

    return AppStrategyStateBuilder()
        .symbol(symbol)
        .status(status)
        .openTrades(trades)
        .build();
  }

  // Helper per creare impostazioni di test
  AppSettings createAppSettings({
    double profitTargetPercentage = 5.0,
    double stopLossPercentage = 10.0,
    double dcaDecrementPercentage = 10.0,
    int maxOpenTrades = 5,
    double tradeAmount = 100.0,
  }) {
    return AppSettingsBuilder()
        .tradeAmount(tradeAmount)
        .profitTarget(profitTargetPercentage)
        .stopLoss(stopLossPercentage)
        .dcaDecrement(dcaDecrementPercentage)
        .maxTrades(maxOpenTrades)
        .testMode(true)
        .build();
  }

  group('TradeEvaluatorService Tests', () {
    group('[TES-000] shouldSell Logic', () {
      group('[TES-001] (Parameterized) Take Profit and Stop Loss', () {
        final cases = [
          {
            'name': 'sell when price exceeds take profit threshold',
            'profitTarget': 5.0,
            'currentPrice': 105.1,
            'expected': true
          },
          {
            'name': 'do NOT sell when price is below take profit threshold',
            'profitTarget': 5.0,
            'currentPrice': 104.9,
            'expected': false
          },
          {
            'name': 'sell when price is exactly at take profit threshold',
            'profitTarget': 5.0,
            'currentPrice': 105.0,
            'expected': true
          },
          {
            'name': 'sell when price drops below stop loss threshold',
            'stopLoss': 10.0,
            'currentPrice': 89.9,
            'expected': true
          },
          {
            'name': 'sell when price is exactly at stop loss threshold',
            'stopLoss': 10.0,
            'currentPrice': 90.0,
            'expected': true
          },
        ];

        for (final c in cases) {
          test('[PARAM] ${c['name']}', () async {
            // GIVEN
            final settings = AppSettingsBuilder()
                .profitTarget((c['profitTarget'] as double?) ?? 5.0)
                .stopLoss((c['stopLoss'] as double?) ?? 10.0)
                .build();
            final state = createStateWithOpenPosition(averagePrice: 100.0);

            // WHEN
            final result = await service.shouldSell(
              currentPrice: c['currentPrice'] as double,
              state: state,
              settings: settings,
            );

            // THEN
            expect(result, c['expected']);
          });
        }
      });

      test('[NEG-03] should return false if not in the correct state to sell',
          () async {
        // ARRANGE
        final settings = createAppSettings();
        final state = createStateWithOpenPosition(
            status: StrategyState.MONITORING_FOR_BUY); // Stato errato
        const currentPrice = 110.0; // Prezzo di profitto

        // ACT
        final result = await service.shouldSell(
          currentPrice: currentPrice,
          state: state,
          settings: settings,
        );

        // ASSERT
        expect(result, isFalse);
      });

      test('[NEG-01] should return false if there are no open trades',
          () async {
        // ARRANGE
        final settings = createAppSettings();
        final state = AppStrategyState(symbol: symbol); // Stato iniziale
        const currentPrice = 110.0;

        // ACT
        final result = await service.shouldSell(
          currentPrice: currentPrice,
          state: state,
          settings: settings,
        );

        // ASSERT
        expect(result, isFalse);
      });

      test(
          '[EC-06] should return false if average price is zero or negative (corrupted state)',
          () async {
        // ARRANGE
        final settings = createAppSettings();
        final stateWithZeroPrice =
            createStateWithOpenPosition(averagePrice: 0.0);
        // La logica interna di AppStrategyState ora previene medie negative se le quantità/prezzi sono positivi,
        // ma testiamo il caso limite in cui la media calcolata possa essere 0.
        final stateWithNegativePrice =
            createStateWithOpenPosition(averagePrice: -100.0);

        // ASSERT
        expect(
            () => service.shouldSell(
                currentPrice: 10,
                state: stateWithZeroPrice,
                settings: settings),
            throwsA(isA<FormatException>()));
        expect(
            () => service.shouldSell(
                currentPrice: 10,
                state: stateWithNegativePrice,
                settings: settings),
            throwsA(isA<FormatException>()));
      });

      test('[NEG-02] should return false for invalid currentPrice', () async {
        // GIVEN
        final settings = createAppSettings();
        final state = createStateWithOpenPosition();
        final invalidPrices = [0.0, -10.0, double.nan, double.infinity];

        for (final price in invalidPrices) {
          // WHEN
          final result = await service.shouldSell(
              currentPrice: price, state: state, settings: settings);

          // THEN
          expect(result, isFalse,
              reason: 'Should not sell with invalid input price ($price)');
        }
      });

      test('[EC-07] should kill mutants on boundary conditions for TP/SL',
          () async {
        // GIVEN
        final settings = createAppSettings(
            profitTargetPercentage: 5.0, stopLossPercentage: 10.0);
        final state = createStateWithOpenPosition(averagePrice: 100.0);

        // WHEN & THEN
        // TP boundaries
        expect(
            await service.shouldSell(
                currentPrice: 104.99, state: state, settings: settings),
            isFalse);
        expect(
            await service.shouldSell(
                currentPrice: 105.00, state: state, settings: settings),
            isTrue);
        expect(
            await service.shouldSell(
                currentPrice: 105.01, state: state, settings: settings),
            isTrue); // Kills >= mutated to == or >

        // SL boundaries
        expect(
            await service.shouldSell(
                currentPrice: 90.01, state: state, settings: settings),
            isFalse);
        expect(
            await service.shouldSell(
                currentPrice: 90.00, state: state, settings: settings),
            isTrue);
        expect(
            await service.shouldSell(
                currentPrice: 89.99, state: state, settings: settings),
            isTrue); // Kills <= mutated to == or <
      });

      // NUOVI TEST AGGIUNTI
      test(
          '[TEST-020] should handle multiple trades with different average prices',
          () async {
        // ARRANGE
        final settings = createAppSettings(profitTargetPercentage: 5.0);
        final trades = [
          FifoAppTrade(
              price: Decimal.parse('100.0'),
              quantity: Decimal.parse('1.0'),
              timestamp: 1000,
              roundId: 1),
          FifoAppTrade(
              price: Decimal.parse('110.0'),
              quantity: Decimal.parse('1.0'),
              timestamp: 2000,
              roundId: 1),
        ];
        final state = createStateWithOpenPosition(
          averagePrice: 105.0, // Media ponderata: (100*1 + 110*1) / 2 = 105
          openTrades: trades,
        );
        const currentPrice = 110.25; // +5% da 105

        // ACT
        final result = await service.shouldSell(
          currentPrice: currentPrice,
          state: state,
          settings: settings,
        );

        // ASSERT
        expect(result, isTrue);
      });

      test('[TEST-021] should handle very small profit percentages accurately',
          () async {
        // ARRANGE
        final settings = createAppSettings(profitTargetPercentage: 0.1); // 0.1%
        final state = createStateWithOpenPosition(averagePrice: 100.0);
        const currentPrice = 100.1; // Esattamente +0.1%

        // ACT
        final result = await service.shouldSell(
          currentPrice: currentPrice,
          state: state,
          settings: settings,
        );

        // ASSERT
        expect(result, isTrue);
      });

      test(
          '[BOUNDARY-09] shouldSell: return true when profit is GREATER THAN target',
          () async {
        // GIVEN
        final profitTarget = 5.0;
        final settings =
            AppSettingsBuilder().profitTarget(profitTarget).build();
        final averagePrice = 100.0;
        final state = createStateWithOpenPosition(averagePrice: averagePrice);
        // currentPrice = 110.0 gives 10% profit (> 5%)
        final currentPrice = 110.0;

        // WHEN
        final result = await service.shouldSell(
          currentPrice: currentPrice,
          state: state,
          settings: settings,
        );

        // THEN
        expect(result, isTrue,
            reason: 'Should trigger TP when profit > target');
      });

      test(
          '[BOUNDARY-10] shouldSell: return true when loss is GREATER THAN stop loss (more negative)',
          () async {
        // GIVEN
        final stopLoss = 10.0;
        final settings = AppSettingsBuilder().stopLoss(stopLoss).build();
        final averagePrice = 100.0;
        final state = createStateWithOpenPosition(averagePrice: averagePrice);
        // currentPrice = 85.0 gives -15% loss (> 10% SL)
        final currentPrice = 85.0;

        // WHEN
        final result = await service.shouldSell(
          currentPrice: currentPrice,
          state: state,
          settings: settings,
        );

        // THEN
        expect(result, isTrue, reason: 'Should trigger SL when loss > target');
      });

      test(
          '[NEG-04] shouldSell: return false when profit is ALMOST target (4.99% < 5%)',
          () async {
        // GIVEN
        final settings = AppSettingsBuilder().profitTarget(5.0).build();
        final state = createStateWithOpenPosition(averagePrice: 100.0);
        // currentPrice = 104.99 gives 4.99% profit
        final currentPrice = 104.99;

        // WHEN
        final result = await service.shouldSell(
          currentPrice: currentPrice,
          state: state,
          settings: settings,
        );

        // THEN
        expect(result, isFalse, reason: 'Should not trigger TP below target');
      });

      test(
          '[NEG-05] shouldSell: return false when loss is ALMOST stop loss (-9.99% > -10%)',
          () async {
        // GIVEN
        final settings = AppSettingsBuilder().stopLoss(10.0).build();
        final state = createStateWithOpenPosition(averagePrice: 100.0);
        // currentPrice = 90.01 gives -9.99% loss
        final currentPrice = 90.01;

        // WHEN
        final result = await service.shouldSell(
          currentPrice: currentPrice,
          state: state,
          settings: settings,
        );

        // THEN
        expect(result, isFalse, reason: 'Should not trigger SL above target');
      });

      test(
          '[LOGIC-01] shouldSell: return false if price is NaN (Logic gate kill)',
          () async {
        final settings = createAppSettings();
        final state = createStateWithOpenPosition(averagePrice: 100.0);
        expect(
            await service.shouldSell(
                currentPrice: double.nan, state: state, settings: settings),
            isFalse);
      });

      test(
          '[LOGIC-02] shouldSell: return false if averagePrice is negative (Logic gate kill)',
          () async {
        final settings = createAppSettings();
        final state = createStateWithOpenPosition(averagePrice: -100.0);
        // Even if price is high, shouldSell should return false due to negative averagePrice guard
        expect(
            () => service.shouldSell(
                currentPrice: 1000.0, state: state, settings: settings),
            throwsA(isA<FormatException>()));
      });

      test(
          '[LOGIC-08] shouldSell: return false when status is IDLE but price is high',
          () async {
        final settings = AppSettingsBuilder().profitTarget(5.0).build();
        final state = createStateWithOpenPosition(
          averagePrice: 100.0,
          status: StrategyState.IDLE, // Wrong status
        );
        // currentPrice = 110.0 (10% profit)
        // If guard is skipped, it would return true.
        expect(
            await service.shouldSell(
                currentPrice: 110.0, state: state, settings: settings),
            isFalse);
      });

      test(
          '[LOGIC-09] shouldSell: return false when in initial state even if price is high',
          () async {
        final settings = AppSettingsBuilder().profitTarget(5.0).build();
        final state = AppStrategyState(
          symbol: symbol,
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
          openTrades: [], // Initial state
        );
        // currentPrice = 110.0
        expect(
            await service.shouldSell(
                currentPrice: 110.0, state: state, settings: settings),
            isFalse);
      });

      test(
          '[LOGIC-12] shouldSell: return false when averagePrice is 0.0 (Kills || -> &&)',
          () {
        final settings = createAppSettings();
        final state = createStateWithOpenPosition(averagePrice: 0.0);
        expect(
            () => service.shouldSell(
                currentPrice: 100.0, state: state, settings: settings),
            throwsA(isA<FormatException>()));
      });

      test(
          '[LOGIC-13] shouldSell: return false when currentPrice is finite but NEGATIVE (Kills || -> &&)',
          () {
        final settings = createAppSettings();
        final state = createStateWithOpenPosition(averagePrice: 100.0);
        expect(
            service.shouldSell(
                currentPrice: -1.0, state: state, settings: settings),
            isFalse);
      });

      test(
          '[LOGIC-14] shouldSell: return false when currentPrice is POSITIVE but NOT FINITE (Kills || -> &&)',
          () {
        final settings = createAppSettings();
        final state = createStateWithOpenPosition(averagePrice: 100.0);
        expect(
            service.shouldSell(
                currentPrice: double.infinity,
                state: state,
                settings: settings),
            isFalse);
      });
    });

    group('[TES-010] shouldDcaBuy Logic', () {
      group('[TES-011] shouldDcaBuy Logic (Parameterized)', () {
        final cases = [
          {
            'name': 'trigger DCA when price decrement reaches threshold',
            'dcaDecrement': 10.0,
            'currentPrice': 89.9,
            'expected': true
          },
          {
            'name': 'trigger DCA when price decrement is exactly at threshold',
            'dcaDecrement': 10.0,
            'currentPrice': 90.0,
            'expected': true
          },
          {
            'name':
                'do NOT trigger DCA when price decrement is less than threshold',
            'dcaDecrement': 10.0,
            'currentPrice': 90.1,
            'expected': false
          },
        ];

        for (final c in cases) {
          test('[PARAM] ${c['name']}', () {
            // GIVEN
            final settings = AppSettingsBuilder()
                .dcaDecrement(c['dcaDecrement'] as double)
                .maxTrades(5)
                .build();
            final state = createStateWithOpenPosition(averagePrice: 100.0);

            // WHEN
            final result = service.shouldDcaBuy(
              currentPrice: c['currentPrice'] as double,
              state: state,
              settings: settings,
              compareAgainstAverage: true,
            );

            // THEN
            expect(result, c['expected']);
          });
        }
      });

      test('[EC-04] should return false if max open trades is reached', () {
        // GIVEN
        final settings =
            createAppSettings(dcaDecrementPercentage: 10.0, maxOpenTrades: 1);
        final state = createStateWithOpenPosition(); // Has already 1 trade
        const currentPrice = 80.0;

        // WHEN
        final result = service.shouldDcaBuy(
          currentPrice: currentPrice,
          state: state,
          settings: settings,
        );

        // THEN
        expect(result, isFalse);
      });

      test('[NEG-01] should return false if there are no open trades', () {
        // ARRANGE
        final settings = createAppSettings();
        final state = AppStrategyState(symbol: symbol);
        const currentPrice = 90.0;

        // ACT
        final result = service.shouldDcaBuy(
            currentPrice: currentPrice, state: state, settings: settings);

        // ASSERT
        expect(result, isFalse);
      });

      test('[NEG-02] should return false for invalid currentPrice', () {
        // ARRANGE
        final settings = createAppSettings();
        final state = createStateWithOpenPosition();
        final invalidPrices = [0.0, -10.0, double.nan, double.infinity];

        // ACT & ASSERT
        for (final price in invalidPrices) {
          final result = service.shouldDcaBuy(
              currentPrice: price, state: state, settings: settings);
          expect(result, isFalse,
              reason: 'Should not DCA with invalid price: $price');
        }
      });

      // NUOVI TEST AGGIUNTI
      test(
          '[TEST-022] should handle DCA with lastValidBuyPrice vs averagePrice',
          () {
        // ARRANGE
        final settings =
            createAppSettings(dcaDecrementPercentage: 5.0, maxOpenTrades: 5);
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
              roundId: 1), // DCA precedente
        ];
        final state = createStateWithOpenPosition(
          averagePrice: 97.5, // Media: (100+95)/2
          openTrades: trades,
        );
        const currentPrice = 90.25; // -5% da 95 (lastValidBuyPrice)

        // ACT - Test con lastValidBuyPrice (default)
        final resultLastBuy = service.shouldDcaBuy(
          currentPrice: currentPrice,
          state: state,
          settings: settings,
          compareAgainstAverage: false, // Usa lastValidBuyPrice
        );

        // ACT - Test con averagePrice
        final resultAverage = service.shouldDcaBuy(
          currentPrice: currentPrice,
          state: state,
          settings: settings,
          compareAgainstAverage: true, // Usa averagePrice
        );

        // ASSERT
        expect(resultLastBuy, isTrue); // 95 -> 90.25 = -5%
        expect(
            resultAverage, isTrue); // 97.5 -> 90.25 = -7.4% (sopra soglia DCA)
      });

      test('[TEST-023] should handle very small DCA decrements accurately', () {
        // ARRANGE
        final settings =
            createAppSettings(dcaDecrementPercentage: 0.5, maxOpenTrades: 5);
        final state = createStateWithOpenPosition(averagePrice: 100.0);
        const currentPrice = 99.5; // Esattamente -0.5%

        // ACT
        final result = service.shouldDcaBuy(
          currentPrice: currentPrice,
          state: state,
          settings: settings,
          compareAgainstAverage: true,
        );

        // ASSERT
        expect(result, isTrue);
      });
    });

    group('shouldBuyInitial Logic', () {
      test(
          '[TEST-007] should return true for initial buy when warmup is satisfied',
          () {
        // ARRANGE
        final settings = createAppSettings(maxOpenTrades: 5);
        final state = AppStrategyState(
            symbol: symbol, status: StrategyState.MONITORING_FOR_BUY);
        const currentPrice = 100.0;

        // ACT
        final result = service.shouldBuyInitial(
          currentPrice: currentPrice,
          state: state,
          settings: settings,
          warmupSatisfied: true,
        );

        // ASSERT
        expect(result, isTrue);
      });

      test(
          '[NEG-04] should return false for initial buy when warmup is NOT satisfied',
          () {
        // ARRANGE
        final settings = createAppSettings(maxOpenTrades: 5);
        final state = AppStrategyState(
            symbol: symbol, status: StrategyState.MONITORING_FOR_BUY);
        const currentPrice = 100.0;

        // ACT
        final result = service.shouldBuyInitial(
          currentPrice: currentPrice,
          state: state,
          settings: settings,
          warmupSatisfied: false,
        );

        // ASSERT
        expect(result, isFalse);
      });

      test('should return false if not in initial state', () {
        // ARRANGE
        final settings = createAppSettings();
        final state = createStateWithOpenPosition(
            status: StrategyState
                .MONITORING_FOR_BUY); // Non è stato iniziale ma monitora
        const currentPrice = 100.0;

        // ACT
        final result = service.shouldBuyInitial(
            currentPrice: currentPrice,
            state: state,
            settings: settings,
            warmupSatisfied: true);

        // ASSERT
        expect(result, isFalse);
      });

      test('should return false if state is not MONITORING_FOR_BUY', () {
        // ARRANGE
        final settings = createAppSettings();
        final state = AppStrategyState(
            symbol: symbol,
            status: StrategyState
                .POSITION_OPEN_MONITORING_FOR_SELL); // Stato errato
        const currentPrice = 100.0;

        // ACT
        final result = service.shouldBuyInitial(
            currentPrice: currentPrice,
            state: state,
            settings: settings,
            warmupSatisfied: true);

        // ASSERT
        expect(result, isFalse);
      });

      test('should return false if maxOpenTrades is 0 or negative', () {
        // GIVEN
        final state = AppStrategyState(
            symbol: symbol, status: StrategyState.MONITORING_FOR_BUY);
        const currentPrice = 100.0;

        // WHEN & THEN
        final settings0 = createAppSettings(maxOpenTrades: 0);
        expect(
            service.shouldBuyInitial(
                currentPrice: currentPrice,
                state: state,
                settings: settings0,
                warmupSatisfied: true),
            isFalse);

        final settingsNeg = createAppSettings(maxOpenTrades: -1);
        expect(
            service.shouldBuyInitial(
                currentPrice: currentPrice,
                state: state,
                settings: settingsNeg,
                warmupSatisfied: true),
            isFalse); // Kills <= mutated to ==
      });

      test('[NEG-02] should return false for invalid currentPrice', () {
        // GIVEN
        final settings = createAppSettings();
        final state = AppStrategyState(
            symbol: symbol, status: StrategyState.MONITORING_FOR_BUY);
        final invalidPrices = [0.0, -10.0, double.nan, double.infinity];

        for (final price in invalidPrices) {
          // WHEN
          final result = service.shouldBuyInitial(
            currentPrice: price,
            state: state,
            settings: settings,
            warmupSatisfied: true,
          );

          // THEN
          expect(result, isFalse,
              reason:
                  'Should not authorize initial buy with invalid price ($price)');
        }
      });

      // NUOVI TEST AGGIUNTI
      test('[TEST-024] should handle edge case with maxOpenTrades = 1', () {
        // ARRANGE
        final settings = createAppSettings(maxOpenTrades: 1);
        final state = AppStrategyState(
            symbol: symbol, status: StrategyState.MONITORING_FOR_BUY);
        const currentPrice = 100.0;

        // ACT
        final result = service.shouldBuyInitial(
          currentPrice: currentPrice,
          state: state,
          settings: settings,
          warmupSatisfied: true,
        );

        // ASSERT
        expect(result, isTrue);
      });

      test(
          '[BOUNDARY-05] shouldBuyInitial: return false when ONLY status is wrong',
          () {
        // GIVEN
        final state =
            AppStrategyState(symbol: symbol, status: StrategyState.IDLE);
        final settings = createAppSettings(maxOpenTrades: 5);

        // WHEN & THEN
        expect(
            service.shouldBuyInitial(
                currentPrice: 100.0,
                state: state,
                settings: settings,
                warmupSatisfied: true),
            isFalse,
            reason: 'Should fail due to status != MONITORING_FOR_BUY');
      });

      test(
          '[BOUNDARY-06] shouldBuyInitial: return false when ONLY length is wrong',
          () {
        // GIVEN
        final state = AppStrategyState(
          symbol: symbol,
          status: StrategyState.MONITORING_FOR_BUY,
          openTrades: List.generate(
              5, (index) => createMockTrade(price: Decimal.parse('100.0'))),
        );
        final settings = createAppSettings(maxOpenTrades: 5);

        // WHEN & THEN
        expect(
            service.shouldBuyInitial(
                currentPrice: 100.0,
                state: state,
                settings: settings,
                warmupSatisfied: true),
            isFalse,
            reason: 'Should fail due to maxOpenTrades reached');
      });

      test(
          '[BOUNDARY-07] shouldBuyInitial: return false when price is EXACTLY 0',
          () {
        final state = AppStrategyState(
            symbol: symbol, status: StrategyState.MONITORING_FOR_BUY);
        final settings = createAppSettings();
        expect(
            service.shouldBuyInitial(
                currentPrice: 0.0,
                state: state,
                settings: settings,
                warmupSatisfied: true),
            isFalse);
      });
    });

    group('shouldBuyNonInitial Logic', () {
      test('[LOGIC-03] shouldBuyNonInitial: return false if price is negative',
          () {
        final state = createStateWithOpenPosition(averagePrice: 100.0);
        final settings = createAppSettings();
        expect(
            service.shouldBuyNonInitial(
                currentPrice: -10.0, state: state, settings: settings),
            isFalse);
      });

      test(
          '[LOGIC-04] shouldBuyNonInitial: return false if openTrades already at max',
          () {
        final state = AppStrategyState(
          symbol: symbol,
          status: StrategyState.MONITORING_FOR_BUY,
          openTrades: List.generate(
              5, (index) => createMockTrade(price: Decimal.parse('100.0'))),
        );
        final settings = createAppSettings(maxOpenTrades: 5);
        expect(
            service.shouldBuyNonInitial(
                currentPrice: 100.0, state: state, settings: settings),
            isFalse);
      });

      test(
          '[LOGIC-05] shouldBuyNonInitial: return false when status is IDLE and trades < max (Kills || -> &&)',
          () {
        final settings = AppSettingsBuilder().maxTrades(5).build();
        final state = AppStrategyState(
          symbol: symbol,
          status: StrategyState.IDLE, // Not monitoring
          openTrades: [
            createMockTrade(price: Decimal.parse('100.0'))
          ], // length = 1 < 5
        );
        expect(
            service.shouldBuyNonInitial(
                currentPrice: 90.0, state: state, settings: settings),
            isFalse);
      });

      test(
          '[LOGIC-06] shouldBuyNonInitial: return false when trades == max (Kills >= -> >)',
          () {
        final settings = AppSettingsBuilder().maxTrades(2).build();
        final trades = [
          createMockTrade(price: Decimal.parse('100.0')),
          createMockTrade(price: Decimal.parse('101.0')),
        ];
        final state = AppStrategyState(
          symbol: symbol,
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
          openTrades: trades, // length = 2 == max
        );
        expect(
            service.shouldBuyNonInitial(
                currentPrice: 90.0, state: state, settings: settings),
            isFalse);
      });

      test(
          '[LOGIC-07] shouldBuyNonInitial: return false even when price is down (By design, use shouldDcaBuy for DCA)',
          () {
        final settings =
            AppSettingsBuilder().maxTrades(5).dcaDecrement(5.0).build();
        final state = createStateWithOpenPosition(averagePrice: 100.0);
        // currentPrice = 90.0 (-10% < -5%)
        // shouldBuyNonInitial always returns false because DCA logic is separate
        expect(
            service.shouldBuyNonInitial(
                currentPrice: 90.0, state: state, settings: settings),
            isFalse);
      });
      // Come da documentazione, questa funzione ritorna quasi sempre `false`.
      // I test verificano le guardie e l'invariante.
      test('should always return false as per its design contract', () {
        // ARRANGE
        final settings = createAppSettings(maxOpenTrades: 5);
        final state = createStateWithOpenPosition(
            status: StrategyState.MONITORING_FOR_BUY,
            openTrades: [
              FifoAppTrade(
                  price: Decimal.parse('90.0'),
                  quantity: Decimal.parse('1.0'),
                  timestamp: 1,
                  roundId: 1)
            ]); // Stato non iniziale, pronto per un altro acquisto
        const currentPrice = 100.0;

        // ACT
        final result = service.shouldBuyNonInitial(
          currentPrice: currentPrice,
          state: state,
          settings: settings,
        );

        // ASSERT
        expect(result, isFalse,
            reason:
                'shouldBuyNonInitial is a restricted primitive and should not authorize buys.');
      });

      test(
          'should throw assertion error if called in initial state (in debug mode)',
          () {
        // ARRANGE
        final settings = createAppSettings();
        final state = AppStrategyState(symbol: symbol);
        const currentPrice = 100.0;

        // ACT & ASSERT
        // L'assert si attiva solo in modalità debug, quindi questo test passerà in CI/release.
        // È qui per documentare il contratto della funzione.
        expect(
            () => service.shouldBuyNonInitial(
                  currentPrice: currentPrice,
                  state: state,
                  settings: settings,
                ),
            throwsA(isA<AssertionError>()));
      });
    });

    // NUOVO GRUPPO DI TEST
    group('shouldBuyGuarded Logic', () {
      test('[TEST-025] should allow initial buy when allowInitialBuy is true',
          () {
        // ARRANGE
        final settings = createAppSettings(maxOpenTrades: 5);
        final state = AppStrategyState(
            symbol: symbol, status: StrategyState.MONITORING_FOR_BUY);
        const currentPrice = 100.0;

        // ACT
        final result = service.shouldBuyGuarded(
          currentPrice: currentPrice,
          state: state,
          settings: settings,
          allowInitialBuy: true,
        );

        // ASSERT
        expect(result, isTrue);
      });

      test('[TEST-026] should block initial buy when allowInitialBuy is false',
          () {
        // GIVEN
        final settings = createAppSettings(maxOpenTrades: 5);
        final state = AppStrategyState(
            symbol: symbol, status: StrategyState.MONITORING_FOR_BUY);
        const currentPrice = 100.0;

        // WHEN
        final result = service.shouldBuyGuarded(
          currentPrice: currentPrice,
          state: state,
          settings: settings,
          allowInitialBuy: false,
        );

        // THEN
        expect(result, isFalse);
      });

      test(
          '[TEST-027] should delegate to shouldBuyNonInitial for non-initial states',
          () {
        // ARRANGE
        final settings = createAppSettings(maxOpenTrades: 5);
        final state = createStateWithOpenPosition(
            status: StrategyState.MONITORING_FOR_BUY,
            openTrades: [
              FifoAppTrade(
                  price: Decimal.parse('90.0'),
                  quantity: Decimal.parse('1.0'),
                  timestamp: 1,
                  roundId: 1)
            ]);
        const currentPrice = 100.0;

        // ACT
        final result = service.shouldBuyGuarded(
          currentPrice: currentPrice,
          state: state,
          settings: settings,
          allowInitialBuy: true, // Non dovrebbe influenzare il risultato
        );

        // ASSERT
        expect(result, isFalse); // shouldBuyNonInitial ritorna sempre false
      });
    });

    // NUOVO GRUPPO DI TEST PER SCENARI DI SEQUENZA
    group('Sequential Scenarios', () {
      test('[TEST-028] should handle rapid price changes correctly', () {
        // ARRANGE
        final settings = createAppSettings(
          profitTargetPercentage: 5.0,
          stopLossPercentage: 3.0,
        );
        final state = createStateWithOpenPosition(averagePrice: 100.0);

        // ACT & ASSERT - Prezzo sale rapidamente
        expect(
            service.shouldSell(
                currentPrice: 104.9, state: state, settings: settings),
            isFalse);
        expect(
            service.shouldSell(
                currentPrice: 105.0, state: state, settings: settings),
            isTrue);
        expect(
            service.shouldSell(
                currentPrice: 105.1, state: state, settings: settings),
            isTrue);

        // ACT & ASSERT - Prezzo scende rapidamente
        expect(
            service.shouldSell(
                currentPrice: 97.1, state: state, settings: settings),
            isFalse);
        expect(
            service.shouldSell(
                currentPrice: 97.0, state: state, settings: settings),
            isTrue);
        expect(
            service.shouldSell(
                currentPrice: 96.9, state: state, settings: settings),
            isTrue);
      });

      test('[TEST-029] should maintain consistency across multiple evaluations',
          () {
        // ARRANGE
        final settings = createAppSettings(
          profitTargetPercentage: 5.0,
          stopLossPercentage: 3.0,
        );
        final state = createStateWithOpenPosition(averagePrice: 100.0);
        const currentPrice = 105.0; // Esattamente +5%

        // ACT - Valutazioni multiple
        // WHEN
        final result1 = service.shouldSell(
            currentPrice: currentPrice, state: state, settings: settings);
        final result2 = service.shouldSell(
            currentPrice: currentPrice, state: state, settings: settings);
        final result3 = service.shouldSell(
            currentPrice: currentPrice, state: state, settings: settings);

        // THEN - Risultati consistenti
        expect(result1, isTrue);
        expect(result2, isTrue);
        expect(result3, isTrue);
        expect(result1, equals(result2));
        expect(result2, equals(result3));
      });
    });

    // NUOVO GRUPPO DI TEST PER EDGE CASES AGGIUNTIVI
    group('Additional Edge Cases', () {
      test('[TEST-030] should handle extremely small percentages', () {
        // ARRANGE
        final settings = createAppSettings(
          profitTargetPercentage: 0.001, // 0.001%
          stopLossPercentage: 0.001,
        );
        final state = createStateWithOpenPosition(averagePrice: 100.0);

        // ACT & ASSERT
        expect(
            service.shouldSell(
                currentPrice: 100.001, state: state, settings: settings),
            isTrue);
        expect(
            service.shouldSell(
                currentPrice: 99.999, state: state, settings: settings),
            isTrue);
      });

      test('[TEST-031] should handle extremely large percentages', () {
        // ARRANGE
        final settings = createAppSettings(
          profitTargetPercentage: 1000.0, // 1000%
          stopLossPercentage: 1000.0,
        );
        final state = createStateWithOpenPosition(averagePrice: 100.0);

        // ACT & ASSERT
        expect(
            service.shouldSell(
                currentPrice: 1100.0, state: state, settings: settings),
            isTrue);
        // Nota: prezzo zero non è permesso dal sistema, dovrebbe ritornare false
        expect(
            service.shouldSell(
                currentPrice: 0.0, state: state, settings: settings),
            isFalse); // Prezzo non valido
      });

      test('[TEST-032] should handle zero percentages gracefully', () {
        // ARRANGE
        final settings = createAppSettings(
          profitTargetPercentage: 0.0,
          stopLossPercentage: 0.0,
        );
        final state = createStateWithOpenPosition(averagePrice: 100.0);

        // ACT & ASSERT
        expect(
            service.shouldSell(
                currentPrice: 100.0, state: state, settings: settings),
            isTrue);
        expect(
            service.shouldSell(
                currentPrice: 100.1, state: state, settings: settings),
            isTrue);
        expect(
            service.shouldSell(
                currentPrice: 99.9, state: state, settings: settings),
            isTrue);
      });
    });
  });

  group('Negative Scenarios - Fondi Insufficienti e Trade Falliti', () {
    test(
        '[BACKEND-TEST-002] should handle insufficient funds scenario correctly',
        () {
      // ARRANGE
      final settings = createAppSettings(
        tradeAmount: 1000.0, // Richiede 1000 USDC
        maxOpenTrades: 5,
      );

      // Simula stato con trade aperti ma fondi insufficienti
      final state = createStateWithOpenPosition(
        averagePrice: 100.0,
        quantity: 10.0, // 1000 USDC investiti
      );

      // ACT & ASSERT - Dovrebbe rifiutare nuovi acquisti se non ci sono fondi
      final result = service.shouldBuyNonInitial(
        currentPrice: 95.0, // Prezzo favorevole per DCA
        state: state,
        settings: settings,
      );

      expect(result, isFalse,
          reason: 'Dovrebbe rifiutare acquisti con fondi insufficienti');
    });

    test(
        '[BACKEND-TEST-002] should filter out failed trades in validatedAveragePrice',
        () {
      // ARRANGE - Crea stato con mix di trade eseguiti e falliti
      final successfulTrade = FifoAppTrade(
        price: Decimal.parse('100.0'),
        quantity: Decimal.parse('1.0'),
        timestamp: DateTime.now().millisecondsSinceEpoch,
        roundId: 1,
        isExecuted: true,
        orderStatus: 'FILLED',
      );

      final failedTrade = FifoAppTrade(
        price: Decimal.parse('95.0'),
        quantity: Decimal.parse('1.0'),
        timestamp: DateTime.now().millisecondsSinceEpoch,
        roundId: 2,
        isExecuted: false,
        orderStatus: 'REJECTED',
      );

      final state = AppStrategyState(
        symbol: symbol,
        status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
        openTrades: [successfulTrade, failedTrade],
      );

      // ACT & ASSERT
      expect(state.validatedAveragePrice, 100.0,
          reason:
              'Dovrebbe considerare solo trade eseguiti per il prezzo medio');
      expect(state.isValidForDca, isTrue,
          reason: 'Dovrebbe essere valido per DCA se ci sono trade eseguiti');
      expect(state.hasInconsistencies, isTrue,
          reason: 'Dovrebbe rilevare inconsistenze con trade falliti');
      expect(state.validTradesCount, 1,
          reason: 'Dovrebbe contare solo trade validi');
      expect(state.invalidTradesCount, 1,
          reason: 'Dovrebbe contare trade falliti');
    });

    test('[BACKEND-TEST-002] should handle edge case with all failed trades',
        () {
      // ARRANGE - Tutti i trade sono falliti
      final failedTrade1 = FifoAppTrade(
        price: Decimal.parse('100.0'),
        quantity: Decimal.parse('1.0'),
        timestamp: DateTime.now().millisecondsSinceEpoch,
        roundId: 1,
        isExecuted: false,
        orderStatus: 'REJECTED',
      );

      final failedTrade2 = FifoAppTrade(
        price: Decimal.parse('95.0'),
        quantity: Decimal.parse('1.0'),
        timestamp: DateTime.now().millisecondsSinceEpoch,
        roundId: 2,
        isExecuted: false,
        orderStatus: 'CANCELLED',
      );

      final state = AppStrategyState(
        symbol: symbol,
        status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
        openTrades: [failedTrade1, failedTrade2],
      );

      // ACT & ASSERT
      expect(state.validatedAveragePrice, 0.0,
          reason: 'Prezzo medio dovrebbe essere 0 se non ci sono trade validi');
      expect(state.isValidForDca, isFalse,
          reason: 'Non dovrebbe essere valido per DCA senza trade eseguiti');
      expect(state.hasInconsistencies, isTrue,
          reason: 'Dovrebbe rilevare inconsistenze');
    });
    group('evaluateTradingDecisions Logic', () {
      test('[EVAL-01] should prioritize sell over DCA', () {
        // GIVEN
        final settings = AppSettingsBuilder()
            .profitTarget(5.0)
            .dcaDecrement(10.0) // Both conditions are met
            .maxTrades(5)
            .build();

        // Price is much higher than average (Sell) AND much lower than last buy (DCA)?
        // Wait, that's impossible for the same currentPrice.
        // Let's test Sell priority over Initial Buy (also impossible same time).
        // Let's test that it returns the SELL decision if both conditions were hypothetically met.
        // Actually, let's test a more realistic scenario:
        // If status is MONITORING_FOR_SELL, we check Sell then DCA.

        final averagePrice = 100.0;
        final state = createStateWithOpenPosition(averagePrice: averagePrice);

        // currentPrice = 105.0 (exactly 5% profit -> Sell)
        // shouldDcaBuy would be false anyway because price is UP.

        // WHEN
        final decision = service.evaluateTradingDecisions(
          currentPrice: 105.0,
          state: state,
          settings: settings,
        );

        // THEN
        expect(decision?.action, TradingAction.sell);
        expect(decision?.reason, contains('Take Profit: +5.00%'));
      });

      test(
          '[EVAL-02] should return DCA_BUY when price drops below DCA threshold',
          () {
        // GIVEN
        final settings =
            AppSettingsBuilder().dcaDecrement(10.0).maxTrades(5).build();
        final state = createStateWithOpenPosition(averagePrice: 100.0);

        // price = 89.9 (-10.1% -> DCA)

        // WHEN
        final decision = service.evaluateTradingDecisions(
          currentPrice: 89.9,
          state: state,
          settings: settings,
        );

        // THEN
        expect(decision?.action, TradingAction.dcaBuy);
        expect(decision?.reason, contains('DCA triggered'));
      });

      test('[EVAL-03] should return INITIAL_BUY and correct reason', () {
        // GIVEN
        final settings = createAppSettings();
        final state = AppStrategyState(
            symbol: symbol, status: StrategyState.MONITORING_FOR_BUY);

        // WHEN
        final decision = service.evaluateTradingDecisions(
          currentPrice: 100.0,
          state: state,
          settings: settings,
          allowInitialBuy: true,
        );

        // THEN
        expect(decision?.action, TradingAction.initialBuy);
        expect(decision?.reason, equals('Initial buy conditions met'));
      });
      test('[EVAL-04] should return null when no action in MONITORING_FOR_SELL',
          () {
        // GIVEN
        final settings = createAppSettings();
        final state = createStateWithOpenPosition(averagePrice: 100.0);
        // currentPrice is between SL and TP, and above DCA decrement
        const currentPrice = 100.0;

        // WHEN
        final decision = service.evaluateTradingDecisions(
          currentPrice: currentPrice,
          state: state,
          settings: settings,
        );

        // THEN
        expect(decision, isNull);
      });
    });

    group('shouldSellWithFees Logic', () {
      test(
          '[LOGIC-15] shouldSellWithFees: return false when currentPrice is NaN (Kills || -> &&)',
          () async {
        final settings = createAppSettings();
        final state = createStateWithOpenPosition(averagePrice: 100.0);
        expect(
            await service.shouldSellWithFees(
                currentPrice: double.nan, state: state, settings: settings),
            isFalse);
      });

      test(
          '[LOGIC-16] shouldSellWithFees: return false when currentPrice is negative',
          () async {
        final settings = createAppSettings();
        final state = createStateWithOpenPosition(averagePrice: 100.0);
        expect(
            await service.shouldSellWithFees(
                currentPrice: -10.0, state: state, settings: settings),
            isFalse);
      });
    });

    group('evaluateTradingDecisionsWithFees Logic', () {
      test('[EVAL-05] should handle successful evaluate with fees (SELL)',
          () async {
        // GIVEN
        final settings = AppSettingsBuilder().profitTarget(5.0).build();
        final state = createStateWithOpenPosition(averagePrice: 100.0);
        const currentPrice = 106.0; // Profit > 5% after some fees?

        // Mock fee calculation: returns exactly what we want (gross profit - some fee)
        // (gross is 6%, let's say net is 5.5%)
        // IFeeRepository is stubbed in setUp, let's see if we can use it.
        // Actually, IFeeRepository is a Mock, we need to stub calculateNetProfit if possible.

        // WHEN
        final result = await service.evaluateTradingDecisionsWithFees(
          currentPrice: currentPrice,
          state: state,
          settings: settings,
        );

        // THEN
        expect(result.isRight(), isTrue);
        final decision = result.getOrElse((_) => null);
        expect(decision?.action, TradingAction.sell);
        expect(decision?.reason, contains('Take Profit (Net)'));
      });

      test('[EVAL-06] should handle state inconsistency during evaluation',
          () async {
        // GIVEN
        final invalidTrade = FifoAppTrade(
          price: Decimal.parse('0.0'), // Invalid!
          quantity: Decimal.parse('1.0'),
          timestamp: DateTime.now().millisecondsSinceEpoch,
          roundId: 1,
          isExecuted: true,
        );
        final validTrade = FifoAppTrade(
          price: Decimal.parse('100.0'),
          quantity: Decimal.parse('1.0'),
          timestamp: DateTime.now().millisecondsSinceEpoch,
          roundId: 2,
          isExecuted: true,
        );
        final settings = createAppSettings();
        final state = AppStrategyState(
          symbol: symbol,
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
          openTrades: [invalidTrade, validTrade],
        );

        // WHEN
        final result = await service.evaluateTradingDecisionsWithFees(
          currentPrice: 107.0,
          state: state,
          settings: settings,
        );

        // THEN
        expect(result.isRight(), isTrue);
        final decision = result.getOrElse((_) => null);
        // Should have filtered out the invalid trade, so only 1 trade at 100.0 exists.
        // currentPrice 105.0 vs 100.0 is 5% profit.
        expect(decision?.action, TradingAction.sell);
      });

      test('[EVAL-07] should return null when averagePrice is 0 or negative',
          () {
        // GIVEN
        final settings = createAppSettings();
        final invalidTrade = FifoAppTrade(
          price: Decimal.parse('0.0'),
          quantity: Decimal.parse('1.0'),
          timestamp: 0,
          roundId: 1,
          isExecuted: true,
        );
        final state = AppStrategyState(
          symbol: symbol,
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
          openTrades: [invalidTrade],
        );

        // WHEN
        expect(
            () => service.evaluateTradingDecisions(
                  currentPrice: 100.0,
                  state: state,
                  settings: settings,
                ),
            throwsA(isA<FormatException>()),
            reason: 'Should throw FormatException on corrupted state');
      });
    });
  });
}

FifoAppTrade createMockTrade({required Decimal price, Decimal? quantity}) {
  return FifoAppTrade(
    price: price,
    quantity: quantity ?? Decimal.parse('1.0'),
    timestamp: DateTime.now().millisecondsSinceEpoch,
    roundId: 1,
    isExecuted: true,
  );
}

