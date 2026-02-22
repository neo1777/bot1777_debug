import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/services/i_trading_api_service.dart';

class CancelAllOrdersUseCase {
  final ITradingApiService _apiService;

  CancelAllOrdersUseCase(this._apiService);

  Future<Either<Failure, void>> call({
    required String symbol,
  }) {
    return _apiService.cancelAllOpenOrders(symbol: symbol);
  }
}
