import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/entities/app_trade.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';

/// Service interface for coordinating atomic transactions across multiple repositories.
///
/// This service manages complex operations that require coordination between
/// different repositories (trading, strategy state, etc.) while maintaining
/// data consistency and providing rollback capabilities.
abstract class TradingTransactionManager {
  /// Saves a trade and strategy state in a single atomic transaction.
  ///
  /// This is the most critical operation as it ensures that trade execution
  /// and strategy state updates are always consistent with each other.
  ///
  /// [trade] - The trade operation to save
  /// [state] - The updated strategy state to save
  ///
  /// Returns [Either<Failure, void>] indicating success or failure.
  /// If either operation fails, both are rolled back automatically.
  Future<Either<Failure, void>> saveTradeAndState(
    AppTrade trade,
    AppStrategyState state,
  );

  /// Executes multiple operations atomically with automatic rollback.
  ///
  /// [operations] - List of operations to execute atomically
  ///
  /// Returns [Either<Failure, List<T>>] with results or failure.
  /// All operations succeed or all are rolled back.
  Future<Either<Failure, List<T>>> executeAtomically<T>(
    List<Future<Either<Failure, T>> Function()> operations,
  );

  /// Creates a backup before executing critical operations.
  ///
  /// [operation] - The critical operation to execute with backup protection
  ///
  /// Returns [Either<Failure, T>] with operation result.
  /// Automatically creates backup before execution and provides restore option on failure.
  Future<Either<Failure, T>> executeWithBackup<T>(
    Future<Either<Failure, T>> Function() operation,
  );

  /// Rolls back to a previous state checkpoint.
  ///
  /// [checkpointId] - Identifier of the checkpoint to restore
  ///
  /// Returns [Either<Failure, void>] indicating success or failure.
  Future<Either<Failure, void>> rollbackToCheckpoint(String checkpointId);

  /// Creates a data consistency checkpoint.
  ///
  /// Creates a snapshot of current data state that can be used for rollback.
  ///
  /// Returns [Either<Failure, String>] with checkpoint ID.
  Future<Either<Failure, String>> createCheckpoint();

  /// Validates data consistency across all repositories.
  ///
  /// Checks for data integrity issues, orphaned records, and consistency violations.
  ///
  /// Returns [Either<Failure, Map<String, dynamic>>] with validation report.
  Future<Either<Failure, Map<String, dynamic>>> validateDataConsistency();

  /// Repairs data inconsistencies if possible.
  ///
  /// Attempts to fix common data integrity issues automatically.
  ///
  /// Returns [Either<Failure, Map<String, dynamic>>] with repair report.
  Future<Either<Failure, Map<String, dynamic>>> repairDataInconsistencies();

  /// Gets transaction statistics and health metrics.
  ///
  /// Returns [Either<Failure, Map<String, dynamic>>] with transaction metrics.
  Future<Either<Failure, Map<String, dynamic>>> getTransactionStatistics();
}
