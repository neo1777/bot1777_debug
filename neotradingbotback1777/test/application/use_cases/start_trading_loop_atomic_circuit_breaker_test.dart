import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/application/use_cases/start_trading_loop_atomic_use_case.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/account_info.dart';
import 'package:neotradingbotback1777/domain/entities/symbol_info.dart';
import 'package:neotradingbotback1777/domain/entities/balance.dart';
import 'package:neotradingbotback1777/domain/entities/price.dart';
import 'package:neotradingbotback1777/domain/entities/exchange_info.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/account_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/i_symbol_info_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/price_repository.dart';
import 'package:neotradingbotback1777/domain/services/i_trading_api_service.dart';
import 'package:neotradingbotback1777/domain/services/trade_evaluator_service.dart';
import 'package:neotradingbotback1777/application/managers/atomic_state_manager.dart';
import 'package:get_it/get_it.dart';
import 'dart:async';
import 'package:neotradingbotback1777/domain/repositories/i_fee_repository.dart';
import 'package:neotradingbotback1777/domain/entities/fee_info.dart';

import 'start_trading_loop_atomic_circuit_breaker_test.mocks.dart';
import '../../helpers/mockito_dummy_registrations.dart' hide MockIFeeRepository;

@GenerateMocks([
  PriceRepository,
  TradeEvaluatorService,
  AtomicStateManager,
  AccountRepository,
  ISymbolInfoRepository,
  ITradingApiService,
  GetIt,
  IFeeRepository,
])
void main() {
  group('StartTradingLoopAtomic Error Handling Tests', () {
    late StartTradingLoopAtomic useCase;
    late MockPriceRepository mockPriceRepository;
    late MockTradeEvaluatorService mockTradeEvaluator;
    late MockAtomicStateManager mockStateManager;
    late MockAccountRepository mockAccountRepository;
    late MockISymbolInfoRepository mockSymbolInfoRepository;
    late GetIt mockServiceLocator;

    late AppSettings testSettings;
    late AppStrategyState testInitialState;
    const String testSymbol = 'BTCUSDC';

    setUp(() async {
      registerMockitoDummies();
      mockPriceRepository = MockPriceRepository();
      mockTradeEvaluator = MockTradeEvaluatorService();
      mockStateManager = MockAtomicStateManager();
      mockAccountRepository = MockAccountRepository();
      mockSymbolInfoRepository = MockISymbolInfoRepository();
      // Use real GetIt instance for reliable DI in tests
      mockServiceLocator = GetIt.asNewInstance();
      final mockFeeRepository = MockIFeeRepository();

      provideDummy<Either<Failure, AccountInfo>>(
          Right(AccountInfo(balances: [])));

      // Setup default mocks
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

      // Default behavior for fee repository
      when(mockFeeRepository.getSymbolFees(testSymbol)).thenAnswer(
        (_) async => Right(FeeInfo(
          symbol: testSymbol,
          makerFee: 0.001,
          takerFee: 0.001,
          feeCurrency: 'BNB',
          isDiscountActive: false,
          discountPercentage: 0.0,
          lastUpdated: DateTime.now(),
        )),
      );
      when(mockFeeRepository.getSymbolFeesIfNeeded(testSymbol)).thenAnswer(
        (_) async => Right(FeeInfo(
          symbol: testSymbol,
          makerFee: 0.001,
          takerFee: 0.001,
          feeCurrency: 'BNB',
          isDiscountActive: false,
          discountPercentage: 0.0,
          lastUpdated: DateTime.now(),
        )),
      );

      // ... (existing mocks) ...

      // Mock per subscribeToPriceStream - ESSENZIALE per il loop di trading
      when(mockPriceRepository.subscribeToPriceStream(testSymbol)).thenAnswer(
        (_) => Stream.fromIterable([
          Right(50000.0),
          Right(50001.0),
        ]),
      );

      // Mock per updatePrice - ESSENZIALE per l'aggiornamento cache
      when(mockPriceRepository.updatePrice(any)).thenAnswer(
        (_) async => const Right(unit),
      );

      // Mock per getState - ESSENZIALE per la gestione dello stato
      when(mockStateManager.getState(testSymbol)).thenAnswer(
        (_) async => Right(testInitialState),
      );

      // Mock per ITradingApiService nel GetIt
      final mockTradingApiService = MockITradingApiService();
      when(mockTradingApiService.getLatestPrice(testSymbol)).thenAnswer(
        (_) async => Right(Price(
            symbol: testSymbol, price: 50000.0, timestamp: DateTime.now())),
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

      // Use real registration
      mockServiceLocator
          .registerSingleton<ITradingApiService>(mockTradingApiService);
      mockServiceLocator.registerSingleton<IFeeRepository>(mockFeeRepository);

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

      when(mockTradeEvaluator.shouldSell(
        currentPrice: anyNamed('currentPrice'),
        state: anyNamed('state'),
        settings: anyNamed('settings'),
        inDustCooldown: anyNamed('inDustCooldown'),
      )).thenReturn(false);

      when(mockTradeEvaluator.shouldSellWithFees(
        currentPrice: anyNamed('currentPrice'),
        state: anyNamed('state'),
        settings: anyNamed('settings'),
        inDustCooldown: anyNamed('inDustCooldown'),
      )).thenAnswer((_) async => false);

      testSettings = AppSettings(
        tradeAmount: 100.0,
        profitTargetPercentage: 5.0,
        stopLossPercentage: 10.0,
        dcaDecrementPercentage: 10.0,
        maxOpenTrades: 5,
        isTestMode: true,
      );

      testInitialState = AppStrategyState(
        symbol: testSymbol,
        status: StrategyState.MONITORING_FOR_BUY,
        openTrades: [],
      );

      useCase = StartTradingLoopAtomic(
        priceRepository: mockPriceRepository,
        tradeEvaluator: mockTradeEvaluator,
        stateManager: mockStateManager,
        accountRepository: mockAccountRepository,
        symbolInfoRepository: mockSymbolInfoRepository,
        serviceLocator: mockServiceLocator,
      );
    });

    group('[BACKEND-TEST-003] Pre-Flight Check Tests', () {
      test('should fail pre-flight check when account info is unavailable',
          () async {
        // ARRANGE
        when(mockPriceRepository.getCurrentPrice(testSymbol)).thenAnswer(
          (_) async => Right(50000.0),
        );
        when(mockAccountRepository.getAccountInfo()).thenAnswer(
            (_) async => Left(ServerFailure(message: 'Network error')));

        // ACT
        final result = await useCase.call(
          symbol: testSymbol,
          settings: testSettings,
          initialState: testInitialState,
        );

        // ASSERT
        expect(result, isFalse);
        verify(mockAccountRepository.getAccountInfo()).called(1);
      });

      test('should fail pre-flight check when symbol info is unavailable',
          () async {
        // ARRANGE
        when(mockPriceRepository.getCurrentPrice(testSymbol)).thenAnswer(
          (_) async => Right(50000.0),
        );
        when(mockSymbolInfoRepository.getSymbolInfo(testSymbol)).thenAnswer(
            (_) async => Left(ServerFailure(message: 'Symbol not found')));

        // ACT
        final result = await useCase.call(
          symbol: testSymbol,
          settings: testSettings,
          initialState: testInitialState,
        );

        // ASSERT
        // Updated expectation: SymbolInfo check IS part of pre-flight or use case logic now
        expect(result, isFalse);
        verify(mockSymbolInfoRepository.getSymbolInfo(testSymbol)).called(1);
      });

      test('should pass pre-flight check when all validations succeed',
          () async {
        // ARRANGE - Mock per successo
        when(mockPriceRepository.getCurrentPrice(testSymbol)).thenAnswer(
          (_) async => Right(50000.0),
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

        // ACT
        final result = await useCase.call(
          symbol: testSymbol,
          settings: testSettings,
          initialState: testInitialState,
        );

        // ASSERT
        expect(result, isTrue);
      });

      test('should fail pre-flight check when initial price is unavailable',
          () async {
        // ARRANGE
        when(mockPriceRepository.getCurrentPrice(testSymbol)).thenAnswer(
            (_) async =>
                Left(ServerFailure(message: 'Price service unavailable')));

        // Mock API REST per fallire anche il fallback
        final mockTradingApiService = MockITradingApiService();
        when(mockTradingApiService.getLatestPrice(testSymbol)).thenAnswer(
          (_) async => Left(ServerFailure(message: 'API REST unavailable')),
        );

        // Use real GetIt override
        if (mockServiceLocator.isRegistered<ITradingApiService>()) {
          await mockServiceLocator.unregister<ITradingApiService>();
        }
        mockServiceLocator
            .registerSingleton<ITradingApiService>(mockTradingApiService);

        // ACT
        final result = await useCase.call(
          symbol: testSymbol,
          settings: testSettings,
          initialState: testInitialState,
        );

        // ASSERT
        expect(result, isFalse);
        verify(mockPriceRepository.getCurrentPrice(testSymbol))
            .called(1); // Fails immediately in pre-flight
      });
    });

    group('[BACKEND-TEST-003] Price Stream Error Handling Tests', () {
      test('should handle price stream failures gracefully', () async {
        // ARRANGE
        when(mockPriceRepository.getCurrentPrice(testSymbol)).thenAnswer(
          (_) async => Right(50000.0),
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
        when(mockPriceRepository.subscribeToPriceStream(testSymbol))
            .thenAnswer((_) => Stream.fromIterable([
                  Left(ServerFailure(message: 'Stream error')),
                  Right(100.0),
                  Left(ServerFailure(message: 'Another stream error')),
                  Right(101.0),
                ]));

        // ACT
        final result = await useCase.call(
          symbol: testSymbol,
          settings: testSettings,
          initialState: testInitialState,
        );

        // ASSERT
        expect(result, isTrue);
        verify(mockPriceRepository.subscribeToPriceStream(testSymbol))
            .called(1);
      });

      test('should continue processing after price stream recovery', () async {
        // ARRANGE
        when(mockPriceRepository.getCurrentPrice(testSymbol)).thenAnswer(
          (_) async => Right(50000.0),
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
        final priceStream = StreamController<Either<Failure, double>>();
        when(mockPriceRepository.subscribeToPriceStream(testSymbol))
            .thenAnswer((_) => priceStream.stream);

        // ACT
        final future = useCase.call(
          symbol: testSymbol,
          settings: testSettings,
          initialState: testInitialState,
        );

        // Simula errori seguiti da recupero
        priceStream.add(Left(ServerFailure(message: 'Stream error')));
        priceStream.add(Right(100.0));
        priceStream.add(Right(101.0));
        await priceStream.close();

        final result = await future;

        // ASSERT
        expect(result, isTrue);
      });
    });

    group('[BACKEND-TEST-003] State Management Error Tests', () {
      test('should handle state retrieval failures gracefully', () async {
        // ARRANGE
        when(mockPriceRepository.getCurrentPrice(testSymbol)).thenAnswer(
          (_) async => Right(50000.0),
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
        when(mockStateManager.getState(testSymbol)).thenAnswer((_) async =>
            Left(ServerFailure(message: 'State service unavailable')));

        // ACT
        final result = await useCase.call(
          symbol: testSymbol,
          settings: testSettings,
          initialState: testInitialState,
        );

        // ASSERT
        expect(result, isTrue); // Il loop continua anche con errori di stato
        verify(mockStateManager.getState(testSymbol)).called(greaterThan(0));
      });

      test('should handle state update failures gracefully', () async {
        // ARRANGE
        when(mockPriceRepository.getCurrentPrice(testSymbol)).thenAnswer(
          (_) async => Right(50000.0),
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
        when(mockStateManager.getState(testSymbol))
            .thenAnswer((_) async => Right(testInitialState));
        when(mockStateManager.forceUpdateState(any)).thenAnswer(
            (_) async => Left(ServerFailure(message: 'Update failed')));

        // ACT
        final result = await useCase.call(
          symbol: testSymbol,
          settings: testSettings,
          initialState: testInitialState,
        );

        // ASSERT
        expect(result, isTrue);
        verifyNever(mockStateManager.forceUpdateState(any));
      });
    });
  });
}

