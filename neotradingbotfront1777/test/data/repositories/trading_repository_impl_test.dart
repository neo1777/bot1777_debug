import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/data/repositories/trading_repository_impl.dart';
import 'package:neotradingbotfront1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pbgrpc.dart'
    as proto;
import 'package:fixnum/fixnum.dart';

import '../../mocks/mocks.dart';

void main() {
  late TradingRepositoryImpl repository;
  late MockTradingRemoteDatasource mockRemoteDatasource;

  setUpAll(() {
    registerFallbackValue(proto.StartStrategyRequest());
    registerFallbackValue(proto.StopStrategyRequest());
    registerFallbackValue(proto.GetStrategyStateRequest());
    registerFallbackValue(proto.PauseTradingRequest());
    registerFallbackValue(proto.ResumeTradingRequest());
  });

  setUp(() {
    mockRemoteDatasource = MockTradingRemoteDatasource();
    repository = TradingRepositoryImpl(remoteDatasource: mockRemoteDatasource);
  });

  group('TradingRepositoryImpl - startStrategy', () {
    const tSymbol = 'BTCUSDC';

    test('should return Right(unit) when successful', () async {
      // arrange
      final tResponse = proto.StrategyResponse()..success = true;
      when(
        () => mockRemoteDatasource.startStrategy(any()),
      ).thenAnswer((_) async => Right(tResponse));

      // act
      final result = await repository.startStrategy(tSymbol);

      // assert
      expect(result.isRight(), true);
      verify(() => mockRemoteDatasource.startStrategy(any())).called(1);
    });
  });

  group('TradingRepositoryImpl - getStrategyState', () {
    const tSymbol = 'BTCUSDC';

    test('should return StrategyState when successful', () async {
      // arrange
      final tResponse =
          proto.StrategyStateResponse()
            ..symbol = tSymbol
            ..status = proto.StrategyStatus.STRATEGY_STATUS_RUNNING
            ..openTradesCount = 1;

      when(
        () => mockRemoteDatasource.getStrategyState(any()),
      ).thenAnswer((_) async => Right(tResponse));

      // act
      final result = await repository.getStrategyState(tSymbol);

      // assert
      expect(result.isRight(), true);
      final state = result.getOrElse((_) => throw Exception());
      expect(state.symbol, tSymbol);
      expect(state.status, StrategyStatus.running);
      verify(() => mockRemoteDatasource.getStrategyState(any())).called(1);
    });
  });

  group('TradingRepositoryImpl - subscribeToStrategyState', () {
    const tSymbol = 'BTCUSDC';

    test('should emit StrategyState when stream yields data', () async {
      // arrange
      final tResponse =
          proto.StrategyStateResponse()
            ..symbol = tSymbol
            ..status = proto.StrategyStatus.STRATEGY_STATUS_RUNNING;

      final stream = Stream.fromIterable([
        Right<Failure, proto.StrategyStateResponse>(tResponse),
      ]);

      when(
        () => mockRemoteDatasource.subscribeStrategyState(any()),
      ).thenAnswer((_) => stream);

      // act & assert
      final emission = await repository.subscribeToStrategyState(tSymbol).first;

      expect(emission.isRight(), true);
      final state = emission.getOrElse((_) => throw Exception());
      expect(state.symbol, tSymbol);
      expect(state.status, StrategyStatus.running);
    });
  });

  group('TradingRepositoryImpl - subscribeToSystemLogs', () {
    test('should emit SystemLog when stream yields data', () async {
      // arrange
      final tLogEntry =
          proto.LogEntry()
            ..level = 'INFO'
            ..message = 'System started'
            ..timestamp = Int64(DateTime.now().millisecondsSinceEpoch);

      final stream = Stream.fromIterable([
        Right<Failure, proto.LogEntry>(tLogEntry),
      ]);

      when(
        () => mockRemoteDatasource.subscribeSystemLogs(),
      ).thenAnswer((_) => stream);

      // act & assert
      final emission = await repository.subscribeToSystemLogs().first;

      expect(emission.isRight(), true);
      final log = emission.getOrElse((_) => throw Exception());
      expect(log.message, 'System started');
    });
  });
}
