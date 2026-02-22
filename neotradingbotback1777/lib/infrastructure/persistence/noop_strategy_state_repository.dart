import 'dart:async';
import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/strategy_state_repository.dart';

/// No-op implementation used in atomic isolates (no disk persistence).
class StrategyStateRepositoryNoop implements StrategyStateRepository {
  @override
  Future<Either<Failure, void>> saveStrategyState(
      AppStrategyState state) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, AppStrategyState?>> getStrategyState(
      String symbol) async {
    return const Right(null);
  }

  @override
  Stream<Either<Failure, AppStrategyState>> subscribeToStateStream(
      String symbol) async* {}

  @override
  Future<Either<Failure, AppStrategyState>> updateStrategyStateAtomically(
    String symbol,
    AppStrategyState Function(AppStrategyState? currentState) updateFunction,
  ) async {
    // Simply apply update on null (initial) and return
    try {
      final updated = updateFunction(null);
      return Right(updated);
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetStrategyState(String symbol) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, Map<String, AppStrategyState>>>
      getAllStrategyStates() async {
    return const Right({});
  }

  @override
  Future<Either<Failure, void>> deleteStrategyState(String symbol) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, bool>> hasStrategyState(String symbol) async {
    return const Right(false);
  }
}
