import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/application/use_cases/run_backtest_use_case.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';

/// Repository for storing and retrieving backtest results.
abstract class BacktestResultRepository {
  /// Saves a [BacktestResult] for later retrieval by [backtestId].
  Either<Failure, void> save(BacktestResult result);

  /// Retrieves a [BacktestResult] by its [backtestId].
  /// Returns [Left(UnexpectedFailure)] if no result exists for the given ID.
  Either<Failure, BacktestResult> getById(String backtestId);

  /// Returns all stored backtest results, newest first.
  List<BacktestResult> getAll();
}
