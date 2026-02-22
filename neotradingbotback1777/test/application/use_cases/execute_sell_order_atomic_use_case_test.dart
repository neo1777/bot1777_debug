import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/entities/app_trade.dart';
import 'package:neotradingbotback1777/domain/entities/order_response.dart';
import 'package:neotradingbotback1777/domain/entities/symbol_info.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:neotradingbotback1777/application/use_cases/execute_sell_order_atomic_use_case.dart';
import '../../mocks.mocks.dart';
import '../../helpers/mockito_dummy_registrations.dart';

void main() {
  late MockITradingApiService mockApiService;
  late MockISymbolInfoRepository mockSymbolInfoRepository;
  late ExecuteSellOrderAtomic useCase;

  setUp(() {
    registerMockitoDummies();
    mockApiService = MockITradingApiService();
    mockSymbolInfoRepository = MockISymbolInfoRepository();
  });

  ExecuteSellOrderAtomic createUseCase({
    required bool isTestMode,
    double price = 50000.0,
    double quantityToSell = 0.001,
  }) {
    return ExecuteSellOrderAtomic(
      apiService: mockApiService,
      symbolInfoRepository: mockSymbolInfoRepository,
      symbol: 'BTCUSDC',
      price: price,
      quantityToSell: quantityToSell,
      isTestMode: isTestMode,
    );
  }

  final tSymbolInfo = SymbolInfo(
    symbol: 'BTCUSDC',
    minQty: 0.0001,
    maxQty: 100.0,
    stepSize: 0.0001,
    minNotional: 10.0,
  );

  void setupMocksForSuccess() {
    when(mockSymbolInfoRepository.getSymbolInfo(any))
        .thenAnswer((_) async => Right(tSymbolInfo));

    // Fix: Stub createOrder
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

  group('ExecuteSellOrderAtomic', () {
    test(
        'should return a simulated AppTrade when in test mode and all checks pass',
        () async {
      // ARRANGE
      useCase = createUseCase(
          isTestMode: true,
          price: 50000,
          quantityToSell: 0.001); // Notional = 50 > 10
      setupMocksForSuccess();

      // ACT
      final result = await useCase.call();

      // ASSERT
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Should have succeeded'),
        (trade) {
          expect(trade, isA<AppTrade>());
          expect(trade.isBuy, isFalse);
          expect(trade.symbol, 'BTCUSDC');
          expect(trade.orderStatus, 'FILLED');
        },
      );
      verify(mockSymbolInfoRepository.getSymbolInfo('BTCUSDC')).called(1);
      verifyNever(mockApiService.createOrder(
          symbol: anyNamed('symbol'),
          side: anyNamed('side'),
          quantity: anyNamed('quantity'),
          clientOrderId: anyNamed('clientOrderId')));
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
    });

    test('should return BusinessLogicFailure for unsellable dust', () async {
      // ARRANGE
      // Notional = 0.0001 * 50000 = 5. Questo è inferiore a minNotional (10)
      useCase =
          createUseCase(isTestMode: true, price: 50000, quantityToSell: 0.0001);
      setupMocksForSuccess();

      // ACT
      final result = await useCase.call();

      // ASSERT
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<BusinessLogicFailure>());
          expect(failure.code, 'DUST_UNSELLABLE');
        },
        (r) => fail('Should have failed due to dust'),
      );
    });

    test('should return an AppTrade when API service succeeds in real mode',
        () async {
      // ARRANGE
      useCase =
          createUseCase(isTestMode: false, price: 50000, quantityToSell: 0.001);
      setupMocksForSuccess();
      final tOrderResponse = OrderResponse(
        symbol: 'BTCUSDC',
        orderId: 123,
        clientOrderId: 'test',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        status: 'FILLED',
        executedQty: 0.001,
        cumulativeQuoteQty: 50.0,
      );
      when(mockApiService.createOrder(
        symbol: anyNamed('symbol'),
        side: anyNamed('side'),
        quantity: anyNamed('quantity'),
        clientOrderId: anyNamed('clientOrderId'),
      )).thenAnswer((_) async => Right(tOrderResponse));

      // ACT
      final result = await useCase.call();

      // ASSERT
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Should have succeeded'),
        (trade) {
          expect(trade.isBuy, isFalse);
          expect(trade.quantity.toDouble(), 0.001);
        },
      );
      verify(mockApiService.createOrder(
        symbol: 'BTCUSDC',
        side: 'SELL',
        quantity: 0.001,
        clientOrderId: anyNamed('clientOrderId'),
      )).called(1);
    });
  });
}

