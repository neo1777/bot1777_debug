import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotfront1777/domain/entities/system_log.dart';
import 'package:neotradingbotfront1777/domain/entities/trade_history.dart';

abstract class ITradingRepository {
  // Strategy Control
  Future<Either<Failure, Unit>> startStrategy(String symbol);
  Future<Either<Failure, Unit>> stopStrategy(String symbol);
  Future<Either<Failure, Unit>> pauseTrading(String symbol);
  Future<Either<Failure, Unit>> resumeTrading(String symbol);

  // Strategy State
  Future<Either<Failure, StrategyState>> getStrategyState(String symbol);
  Stream<Either<Failure, StrategyState>> subscribeToStrategyState(
    String symbol,
  );

  // System Logs
  Stream<Either<Failure, SystemLog>> subscribeToSystemLogs();

  // Trade History
  Future<Either<Failure, List<TradeHistory>>> getTradeHistory(String symbol);

  // Reports
  Future<Either<Failure, Unit>> sendStatusReport();
}
