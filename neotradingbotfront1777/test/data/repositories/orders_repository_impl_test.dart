import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neotradingbotfront1777/data/repositories/orders_repository_impl.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pbgrpc.dart'
    as grpc;
import 'package:fixnum/fixnum.dart';

import '../../mocks/mocks.dart';

void main() {
  late OrdersRepositoryImpl repository;
  late MockTradingRemoteDatasource mockRemoteDatasource;

  setUpAll(() {
    registerFallbackValue(grpc.OpenOrdersRequest());
    registerFallbackValue(grpc.SymbolLimitsRequest());
    registerFallbackValue(grpc.CancelOrderRequest());
  });

  setUp(() {
    mockRemoteDatasource = MockTradingRemoteDatasource();
    repository = OrdersRepositoryImpl(remoteDatasource: mockRemoteDatasource);
  });

  group('OrdersRepositoryImpl - getOpenOrders', () {
    const tSymbol = 'BTCUSDC';

    test('should return list of OrderStatus when successful', () async {
      // arrange
      final tResponse = grpc.OpenOrdersResponse();
      final tOrder =
          grpc.OrderStatus()
            ..symbol = tSymbol
            ..price = 50000.0
            ..origQty = 0.1
            ..side = 'BUY'
            ..status = 'NEW'
            ..orderId = Int64(12345);
      tResponse.orders.add(tOrder);

      when(
        () => mockRemoteDatasource.getOpenOrders(any()),
      ).thenAnswer((_) async => Right(tResponse));

      // act
      final result = await repository.getOpenOrders(tSymbol);

      // assert
      expect(result.isRight(), true);
      final orders = result.getOrElse((_) => throw Exception());
      expect(orders.length, 1);
      expect(orders.first.symbol, tSymbol);
      verify(() => mockRemoteDatasource.getOpenOrders(any())).called(1);
    });
  });

  group('OrdersRepositoryImpl - getSymbolLimits', () {
    const tSymbol = 'BTCUSDC';

    test('should return SymbolLimits when successful', () async {
      // arrange
      final tResponse =
          grpc.SymbolLimitsResponse()
            ..symbol = tSymbol
            ..minNotional = 10.0
            ..minQty = 0.001
            ..maxQty = 100.0
            ..stepSize = 0.0001;

      when(
        () => mockRemoteDatasource.getSymbolLimits(any()),
      ).thenAnswer((_) async => Right(tResponse));

      // act
      final result = await repository.getSymbolLimits(tSymbol);

      // assert
      expect(result.isRight(), true);
      final limits = result.getOrElse((_) => throw Exception());
      expect(limits.symbol, tSymbol);
      expect(limits.minNotional, 10.0);
    });
  });

  group('OrdersRepositoryImpl - cancelOrder', () {
    const tSymbol = 'BTCUSDC';
    const tOrderId = 12345;

    test('should return Right(null) when successful', () async {
      // arrange
      final tResponse = grpc.CancelOrderResponse()..success = true;
      when(
        () => mockRemoteDatasource.cancelOrder(any()),
      ).thenAnswer((_) async => Right(tResponse));

      // act
      final result = await repository.cancelOrder(tSymbol, tOrderId);

      // assert
      expect(result.isRight(), true);
      verify(() => mockRemoteDatasource.cancelOrder(any())).called(1);
    });
  });

  group('OrdersRepositoryImpl - cancelAllOrders', () {
    const tSymbol = 'BTCUSDC';

    test('should return Right(null) when successful', () async {
      // arrange
      final tResponse = grpc.CancelOrderResponse()..success = true;
      when(
        () => mockRemoteDatasource.cancelAllOrders(any()),
      ).thenAnswer((_) async => Right(tResponse));

      // act
      final result = await repository.cancelAllOrders(tSymbol);

      // assert
      expect(result.isRight(), true);
      verify(() => mockRemoteDatasource.cancelAllOrders(any())).called(1);
    });
  });
}
