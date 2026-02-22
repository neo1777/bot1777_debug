import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';

/// Repository interface for trading strategy state management.
///
/// This repository handles strategy states with atomic operations,
/// streaming capabilities, and automatic state synchronization.
abstract class StrategyStateRepository {
  /// Saves strategy state with atomic operation protection.
  ///
  /// [state] - The strategy state to save
  ///
  /// Returns [Either<Failure, void>] indicating success or failure.
  /// Uses mutex protection to prevent race conditions.
  Future<Either<Failure, void>> saveStrategyState(AppStrategyState state);

  /// Retrieves strategy state for a specific symbol.
  ///
  /// [symbol] - The trading pair symbol to query
  ///
  /// Returns [Either<Failure, AppStrategyState?>] with state or null if not found.
  Future<Either<Failure, AppStrategyState?>> getStrategyState(String symbol);

  /// Subscribes to real-time strategy state updates.
  ///
  /// Provides a stream of state changes for a specific symbol.
  /// The stream includes both local updates and external synchronization.
  ///
  /// [symbol] - The trading pair symbol to monitor
  ///
  /// Returns [Stream<Either<Failure, AppStrategyState>>] with state updates.
  Stream<Either<Failure, AppStrategyState>> subscribeToStateStream(
      String symbol);

  /// Updates strategy state atomically with rollback protection.
  ///
  /// [symbol] - The trading pair symbol
  /// [updateFunction] - Function that receives current state and returns updated state
  ///
  /// Returns [Either<Failure, AppStrategyState>] with the updated state.
  /// Automatically handles rollback if the update function fails.
  Future<Either<Failure, AppStrategyState>> updateStrategyStateAtomically(
    String symbol,
    AppStrategyState Function(AppStrategyState? currentState) updateFunction,
  );

  /// Resets strategy state for a symbol to initial state.
  ///
  /// [symbol] - The trading pair symbol to reset
  ///
  /// Returns [Either<Failure, void>] indicating success or failure.
  Future<Either<Failure, void>> resetStrategyState(String symbol);

  /// Gets all active strategy states.
  ///
  /// Returns [Either<Failure, Map<String, AppStrategyState>>] with all states.
  Future<Either<Failure, Map<String, AppStrategyState>>> getAllStrategyStates();

  /// Deletes strategy state for a specific symbol.
  ///
  /// [symbol] - The trading pair symbol to delete
  ///
  /// Returns [Either<Failure, void>] indicating success or failure.
  Future<Either<Failure, void>> deleteStrategyState(String symbol);

  /// Checks if a strategy state exists for a symbol.
  ///
  /// [symbol] - The trading pair symbol to check
  ///
  /// Returns [Either<Failure, bool>] indicating if state exists.
  Future<Either<Failure, bool>> hasStrategyState(String symbol);
}
