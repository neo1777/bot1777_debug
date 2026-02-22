import 'dart:collection';

import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/application/use_cases/run_backtest_use_case.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/backtest_result_repository.dart';

/// In-memory implementation of [BacktestResultRepository].
///
/// Uses a [LinkedHashMap] with LRU eviction (max [_maxEntries] results).
/// Sufficient for current needs; Hive persistence can be added later.
class InMemoryBacktestResultRepository implements BacktestResultRepository {
  static const int _maxEntries = 50;

  final LinkedHashMap<String, BacktestResult> _results = LinkedHashMap();

  @override
  Either<Failure, void> save(BacktestResult result) {
    try {
      // LRU eviction: remove oldest if at capacity
      while (_results.length >= _maxEntries) {
        _results.remove(_results.keys.first);
      }
      _results[result.backtestId] = result;
      return const Right(null);
    } catch (e) {
      return Left(
          UnexpectedFailure(message: 'Failed to save backtest result: $e'));
    }
  }

  @override
  Either<Failure, BacktestResult> getById(String backtestId) {
    final result = _results[backtestId];
    if (result == null) {
      return Left(UnexpectedFailure(
          message: 'Backtest result not found for ID: $backtestId'));
    }
    return Right(result);
  }

  @override
  List<BacktestResult> getAll() {
    return _results.values.toList().reversed.toList();
  }
}
