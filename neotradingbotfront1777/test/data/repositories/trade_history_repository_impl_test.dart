import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/data/datasources/i_trading_remote_datasource.dart';
import 'package:neotradingbotfront1777/data/repositories/trade_history_repository_impl.dart';
import 'package:neotradingbotfront1777/domain/entities/app_trade.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

class MockTradingRemoteDatasource extends Mock
    implements ITradingRemoteDatasource {}

void main() {
  late MockTradingRemoteDatasource mockDatasource;
  late TradeHistoryRepositoryImpl repository;

  setUp(() {
    mockDatasource = MockTradingRemoteDatasource();
    repository = TradeHistoryRepositoryImpl(remoteDatasource: mockDatasource);
  });

  group('TradeHistoryRepositoryImpl — getTradeHistory', () {
    test('[THR-01] returns list of AppTrade on success', () async {
      final response = TradeHistoryResponse(
        trades: [
          Trade(
            symbol: 'BTCUSDC',
            price: 45000.0,
            quantity: 0.5,
            isBuy: true,
            timestamp: Int64(1700000000000),
            orderStatus: 'FILLED',
          ),
        ],
      );

      when(
        () => mockDatasource.getTradeHistory(),
      ).thenAnswer((_) async => Right(response));

      final result = await repository.getTradeHistory();

      expect(result.isRight(), true);
      result.fold((_) => fail('Expected Right'), (trades) {
        expect(trades.length, 1);
        expect(trades[0], isA<AppTrade>());
        expect(trades[0].symbol, 'BTCUSDC');
        expect(trades[0].price, 45000.0);
      });
    });

    test('[THR-02] returns Failure when datasource fails', () async {
      when(() => mockDatasource.getTradeHistory()).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'Connection refused')),
      );

      final result = await repository.getTradeHistory();

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Connection refused'),
        (_) => fail('Expected Left'),
      );
    });

    test('[THR-03] returns UnexpectedFailure on exception', () async {
      when(() => mockDatasource.getTradeHistory()).thenThrow(Exception('Boom'));

      final result = await repository.getTradeHistory();

      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<UnexpectedFailure>());
        expect(failure.message, contains('Boom'));
      }, (_) => fail('Expected Left'));
    });
  });

  group('TradeHistoryRepositoryImpl — subscribeToTradeHistory', () {
    test('[THR-04] returns Right with stream on success', () {
      final tradeStream = Stream.fromIterable([
        Right<Failure, Trade>(
          Trade(
            symbol: 'BTCUSDC',
            price: 45000.0,
            quantity: 0.5,
            isBuy: true,
            timestamp: Int64(1700000000000),
          ),
        ),
      ]);

      when(
        () => mockDatasource.subscribeTradeHistory(),
      ).thenAnswer((_) => tradeStream);

      final result = repository.subscribeToTradeHistory();

      expect(result.isRight(), true);
    });

    test('[THR-05] returns Failure when subscription throws', () {
      when(
        () => mockDatasource.subscribeTradeHistory(),
      ).thenThrow(Exception('Stream error'));

      final result = repository.subscribeToTradeHistory();

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<UnexpectedFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });
}
