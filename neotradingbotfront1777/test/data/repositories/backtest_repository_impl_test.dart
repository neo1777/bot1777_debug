import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/data/repositories/backtest_repository_impl.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pbgrpc.dart';

import '../../mocks/mocks.dart';

void main() {
  late BacktestRepositoryImpl repository;
  late MockTradingRemoteDatasource mockRemoteDatasource;

  setUpAll(() {
    registerFallbackValue(StartBacktestRequest());
    registerFallbackValue(GetBacktestResultsRequest(backtestId: 'test'));
  });

  setUp(() {
    mockRemoteDatasource = MockTradingRemoteDatasource();
    repository = BacktestRepositoryImpl(mockRemoteDatasource);
  });

  group('BacktestRepositoryImpl - startBacktest', () {
    const tSymbol = 'BTCUSDC';
    const tInterval = '1h';
    const tPeriod = 7;
    const tStrategy = 'Standard';
    const tBacktestId = 'test-id-123';

    test(
      'should return backtestId when remote datasource call is successful',
      () async {
        // arrange
        final tResponse = BacktestResponse()..backtestId = tBacktestId;
        when(
          () => mockRemoteDatasource.startBacktest(any()),
        ).thenAnswer((_) async => Right(tResponse));

        // act
        final result = await repository.startBacktest(
          symbol: tSymbol,
          interval: tInterval,
          period: tPeriod,
          strategyName: tStrategy,
        );

        // assert
        expect(result.isRight(), true);
        expect(result.getOrElse((_) => ''), tBacktestId);
        verify(() => mockRemoteDatasource.startBacktest(any())).called(1);
      },
    );

    test('should return Failure when remote datasource call fails', () async {
      // arrange
      final tFailure = ServerFailure(message: 'Server Error');
      when(
        () => mockRemoteDatasource.startBacktest(any()),
      ).thenAnswer((_) async => Left(tFailure));

      // act
      final result = await repository.startBacktest(
        symbol: tSymbol,
        interval: tInterval,
        period: tPeriod,
        strategyName: tStrategy,
      );

      // assert
      expect(result.isLeft(), true);
      expect(result.fold((l) => l, (r) => null), equals(tFailure));
    });
  });

  group('BacktestRepositoryImpl - getBacktestResults', () {
    const tBacktestId = 'test-id-123';

    test(
      'should return BacktestResult when remote datasource call is successful',
      () async {
        // arrange
        final tResponse =
            BacktestResultsResponse()
              ..backtestId = tBacktestId
              ..profitPercentage = 5.0;

        when(
          () => mockRemoteDatasource.getBacktestResults(any()),
        ).thenAnswer((_) async => Right(tResponse));

        // act
        final result = await repository.getBacktestResults(tBacktestId);

        // assert
        expect(result.isRight(), true);
        final resultData = result.getOrElse((_) => throw Exception());
        expect(resultData.profitPercentage, 5.0);
        verify(() => mockRemoteDatasource.getBacktestResults(any())).called(1);
      },
    );

    test('should return Failure when remote datasource call fails', () async {
      // arrange
      final tFailure = ServerFailure(message: 'Server Error');
      when(
        () => mockRemoteDatasource.getBacktestResults(any()),
      ).thenAnswer((_) async => Left(tFailure));

      // act
      final result = await repository.getBacktestResults(tBacktestId);

      // assert
      expect(result.isLeft(), true);
      expect(result.fold((l) => l, (r) => null), equals(tFailure));
    });
  });
}
