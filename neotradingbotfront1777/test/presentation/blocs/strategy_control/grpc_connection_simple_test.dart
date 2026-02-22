import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/presentation/blocs/strategy_control/strategy_control_bloc.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_trading_repository.dart';

// Mock del repository
class MockTradingRepository extends Mock implements ITradingRepository {}

void main() {
  group('[FRONTEND-TEST-012] gRPC Connection Recovery Tests', () {
    late MockTradingRepository mockRepository;

    setUpAll(() {
      registerFallbackValue(const StartStrategyRequested(''));
    });

    setUp(() {
      mockRepository = MockTradingRepository();
    });

    group('Basic Network Tests', () {
      blocTest<StrategyControlBloc, StrategyControlState>(
        'should handle network timeout',
        build: () {
          when(() => mockRepository.startStrategy(any())).thenAnswer((_) async {
            await Future.delayed(const Duration(seconds: 2));
            throw Exception('gRPC timeout');
          });
          return StrategyControlBloc(tradingRepository: mockRepository);
        },
        act: (bloc) => bloc.add(const StartStrategyRequested('BTCUSDC')),
        wait: const Duration(seconds: 5),
        expect:
            () => [
              const StrategyControlState(status: OperationStatus.inProgress),
              isA<StrategyControlState>()
                  .having((s) => s.status, 'status', OperationStatus.failure)
                  .having(
                    (s) => s.errorMessage,
                    'errorMessage',
                    contains('gRPC timeout'),
                  ),
            ],
        verify: (_) {
          verify(() => mockRepository.startStrategy('BTCUSDC')).called(1);
        },
      );

      blocTest<StrategyControlBloc, StrategyControlState>(
        'should handle network error',
        build: () {
          when(() => mockRepository.startStrategy(any())).thenAnswer(
            (_) async => Left(ServerFailure(message: 'Connection refused')),
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
                    'Connection refused',
                  ),
            ],
        verify: (_) {
          verify(() => mockRepository.startStrategy('BTCUSDC')).called(1);
        },
      );

      blocTest<StrategyControlBloc, StrategyControlState>(
        'should handle successful operation',
        build: () {
          when(
            () => mockRepository.startStrategy(any()),
          ).thenAnswer((_) async => const Right(unit));
          return StrategyControlBloc(tradingRepository: mockRepository);
        },
        act: (bloc) => bloc.add(const StartStrategyRequested('BTCUSDC')),
        expect:
            () => [
              const StrategyControlState(status: OperationStatus.inProgress),
              const StrategyControlState(status: OperationStatus.success),
            ],
        verify: (_) {
          verify(() => mockRepository.startStrategy('BTCUSDC')).called(1);
        },
      );
    });

    group('Retry Tests', () {
      blocTest<StrategyControlBloc, StrategyControlState>(
        'should retry after failure',
        build: () {
          var callCount = 0;
          when(() => mockRepository.startStrategy(any())).thenAnswer((_) async {
            callCount++;
            if (callCount == 1) {
              throw Exception('Network error');
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
        verify: (_) {
          verify(() => mockRepository.startStrategy('BTCUSDC')).called(2);
        },
      );
    });

    group('Multiple Operations Tests', () {
      blocTest<StrategyControlBloc, StrategyControlState>(
        'should handle multiple operations',
        build: () {
          when(() => mockRepository.startStrategy(any())).thenAnswer((_) async {
            await Future.delayed(const Duration(milliseconds: 50));
            throw Exception('Network timeout');
          });
          return StrategyControlBloc(tradingRepository: mockRepository);
        },
        act: (bloc) async {
          bloc.add(const StartStrategyRequested('BTCUSDC'));
          await Future.delayed(const Duration(milliseconds: 200));
          bloc.add(const StartStrategyRequested('ETHUSDC'));
        },
        wait: const Duration(milliseconds: 500),
        expect:
            () => [
              const StrategyControlState(status: OperationStatus.inProgress),
              isA<StrategyControlState>().having(
                (s) => s.status,
                'status',
                OperationStatus.failure,
              ),
              const StrategyControlState(status: OperationStatus.inProgress),
              isA<StrategyControlState>().having(
                (s) => s.status,
                'status',
                OperationStatus.failure,
              ),
            ],
      );
    });
  });
}
