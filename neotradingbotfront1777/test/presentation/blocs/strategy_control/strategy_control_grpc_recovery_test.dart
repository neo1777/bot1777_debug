import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/presentation/blocs/strategy_control/strategy_control_bloc.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_trading_repository.dart';

class MockTradingRepository extends Mock implements ITradingRepository {}

void main() {
  group('[FRONTEND-TEST-013] gRPC Connection Recovery Tests', () {
    late MockTradingRepository mockRepository;

    setUpAll(() {
      registerFallbackValue(const StartStrategyRequested(''));
    });

    setUp(() {
      mockRepository = MockTradingRepository();
    });

    blocTest<StrategyControlBloc, StrategyControlState>(
      'should recover after transient gRPC failure',
      build: () {
        var callCount = 0;
        when(() => mockRepository.startStrategy(any())).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            return Left(ServerFailure(message: 'gRPC UNAVAILABLE'));
          }
          return const Right(unit);
        });
        return StrategyControlBloc(tradingRepository: mockRepository);
      },
      act: (bloc) async {
        bloc.add(const StartStrategyRequested('BTCUSDC'));
        await Future.delayed(const Duration(milliseconds: 100));
        bloc.add(const StartStrategyRequested('BTCUSDC'));
      },
      expect:
          () => [
            const StrategyControlState(status: OperationStatus.inProgress),
            isA<StrategyControlState>().having(
              (s) => s.status,
              'status',
              OperationStatus.failure,
            ),
            const StrategyControlState(status: OperationStatus.inProgress),
            const StrategyControlState(status: OperationStatus.success),
          ],
    );

    blocTest<StrategyControlBloc, StrategyControlState>(
      'should handle permanent gRPC failure',
      build: () {
        when(() => mockRepository.startStrategy(any())).thenAnswer(
          (_) async => Left(ServerFailure(message: 'gRPC UNAVAILABLE')),
        );
        return StrategyControlBloc(tradingRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const StartStrategyRequested('BTCUSDC')),
      expect:
          () => [
            const StrategyControlState(status: OperationStatus.inProgress),
            isA<StrategyControlState>()
                .having((s) => s.status, 'status', OperationStatus.failure)
                .having(
                  (s) => s.errorMessage,
                  'errorMessage',
                  'gRPC UNAVAILABLE',
                ),
          ],
    );
  });
}

