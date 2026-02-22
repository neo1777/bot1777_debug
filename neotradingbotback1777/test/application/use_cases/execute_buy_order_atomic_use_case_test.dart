import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/entities/account_info.dart';
import 'package:neotradingbotback1777/domain/entities/app_trade.dart';
import 'package:neotradingbotback1777/domain/entities/balance.dart';
import 'package:neotradingbotback1777/domain/entities/order_response.dart';
import 'package:neotradingbotback1777/domain/entities/symbol_info.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:neotradingbotback1777/application/use_cases/execute_buy_order_atomic_use_case.dart';
import '../../mocks.mocks.dart';
import '../../helpers/mockito_dummy_registrations.dart';

void main() {
  late MockITradingApiService mockApiService;
  late MockISymbolInfoRepository mockSymbolInfoRepository;
  late MockAccountRepository mockAccountRepository;
  late ExecuteBuyOrderAtomic useCase;

  setUp(() {
    registerMockitoDummies();
    mockApiService = MockITradingApiService();
    mockSymbolInfoRepository = MockISymbolInfoRepository();
    mockAccountRepository = MockAccountRepository();
  });

  // Helper per creare un'istanza del caso d'uso con parametri comuni
  ExecuteBuyOrderAtomic createUseCase({
    required bool isTestMode,
    double price = 50000.0,
    double tradeAmount = 100.0,
    double maxBuyOveragePct = 0.03,
    bool strictBudget = false,
  }) {
    return ExecuteBuyOrderAtomic(
      apiService: mockApiService,
      symbolInfoRepository: mockSymbolInfoRepository,
      accountRepository: mockAccountRepository,
      symbol: 'BTCUSDC',
      price: price,
      tradeAmount: tradeAmount,
      isTestMode: isTestMode,
      maxBuyOveragePct: maxBuyOveragePct,
      strictBudget: strictBudget,
    );
  }

  // Dati di mock comuni
  final tSymbolInfo = SymbolInfo(
    symbol: 'BTCUSDC',
    minQty: 0.0001,
    maxQty: 100.0,
    stepSize: 0.0001,
    minNotional: 10.0,
  );

  final tAccountInfo = AccountInfo(
    balances: [
      Balance(asset: 'USDC', free: 1000.0, locked: 0.0),
      Balance(asset: 'BTC', free: 1.0, locked: 0.0),
    ],
  );

  void setupMocksForSuccess() {
    when(mockSymbolInfoRepository.getSymbolInfo(any))
        .thenAnswer((_) async => Right(tSymbolInfo));
    when(mockAccountRepository.getAccountInfo())
        .thenAnswer((_) async => Right(tAccountInfo));

    // Fix: Stub createOrder even for test mode to prevent MissingStubError if called
    // (though verifyNever checks it, sometimes implementation calls it safely?).
    // Actually atomic use case for BUY/SELL calls createOrder ONLY if !isTestMode.
    // However, let's provide a default stub to be safe.
    when(mockApiService.createOrder(
      symbol: anyNamed('symbol'),
      side: anyNamed('side'),
      quantity: anyNamed('quantity'),
      clientOrderId: anyNamed('clientOrderId'),
    )).thenAnswer((_) async => Right(OrderResponse(
          symbol: 'BTCUSDC',
          orderId: 123,
          clientOrderId: 'test',
          timestamp: 1234567890,
          status: 'FILLED',
          executedQty: 0.001,
          cumulativeQuoteQty: 50.0,
        )));
  }

  group('ExecuteBuyOrderAtomic', () {
    test(
        'should return a simulated AppTrade when in test mode and all checks pass',
        () async {
      // ARRANGE
      useCase = createUseCase(isTestMode: true);
      setupMocksForSuccess();

      // ACT
      final result = await useCase.call();

      // ASSERT
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Should have succeeded'),
        (trade) {
          expect(trade, isA<AppTrade>());
          expect(trade.isBuy, isTrue);
          expect(trade.symbol, 'BTCUSDC');
          expect(trade.orderStatus, 'FILLED');
        },
      );
      verify(mockSymbolInfoRepository.getSymbolInfo('BTCUSDC')).called(1);
      verify(mockAccountRepository.getAccountInfo()).called(1);
      verifyNever(mockApiService.createOrder(
        symbol: anyNamed('symbol'),
        side: anyNamed('side'),
        quantity: anyNamed('quantity'),
        clientOrderId: anyNamed('clientOrderId'),
      ));
    });

    test('should return a Failure when symbol info repository fails', () async {
      // ARRANGE
      useCase = createUseCase(isTestMode: true);
      when(mockSymbolInfoRepository.getSymbolInfo(any))
          .thenAnswer((_) async => Left(ServerFailure(message: 'API Error')));

      // ACT
      final result = await useCase.call();

      // ASSERT
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (r) => fail('Should have failed'),
      );
      verify(mockSymbolInfoRepository.getSymbolInfo('BTCUSDC')).called(1);
      verifyNever(mockAccountRepository.getAccountInfo());
    });

    test('should return a Failure when balance is insufficient', () async {
      // ARRANGE
      useCase =
          createUseCase(isTestMode: true, tradeAmount: 2000.0); // > 1000 free
      setupMocksForSuccess(); // Mocks default success, will be overridden by insufficient balance logic

      // ACT
      final result = await useCase.call();

      // ASSERT
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<BusinessLogicFailure>());
          expect(failure.message, contains('Saldo USDC insufficiente'));
        },
        (r) => fail('Should have failed due to insufficient balance'),
      );
      verify(mockSymbolInfoRepository.getSymbolInfo('BTCUSDC')).called(1);
      verify(mockAccountRepository.getAccountInfo()).called(1);
    });

    test('should return a Failure when API service fails in real mode',
        () async {
      // ARRANGE
      useCase = createUseCase(isTestMode: false);
      setupMocksForSuccess();
      when(mockApiService.createOrder(
        symbol: anyNamed('symbol'),
        side: anyNamed('side'),
        quantity: anyNamed('quantity'),
        clientOrderId: anyNamed('clientOrderId'),
      )).thenAnswer((_) async => Left(ServerFailure(message: 'Binance Error')));

      // ACT
      final result = await useCase.call();

      // ASSERT
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (r) => fail('Should have failed'),
      );
      verify(mockApiService.createOrder(
        symbol: 'BTCUSDC',
        side: 'BUY',
        quantity: anyNamed('quantity'),
        clientOrderId: anyNamed('clientOrderId'),
      )).called(1);
    });

    test('should return an AppTrade when API service succeeds in real mode',
        () async {
      // ARRANGE
      useCase =
          createUseCase(isTestMode: false, price: 50000, tradeAmount: 100);
      setupMocksForSuccess();
      final tOrderResponse = OrderResponse(
          symbol: 'BTCUSDC',
          orderId: 123,
          clientOrderId: 'test',
          timestamp: DateTime.now().millisecondsSinceEpoch,
          status: 'FILLED',
          executedQty: 0.002,
          cumulativeQuoteQty: 100.0,
          fills: [
            {'price': '50000.0', 'qty': '0.002'}
          ]);
      when(mockApiService.createOrder(
              symbol: anyNamed('symbol'),
              side: anyNamed('side'),
              quantity: anyNamed('quantity'),
              clientOrderId: anyNamed('clientOrderId')))
          .thenAnswer((_) async => Right(tOrderResponse));

      // ACT
      final result = await useCase.call();

      // ASSERT
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Should have succeeded'),
        (trade) {
          expect(trade.isBuy, isTrue);
          expect(trade.quantity.toDouble(), 0.002);
          expect(trade.price.toDouble(), 50000.0);
        },
      );
      verify(mockApiService.createOrder(
              symbol: anyNamed('symbol'),
              side: anyNamed('side'),
              quantity: anyNamed('quantity'),
              clientOrderId: anyNamed('clientOrderId')))
          .called(1);
    });

    test(
        'should allow overage to satisfy minNotional when strictBudget is false',
        () async {
      // ARRANGE
      // minNotional is 10.0 in tSymbolInfo
      // price 50.0 -> minQty to satisfy minNotional = 10.0 / 50.0 = 0.2
      // tradeAmount 9.9 -> targetQty = 9.9 / 50.0 = 0.198 (below 0.2)
      // maxBuyOveragePct 0.03 (3%) -> maxAllowed = 9.9 * 1.03 = 10.197 (above 10.0)
      useCase = createUseCase(
        isTestMode: true,
        price: 50.0,
        tradeAmount: 9.9,
        maxBuyOveragePct: 0.03,
        strictBudget: false,
      );
      setupMocksForSuccess();

      // ACT
      final result = await useCase.call();

      // ASSERT
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Should have succeeded with overage'),
        (trade) {
          expect(trade.quantity.toDouble(), 0.2); // Increased from 0.198
          expect(trade.quantity.toDouble() * 50.0, 10.0); // Exactly minNotional
        },
      );
    });

    test(
        'should fail when tradeAmount is below minNotional and overage is not enough',
        () async {
      // ARRANGE
      // tradeAmount 9.0 -> targetQty = 9.0 / 50.0 = 0.18
      // maxBuyOveragePct 0.03 (3%) -> maxAllowed = 9.0 * 1.03 = 9.27 (still below 10.0)
      useCase = createUseCase(
        isTestMode: true,
        price: 50.0,
        tradeAmount: 9.0,
        maxBuyOveragePct: 0.03,
        strictBudget: false,
      );
      setupMocksForSuccess();

      // ACT
      final result = await useCase.call();

      // ASSERT
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('Importo trade insufficiente'));
        },
        (r) => fail(
            'Should have failed as overage (3%) is not enough to reach 10.0'),
      );
    });

    test(
        'should fail when tradeAmount is below minNotional and strictBudget is true',
        () async {
      // ARRANGE
      useCase = createUseCase(
        isTestMode: true,
        price: 50.0,
        tradeAmount: 9.9,
        maxBuyOveragePct: 0.03,
        strictBudget: true, // Budget is strict!
      );
      setupMocksForSuccess();

      // ACT
      final result = await useCase.call();

      // ASSERT
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('Importo trade insufficiente'));
        },
        (r) => fail('Should have failed because strictBudget is true'),
      );
    });
  });
}

