import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/entities/app_trade.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/trading_repository_new.dart';
import 'package:neotradingbotback1777/domain/services/profit_calculation_service.dart';

class GetTradeHistory {
  final TradingRepository _repository;
  final ProfitCalculationService _profitCalculationService;

  GetTradeHistory(this._repository, this._profitCalculationService);

  Future<Either<Failure, List<AppTrade>>> call() async {
    final tradesEither = await _repository.getAllTrades();

    return tradesEither.fold(
      (failure) => Left(failure),
      (trades) {
        final tradesWithProfit =
            _profitCalculationService.calculateFifoProfit(trades);
        return Right(tradesWithProfit);
      },
    );
  }
}
