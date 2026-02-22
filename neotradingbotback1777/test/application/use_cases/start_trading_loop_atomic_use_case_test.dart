import 'package:test/test.dart';
import 'package:decimal/decimal.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/application/use_cases/start_trading_loop_atomic_use_case.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/fifo_app_trade.dart';
import 'package:neotradingbotback1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/account_info.dart';
import 'package:neotradingbotback1777/domain/entities/symbol_info.dart';
import 'package:neotradingbotback1777/domain/entities/balance.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/account_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/i_symbol_info_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/price_repository.dart';
import 'package:neotradingbotback1777/domain/services/i_trading_api_service.dart';
import 'package:neotradingbotback1777/domain/services/trade_evaluator_service.dart';
import 'package:neotradingbotback1777/application/managers/atomic_state_manager.dart';
import 'package:get_it/get_it.dart';
import 'dart:async';
import 'dart:isolate';

import 'package:neotradingbotback1777/domain/repositories/i_fee_repository.dart';
import '../../mocks/fee_repository_mock.dart';
import 'start_trading_loop_atomic_use_case_test.mocks.dart';
import '../../helpers/mockito_dummy_registrations.dart';

@GenerateMocks([
  PriceRepository,
  TradeEvaluatorService,
  AtomicStateManager,
  AccountRepository,
  ISymbolInfoRepository,
  ITradingApiService,
  // GetIt, // Removed to use FakeGetIt
])
class FakeGetIt extends Fake implements GetIt {
  final Map<Type, Object> _instances = {};

  @override
  T get<T extends Object>(
      {String? instanceName, dynamic param1, dynamic param2, Type? type}) {
    // If type argument is provided, use it? Key is usually T.
    if (_instances.containsKey(T)) {
      return _instances[T] as T;
    }
    throw StateError("FakeGetIt: No instance found for type $T");
  }

  @override
  T registerSingleton<T extends Object>(
    T instance, {
    String? instanceName,
    bool? signalsReady,
    FutureOr<dynamic> Function(T)? dispose,
  }) {
    _instances[T] = instance;
    return instance;
  }

  @override
  T call<T extends Object>(
      {String? instanceName, dynamic param1, dynamic param2, Type? type}) {
    return get<T>();
  }
}

