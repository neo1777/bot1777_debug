import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/data/datasources/i_trading_remote_datasource.dart';
import 'package:neotradingbotfront1777/data/repositories/price_repository_impl.dart';
import 'package:neotradingbotfront1777/domain/entities/price_data.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pb.dart';
import 'package:test/test.dart';

class MockTradingRemoteDatasource extends Mock
    implements ITradingRemoteDatasource {}

class FakeStreamCurrentPriceRequest extends Fake
    implements StreamCurrentPriceRequest {}

void main() {
  late MockTradingRemoteDatasource mockDatasource;
  late PriceRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(FakeStreamCurrentPriceRequest());
  });

  setUp(() {
    mockDatasource = MockTradingRemoteDatasource();
    repository = PriceRepositoryImpl(remoteDatasource: mockDatasource);
  });

  group('PriceRepositoryImpl — getTickerInfo', () {
    test('[PR-01] returns PriceData on success', () async {
      final response = PriceResponse(
        price: 45000.0,
        priceChange24h: 2.5,
        volume24h: 1000.0,
        priceStr: '45000.00',
      );

      when(
        () => mockDatasource.getTickerInfo(any()),
      ).thenAnswer((_) async => Right(response));

      final result = await repository.getTickerInfo('BTCUSDC');

      expect(result.isRight(), true);
      result.fold((_) => fail('Expected Right'), (priceData) {
        expect(priceData, isA<PriceData>());
        expect(priceData.symbol, 'BTCUSDC');
        expect(priceData.price, 45000.0);
        expect(priceData.priceChange24h, 2.5);
      });
    });

    test('[PR-02] returns Failure when datasource fails', () async {
      when(() => mockDatasource.getTickerInfo(any())).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'Ticker not found')),
      );

      final result = await repository.getTickerInfo('INVALID');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Ticker not found'),
        (_) => fail('Expected Left'),
      );
    });

    test('[PR-03] returns UnexpectedFailure on exception', () async {
      when(
        () => mockDatasource.getTickerInfo(any()),
      ).thenThrow(Exception('Network error'));

      final result = await repository.getTickerInfo('BTCUSDC');

      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<UnexpectedFailure>());
        expect(failure.message, contains('Network error'));
      }, (_) => fail('Expected Left'));
    });
  });

  group('PriceRepositoryImpl — streamCurrentPrice', () {
    test('[PR-04] returns stream of PriceData', () async {
      final priceStream = Stream.fromIterable([
        Right<Failure, PriceResponse>(
          PriceResponse(price: 45000.0, priceStr: '45000.00'),
        ),
        Right<Failure, PriceResponse>(
          PriceResponse(price: 45100.0, priceStr: '45100.00'),
        ),
      ]);

      when(
        () => mockDatasource.streamCurrentPrice(any()),
      ).thenAnswer((_) => priceStream);

      final stream = repository.streamCurrentPrice('BTCUSDC');
      final events = await stream.toList();

      expect(events.length, 2);
      expect(events[0].isRight(), true);
      events[0].fold(
        (_) => fail('Expected Right'),
        (data) => expect(data.price, 45000.0),
      );
    });

    test('[PR-05] propagates failure from stream', () async {
      final priceStream = Stream.fromIterable([
        const Left<Failure, PriceResponse>(
          ServerFailure(message: 'Stream interrupted'),
        ),
      ]);

      when(
        () => mockDatasource.streamCurrentPrice(any()),
      ).thenAnswer((_) => priceStream);

      final stream = repository.streamCurrentPrice('BTCUSDC');
      final events = await stream.toList();

      expect(events.length, 1);
      expect(events[0].isLeft(), true);
    });
  });
}
