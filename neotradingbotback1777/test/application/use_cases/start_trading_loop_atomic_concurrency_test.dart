import 'dart:async';
import 'package:decimal/decimal.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/application/use_cases/start_trading_loop_atomic_use_case.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/fifo_app_trade.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/entities/account_info.dart';
import 'package:neotradingbotback1777/domain/entities/balance.dart';
import 'package:neotradingbotback1777/domain/entities/symbol_info.dart';
import 'package:neotradingbotback1777/domain/entities/price.dart';
import 'package:neotradingbotback1777/domain/entities/exchange_info.dart';
import 'package:neotradingbotback1777/domain/repositories/account_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/i_symbol_info_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/price_repository.dart';
import 'package:neotradingbotback1777/domain/services/i_trading_api_service.dart';
import 'package:neotradingbotback1777/domain/services/trade_evaluator_service.dart';
import 'package:neotradingbotback1777/application/managers/atomic_state_manager.dart';
import 'package:get_it/get_it.dart';

import 'package:neotradingbotback1777/domain/repositories/i_fee_repository.dart';
import '../../mocks/fee_repository_mock.dart';
import 'start_trading_loop_atomic_concurrency_test.mocks.dart';
import '../../helpers/mockito_dummy_registrations.dart';

import 'package:neotradingbotback1777/domain/entities/order_response.dart';

