import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/application/use_cases/start_strategy_atomic_use_case.dart';
import 'package:neotradingbotback1777/application/use_cases/start_trading_loop_atomic_use_case.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/account_info.dart';
import 'package:neotradingbotback1777/domain/entities/balance.dart';
import 'package:neotradingbotback1777/domain/entities/symbol_info.dart';
import 'package:neotradingbotback1777/domain/entities/price.dart';
import 'package:neotradingbotback1777/domain/entities/exchange_info.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/application/managers/trading_loop_manager.dart';
import 'package:neotradingbotback1777/application/managers/atomic_state_manager.dart';
import 'package:neotradingbotback1777/domain/repositories/price_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/account_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/i_symbol_info_repository.dart';
import 'package:neotradingbotback1777/domain/services/trade_evaluator_service.dart';
import 'package:neotradingbotback1777/domain/services/i_trading_api_service.dart';
import 'package:get_it/get_it.dart';
import 'package:neotradingbotback1777/domain/repositories/i_fee_repository.dart'; // Added
import 'package:neotradingbotback1777/domain/entities/fee_info.dart'; // Added

import 'system_stability_integration_test.mocks.dart';

@GenerateMocks([
  TradingLoopManager,
  AtomicStateManager,
  PriceRepository,
  AccountRepository,
  ISymbolInfoRepository,
  TradeEvaluatorService,
  ITradingApiService,
  GetIt,
])
void main() {
  group('[INTEGRATION-TEST-001] System Stability Integration Tests', () {
    late MockTradingLoopManager mockTradingLoopManager;
    late MockAtomicStateManager mockStateManager;
    late MockPriceRepository mockPriceRepository;
    late MockAccountRepository mockAccountRepository;
    late MockISymbolInfoRepository mockSymbolInfoRepository;
    late MockTradeEvaluatorService mockTradeEvaluator;
    late MockITradingApiService mockTradingApiService;
    late GetIt serviceLocator;

    late AppSettings testSettings;
    const String testSymbol = 'BTCUSDC';

    setUp(() {
      mockTradingLoopManager = MockTradingLoopManager();
      mockStateManager = MockAtomicStateManager();
      mockPriceRepository = MockPriceRepository();
      mockAccountRepository = MockAccountRepository();
      mockSymbolInfoRepository = MockISymbolInfoRepository();
      mockTradeEvaluator = MockTradeEvaluatorService();
      mockTradingApiService = MockITradingApiService();
      serviceLocator = GetIt.asNewInstance();
      serviceLocator
          .registerSingleton<ITradingApiService>(mockTradingApiService);
      serviceLocator
          .registerSingleton<ISymbolInfoRepository>(mockSymbolInfoRepository);
      serviceLocator
          .registerSingleton<AccountRepository>(mockAccountRepository);
      serviceLocator.registerSingleton<IFeeRepository>(FakeFeeRepository());

      // Provide dummies for Either types
      provideDummy<Either<Failure, Price>>(
          Right(Price(symbol: 'DUMMY', price: 0, timestamp: DateTime.now())));
      provideDummy<Either<Failure, ExchangeInfo>>(
          const Right(ExchangeInfo(symbols: [])));
      provideDummy<Either<Failure, AccountInfo>>(
          const Right(AccountInfo(balances: [])));
      provideDummy<Either<Failure, AccountInfo?>>(
          const Right(AccountInfo(balances: [])));
      provideDummy<Either<Failure, SymbolInfo>>(const Right(SymbolInfo(
          symbol: 'DUMMY', minQty: 0, maxQty: 0, stepSize: 0, minNotional: 0)));
      provideDummy<Either<Failure, double>>(const Right(0.0));
      provideDummy<Either<Failure, double?>>(const Right(0.0));
      provideDummy<Either<Failure, Unit>>(const Right(unit));
      provideDummy<Either<Failure, AppStrategyState>>(Right(AppStrategyState(
          symbol: 'DUMMY', status: StrategyState.MONITORING_FOR_BUY)));
      provideDummy<Either<Failure, Price?>>(
          Right(Price(symbol: 'DUMMY', price: 0, timestamp: DateTime.now())));
      provideDummy<Either<Failure, ExchangeInfo?>>(
          const Right(ExchangeInfo(symbols: [])));
      provideDummy<Either<Failure, SymbolInfo?>>(const Right(SymbolInfo(
          symbol: 'DUMMY', minQty: 0, maxQty: 0, stepSize: 0, minNotional: 0)));
      provideDummy<Either<Failure, void>>(const Right(null));

      // Setup standard mocks
      // Setup standard mocks - REMOVED MockGetIt stubs as we use Real GetIt

      // Mock per ITradingApiService
      when(mockTradingApiService.getLatestPrice(testSymbol)).thenAnswer(
        (_) async => Right(Price(
          symbol: testSymbol,
          price: 50000.0,
          timestamp: DateTime.now(),
        )),
      );
      when(mockTradingApiService.getExchangeInfo()).thenAnswer(
        (_) async => Right(ExchangeInfo(symbols: [
          SymbolInfo(
            symbol: testSymbol,
            baseAsset: 'BTC',
            quoteAsset: 'USDC',
            minQty: 0.001,
            maxQty: 1000.0,
            stepSize: 0.001,
            minNotional: 10.0,
          ),
        ])),
      );

      // Mock per repository
      when(mockAccountRepository.getAccountInfo()).thenAnswer(
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
      when(mockPriceRepository.getCurrentPrice(testSymbol)).thenAnswer(
        (_) async => Right(50000.0),
      );
      when(mockPriceRepository.updatePrice(any)).thenAnswer(
        (_) async => const Right(unit),
      );

      // Mock per state manager
      when(mockStateManager.executeAtomicOperation(any, any)).thenAnswer(
        (_) async => Right(AppStrategyState(
          symbol: testSymbol,
          status: StrategyState.MONITORING_FOR_BUY,
          currentRoundId: 1,
          openTrades: [],
        )),
      );
      when(mockStateManager.forceUpdateState(any)).thenAnswer(
        // ignore: void_checks
        (_) async => const Right(unit),
      );
      when(mockStateManager.getState(testSymbol)).thenAnswer(
        (_) async => Right(AppStrategyState(
          symbol: testSymbol,
          status: StrategyState.MONITORING_FOR_BUY,
        )),
      );

      // Mock per trading loop manager
      when(mockTradingLoopManager.startAtomicLoopForSymbol(any, any, any))
          .thenAnswer((_) async => true);
      when(mockTradingLoopManager.stopAndRemoveLoop(any)).thenAnswer(
        (_) async {},
      );

      // Stub per PriceStream
      when(mockPriceRepository.subscribeToPriceStream(any)).thenAnswer(
        (_) => Stream.value(const Right(50000.0)),
      );

      // Stub per TradeEvaluator
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

      when(mockAccountRepository.subscribeToAccountInfoStream())
          .thenAnswer((_) => Stream.empty());

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
    });

    test('should start strategy and trading loop successfully', () async {
      // ARRANGE
      final startStrategyUseCase = StartStrategyAtomic(
        mockTradingLoopManager,
        mockStateManager,
      );

      // ACT - Avvia strategia
      final strategyResult = await startStrategyUseCase.call(
        symbol: testSymbol,
        settings: testSettings,
      );

      // ASSERT
      expect(strategyResult.isRight(), isTrue);
      verify(mockStateManager.executeAtomicOperation(any, any)).called(1);
      verify(mockTradingLoopManager.startAtomicLoopForSymbol(any, any, any))
          .called(1);
    });

    test('should handle strategy startup failure gracefully', () async {
      // ARRANGE - Configura fallimento
      when(mockStateManager.executeAtomicOperation(any, any)).thenAnswer(
        (_) async => Left(ServerFailure(message: 'State manager error')),
      );

      final startStrategyUseCase = StartStrategyAtomic(
        mockTradingLoopManager,
        mockStateManager,
      );

      // ACT
      final result = await startStrategyUseCase.call(
        symbol: testSymbol,
        settings: testSettings,
      );

      // ASSERT
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Should fail'),
      );
    });

    test('should maintain system consistency during operations', () async {
      // ARRANGE
      final startTradingLoopUseCase = StartTradingLoopAtomic(
        priceRepository: mockPriceRepository,
        tradeEvaluator: mockTradeEvaluator,
        stateManager: mockStateManager,
        accountRepository: mockAccountRepository,
        symbolInfoRepository: mockSymbolInfoRepository,
        serviceLocator: serviceLocator,
      );

      // ACT - Esegui operazioni multiple
      final initialState = AppStrategyState(
        symbol: testSymbol,
        status: StrategyState.MONITORING_FOR_BUY,
      );

      final result1 = await startTradingLoopUseCase.call(
        symbol: testSymbol,
        settings: testSettings,
        initialState: initialState,
      );

      final result2 = await startTradingLoopUseCase.call(
        symbol: testSymbol,
        settings: testSettings,
        initialState: initialState,
      );

      // ASSERT
      expect(result1, isTrue);
      expect(result2, isTrue);

      // Verifica che i mock siano stati chiamati correttamente
      verify(mockPriceRepository.getCurrentPrice(testSymbol)).called(4);
      verify(mockAccountRepository.getAccountInfo()).called(4);
      verify(mockSymbolInfoRepository.getSymbolInfo(testSymbol)).called(2);
    });
  });
}

class FakeFeeRepository extends Fake implements IFeeRepository {
  @override
  Future<Either<Failure, FeeInfo>> getSymbolFees(String symbol) async {
    return Right(FeeInfo.defaultBinance(symbol: symbol));
  }
}
