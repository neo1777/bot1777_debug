import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/data/datasources/i_trading_remote_datasource.dart';
import 'package:neotradingbotfront1777/data/mappers/strategy_state_mapper.dart';
import 'package:neotradingbotfront1777/data/mappers/system_log_mapper.dart';
import 'package:neotradingbotfront1777/data/repositories/base_repository.dart';
import 'package:neotradingbotfront1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotfront1777/domain/entities/system_log.dart';
import 'package:neotradingbotfront1777/domain/entities/trade_history.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_trading_repository.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pb.dart'
    as grpc;
import 'package:neotradingbotfront1777/data/mappers/trade_mapper.dart';

class TradingRepositoryImpl extends BaseRepository
    implements ITradingRepository {
  final ITradingRemoteDatasource _remoteDatasource;

  TradingRepositoryImpl({required ITradingRemoteDatasource remoteDatasource})
    : _remoteDatasource = remoteDatasource;

  @override
  Future<Either<Failure, Unit>> startStrategy(String symbol) async {
    try {
      final request = grpc.StartStrategyRequest(
        symbol: symbol.trim().toUpperCase(),
      );
      final result = await _remoteDatasource.startStrategy(request);
      return result.fold(
        (failure) => Left<Failure, Unit>(failure),
        (_) => Right(unit),
      );
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Errore imprevisto: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> stopStrategy(String symbol) async {
    try {
      final request = grpc.StopStrategyRequest(
        symbol: symbol.trim().toUpperCase(),
      );
      final result = await _remoteDatasource.stopStrategy(request);
      return result.fold(
        (failure) => Left<Failure, Unit>(failure),
        (_) => Right(unit),
      );
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Errore imprevisto: $e'));
    }
  }

  @override
  Stream<Either<Failure, StrategyState>> subscribeToStrategyState(
    String symbol,
  ) {
    final request = grpc.GetStrategyStateRequest(
      symbol: symbol.trim().toUpperCase(),
    );
    return _remoteDatasource
        .subscribeStrategyState(request)
        .map(
          (response) => response.fold(
            (failure) => Left<Failure, StrategyState>(failure),
            (data) => Right(strategyStateFromProto(data)),
          ),
        );
  }

  @override
  Future<Either<Failure, Unit>> pauseTrading(String symbol) async {
    try {
      final request = grpc.PauseTradingRequest(
        symbol: symbol.trim().toUpperCase(),
      );
      final result = await _remoteDatasource.pauseTrading(request);
      return result.fold(
        (failure) => Left<Failure, Unit>(failure),
        (_) => Right(unit),
      );
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Errore imprevisto: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> resumeTrading(String symbol) async {
    try {
      final request = grpc.ResumeTradingRequest(
        symbol: symbol.trim().toUpperCase(),
      );
      final result = await _remoteDatasource.resumeTrading(request);
      return result.fold(
        (failure) => Left<Failure, Unit>(failure),
        (_) => Right(unit),
      );
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Errore imprevisto: $e'));
    }
  }

  @override
  Future<Either<Failure, StrategyState>> getStrategyState(String symbol) async {
    try {
      final request = grpc.GetStrategyStateRequest(
        symbol: symbol.trim().toUpperCase(),
      );
      final result = await _remoteDatasource.getStrategyState(request);
      return result.fold(
        (failure) => Left<Failure, StrategyState>(failure),
        (data) => Right(strategyStateFromProto(data)),
      );
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Errore imprevisto: $e'));
    }
  }

  @override
  Stream<Either<Failure, SystemLog>> subscribeToSystemLogs() {
    return _remoteDatasource.subscribeSystemLogs().map(
      (response) => response.fold(
        (failure) => Left<Failure, SystemLog>(failure),
        (data) => Right(systemLogFromProto(data)),
      ),
    );
  }

  @override
  Future<Either<Failure, List<TradeHistory>>> getTradeHistory(
    String symbol,
  ) async {
    try {
      final result = await _remoteDatasource.getTradeHistory();
      return result.fold(
        (failure) => Left<Failure, List<TradeHistory>>(failure),
        (data) => Right(tradeHistoryFromProto(data)),
      );
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Errore imprevisto: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendStatusReport() async {
    try {
      final result = await _remoteDatasource.sendStatusReport();
      return result.fold(
        (failure) => Left<Failure, Unit>(failure),
        (_) => Right(unit),
      );
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Errore imprevisto: $e'));
    }
  }
}