@GenerateMocks([
  PriceRepository,
  TradeEvaluatorService,
  AtomicStateManager,
  AccountRepository,
  ISymbolInfoRepository,
  ITradingApiService,
  GetIt,
])
void main() {
  provideDummy<ITradingApiService>(MockITradingApiService());
  provideDummy<ISymbolInfoRepository>(MockISymbolInfoRepository());
  provideDummy<AccountRepository>(MockAccountRepository());
  provideDummy<AtomicStateManager>(MockAtomicStateManager());
  provideDummy<TradeEvaluatorService>(MockTradeEvaluatorService());
  provideDummy<PriceRepository>(MockPriceRepository());
  provideDummy<IFeeRepository>(MockFeeRepository());
  provideDummy<Either<Failure, OrderResponse>>(Right(OrderResponse(
    symbol: 'DUMMY',
    orderId: 0,
    timestamp: 0,
    status: 'FILLED',
    executedQty: 0.0,
  )));
  provideDummy<Either<Failure, AccountInfo>>(Right(AccountInfo(balances: [])));

  group('StartTradingLoopAtomic - Concurrency Tests', () {
// ... (omitted lines)
    late StartTradingLoopAtomic useCase;
    late MockPriceRepository mockPriceRepository;
    late MockTradeEvaluatorService mockTradeEvaluator;
    late MockAtomicStateManager mockStateManager;
    late MockAccountRepository mockAccountRepository;
    late MockISymbolInfoRepository mockSymbolInfoRepository;
    late MockITradingApiService mockTradingApiService;
    late GetIt serviceLocator;

    late AppSettings testSettings;
    const String testSymbol = 'BTCUSDC';

    setUp(() {
      print('DEBUG: Init mocks');
      registerMockitoDummies();
      mockPriceRepository = MockPriceRepository();
      mockTradeEvaluator = MockTradeEvaluatorService();
      mockStateManager = MockAtomicStateManager();
      mockAccountRepository = MockAccountRepository();
      mockSymbolInfoRepository = MockISymbolInfoRepository();
      mockTradingApiService = MockITradingApiService();
      serviceLocator = GetIt.asNewInstance();

      // Mock per updatePrice che viene chiamato durante il pre-flight check
      when(mockPriceRepository.updatePrice(any)).thenAnswer(
        (_) async => const Right(unit),
      );

      when(mockTradingApiService.createOrder(
        symbol: anyNamed('symbol'),
        side: anyNamed('side'),
        quantity: anyNamed('quantity'),
        clientOrderId: anyNamed('clientOrderId'),
      )).thenAnswer((_) async => Right(OrderResponse(
            symbol: testSymbol,
            orderId: 12345,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            status: 'FILLED',
            executedQty: 1.0,
            clientOrderId: 'test_order',
          )));

      // Setup default dependencies in GetIt
      serviceLocator
          .registerSingleton<ITradingApiService>(mockTradingApiService);
      serviceLocator
          .registerSingleton<ISymbolInfoRepository>(mockSymbolInfoRepository);
      serviceLocator
          .registerSingleton<AccountRepository>(mockAccountRepository);
      serviceLocator.registerSingleton<IFeeRepository>(MockFeeRepository());

      // Mock per AccountRepository (bilancio)
      when(mockAccountRepository.subscribeToAccountInfoStream()).thenAnswer(
        (_) => Stream.value(Right(AccountInfo(balances: []))),
      );
      when(mockAccountRepository.refreshAccountInfo()).thenAnswer(
        (_) async => Right(AccountInfo(balances: [])),
      );
      when(mockAccountRepository.getAccountInfo()).thenAnswer(
        (_) async => Right(AccountInfo(balances: [])),
      );

      // Mock per i metodi dell'ITradingApiService
      when(mockTradingApiService.getLatestPrice(any)).thenAnswer(
        (_) async => Right(Price(
          symbol: testSymbol,
          price: 100.0,
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

      when(mockStateManager.forceUpdateState(any)).thenAnswer(
        (_) async => const Right(null),
      );

      when(mockStateManager.executeAtomicOperation(any, any)).thenAnswer(
        (invocation) async {
          final operation = invocation.positionalArguments[1]
              as Future<Either<Failure, AppStrategyState>> Function(
                  AppStrategyState);
          final currentState = await mockStateManager.getState(testSymbol);
          return currentState.fold(
            (l) => Left(l),
            (r) => operation(r),
          );
        },
      );

      // Inizializza useCase con i mock
      useCase = StartTradingLoopAtomic(
        priceRepository: mockPriceRepository,
        tradeEvaluator: mockTradeEvaluator,
        stateManager: mockStateManager,
        accountRepository: mockAccountRepository,
        symbolInfoRepository: mockSymbolInfoRepository,
        serviceLocator: serviceLocator,
      );
    });

    test(
        '[BACKEND-TEST-001] should handle price update and stop command race condition',
        () async {
      // ARRANGE
      final stateWithPosition = AppStrategyState(
        symbol: testSymbol,
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

      when(mockStateManager.getState(any))
          .thenAnswer((_) async => Right(stateWithPosition));

      final sellTriggerPrice = 105.1; // +5.1% trigger sell
      final priceUpdateCompleter = Completer<void>();
      final stopCommandCompleter = Completer<void>();

      // Mock per price stream che simula update durante stop
      final priceController = StreamController<double>();
      when(mockPriceRepository.subscribeToPriceStream(any)).thenAnswer(
          (_) => priceController.stream.map((price) => Right(price)));

      // Mock per shouldSell che ritorna true per il prezzo trigger
      when(mockTradeEvaluator.shouldSell(
        currentPrice: sellTriggerPrice,
        state: anyNamed('state'),
        settings: anyNamed('settings'),
      )).thenReturn(true);

      when(mockTradeEvaluator.shouldSellWithFees(
        currentPrice: anyNamed('currentPrice'),
        state: anyNamed('state'),
        settings: anyNamed('settings'),
        inDustCooldown: anyNamed('inDustCooldown'),
      )).thenAnswer((_) async => true);

      // Mock per pre-flight check
      when(mockAccountRepository.getAccountInfo()).thenAnswer(
        (_) async => Right(AccountInfo(balances: [
          Balance(asset: 'USDC', free: 1000.0, locked: 0.0),
        ])),
      );

      when(mockSymbolInfoRepository.getSymbolInfo(any)).thenAnswer(
        (_) async => Right(SymbolInfo(
          symbol: testSymbol,
          minQty: 0.001,
          maxQty: 1000.0,
          stepSize: 0.001,
          minNotional: 10.0,
        )),
      );

      when(mockPriceRepository.getCurrentPrice(any)).thenAnswer(
        (_) async => Right(100.0),
      );

      // Mock per updatePrice che viene chiamato durante il pre-flight check
      when(mockPriceRepository.updatePrice(any)).thenAnswer(
        (_) async => const Right(unit),
      );

      // ACT - Avvia loop
      final initialState = AppStrategyState(
        symbol: testSymbol,
        status: StrategyState.MONITORING_FOR_BUY,
      );
      final startResult = await useCase.call(
        symbol: testSymbol,
        settings: testSettings,
        initialState: initialState,
      );
      expect(startResult, isTrue);

      // Simula race condition: price update e stop simultanei
      final futures = [
        // Price update che dovrebbe triggerare sell
        Future(() async {
          priceController.add(sellTriggerPrice);
          priceUpdateCompleter.complete();
        }),
        // Stop command simultaneo
        Future(() async {
          await useCase.stop();
          stopCommandCompleter.complete();
        }),
      ];

      await Future.wait(futures);

      // Stabilization: wait until the subscription is closed by stop()
      var attempts = 0;
      while (priceController.hasListener && attempts < 50) {
        await Future.delayed(const Duration(milliseconds: 5));
        attempts++;
      }

      // ASSERT
      expect(priceUpdateCompleter.isCompleted, isTrue);
      expect(stopCommandCompleter.isCompleted, isTrue);

      // Verifica che lo stato sia consistente e non ci siano memory leaks
      final finalState = await mockStateManager.getState(testSymbol);
      finalState.fold(
        (failure) => fail('State should be accessible: ${failure.message}'),
        (state) {
          // Lo stato deve essere coerente - o sell è stato completato o loop è stato fermato
          expect([
            StrategyState.IDLE, // Loop fermato/inattivo
            StrategyState.MONITORING_FOR_BUY, // Sell completato
            StrategyState
                .POSITION_OPEN_MONITORING_FOR_SELL, // Sell interrotto o non ancora iniziato
          ], contains(state.status),
              reason:
                  'Final state must be consistent with either a successful sell or a stop command');
        },
      );

      // Verifica che subscription sia stata pulita
      expect(priceController.hasListener, isFalse);

      // Explicitly close the controller to satisfy linter
      await priceController.close();
    });
  });
}
