import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:decimal/decimal.dart';

import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/fifo_app_trade.dart';
import 'package:neotradingbotback1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotback1777/domain/services/trade_evaluator_service.dart';
import 'package:neotradingbotback1777/domain/services/trading_signal_analyzer.dart';

class MockTradeEvaluatorService extends Mock implements TradeEvaluatorService {}

void main() {
  late TradingSignalAnalyzer analyzer;
  late MockTradeEvaluatorService mockTradeEvaluator;
  late AppSettings defaultSettings;

  setUpAll(() {
    registerFallbackValue(AppStrategyState(symbol: 'BTCUSDT'));
    registerFallbackValue(AppSettings(
      tradeAmount: 10.0,
      profitTargetPercentage: 2.0,
      stopLossPercentage: 1.0,
      dcaDecrementPercentage: 5.0,
      maxOpenTrades: 3,
      isTestMode: false,
    ));
  });

  setUp(() {
    mockTradeEvaluator = MockTradeEvaluatorService();
    analyzer = TradingSignalAnalyzer(mockTradeEvaluator);
    defaultSettings = AppSettings(
      tradeAmount: 10.0,
      profitTargetPercentage: 2.0,
      stopLossPercentage: 1.0,
      isTestMode: false,
      enableFeeAwareTrading: false,
      maxOpenTrades: 3,
      dcaDecrementPercentage: 5.0,
      dcaCompareAgainstAverage: false,
    );
  });

  group('TradingSignalAnalyzer - shouldBuy', () {
    test('returns false if warmup is not done', () {
      final state = AppStrategyState(
          symbol: 'BTCUSDT', status: StrategyState.MONITORING_FOR_BUY);
      final result =
          analyzer.shouldBuy(50000, state, defaultSettings, false, false);
      expect(result, isFalse);
    });

    test('returns false if in cooldown', () {
      final state = AppStrategyState(
          symbol: 'BTCUSDT', status: StrategyState.MONITORING_FOR_BUY);
      final result =
          analyzer.shouldBuy(50000, state, defaultSettings, true, true);
      expect(result, isFalse);
    });

    test('returns false if state status is not MONITORING_FOR_BUY', () {
      final state = AppStrategyState(
          symbol: 'BTCUSDT',
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL);
      final result =
          analyzer.shouldBuy(50000, state, defaultSettings, false, true);
      expect(result, isFalse);
    });

    test('delegates to TradeEvaluatorService when all conditions are met', () {
      final state = AppStrategyState(
          symbol: 'BTCUSDT', status: StrategyState.MONITORING_FOR_BUY);
      when(() => mockTradeEvaluator.shouldBuyGuarded(
            currentPrice: any(named: 'currentPrice'),
            state: any(named: 'state'),
            settings: any(named: 'settings'),
            allowInitialBuy: any(named: 'allowInitialBuy'),
          )).thenReturn(true);

      final result =
          analyzer.shouldBuy(50000, state, defaultSettings, false, true);

      expect(result, isTrue);
      verify(() => mockTradeEvaluator.shouldBuyGuarded(
            currentPrice: 50000,
            state: state,
            settings: defaultSettings,
            allowInitialBuy: true,
          )).called(1);
    });
  });

  group('TradingSignalAnalyzer - shouldSell', () {
    test(
        'returns false if state status is not POSITION_OPEN_MONITORING_FOR_SELL',
        () async {
      final state = AppStrategyState(
          symbol: 'BTCUSDT', status: StrategyState.MONITORING_FOR_BUY);
      final result =
          await analyzer.shouldSell(50000, state, defaultSettings, false);
      expect(result, isFalse);
    });

    test('delegates to shouldSell if enableFeeAwareTrading is false', () async {
      final state = AppStrategyState(
          symbol: 'BTCUSDT',
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL);
      when(() => mockTradeEvaluator.shouldSell(
            currentPrice: any(named: 'currentPrice'),
            state: any(named: 'state'),
            settings: any(named: 'settings'),
            inDustCooldown: any(named: 'inDustCooldown'),
          )).thenReturn(true);

      final result =
          await analyzer.shouldSell(50000, state, defaultSettings, false);

      expect(result, isTrue);
      verify(() => mockTradeEvaluator.shouldSell(
            currentPrice: 50000,
            state: state,
            settings: defaultSettings,
            inDustCooldown: false,
          )).called(1);
      verifyNever(() => mockTradeEvaluator.shouldSellWithFees(
            currentPrice: any(named: 'currentPrice'),
            state: any(named: 'state'),
            settings: any(named: 'settings'),
            inDustCooldown: any(named: 'inDustCooldown'),
          ));
    });

    test('delegates to shouldSellWithFees if enableFeeAwareTrading is true',
        () async {
      final settingsWithFees =
          defaultSettings.copyWith(enableFeeAwareTrading: true);
      final state = AppStrategyState(
          symbol: 'BTCUSDT',
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL);
      when(() => mockTradeEvaluator.shouldSellWithFees(
            currentPrice: any(named: 'currentPrice'),
            state: any(named: 'state'),
            settings: any(named: 'settings'),
            inDustCooldown: any(named: 'inDustCooldown'),
          )).thenAnswer((_) async => true);

      final result =
          await analyzer.shouldSell(50000, state, settingsWithFees, false);

      expect(result, isTrue);
      verify(() => mockTradeEvaluator.shouldSellWithFees(
            currentPrice: 50000,
            state: state,
            settings: settingsWithFees,
            inDustCooldown: false,
          )).called(1);
      verifyNever(() => mockTradeEvaluator.shouldSell(
            currentPrice: any(named: 'currentPrice'),
            state: any(named: 'state'),
            settings: any(named: 'settings'),
            inDustCooldown: any(named: 'inDustCooldown'),
          ));
    });
  });

  group('TradingSignalAnalyzer - shouldDca', () {
    test(
        'returns false if state status is not POSITION_OPEN_MONITORING_FOR_SELL',
        () {
      final state = AppStrategyState(
          symbol: 'BTCUSDT', status: StrategyState.MONITORING_FOR_BUY);

      when(() => mockTradeEvaluator.shouldDcaBuy(
            currentPrice: any(named: 'currentPrice'),
            state: any(named: 'state'),
            settings: any(named: 'settings'),
            compareAgainstAverage: any(named: 'compareAgainstAverage'),
            availableBalance: any(named: 'availableBalance'),
          )).thenReturn(false);

      final result = analyzer.shouldDca(50000, state, defaultSettings, false);
      expect(result, isFalse);
    });

    test('returns false if in DCA cooldown', () {
      final state = AppStrategyState(
          symbol: 'BTCUSDT',
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL);
      final result = analyzer.shouldDca(50000, state, defaultSettings, true);
      expect(result, isFalse);
      verifyNever(() => mockTradeEvaluator.shouldDcaBuy(
            currentPrice: any(named: 'currentPrice'),
            state: any(named: 'state'),
            settings: any(named: 'settings'),
            compareAgainstAverage: any(named: 'compareAgainstAverage'),
            availableBalance: any(named: 'availableBalance'),
          ));
    });

    test('returns false if total open trades >= maxOpenTrades', () {
      final trade1 = FifoAppTrade(
        price: Decimal.parse('50000'),
        quantity: Decimal.parse('1'),
        roundId: 1,
        timestamp: 1,
        orderStatus: 'FILLED',
      );
      final state = AppStrategyState(
        symbol: 'BTCUSDT',
        status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
        openTrades: [trade1, trade1, trade1],
      );

      when(() => mockTradeEvaluator.shouldDcaBuy(
            currentPrice: any(named: 'currentPrice'),
            state: any(named: 'state'),
            settings: any(named: 'settings'),
            compareAgainstAverage: any(named: 'compareAgainstAverage'),
            availableBalance: any(named: 'availableBalance'),
          )).thenReturn(false);

      final result = analyzer.shouldDca(50000, state, defaultSettings, false);
      expect(result, isFalse);
    });

    test('returns false if referencePrice <= 0', () {
      final trade = FifoAppTrade(
        price: Decimal.parse('0'), // Trigger 0 reference price
        quantity: Decimal.parse('1'),
        roundId: 1,
        timestamp: 1,
        orderStatus: 'FILLED',
      );
      final state = AppStrategyState(
        symbol: 'BTCUSDT',
        status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
        openTrades: [trade],
      );

      when(() => mockTradeEvaluator.shouldDcaBuy(
            currentPrice: any(named: 'currentPrice'),
            state: any(named: 'state'),
            settings: any(named: 'settings'),
            compareAgainstAverage: any(named: 'compareAgainstAverage'),
            availableBalance: any(named: 'availableBalance'),
          )).thenReturn(false);

      final result = analyzer.shouldDca(50000, state, defaultSettings, false);
      expect(result, isFalse);
    });

    test(
        'returns true when current price falls below threshold (against last valid buy price)',
        () {
      final trade = FifoAppTrade(
        price: Decimal.parse('50000'),
        quantity: Decimal.parse('1'),
        roundId: 1,
        timestamp: 1,
        orderStatus: 'FILLED',
      );
      final state = AppStrategyState(
        symbol: 'BTCUSDT',
        status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
        openTrades: [trade],
      );

      when(() => mockTradeEvaluator.shouldDcaBuy(
            currentPrice: any(named: 'currentPrice'),
            state: any(named: 'state'),
            settings: any(named: 'settings'),
            compareAgainstAverage: any(named: 'compareAgainstAverage'),
            availableBalance: any(named: 'availableBalance'),
          )).thenReturn(false);

      // Settings: 5% decrement. 5% of 50000 is 2500. Threshold is 47500.
      final resultFalse =
          analyzer.shouldDca(48000, state, defaultSettings, false); // -4%
      expect(resultFalse, isFalse);

      when(() => mockTradeEvaluator.shouldDcaBuy(
            currentPrice: 47000,
            state: state,
            settings: defaultSettings,
            compareAgainstAverage: false,
            availableBalance: any(named: 'availableBalance'),
          )).thenReturn(true);

      final resultTrue =
          analyzer.shouldDca(47000, state, defaultSettings, false); // -6%
      expect(resultTrue, isTrue);
    });

    test(
        'returns true when current price falls below threshold (against average price)',
        () {
      final trade1 = FifoAppTrade(
        price: Decimal.parse('60000'),
        quantity: Decimal.parse('1'),
        roundId: 1,
        timestamp: 1,
        orderStatus: 'FILLED',
      );
      final trade2 = FifoAppTrade(
        price: Decimal.parse('40000'),
        quantity: Decimal.parse('1'),
        roundId: 2,
        timestamp: 2,
        orderStatus: 'FILLED',
      );
      final state = AppStrategyState(
        symbol: 'BTCUSDT',
        status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
        openTrades: [trade1, trade2],
      );

      // Average is 50000. Settings: dcaCompareAgainstAverage = true, 10% decrement.
      // 10% of 50000 is 5000. Threshold is 45000.
      final settings = defaultSettings.copyWith(
        dcaCompareAgainstAverage: true,
        dcaDecrementPercentage: 10.0,
      );

      when(() => mockTradeEvaluator.shouldDcaBuy(
            currentPrice: 46000,
            state: state,
            settings: settings,
            compareAgainstAverage: true,
            availableBalance: any(named: 'availableBalance'),
          )).thenReturn(false);

      final resultFalse =
          analyzer.shouldDca(46000, state, settings, false); // -8%
      expect(resultFalse, isFalse);

      when(() => mockTradeEvaluator.shouldDcaBuy(
            currentPrice: 44000,
            state: state,
            settings: settings,
            compareAgainstAverage: true,
            availableBalance: any(named: 'availableBalance'),
          )).thenReturn(true);

      final resultTrue =
          analyzer.shouldDca(44000, state, settings, false); // -12%
      expect(resultTrue, isTrue);
    });
  });
}

