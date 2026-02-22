import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:neotradingbotfront1777/domain/entities/system_log.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_trading_repository.dart';
import 'package:neotradingbotfront1777/presentation/blocs/system_log/system_log_bloc.dart';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';

// Definizione del Mock con Mocktail
class MockTradingRepository extends Mock implements ITradingRepository {}

void main() {
  late MockTradingRepository mockTradingRepository;
  late SystemLogBloc systemLogBloc;
  late StreamController<Either<Failure, SystemLog>> logStreamController;

  setUp(() {
    mockTradingRepository = MockTradingRepository();
    logStreamController =
        StreamController<Either<Failure, SystemLog>>.broadcast();
    when(
      () => mockTradingRepository.subscribeToSystemLogs(),
    ).thenAnswer((_) => logStreamController.stream);
    systemLogBloc = SystemLogBloc(tradingRepository: mockTradingRepository);
  });

  tearDown(() {
    logStreamController.close();
    systemLogBloc.close();
  });

  final tLog = SystemLog(
    timestamp: DateTime.now(),
    level: LogLevel.info,
    message: 'Test log message',
  );

  group('SystemLogBloc', () {
    test('initial state is correct', () {
      expect(systemLogBloc.state, const SystemLogState());
    });

    blocTest<SystemLogBloc, SystemLogState>(
      'emits [loading, subscribed] when subscription is requested and succeeds',
      build: () => systemLogBloc,
      act: (bloc) => bloc.add(const SystemLogSubscriptionRequested()),
      expect:
          () => <SystemLogState>[
            const SystemLogState(status: SystemLogStatus.loading),
            const SystemLogState(status: SystemLogStatus.subscribed),
          ],
      verify: (_) {
        verify(() => mockTradingRepository.subscribeToSystemLogs()).called(1);
      },
    );

    blocTest<SystemLogBloc, SystemLogState>(
      'emits new log when received from repository',
      build: () => systemLogBloc,
      act: (bloc) async {
        bloc.add(const SystemLogSubscriptionRequested());
        await Future.delayed(Duration.zero);
        logStreamController.add(Right(tLog));
      },
      skip: 2,
      expect:
          () => <SystemLogState>[
            SystemLogState(status: SystemLogStatus.subscribed, logs: [tLog]),
          ],
    );

    blocTest<SystemLogBloc, SystemLogState>(
      'emits failure when stream emits a Left(Failure)',
      build: () => systemLogBloc,
      act: (bloc) async {
        bloc.add(const SystemLogSubscriptionRequested());
        await Future.delayed(Duration.zero);
        logStreamController.add(Left(ServerFailure(message: 'Stream Error')));
      },
      skip: 2,
      expect:
          () => <SystemLogState>[
            const SystemLogState(
              status: SystemLogStatus.failure,
              errorMessage: 'Stream Error',
            ),
          ],
    );

    blocTest<SystemLogBloc, SystemLogState>(
      'emits failure when stream completes (onDone)',
      build: () => systemLogBloc,
      act: (bloc) async {
        bloc.add(const SystemLogSubscriptionRequested());
        await Future.delayed(Duration.zero);
        await logStreamController.close();
      },
      skip: 2,
      expect:
          () => <SystemLogState>[
            const SystemLogState(
              status: SystemLogStatus.failure,
              errorMessage: 'Connessione log interrotta',
            ),
          ],
    );

    blocTest<SystemLogBloc, SystemLogState>(
      'emits failure when stream has an error',
      build: () => systemLogBloc,
      act: (bloc) async {
        bloc.add(const SystemLogSubscriptionRequested());
        await Future.delayed(Duration.zero);
        logStreamController.addError('Connection reset');
      },
      skip: 2,
      expect:
          () => <SystemLogState>[
            const SystemLogState(
              status: SystemLogStatus.failure,
              errorMessage: 'Errore nello stream dei log: Connection reset',
            ),
          ],
    );

    blocTest<SystemLogBloc, SystemLogState>(
      'updates active levels when filter changed',
      build: () => systemLogBloc,
      act:
          (bloc) =>
              bloc.add(const SystemLogFilterChanged(levels: {LogLevel.error})),
      expect:
          () => <SystemLogState>[
            const SystemLogState(activeLevels: {LogLevel.error}),
          ],
    );

    blocTest<SystemLogBloc, SystemLogState>(
      'updates query when filter changed',
      build: () => systemLogBloc,
      act: (bloc) => bloc.add(const SystemLogFilterChanged(query: 'search')),
      expect: () => <SystemLogState>[const SystemLogState(query: 'search')],
    );

    blocTest<SystemLogBloc, SystemLogState>(
      'clears logs when clear requested',
      build: () => systemLogBloc,
      seed: () => SystemLogState(logs: [tLog]),
      act: (bloc) => bloc.add(const SystemLogClearRequested()),
      expect: () => <SystemLogState>[const SystemLogState(logs: [])],
    );

    blocTest<SystemLogBloc, SystemLogState>(
      'increases visible count when load more requested',
      build: () => systemLogBloc,
      seed:
          () => SystemLogState(
            logs: List.generate(100, (i) => tLog),
            visibleCount: 50,
          ),
      act: (bloc) => bloc.add(const SystemLogLoadMoreRequested()),
      expect:
          () => <SystemLogState>[
            SystemLogState(
              logs: List.generate(100, (i) => tLog),
              visibleCount: 100, // 50 + 50 (default pageSize)
            ),
          ],
    );

    blocTest<SystemLogBloc, SystemLogState>(
      'toggles autoScroll when requested',
      build: () => systemLogBloc,
      act: (bloc) => bloc.add(const SystemLogToggleAutoScroll(false)),
      expect: () => <SystemLogState>[const SystemLogState(autoScroll: false)],
    );
  });
}
