import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/domain/entities/app_trade.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_trade_history_repository.dart';
import 'package:neotradingbotfront1777/data/datasources/i_trading_remote_datasource.dart';
import 'package:neotradingbotfront1777/data/mappers/trade_mapper.dart';
import 'package:neotradingbotfront1777/data/repositories/base_repository.dart';

class TradeHistoryRepositoryImpl extends BaseRepository
    implements ITradeHistoryRepository {
  final ITradingRemoteDatasource _remoteDatasource;

  TradeHistoryRepositoryImpl({
    required ITradingRemoteDatasource remoteDatasource,
  }) : _remoteDatasource = remoteDatasource;

  @override
  Future<Either<Failure, List<AppTrade>>> getTradeHistory() async {
    try {
      final result = await _remoteDatasource.getTradeHistory();
      return result.fold(
        (failure) => Left<Failure, List<AppTrade>>(failure),
        (data) => Right(data.trades.map((t) => appTradeFromProto(t)).toList()),
      );
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Errore imprevisto: $e'));
    }
  }

  @override
  Either<Failure, Stream<AppTrade>> subscribeToTradeHistory() {
    try {
      final stream = _remoteDatasource.subscribeTradeHistory().map(
        (response) => response.fold(
          (failure) => throw Exception(failure.message),
          (data) => appTradeFromProto(data),
        ),
      );
      return Right(stream);
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Errore imprevisto: $e'));
    }
  }
}
