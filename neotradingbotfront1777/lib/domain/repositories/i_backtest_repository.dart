import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/domain/entities/backtest_result.dart';

abstract class IBacktestRepository {
  Future<Either<Failure, String>> startBacktest({
    required String symbol,
    required String interval,
    required int period,
    required String strategyName,
  });

  Future<Either<Failure, BacktestResult>> getBacktestResults(String backtestId);
}
