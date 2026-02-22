import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:mocktail/mocktail.dart';

import 'package:neotradingbotfront1777/core/di/injection.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/core/symbol/symbol_context.dart';
import 'package:neotradingbotfront1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_trading_repository.dart';
import 'package:neotradingbotfront1777/domain/usecases/manage_strategy_run_control_use_case.dart';
import 'package:neotradingbotfront1777/presentation/features/dashboard/bloc/strategy_state_bloc.dart';

class MockTradingRepository extends Mock implements ITradingRepository {}

class MockManageStrategyRunControlUseCase extends Mock
    implements ManageStrategyRunControlUseCase {}

class MockSymbolContext extends Mock implements SymbolContext {}

void main() {
  late MockTradingRepository mockTradingRepository;
  late MockManageStrategyRunControlUseCase mockManageUseCase;
  late MockSymbolContext mockSymbolContext;
  late StrategyStateBloc strategyStateBloc;
  late StreamController<Either<Failure, StrategyState>> streamController;

  final tStrategyState = StrategyState(
    symbol: 'BTCUSDC',
    status: StrategyStatus.running,
    openTradesCount: 0,
    averagePrice: 0.0,
    totalQuantity: 0.0,
    lastBuyPrice: 0.0,
    currentRoundId: 0,
    cumulativeProfit: 0.0,
    successfulRounds: 0,
    failedRounds: 0,
  );

  setUpAll(() {
    registerFallbackValue(tStrategyState);
  });

  setUp(() async {
    mockTradingRepository = MockTradingRepository();
    mockManageUseCase = MockManageStrategyRunControlUseCase();
    mockSymbolContext = MockSymbolContext();
    streamController = StreamController<Either<Failure, StrategyState>>();

    // Setup GetIt
    sl.allowReassignment = true;
    sl.registerSingleton<SymbolContext>(mockSymbolContext);

    strategyStateBloc = StrategyStateBloc(
      tradingRepository: mockTradingRepository,
      manageStrategyRunControlUseCase: mockManageUseCase,
    );
  });

  tearDown(() async {
    await strategyStateBloc.close();
    await streamController.close();
  });

  group('StrategyStateSubscriptionRequested', () {
    blocTest<StrategyStateBloc, StrategyStateState>(
      'emits [loading, subscribed] when repository succeeds',
      build: () {
        when(
          () => mockTradingRepository.getStrategyState(any()),
        ).thenAnswer((_) async => Right(tStrategyState));
        when(
          () => mockTradingRepository.subscribeToStrategyState(any()),
        ).thenAnswer((_) => streamController.stream);
        return strategyStateBloc;
      },
      act:
          (bloc) =>
              bloc.add(const StrategyStateSubscriptionRequested('BTCUSDC')),
      expect:
          () => [
            const StrategyStateState(
              status: StrategyStateStatus.loading,
              currentSymbol: 'BTCUSDC',
            ),
            StrategyStateState(
              status: StrategyStateStatus.subscribed,
              strategyState: tStrategyState,
              currentSymbol: 'BTCUSDC',
            ),
          ],
    );

    blocTest<StrategyStateBloc, StrategyStateState>(
      'handles NotFoundFailure as initial state',
      build: () {
        when(() => mockTradingRepository.getStrategyState(any())).thenAnswer(
          (_) async => const Left(NotFoundFailure(message: 'Not found')),
        );
        when(
          () => mockTradingRepository.subscribeToStrategyState(any()),
        ).thenAnswer((_) => streamController.stream);
        return strategyStateBloc;
      },
      act:
          (bloc) =>
              bloc.add(const StrategyStateSubscriptionRequested('BTCUSDC')),
      expect:
          () => [
            const StrategyStateState(
              status: StrategyStateStatus.loading,
              currentSymbol: 'BTCUSDC',
            ),
            isA<StrategyStateState>().having(
              (s) => s.status,
              'status',
              StrategyStateStatus.subscribed,
            ),
          ],
    );

    blocTest<StrategyStateBloc, StrategyStateState>(
      'emits failure on repository error',
      build: () {
        when(
          () => mockTradingRepository.getStrategyState(any()),
        ).thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));
        when(
          () => mockTradingRepository.subscribeToStrategyState(any()),
        ).thenAnswer((_) => streamController.stream);
        return strategyStateBloc;
      },
      act:
          (bloc) =>
              bloc.add(const StrategyStateSubscriptionRequested('BTCUSDC')),
      expect:
          () => [
            const StrategyStateState(
              status: StrategyStateStatus.loading,
              currentSymbol: 'BTCUSDC',
            ),
            const StrategyStateState(
              status: StrategyStateStatus.failure,
              failureMessage: 'Error',
              currentSymbol: 'BTCUSDC',
            ),
          ],
    );

    blocTest<StrategyStateBloc, StrategyStateState>(
      'updates state and calls use case on stream event',
      build: () {
        when(
          () => mockTradingRepository.getStrategyState(any()),
        ).thenAnswer((_) async => Right(tStrategyState));
        when(
          () => mockTradingRepository.subscribeToStrategyState(any()),
        ).thenAnswer((_) => streamController.stream);
        when(() => mockManageUseCase(any())).thenAnswer((_) async {});
        return strategyStateBloc;
      },
      act: (bloc) async {
        bloc.add(const StrategyStateSubscriptionRequested('BTCUSDC'));
        await Future.delayed(Duration.zero);
        final newState = tStrategyState.copyWith(status: StrategyStatus.paused);
        streamController.add(Right(newState));
      },
      skip: 2, // Skip loading and initial subscribed state
      expect:
          () => [
            StrategyStateState(
              status: StrategyStateStatus.subscribed,
              strategyState: tStrategyState.copyWith(
                status: StrategyStatus.paused,
              ),
              currentSymbol: 'BTCUSDC',
            ),
          ],
      verify: (_) {
        verify(() => mockManageUseCase(any())).called(1);
      },
    );

    blocTest<StrategyStateBloc, StrategyStateState>(
      'emits failure on stream error event',
      build: () {
        when(
          () => mockTradingRepository.getStrategyState(any()),
        ).thenAnswer((_) async => Right(tStrategyState));
        when(
          () => mockTradingRepository.subscribeToStrategyState(any()),
        ).thenAnswer((_) => streamController.stream);
        return strategyStateBloc;
      },
      act: (bloc) async {
        bloc.add(const StrategyStateSubscriptionRequested('BTCUSDC'));
        await Future.delayed(Duration.zero);
        streamController.add(
          const Left(ServerFailure(message: 'Stream Error')),
        );
      },
      skip: 2,
      expect:
          () => [
            StrategyStateState(
              status: StrategyStateStatus.failure,
              strategyState: tStrategyState,
              failureMessage: 'Stream Error',
              currentSymbol: 'BTCUSDC',
            ),
          ],
    );
  });

  group('SymbolChanged', () {
    blocTest<StrategyStateBloc, StrategyStateState>(
      'persists symbol and triggers subscription',
      build: () {
        when(
          () => mockSymbolContext.setActiveSymbol(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockTradingRepository.getStrategyState(any()),
        ).thenAnswer((_) async => Right(tStrategyState));
        when(
          () => mockTradingRepository.subscribeToStrategyState(any()),
        ).thenAnswer((_) => streamController.stream);
        return strategyStateBloc;
      },
      act: (bloc) => bloc.add(const SymbolChanged('ETHUSDC')),
      expect:
          () => [
            const StrategyStateState(
              status: StrategyStateStatus.loading,
              currentSymbol: 'ETHUSDC',
            ),
            StrategyStateState(
              status: StrategyStateStatus.subscribed,
              strategyState: tStrategyState,
              currentSymbol: 'ETHUSDC',
            ),
          ],
      verify: (_) {
        verify(() => mockSymbolContext.setActiveSymbol('ETHUSDC')).called(1);
      },
    );
  });
}

