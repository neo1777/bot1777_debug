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
  final tFailure = ServerFailure(message: 'API Error');

  group('StrategyControlBloc', () {
    test('[SCB-000] initial state is correct', () {
      expect(strategyControlBloc.state, const StrategyControlState());
    });

    group('StartStrategyRequested', () {
      blocTest<StrategyControlBloc, StrategyControlState>(
        '[SCB-001] emits [inProgress, success] when startStrategy is successful',
        build: () {
          // GIVEN
          when(
            () => mockTradingRepository.startStrategy(any()),
          ).thenAnswer((_) async => Right<Failure, Unit>(unit));
          return strategyControlBloc;
        },
        act: (bloc) {
          // WHEN
          bloc.add(const StartStrategyRequested(tSymbol));
        },
        expect:
            () => const <StrategyControlState>[
              // THEN
              StrategyControlState(status: OperationStatus.inProgress),
              StrategyControlState(status: OperationStatus.success),
            ],
        verify: (_) {
          verify(() => mockTradingRepository.startStrategy(tSymbol)).called(1);
        },
      );

      blocTest<StrategyControlBloc, StrategyControlState>(
        '[SCB-002] emits [inProgress, failure] when startStrategy fails',
        build: () {
          // GIVEN
          when(
            () => mockTradingRepository.startStrategy(any()),
          ).thenAnswer((_) async => Left(tFailure));
          return strategyControlBloc;
        },
        act: (bloc) {
          // WHEN
          bloc.add(const StartStrategyRequested(tSymbol));
        },
        expect:
            () => <StrategyControlState>[
              // THEN
              const StrategyControlState(status: OperationStatus.inProgress),
              StrategyControlState(
                status: OperationStatus.failure,
                errorMessage: tFailure.message,
              ),
            ],
      );
    });

    group('StopStrategyRequested', () {
      blocTest<StrategyControlBloc, StrategyControlState>(
        '[SCB-003] emits [inProgress, success] when stopStrategy is successful',
        build: () {
          // GIVEN
          when(
            () => mockTradingRepository.stopStrategy(any()),
          ).thenAnswer((_) async => Right<Failure, Unit>(unit));
          return strategyControlBloc;
        },
        act: (bloc) {
          // WHEN
          bloc.add(const StopStrategyRequested(tSymbol));
        },
        expect:
            () => const <StrategyControlState>[
              // THEN
              StrategyControlState(status: OperationStatus.inProgress),
              StrategyControlState(status: OperationStatus.success),
            ],
        verify: (_) {
          verify(() => mockTradingRepository.stopStrategy(tSymbol)).called(1);
        },
      );

      blocTest<StrategyControlBloc, StrategyControlState>(
        '[SCB-004] emits [inProgress, failure] when stopStrategy fails',
        build: () {
          // GIVEN
          when(
            () => mockTradingRepository.stopStrategy(any()),
          ).thenAnswer((_) async => Left(tFailure));
          return strategyControlBloc;
        },
        act: (bloc) {
          // WHEN
          bloc.add(const StopStrategyRequested(tSymbol));
        },
        expect:
            () => <StrategyControlState>[
              // THEN
              const StrategyControlState(status: OperationStatus.inProgress),
              StrategyControlState(
                status: OperationStatus.failure,
                errorMessage: tFailure.message,
              ),
            ],
      );
    });

    group('PauseStrategyRequested', () {
      blocTest<StrategyControlBloc, StrategyControlState>(
        '[SCB-005] emits [inProgress, success] when pauseTrading is successful',
        build: () {
          // GIVEN
          when(
            () => mockTradingRepository.pauseTrading(any()),
          ).thenAnswer((_) async => Right<Failure, Unit>(unit));
          return strategyControlBloc;
        },
        act: (bloc) {
          // WHEN
          bloc.add(const PauseStrategyRequested(tSymbol));
        },
        expect:
            () => const <StrategyControlState>[
              // THEN
              StrategyControlState(status: OperationStatus.inProgress),
              StrategyControlState(status: OperationStatus.success),
            ],
        verify: (_) {
          verify(() => mockTradingRepository.pauseTrading(tSymbol)).called(1);
        },
      );

      blocTest<StrategyControlBloc, StrategyControlState>(
        '[SCB-006] emits [inProgress, failure] when pauseTrading fails',
        build: () {
          // GIVEN
          when(
            () => mockTradingRepository.pauseTrading(any()),
          ).thenAnswer((_) async => Left(tFailure));
          return strategyControlBloc;
        },
        act: (bloc) {
          // WHEN
          bloc.add(const PauseStrategyRequested(tSymbol));
        },
        expect:
            () => <StrategyControlState>[
              // THEN
              const StrategyControlState(status: OperationStatus.inProgress),
              StrategyControlState(
                status: OperationStatus.failure,
                errorMessage: tFailure.message,
              ),
            ],
      );
    });

    group('ResumeStrategyRequested', () {
      blocTest<StrategyControlBloc, StrategyControlState>(
        '[SCB-007] emits [inProgress, success] when resumeTrading is successful',
        build: () {
          // GIVEN
          when(
            () => mockTradingRepository.resumeTrading(any()),
          ).thenAnswer((_) async => Right<Failure, Unit>(unit));
          return strategyControlBloc;
        },
        act: (bloc) {
          // WHEN
          bloc.add(const ResumeStrategyRequested(tSymbol));
        },
        expect:
            () => const <StrategyControlState>[
              // THEN
              StrategyControlState(status: OperationStatus.inProgress),
              StrategyControlState(status: OperationStatus.success),
            ],
        verify: (_) {
          verify(() => mockTradingRepository.resumeTrading(tSymbol)).called(1);
        },
      );

      blocTest<StrategyControlBloc, StrategyControlState>(
        '[SCB-008] emits [inProgress, failure] when resumeTrading fails',
        build: () {
          // GIVEN
          when(
            () => mockTradingRepository.resumeTrading(any()),
          ).thenAnswer((_) async => Left(tFailure));
          return strategyControlBloc;
        },
        act: (bloc) {
          // WHEN
          bloc.add(const ResumeStrategyRequested(tSymbol));
        },
        expect:
            () => <StrategyControlState>[
              // THEN
              const StrategyControlState(status: OperationStatus.inProgress),
              StrategyControlState(
                status: OperationStatus.failure,
                errorMessage: tFailure.message,
              ),
            ],
      );
    });
  });
}
