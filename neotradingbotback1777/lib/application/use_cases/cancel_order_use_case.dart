import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/services/i_trading_api_service.dart';

class CancelOrderUseCase {
  final ITradingApiService _apiService;

  CancelOrderUseCase(this._apiService);

  Future<Either<Failure, void>> call({
    required String symbol,
    required int orderId,
  }) {
    return _apiService.cancelOrder(symbol: symbol, orderId: orderId);
  }
}
