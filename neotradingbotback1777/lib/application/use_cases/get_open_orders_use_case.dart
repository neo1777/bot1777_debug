import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/services/i_trading_api_service.dart';

class GetOpenOrders {
  final ITradingApiService _apiService;

  GetOpenOrders(this._apiService);

  Future<Either<Failure, List<Map<String, dynamic>>>> call(
      {required String symbol}) {
    return _apiService.getOpenOrders(symbol);
  }
}
