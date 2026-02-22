import 'dart:async';
import 'package:decimal/decimal.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/application/managers/atomic_state_manager.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/fifo_app_trade.dart';
import 'package:neotradingbotback1777/domain/repositories/strategy_state_repository.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';

import 'atomic_state_manager_race_condition_test.mocks.dart';
import '../../helpers/mockito_dummy_registrations.dart';

@GenerateMocks([StrategyStateRepository])
void main() {
  group('[BACKEND-TEST-013] AtomicStateManager - Race Conditions', () {
    late MockStrategyStateRepository mockRepository;
    late AtomicStateManager manager;
    const String testSymbol = 'BTCUSDC';

    setUp(() {
      registerMockitoDummies();
      mockRepository = MockStrategyStateRepository();
      manager = AtomicStateManager(mockRepository, persistChanges: true);
    });

    test(
      'should handle concurrent STOP command during SELL execution',
      () async {
        // ARRANGE
        final initialState = AppStrategyState(
          symbol: testSymbol,
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
          currentRoundId: 5,
          cumulativeProfit: 150.0,
        );

        when(mockRepository.getStrategyState(testSymbol))
            .thenAnswer((_) async => Right(initialState));

        when(mockRepository.saveStrategyState(any))
            .thenAnswer((_) async => const Right(null));

        // Simula operazione SELL in corso (lunga 2 secondi)
        final sellOperation = manager.executeAtomicOperation(
          testSymbol,
          (currentState) async {
            await Future.delayed(const Duration(seconds: 2));
            return Right(currentState.copyWith(
              status: StrategyState.MONITORING_FOR_BUY,
              currentRoundId: currentState.currentRoundId + 1,
              cumulativeProfit: currentState.cumulativeProfit + 50.0,
            ));
          },
        );

        // Simula comando STOP simultaneo (dopo 500ms)
        final stopOperation = Future.delayed(
          const Duration(milliseconds: 500),
          () => manager.executeAtomicOperation(
            testSymbol,
            (currentState) async {
              return Right(currentState.copyWith(
                status: StrategyState.IDLE,
              ));
            },
          ),
        );

        // ACT - Esegui operazioni concorrenti
        final results = await Future.wait([sellOperation, stopOperation]);

        // ASSERT
        expect(results.length, 2);

        // Entrambe le operazioni devono avere successo (serializzate dal mutex)
        final successfulResults = results.where((r) => r.isRight()).toList();
        expect(successfulResults.length, 2,
            reason:
                'Entrambe le operazioni dovrebbero avere successo (serializzate)');

        // Lo stato finale deve essere deterministico (determinato dall'ultima operazione)
        final finalState =
            successfulResults.last.getOrElse((_) => throw Exception());

        // Lo stato finale deve essere IDLE (l'ultima operazione è STOP)
        expect(finalState.status, StrategyState.IDLE,
            reason: 'Stato finale deve essere IDLE (ultima operazione: STOP)');

        // Verifica che le operazioni siano atomiche (serializzate)
        verify(mockRepository.saveStrategyState(any)).called(2);
      },
    );

    test(
      'should prevent state corruption during high-frequency updates',
      () async {
        // ARRANGE
        final initialState = AppStrategyState(
          symbol: testSymbol,
          status: StrategyState.MONITORING_FOR_BUY,
          currentRoundId: 1,
        );

        when(mockRepository.getStrategyState(testSymbol))
            .thenAnswer((_) async => Right(initialState));

        when(mockRepository.saveStrategyState(any))
            .thenAnswer((_) async => const Right(null));

        // ACT - Genera 50 update concorrenti
        final updates = <Future<Either<Failure, AppStrategyState>>>[];

        for (int i = 0; i < 50; i++) {
          final update = manager.executeAtomicOperation(
            testSymbol,
            (currentState) async {
              // Simula update rapido
              await Future.delayed(Duration(milliseconds: i % 10));
              return Right(currentState.copyWith(
                currentRoundId: currentState.currentRoundId + 1,
              ));
            },
          );
          updates.add(update);
        }

        final results = await Future.wait(updates);

        // ASSERT
        final successfulResults = results.where((r) => r.isRight()).toList();
        expect(successfulResults.length, greaterThan(0),
            reason: 'Almeno alcune operazioni dovrebbero avere successo');

        if (successfulResults.isNotEmpty) {
          final finalState =
              successfulResults.last.getOrElse((_) => throw Exception());
          expect(finalState.currentRoundId,
              greaterThan(initialState.currentRoundId),
              reason: 'Round ID deve essere incrementato');
          expect(finalState.currentRoundId, lessThanOrEqualTo(51),
              reason: 'Round ID non deve superare il massimo possibile');
        }

        // Verifica che tutte le operazioni siano state serializzate
        verify(mockRepository.saveStrategyState(any))
            .called(successfulResults.length);
      },
    );

    test(
      'should handle cache invalidation during concurrent operations',
      () async {
        // ARRANGE
        final initialState = AppStrategyState(
          symbol: testSymbol,
          status: StrategyState.MONITORING_FOR_BUY,
          currentRoundId: 1,
        );

        when(mockRepository.getStrategyState(testSymbol))
            .thenAnswer((_) async => Right(initialState));

        when(mockRepository.saveStrategyState(any))
            .thenAnswer((_) async => const Right(null));

        // ACT - Esegui operazioni concorrenti con cache invalidation
        final futures = [
          // Operazione 1: Update stato
          manager.executeAtomicOperation(
            testSymbol,
            (currentState) async {
              await Future.delayed(const Duration(milliseconds: 100));
              return Right(currentState.copyWith(
                status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
                openTrades: [
                  FifoAppTrade(
                    price: Decimal.parse('100.0'),
                    quantity: Decimal.parse('1.0'),
                    timestamp: DateTime.now().millisecondsSinceEpoch,
                    roundId: 1,
                  ),
                ],
              ));
            },
          ),
          // Operazione 2: Cache invalidation
          Future(() async {
            await Future.delayed(const Duration(milliseconds: 50));
            manager.invalidateCache();
          }),
          // Operazione 3: Altro update
          manager.executeAtomicOperation(
            testSymbol,
            (currentState) async {
              await Future.delayed(const Duration(milliseconds: 150));
              return Right(currentState.copyWith(
                currentRoundId: currentState.currentRoundId + 1,
              ));
            },
          ),
        ];

        final results = await Future.wait(futures);

        // ASSERT
        expect(results.length, 3);

        // Le operazioni atomiche dovrebbero avere successo
        final atomicResults =
            results.whereType<Either<Failure, AppStrategyState>>().toList();
        expect(atomicResults.length, 2);

        for (final result in atomicResults) {
          expect(result.isRight(), isTrue,
              reason: 'Le operazioni atomiche dovrebbero avere successo');
        }
      },
    );

    test(
      'should maintain consistency during rapid state transitions',
      () async {
        // ARRANGE
        final initialState = AppStrategyState(
          symbol: testSymbol,
          status: StrategyState.IDLE,
          currentRoundId: 1,
        );

        when(mockRepository.getStrategyState(testSymbol))
            .thenAnswer((_) async => Right(initialState));

        when(mockRepository.saveStrategyState(any))
            .thenAnswer((_) async => const Right(null));

        // ACT - Simula transizioni di stato rapide
        final transitions = [
          StrategyState.MONITORING_FOR_BUY,
          StrategyState.BUY_ORDER_PLACED,
          StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
          StrategyState.SELL_ORDER_PLACED,
          StrategyState.MONITORING_FOR_BUY,
        ];

        final futures = <Future<Either<Failure, AppStrategyState>>>[];

        for (int i = 0; i < transitions.length; i++) {
          final future = manager.executeAtomicOperation(
            testSymbol,
            (currentState) async {
              return Right(currentState.copyWith(
                status: transitions[i],
                currentRoundId: currentState.currentRoundId + 1,
              ));
            },
          );
          futures.add(future);
        }

        final results = await Future.wait(futures);

        // ASSERT
        expect(results.length, transitions.length);

        // Tutte le operazioni dovrebbero avere successo
        for (final result in results) {
          expect(result.isRight(), isTrue);
        }

        // Verifica che le transizioni siano state serializzate
        verify(mockRepository.saveStrategyState(any))
            .called(transitions.length);

        // Verifica che lo stato finale sia corretto
        final finalState = results.last.getOrElse((_) => throw Exception());
        expect(finalState.status, StrategyState.MONITORING_FOR_BUY);
        expect(finalState.currentRoundId,
            initialState.currentRoundId + transitions.length);
      },
    );

    test(
      'should handle repository failures gracefully during concurrent operations',
      () async {
        // ARRANGE
        final initialState = AppStrategyState(
          symbol: testSymbol,
          status: StrategyState.MONITORING_FOR_BUY,
          currentRoundId: 1,
        );

        when(mockRepository.getStrategyState(testSymbol))
            .thenAnswer((_) async => Right(initialState));

        // Simula fallimenti intermittenti del repository
        var callCount = 0;
        when(mockRepository.saveStrategyState(any)).thenAnswer((_) async {
          callCount++;
          if (callCount % 3 == 0) {
            return Left(CacheFailure(message: 'Simulated repository failure'));
          }
          return const Right(null);
        });

        // ACT - Esegui operazioni concorrenti
        final updates = <Future<Either<Failure, AppStrategyState>>>[];

        for (int i = 0; i < 15; i++) {
          final update = manager.executeAtomicOperation(
            testSymbol,
            (currentState) async {
              return Right(currentState.copyWith(
                currentRoundId: currentState.currentRoundId + 1,
              ));
            },
          );
          updates.add(update);
        }

        final results = await Future.wait(updates);

        // ASSERT
        expect(results.length, 15);

        // Alcune operazioni dovrebbero fallire
        final successCount = results.where((r) => r.isRight()).length;
        final failureCount = results.where((r) => r.isLeft()).length;

        expect(successCount, greaterThan(0),
            reason: 'Alcune operazioni dovrebbero avere successo');
        expect(failureCount, greaterThan(0),
            reason: 'Alcune operazioni dovrebbero fallire');
        expect(successCount + failureCount, 15);

        // Verifica che i fallimenti siano gestiti gracefully
        for (final result in results) {
          if (result.isLeft()) {
            expect(
                result.fold(
                  (failure) => failure.runtimeType,
                  (_) => null,
                ),
                CacheFailure);
          }
        }
      },
    );
  });
}