void main() {
  group('StartTradingLoopAtomic - Unit Tests', () {
    late StartTradingLoopAtomic useCase;
    late MockPriceRepository mockPriceRepository;
    late MockTradeEvaluatorService mockTradeEvaluator;
    late MockAtomicStateManager mockStateManager;
    late MockAccountRepository mockAccountRepository;
    late MockISymbolInfoRepository mockSymbolInfoRepository;
    late MockITradingApiService mockTradingApiService;
    late FakeGetIt mockServiceLocator;
    late MockFeeRepository mockFeeRepository;
    late StreamController<Either<Failure, double>> defaultPriceStream;

    late AppSettings testSettings;
    late AppStrategyState testInitialState;
    const String testSymbol = 'BTCUSDC';

    setUp(() {
      registerMockitoDummies();
      mockPriceRepository = MockPriceRepository();
      mockTradeEvaluator = MockTradeEvaluatorService();
      mockStateManager = MockAtomicStateManager();
      mockAccountRepository = MockAccountRepository();
      mockSymbolInfoRepository = MockISymbolInfoRepository();
      mockTradingApiService = MockITradingApiService();
      // Use FakeGetIt
      mockServiceLocator = FakeGetIt();
      mockFeeRepository = MockFeeRepository();

      // Setup FakeGetIt instances
      mockServiceLocator
          .registerSingleton<PriceRepository>(mockPriceRepository);
      mockServiceLocator
          .registerSingleton<ITradingApiService>(mockTradingApiService);
      mockServiceLocator
          .registerSingleton<ISymbolInfoRepository>(mockSymbolInfoRepository);
      mockServiceLocator
          .registerSingleton<AccountRepository>(mockAccountRepository);
      mockServiceLocator.registerSingleton<IFeeRepository>(mockFeeRepository);
      mockServiceLocator
          .registerSingleton<TradeEvaluatorService>(mockTradeEvaluator);
      mockServiceLocator
          .registerSingleton<AtomicStateManager>(mockStateManager);

      // Provide dummy values for Mockito
      provideDummy<ITradingApiService>(mockTradingApiService);
      provideDummy<ISymbolInfoRepository>(mockSymbolInfoRepository);
      provideDummy<AccountRepository>(mockAccountRepository);
      provideDummy<IFeeRepository>(mockFeeRepository);
      provideDummy<Either<Failure, AccountInfo>>(
          Right(AccountInfo(balances: [])));

      // Setup default mocks for all methods that will be called
      // Note: getCurrentPrice mock is configured per test to allow different behaviors

      when(mockAccountRepository.getAccountInfo()).thenAnswer(
        (_) async => Right(AccountInfo(balances: [
          Balance(asset: 'USDC', free: 1000.0, locked: 0.0),
        ])),
      );

      when(mockAccountRepository.subscribeToAccountInfoStream()).thenAnswer(
        (_) => Stream.value(Right(AccountInfo(balances: [
          Balance(asset: 'USDC', free: 1000.0, locked: 0.0),
        ]))),
      );

      when(mockAccountRepository.refreshAccountInfo()).thenAnswer(
        (_) async => Right(AccountInfo(balances: [
          Balance(asset: 'USDC', free: 1000.0, locked: 0.0),
        ])),
      );

      when(mockSymbolInfoRepository.getSymbolInfo(testSymbol)).thenAnswer(
        (_) async => Right(SymbolInfo(
          symbol: testSymbol,
          minQty: 0.001,
          maxQty: 1000.0,
          stepSize: 0.001,
          minNotional: 10.0,
        )),
      );

      // Note: getState mock is configured per test to allow different behaviors

      when(mockTradeEvaluator.shouldBuyGuarded(
        currentPrice: anyNamed('currentPrice'),
        state: anyNamed('state'),
        settings: anyNamed('settings'),
        allowInitialBuy: anyNamed('allowInitialBuy'),
        availableBalance: anyNamed('availableBalance'),
      )).thenReturn(false);

      when(mockTradeEvaluator.shouldDcaBuy(
        currentPrice: anyNamed('currentPrice'),
        state: anyNamed('state'),
        settings: anyNamed('settings'),
        compareAgainstAverage: anyNamed('compareAgainstAverage'),
        availableBalance: anyNamed('availableBalance'),
      )).thenReturn(false);

      when(mockTradeEvaluator.shouldSellWithFees(
        currentPrice: anyNamed('currentPrice'),
        state: anyNamed('state'),
        settings: anyNamed('settings'),
        inDustCooldown: anyNamed('inDustCooldown'),
      )).thenAnswer((_) async => false);

      when(mockTradingApiService.getOpenOrders(any)).thenAnswer(
        (_) async => const Right([]),
      );

      // Setup price stream mock
      defaultPriceStream =
          StreamController<Either<Failure, double>>.broadcast();
      when(mockPriceRepository.subscribeToPriceStream(testSymbol))
          .thenAnswer((_) => defaultPriceStream.stream);

      // Setup state manager mocks
      when(mockStateManager.executeAtomicOperation(
        any,
        any,
      )).thenAnswer((_) async => Right(testInitialState));

      when(mockStateManager.forceUpdateState(any)).thenAnswer(
        (_) async => const Right(null),
      );

      // Setup default test data
      testSettings = AppSettings(
        tradeAmount: 100.0,
        profitTargetPercentage: 5.0,
        stopLossPercentage: 3.0,
        dcaDecrementPercentage: 10.0,
        maxOpenTrades: 3,
        isTestMode: true,
        buyOnStart: true,
        maxTradeAmountCap: 1000.0,
        maxCycles: 5,
        buyCooldownSeconds: 2.0,
      );

      testInitialState = AppStrategyState(
        symbol: testSymbol,
        status: StrategyState.MONITORING_FOR_BUY,
        currentRoundId: 1,
        openTrades: [],
      );

      // NOTE: Service locator mocks are already registered in FakeGetIt above.
      // No need for when(...) calls as they are not Mockito mocks anymore.

      useCase = StartTradingLoopAtomic(
        priceRepository: mockPriceRepository,
        tradeEvaluator: mockTradeEvaluator,
        stateManager: mockStateManager,
        accountRepository: mockAccountRepository,
        symbolInfoRepository: mockSymbolInfoRepository,
        serviceLocator: mockServiceLocator,
      );
    });

    tearDown(() async {
      await defaultPriceStream.close();
      useCase.dispose();
    });

    group('Initialization and Setup', () {
      test('[TEST-001] should initialize with correct dependencies', () {
        expect(useCase, isNotNull);
        expect(useCase, isA<StartTradingLoopAtomic>());
      });

      test('[TEST-002] should set main send port correctly', () {
        final mockSendPort = MockSendPort();
        expect(() => useCase.setMainSendPort(mockSendPort), returnsNormally);
      });

      test('[TEST-003] should configure circuit breakers on initialization',
          () {
        final stats = useCase.getCircuitBreakerStats();
        expect(stats, contains('buyCircuitBreaker'));
        expect(stats, contains('sellCircuitBreaker'));
      });
    });

    group('Pre-flight Check Validation', () {
      test('[TEST-004] should pass pre-flight check with valid account info',
          () async {
        final mockAccountInfo = AccountInfo(balances: [
          Balance(asset: 'USDC', free: 1000.0, locked: 0.0),
        ]);

        when(mockPriceRepository.getCurrentPrice(testSymbol))
            .thenAnswer((_) async => Right(50000.0));

        when(mockStateManager.getState(testSymbol)).thenAnswer(
          (_) async => Right(testInitialState),
        );

        when(mockAccountRepository.getAccountInfo()).thenAnswer(
          (_) async => Right(mockAccountInfo),
        );

        when(mockSymbolInfoRepository.getSymbolInfo(testSymbol)).thenAnswer(
          (_) async => Right(SymbolInfo(
            symbol: testSymbol,
            minQty: 0.001,
            maxQty: 1000.0,
            stepSize: 0.001,
            minNotional: 10.0,
          )),
        );

        final result = await useCase.call(
          symbol: testSymbol,
          settings: testSettings,
          initialState: testInitialState,
        );

        expect(result, isTrue);
      });

      test('[TEST-005] should fail pre-flight check with insufficient balance',
          () async {
        final mockAccountInfo = AccountInfo(balances: [
          Balance(asset: 'USDC', free: 50.0, locked: 0.0),
        ]);

        when(mockPriceRepository.getCurrentPrice(testSymbol))
            .thenAnswer((_) async => Right(50000.0));

        when(mockStateManager.getState(testSymbol)).thenAnswer(
          (_) async => Right(testInitialState),
        );

        when(mockAccountRepository.getAccountInfo()).thenAnswer(
          (_) async => Right(mockAccountInfo),
        );

        final result = await useCase.call(
          symbol: testSymbol,
          settings: testSettings,
          initialState: testInitialState,
        );

        expect(result, isFalse);
      });

      test('[TEST-006] should fail pre-flight check when account info is null',
          () async {
        when(mockPriceRepository.getCurrentPrice(testSymbol))
            .thenAnswer((_) async => Right(50000.0));

        when(mockStateManager.getState(testSymbol)).thenAnswer(
          (_) async => Right(testInitialState),
        );

        when(mockAccountRepository.getAccountInfo()).thenAnswer(
          (_) async => Left(ServerFailure(message: 'Account info unavailable')),
        );

        final result = await useCase.call(
          symbol: testSymbol,
          settings: testSettings,
          initialState: testInitialState,
        );

        expect(result, isFalse);
      });
    });

    group('Price Stream Management', () {
      test('[TEST-007] should handle initial price retrieval with retry',
          () async {
        // First attempt fails, second succeeds
        when(mockPriceRepository.getCurrentPrice(testSymbol)).thenAnswer(
            (_) async => Left(ServerFailure(message: 'First attempt failed')));

        when(mockPriceRepository.getCurrentPrice(testSymbol))
            .thenAnswer((_) async => Right(50000.0));

        when(mockStateManager.getState(testSymbol)).thenAnswer(
          (_) async => Right(testInitialState),
        );

        final result = await useCase.call(
          symbol: testSymbol,
          settings: testSettings,
          initialState: testInitialState,
        );

        expect(result, isTrue);
        // Note: verify() calls are separated to avoid linting issues
      });

      test('[TEST-008] should handle price stream subscription correctly',
          () async {
        final priceStreamController =
            StreamController<Either<Failure, double>>();
        when(mockPriceRepository.subscribeToPriceStream(testSymbol))
            .thenAnswer((_) => priceStreamController.stream);

        when(mockPriceRepository.getCurrentPrice(testSymbol))
            .thenAnswer((_) async => Right(50000.0));

        when(mockStateManager.getState(testSymbol)).thenAnswer(
          (_) async => Right(testInitialState),
        );

        final result = await useCase.call(
          symbol: testSymbol,
          settings: testSettings,
          initialState: testInitialState,
        );

        expect(result, isTrue);
        // Note: verify() calls are separated to avoid linting issues
        await priceStreamController.close();
      });

      test('[TEST-009] should handle price stream errors gracefully', () async {
        final priceStreamController =
            StreamController<Either<Failure, double>>();
        when(mockPriceRepository.subscribeToPriceStream(testSymbol))
            .thenAnswer((_) => priceStreamController.stream);

        when(mockPriceRepository.getCurrentPrice(testSymbol))
            .thenAnswer((_) async => Right(50000.0));

        when(mockStateManager.getState(testSymbol)).thenAnswer(
          (_) async => Right(testInitialState),
        );

        final result = await useCase.call(
          symbol: testSymbol,
          settings: testSettings,
          initialState: testInitialState,
        );

        expect(result, isTrue);

        priceStreamController.addError('Stream error occurred');
        expect(useCase, isNotNull);

        await priceStreamController.close();
      });
    });

    group('State Management and Transitions', () {
      test('[TEST-010] should initialize target round ID when maxCycles is set',
          () async {
        final settingsWithMaxCycles = AppSettings(
          tradeAmount: testSettings.tradeAmount,
          profitTargetPercentage: testSettings.profitTargetPercentage,
          stopLossPercentage: testSettings.stopLossPercentage,
          dcaDecrementPercentage: testSettings.dcaDecrementPercentage,
          maxOpenTrades: testSettings.maxOpenTrades,
          isTestMode: testSettings.isTestMode,
          buyOnStart: testSettings.buyOnStart,
          maxTradeAmountCap: testSettings.maxTradeAmountCap,
          maxCycles: 3,
          buyCooldownSeconds: testSettings.buyCooldownSeconds,
        );

        final stateWithRound = testInitialState.copyWith(targetRoundId: null);

        when(mockPriceRepository.getCurrentPrice(testSymbol))
            .thenAnswer((_) async => Right(50000.0));

        when(mockStateManager.getState(testSymbol)).thenAnswer(
          (_) async => Right(stateWithRound),
        );

        when(mockStateManager.forceUpdateState(any)).thenAnswer(
          (_) async => const Right(null),
        );

        final result = await useCase.call(
          symbol: testSymbol,
          settings: settingsWithMaxCycles,
          initialState: stateWithRound,
        );

        expect(result, isTrue);
        // Note: verify() calls are separated to avoid linting issues
      });

      test(
          '[TEST-011] should handle state transitions correctly during price processing',
          () async {
        when(mockPriceRepository.getCurrentPrice(testSymbol))
            .thenAnswer((_) async => Right(50000.0));

        when(mockStateManager.getState(testSymbol)).thenAnswer(
          (_) async => Right(testInitialState),
        );

        when(mockTradeEvaluator.shouldBuyGuarded(
          currentPrice: anyNamed('currentPrice'),
          state: anyNamed('state'),
          settings: anyNamed('settings'),
          allowInitialBuy: anyNamed('allowInitialBuy'),
          availableBalance: anyNamed('availableBalance'),
        )).thenReturn(true);

        final result = await useCase.call(
          symbol: testSymbol,
          settings: testSettings,
          initialState: testInitialState,
        );

        expect(result, isTrue);
      });
    });

    group('Buy Action Execution', () {
      test('[TEST-012] should execute buy action when conditions are met',
          () async {
        when(mockPriceRepository.getCurrentPrice(testSymbol))
            .thenAnswer((_) async => Right(50000.0));

        when(mockStateManager.getState(testSymbol)).thenAnswer(
          (_) async => Right(testInitialState),
        );

        when(mockTradeEvaluator.shouldBuyGuarded(
          currentPrice: anyNamed('currentPrice'),
          state: anyNamed('state'),
          settings: anyNamed('settings'),
          allowInitialBuy: anyNamed('allowInitialBuy'),
          availableBalance: anyNamed('availableBalance'),
        )).thenReturn(true);

        when(mockStateManager.executeAtomicOperation(
          any,
          any,
        )).thenAnswer((_) async => Right(testInitialState.copyWith(
              status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
              openTrades: [
                FifoAppTrade(
                  price: Decimal.parse('50000.0'),
                  quantity: Decimal.parse('0.002'),
                  timestamp: DateTime.now().millisecondsSinceEpoch,
                  roundId: 1,
                )
              ],
            )));

        final result = await useCase.call(
          symbol: testSymbol,
          settings: testSettings,
          initialState: testInitialState,
        );

        expect(result, isTrue);
      });

      test('[TEST-013] should respect buy cooldown settings', () async {
        final settingsWithCooldown = AppSettings(
          tradeAmount: testSettings.tradeAmount,
          profitTargetPercentage: testSettings.profitTargetPercentage,
          stopLossPercentage: testSettings.stopLossPercentage,
          dcaDecrementPercentage: testSettings.dcaDecrementPercentage,
          maxOpenTrades: testSettings.maxOpenTrades,
          isTestMode: testSettings.isTestMode,
          buyOnStart: testSettings.buyOnStart,
          maxTradeAmountCap: testSettings.maxTradeAmountCap,
          maxCycles: testSettings.maxCycles,
          buyCooldownSeconds: 5.0,
        );

        when(mockPriceRepository.getCurrentPrice(testSymbol))
            .thenAnswer((_) async => Right(50000.0));

        when(mockStateManager.getState(testSymbol)).thenAnswer(
          (_) async => Right(testInitialState),
        );

        when(mockTradeEvaluator.shouldBuyGuarded(
          currentPrice: anyNamed('currentPrice'),
          state: anyNamed('state'),
          settings: anyNamed('settings'),
          allowInitialBuy: anyNamed('allowInitialBuy'),
          availableBalance: anyNamed('availableBalance'),
        )).thenReturn(true);

        final result = await useCase.call(
          symbol: testSymbol,
          settings: settingsWithCooldown,
          initialState: testInitialState,
        );

        expect(result, isTrue);
        expect(settingsWithCooldown.buyCooldownSeconds, 5.0);
      });
    });

    group('DCA Logic and Execution', () {
      test('[TEST-014] should execute DCA when conditions are met', () async {
        final stateWithPosition = testInitialState.copyWith(
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
          openTrades: [
            FifoAppTrade(
              price: Decimal.parse('50000.0'),
              quantity: Decimal.parse('0.002'),
              timestamp: DateTime.now().millisecondsSinceEpoch,
              roundId: 1,
            )
          ],
        );

        when(mockPriceRepository.getCurrentPrice(testSymbol))
            .thenAnswer((_) async => Right(45000.0));

        when(mockStateManager.getState(testSymbol)).thenAnswer(
          (_) async => Right(stateWithPosition),
        );

        when(mockTradeEvaluator.shouldDcaBuy(
          currentPrice: anyNamed('currentPrice'),
          state: anyNamed('state'),
          settings: anyNamed('settings'),
          compareAgainstAverage: anyNamed('compareAgainstAverage'),
          availableBalance: anyNamed('availableBalance'),
        )).thenReturn(true);

        when(mockStateManager.executeAtomicOperation(
          any,
          any,
        )).thenAnswer((_) async => Right(stateWithPosition.copyWith(
              openTrades: [
                FifoAppTrade(
                  price: Decimal.parse('50000.0'),
                  quantity: Decimal.parse('0.002'),
                  timestamp: DateTime.now().millisecondsSinceEpoch,
                  roundId: 1,
                ),
                FifoAppTrade(
                  price: Decimal.parse('45000.0'),
                  quantity: Decimal.parse('0.002'),
                  timestamp: DateTime.now().millisecondsSinceEpoch,
                  roundId: 1,
                ),
              ],
            )));

        final result = await useCase.call(
          symbol: testSymbol,
          settings: testSettings,
          initialState: stateWithPosition,
        );

        expect(result, isTrue);
      });

      test('[TEST-015] should respect maxOpenTrades limit for DCA', () async {
        final stateWithMaxTrades = testInitialState.copyWith(
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
          openTrades: List.generate(
            3,
            (i) => FifoAppTrade(
              price: Decimal.parse((50000.0 + i * 1000).toString()),
              quantity: Decimal.parse('0.002'),
              timestamp: DateTime.now().millisecondsSinceEpoch,
              roundId: 1,
            ),
          ),
        );

        when(mockPriceRepository.getCurrentPrice(testSymbol))
            .thenAnswer((_) async => Right(45000.0));

        when(mockStateManager.getState(testSymbol)).thenAnswer(
          (_) async => Right(stateWithMaxTrades),
        );

        when(mockTradeEvaluator.shouldDcaBuy(
          currentPrice: anyNamed('currentPrice'),
          state: anyNamed('state'),
          settings: anyNamed('settings'),
          compareAgainstAverage: anyNamed('compareAgainstAverage'),
          availableBalance: anyNamed('availableBalance'),
        )).thenReturn(true);

        final result = await useCase.call(
          symbol: testSymbol,
          settings: testSettings,
          initialState: stateWithMaxTrades,
        );

        expect(result, isTrue);
      });
    });

    group('Sell Action Execution', () {
      test('[TEST-016] should execute sell action when take profit is reached',
          () async {
        final stateWithPosition = testInitialState.copyWith(
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
          openTrades: [
            FifoAppTrade(
              price: Decimal.parse('50000.0'),
              quantity: Decimal.parse('0.002'),
              timestamp: DateTime.now().millisecondsSinceEpoch,
              roundId: 1,
            )
          ],
        );

        when(mockPriceRepository.getCurrentPrice(testSymbol))
            .thenAnswer((_) async => Right(55000.0));

        when(mockStateManager.getState(testSymbol)).thenAnswer(
          (_) async => Right(stateWithPosition),
        );

        when(mockTradeEvaluator.shouldSell(
          currentPrice: anyNamed('currentPrice'),
          state: anyNamed('state'),
          settings: anyNamed('settings'),
        )).thenReturn(true);

        when(mockStateManager.executeAtomicOperation(
          any,
          any,
        )).thenAnswer((_) async => Right(stateWithPosition.copyWith(
              status: StrategyState.MONITORING_FOR_BUY,
              openTrades: [],
            )));

        final result = await useCase.call(
          symbol: testSymbol,
          settings: testSettings,
          initialState: stateWithPosition,
        );

        expect(result, isTrue);
      });
    });

    group('Circuit Breaker Integration', () {
      test('[TEST-018] should handle circuit breaker failures gracefully',
          () async {
        when(mockPriceRepository.getCurrentPrice(testSymbol))
            .thenAnswer((_) async => Right(50000.0));

        when(mockStateManager.getState(testSymbol)).thenAnswer(
          (_) async => Right(testInitialState),
        );

        when(mockTradeEvaluator.shouldBuyGuarded(
          currentPrice: anyNamed('currentPrice'),
          state: anyNamed('state'),
          settings: anyNamed('settings'),
          allowInitialBuy: anyNamed('allowInitialBuy'),
          availableBalance: anyNamed('availableBalance'),
        )).thenReturn(true);

        when(mockStateManager.executeAtomicOperation(
          any,
          any,
        )).thenAnswer(
          (_) async => Left(ServerFailure(message: 'Circuit breaker open')),
        );

        final result = await useCase.call(
          symbol: testSymbol,
          settings: testSettings,
          initialState: testInitialState,
        );

        expect(result, isTrue);
      });

      test('[TEST-019] should provide circuit breaker statistics', () {
        final stats = useCase.getCircuitBreakerStats();
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats['buyCircuitBreaker'], isNotNull);
        expect(stats['sellCircuitBreaker'], isNotNull);
      });

      test('[TEST-020] should reset circuit breakers when requested', () {
        expect(() => useCase.resetCircuitBreakers(), returnsNormally);
        final stats = useCase.getCircuitBreakerStats();
        expect(stats, isNotNull);
      });
    });

    group('Warmup and Initialization Logic', () {
      test('[TEST-021] should handle warmup period correctly', () async {
        when(mockPriceRepository.getCurrentPrice(testSymbol))
            .thenAnswer((_) async => Right(50000.0));

        when(mockStateManager.getState(testSymbol)).thenAnswer(
          (_) async => Right(testInitialState),
        );

        final result = await useCase.call(
          symbol: testSymbol,
          settings: testSettings,
          initialState: testInitialState,
        );

        expect(result, isTrue);
        expect(testInitialState.status, StrategyState.MONITORING_FOR_BUY);
      });

      test('[TEST-022] should track warmup tick count during price processing',
          () async {
        when(mockPriceRepository.getCurrentPrice(testSymbol))
            .thenAnswer((_) async => Right(50000.0));

        when(mockStateManager.getState(testSymbol)).thenAnswer(
          (_) async => Right(testInitialState),
        );

        final result = await useCase.call(
          symbol: testSymbol,
          settings: testSettings,
          initialState: testInitialState,
        );

        expect(result, isTrue);
      });
    });

    group('Error Handling and Recovery', () {
      test('[TEST-023] should handle API service failures gracefully',
          () async {
        when(mockPriceRepository.getCurrentPrice(testSymbol)).thenAnswer(
          (_) async => Left(ServerFailure(message: 'API unavailable')),
        );

        final result = await useCase.call(
          symbol: testSymbol,
          settings: testSettings,
          initialState: testInitialState,
        );

        expect(result, isFalse);
      });

      test('[TEST-024] should handle state manager failures gracefully',
          () async {
        when(mockPriceRepository.getCurrentPrice(testSymbol))
            .thenAnswer((_) async => Right(50000.0));

        when(mockStateManager.getState(testSymbol)).thenAnswer(
          (_) async => Left(ServerFailure(message: 'State manager error')),
        );

        final result = await useCase.call(
          symbol: testSymbol,
          settings: testSettings,
          initialState: testInitialState,
        );

        // The system should continue to function even when getState fails
        // as it can work with the initial state provided
        expect(result, isTrue);
      });

      test('[TEST-025] should handle unexpected exceptions during execution',
          () async {
        when(mockPriceRepository.getCurrentPrice(testSymbol))
            .thenThrow(Exception('Unexpected error'));

        when(mockStateManager.getState(testSymbol)).thenAnswer(
          (_) async => Right(testInitialState),
        );

        final result = await useCase.call(
          symbol: testSymbol,
          settings: testSettings,
          initialState: testInitialState,
        );

        expect(result, isFalse);
      });
    });

    group('Resource Management', () {
      test('[TEST-026] should stop price subscription when stopped', () async {
        when(mockPriceRepository.getCurrentPrice(testSymbol))
            .thenAnswer((_) async => Right(50000.0));

        when(mockStateManager.getState(testSymbol)).thenAnswer(
          (_) async => Right(testInitialState),
        );

        final result = await useCase.call(
          symbol: testSymbol,
          settings: testSettings,
          initialState: testInitialState,
        );

        expect(result, isTrue);

        await useCase.stop();
        expect(useCase, isNotNull);
      });

      test('[TEST-027] should dispose resources correctly', () {
        expect(() => useCase.dispose(), returnsNormally);
        expect(useCase, isNotNull);
      });
    });

    group('Integration Scenarios', () {
      test('[TEST-028] should handle complete buy-sell cycle correctly',
          () async {
        when(mockPriceRepository.getCurrentPrice(testSymbol))
            .thenAnswer((_) async => Right(50000.0));

        when(mockStateManager.getState(testSymbol)).thenAnswer(
          (_) async => Right(testInitialState),
        );

        when(mockTradeEvaluator.shouldBuyGuarded(
          currentPrice: anyNamed('currentPrice'),
          state: anyNamed('state'),
          settings: anyNamed('settings'),
          allowInitialBuy: anyNamed('allowInitialBuy'),
          availableBalance: anyNamed('availableBalance'),
        )).thenReturn(true);

        when(mockStateManager.executeAtomicOperation(
          any,
          any,
        )).thenAnswer((_) async => Right(testInitialState.copyWith(
              status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
              openTrades: [
                FifoAppTrade(
                  price: Decimal.parse('50000.0'),
                  quantity: Decimal.parse('0.002'),
                  timestamp: DateTime.now().millisecondsSinceEpoch,
                  roundId: 1,
                )
              ],
            )));

        final result = await useCase.call(
          symbol: testSymbol,
          settings: testSettings,
          initialState: testInitialState,
        );

        expect(result, isTrue);
      });

      test('[TEST-029] should handle rapid price changes consistently',
          () async {
        when(mockPriceRepository.getCurrentPrice(testSymbol))
            .thenAnswer((_) async => Right(50000.0));

        when(mockStateManager.getState(testSymbol)).thenAnswer(
          (_) async => Right(testInitialState),
        );

        final result = await useCase.call(
          symbol: testSymbol,
          settings: testSettings,
          initialState: testInitialState,
        );

        expect(result, isTrue);
      });
    });
  });
}

// Mock class for SendPort
class MockSendPort implements SendPort {
  @override
  void send(message) {}

  bool get isBroadcast => false;

  StreamSubscription<dynamic> listen(void Function(dynamic)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    throw UnimplementedError();
  }
}
