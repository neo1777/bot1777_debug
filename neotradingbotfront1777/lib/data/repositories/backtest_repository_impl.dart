import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/data/datasources/i_trading_remote_datasource.dart';
import 'package:neotradingbotfront1777/data/mappers/backtest_result_mapper.dart';
import 'package:neotradingbotfront1777/domain/entities/backtest_result.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_backtest_repository.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pb.dart';
import 'package:fixnum/fixnum.dart';

class BacktestRepositoryImpl implements IBacktestRepository {
  final ITradingRemoteDatasource remoteDatasource;

  BacktestRepositoryImpl(this.remoteDatasource);

  @override
  Future<Either<Failure, String>> startBacktest({
    required String symbol,
    required String interval,
    required int period,
    required String strategyName,
  }) async {
    try {
      final endTime = DateTime.now().millisecondsSinceEpoch;
      final startTime =
          endTime - (period * 24 * 60 * 60 * 1000); // period in days

      final request = StartBacktestRequest(
        symbol: symbol,
        interval: interval,
        startTime: Int64(startTime),
        endTime: Int64(endTime),
        initialBalance: 1000.0, // Default for now, maybe expose to UI later
        // settings: Settings(...), // Optional settings if needed
      );

      final result = await remoteDatasource.startBacktest(request);
      return result.map((r) => r.backtestId);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, BacktestResult>> getBacktestResults(
    String backtestId,
  ) async {
    try {
      final request = GetBacktestResultsRequest(backtestId: backtestId);
      final result = await remoteDatasource.getBacktestResults(request);

      return result.map((r) => BacktestResultMapper.fromProto(r));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
