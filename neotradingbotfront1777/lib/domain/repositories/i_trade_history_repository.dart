import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/domain/entities/app_trade.dart';

abstract class ITradeHistoryRepository {
  Future<Either<Failure, List<AppTrade>>> getTradeHistory();
  Either<Failure, Stream<AppTrade>> subscribeToTradeHistory();
}
