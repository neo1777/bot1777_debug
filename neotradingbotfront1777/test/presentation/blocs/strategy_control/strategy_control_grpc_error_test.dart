import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/presentation/blocs/strategy_control/strategy_control_bloc.dart';
import '../../../mocks/mocks.dart';

void main() {
  late MockTradingRepository mockTradingRepository;
  late StrategyControlBloc strategyControlBloc;

  setUpAll(() {
    registerFallbackValue(Right<Failure, Unit>(unit));
    registerFallbackValue(const StartStrategyRequested(''));
  });

  setUp(() {
    mockTradingRepository = MockTradingRepository();
    strategyControlBloc = StrategyControlBloc(
      tradingRepository: mockTradingRepository,
    );
  });

  tearDown(() {
    strategyControlBloc.close();
  });

  const tSymbol = 'BTCUSDC';

  group('[FRONTEND-TEST-001] Gestione Errori gRPC', () {
    group('Network Failures', () {
      blocTest<StrategyControlBloc, StrategyControlState>(
        'should handle network timeout gracefully',
        build: () {
          when(() => mockTradingRepository.startStrategy(any())).thenAnswer((
            _,
          ) async {
            // Simula timeout di rete
            await Future.delayed(const Duration(seconds: 10));
            return Left(NetworkFailure(message: 'Connection timeout'));
          });
          return strategyControlBloc;
        },
        act: (bloc) => bloc.add(const StartStrategyRequested(tSymbol)),
        wait: const Duration(seconds: 15),
        expect:
            () => <StrategyControlState>[
              const StrategyControlState(status: OperationStatus.inProgress),
              const StrategyControlState(
                status: OperationStatus.failure,
                errorMessage: 'Connection timeout',
              ),
            ],
        verify: (_) {
          verify(() => mockTradingRepository.startStrategy(tSymbol)).called(1);
        },
      );

      blocTest<StrategyControlBloc, StrategyControlState>(
        'should handle intermittent network failures',
        build: () {
          int callCount = 0;
          when(() => mockTradingRepository.startStrategy(any())).thenAnswer((
            _,
          ) async {
            callCount++;
            if (callCount % 2 == 0) {
              return Right<Failure, Unit>(unit);
            } else {
              return Left(NetworkFailure(message: 'Intermittent failure'));
            }
          });
          return strategyControlBloc;
        },
        act: (bloc) {
          bloc.add(const StartStrategyRequested(tSymbol));
          bloc.add(const StartStrategyRequested(tSymbol));
        },
        expect:
            () => <StrategyControlState>[
              const StrategyControlState(status: OperationStatus.inProgress),
              const StrategyControlState(
                status: OperationStatus.failure,
                errorMessage: 'Intermittent failure',
              ),
              const StrategyControlState(status: OperationStatus.inProgress),
              const StrategyControlState(status: OperationStatus.success),
            ],
        verify: (_) {
          verify(() => mockTradingRepository.startStrategy(tSymbol)).called(2);
        },
      );

      blocTest<StrategyControlBloc, StrategyControlState>(
        'should handle connection refused errors',
        build: () {
          when(() => mockTradingRepository.startStrategy(any())).thenAnswer(
            (_) async => Left(NetworkFailure(message: 'Connection refused')),
          );
          return strategyControlBloc;
        },
        act: (bloc) => bloc.add(const StartStrategyRequested(tSymbol)),
        expect:
            () => <StrategyControlState>[
              const StrategyControlState(status: OperationStatus.inProgress),
              const StrategyControlState(
                status: OperationStatus.failure,
                errorMessage: 'Connection refused',
              ),
            ],
      );
    });

    group('Server Errors', () {
      blocTest<StrategyControlBloc, StrategyControlState>(
        'should handle server unavailable errors',
        build: () {
          when(() => mockTradingRepository.startStrategy(any())).thenAnswer(
            (_) async => Left(ServerFailure(message: 'Service unavailable')),
          );
          return strategyControlBloc;
        },
        act: (bloc) => bloc.add(const StartStrategyRequested(tSymbol)),
        expect:
            () => <StrategyControlState>[
              const StrategyControlState(status: OperationStatus.inProgress),
              const StrategyControlState(
                status: OperationStatus.failure,
                errorMessage: 'Service unavailable',
              ),
            ],
      );

      blocTest<StrategyControlBloc, StrategyControlState>(
        'should handle authentication failures',
        build: () {
          when(() => mockTradingRepository.startStrategy(any())).thenAnswer(
            (_) async => Left(ServerFailure(message: 'Unauthorized access')),
          );
          return strategyControlBloc;
        },
        act: (bloc) => bloc.add(const StartStrategyRequested(tSymbol)),
        expect:
            () => <StrategyControlState>[
              const StrategyControlState(status: OperationStatus.inProgress),
              const StrategyControlState(
                status: OperationStatus.failure,
                errorMessage: 'Unauthorized access',
              ),
            ],
      );

      blocTest<StrategyControlBloc, StrategyControlState>(
        'should handle internal server errors',
        build: () {
          when(() => mockTradingRepository.startStrategy(any())).thenAnswer(
            (_) async => Left(ServerFailure(message: 'Internal server error')),
          );
          return strategyControlBloc;
        },
        act: (bloc) => bloc.add(const StartStrategyRequested(tSymbol)),
        expect:
            () => <StrategyControlState>[
              const StrategyControlState(status: OperationStatus.inProgress),
              const StrategyControlState(
                status: OperationStatus.failure,
                errorMessage: 'Internal server error',
              ),
            ],
      );
    });

    group('gRPC Specific Errors', () {
      blocTest<StrategyControlBloc, StrategyControlState>(
        'should handle gRPC deadline exceeded errors',
        build: () {
          when(() => mockTradingRepository.startStrategy(any())).thenAnswer(
            (_) async => Left(ServerFailure(message: 'Deadline exceeded')),
          );
          return strategyControlBloc;
        },
        act: (bloc) => bloc.add(const StartStrategyRequested(tSymbol)),
        expect:
            () => <StrategyControlState>[
              const StrategyControlState(status: OperationStatus.inProgress),
              const StrategyControlState(
                status: OperationStatus.failure,
                errorMessage: 'Deadline exceeded',
              ),
            ],
      );

      blocTest<StrategyControlBloc, StrategyControlState>(
        'should handle gRPC resource exhausted errors',
        build: () {
          when(() => mockTradingRepository.startStrategy(any())).thenAnswer(
            (_) async => Left(ServerFailure(message: 'Resource exhausted')),
          );
          return strategyControlBloc;
        },
        act: (bloc) => bloc.add(const StartStrategyRequested(tSymbol)),
        expect:
            () => <StrategyControlState>[
              const StrategyControlState(status: OperationStatus.inProgress),
              const StrategyControlState(
                status: OperationStatus.failure,
                errorMessage: 'Resource exhausted',
              ),
            ],
      );

      blocTest<StrategyControlBloc, StrategyControlState>(
        'should handle gRPC unavailable errors',
        build: () {
          when(() => mockTradingRepository.startStrategy(any())).thenAnswer(
            (_) async => Left(ServerFailure(message: 'Service unavailable')),
          );
          return strategyControlBloc;
        },
        act: (bloc) => bloc.add(const StartStrategyRequested(tSymbol)),
        expect:
            () => <StrategyControlState>[
              const StrategyControlState(status: OperationStatus.inProgress),
              const StrategyControlState(
                status: OperationStatus.failure,
                errorMessage: 'Service unavailable',
              ),
            ],
      );
    });

    group('Recovery Scenarios', () {
      blocTest<StrategyControlBloc, StrategyControlState>(
        'should recover from failure state on successful retry',
        build: () {
          int callCount = 0;
          when(() => mockTradingRepository.startStrategy(any())).thenAnswer((
            _,
          ) async {
            callCount++;
            if (callCount == 1) {
              return Left(NetworkFailure(message: 'First attempt failed'));
            } else {
              return Right<Failure, Unit>(unit);
            }
          });
          return strategyControlBloc;
        },
        act: (bloc) {
          bloc.add(const StartStrategyRequested(tSymbol));
          bloc.add(const StartStrategyRequested(tSymbol));
        },
        expect:
            () => <StrategyControlState>[
              const StrategyControlState(status: OperationStatus.inProgress),
              const StrategyControlState(
                status: OperationStatus.failure,
                errorMessage: 'First attempt failed',
              ),
              const StrategyControlState(status: OperationStatus.inProgress),
              const StrategyControlState(status: OperationStatus.success),
            ],
        verify: (_) {
          verify(() => mockTradingRepository.startStrategy(tSymbol)).called(2);
        },
      );

      blocTest<StrategyControlBloc, StrategyControlState>(
        'should maintain error state until successful operation',
        build: () {
          int callCount = 0;
          when(() => mockTradingRepository.startStrategy(any())).thenAnswer((
            _,
          ) async {
            callCount++;
            if (callCount <= 3) {
              return Left(ServerFailure(message: 'Persistent failure'));
            } else {
              return Right<Failure, Unit>(unit);
            }
          });
          return strategyControlBloc;
        },
        act: (bloc) {
          bloc.add(const StartStrategyRequested(tSymbol));
          bloc.add(const StartStrategyRequested(tSymbol));
          bloc.add(const StartStrategyRequested(tSymbol));
          bloc.add(const StartStrategyRequested(tSymbol));
        },
        expect:
            () => <StrategyControlState>[
              const StrategyControlState(status: OperationStatus.inProgress),
              const StrategyControlState(
                status: OperationStatus.failure,
                errorMessage: 'Persistent failure',
              ),
              const StrategyControlState(status: OperationStatus.inProgress),
              const StrategyControlState(
                status: OperationStatus.failure,
                errorMessage: 'Persistent failure',
              ),
              const StrategyControlState(status: OperationStatus.inProgress),
              const StrategyControlState(
                status: OperationStatus.failure,
                errorMessage: 'Persistent failure',
              ),
              const StrategyControlState(status: OperationStatus.inProgress),
              const StrategyControlState(status: OperationStatus.success),
            ],
        verify: (_) {
          verify(() => mockTradingRepository.startStrategy(tSymbol)).called(4);
        },
      );
    });

    group('Error Message Handling', () {
      blocTest<StrategyControlBloc, StrategyControlState>(
        'should display clear error messages for different failure types',
        build: () {
          when(() => mockTradingRepository.startStrategy(any())).thenAnswer(
            (_) async =>
                Left(NetworkFailure(message: 'Network connection lost')),
          );
          return strategyControlBloc;
        },
        act: (bloc) => bloc.add(const StartStrategyRequested(tSymbol)),
        expect:
            () => <StrategyControlState>[
              const StrategyControlState(status: OperationStatus.inProgress),
              const StrategyControlState(
                status: OperationStatus.failure,
                errorMessage: 'Network connection lost',
              ),
            ],
      );

      blocTest<StrategyControlBloc, StrategyControlState>(
        'should handle empty error messages gracefully',
        build: () {
          when(
            () => mockTradingRepository.startStrategy(any()),
          ).thenAnswer((_) async => Left(ServerFailure(message: '')));
          return strategyControlBloc;
        },
        act: (bloc) => bloc.add(const StartStrategyRequested(tSymbol)),
        expect:
            () => <StrategyControlState>[
              const StrategyControlState(status: OperationStatus.inProgress),
              const StrategyControlState(
                status: OperationStatus.failure,
                errorMessage: '',
              ),
            ],
      );

      blocTest<StrategyControlBloc, StrategyControlState>(
        'should handle very long error messages',
        build: () {
          final longMessage = 'A' * 1000; // Messaggio molto lungo
          when(
            () => mockTradingRepository.startStrategy(any()),
          ).thenAnswer((_) async => Left(ServerFailure(message: longMessage)));
          return strategyControlBloc;
        },
        act: (bloc) => bloc.add(const StartStrategyRequested(tSymbol)),
        expect:
            () => <StrategyControlState>[
              const StrategyControlState(status: OperationStatus.inProgress),
              StrategyControlState(
                status: OperationStatus.failure,
                errorMessage: 'A' * 1000,
              ),
            ],
      );
    });

    group('Concurrent Error Handling', () {
      blocTest<StrategyControlBloc, StrategyControlState>(
        'should handle multiple concurrent error events',
        build: () {
          when(() => mockTradingRepository.startStrategy(any())).thenAnswer(
            (_) async => Left(NetworkFailure(message: 'Concurrent error')),
          );
          when(
            () => mockTradingRepository.stopStrategy(any()),
          ).thenAnswer((_) async => Left(ServerFailure(message: 'Stop error')));
          return strategyControlBloc;
        },
        act: (bloc) {
          bloc.add(const StartStrategyRequested(tSymbol));
          bloc.add(const StopStrategyRequested(tSymbol));
        },
        expect:
            () => <StrategyControlState>[
              const StrategyControlState(status: OperationStatus.inProgress),
              const StrategyControlState(
                status: OperationStatus.failure,
                errorMessage: 'Concurrent error',
              ),
              const StrategyControlState(status: OperationStatus.inProgress),
              const StrategyControlState(
                status: OperationStatus.failure,
                errorMessage: 'Stop error',
              ),
            ],
        verify: (_) {
          verify(() => mockTradingRepository.startStrategy(tSymbol)).called(1);
          verify(() => mockTradingRepository.stopStrategy(tSymbol)).called(1);
        },
      );
    });
  });
}
