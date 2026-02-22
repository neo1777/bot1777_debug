import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/price_repository.dart';

class GetCurrentPrice {
  final PriceRepository _repository;
  GetCurrentPrice(this._repository);

  Future<Either<Failure, double?>> call({required String symbol}) {
    return _repository.getCurrentPrice(symbol);
  }
}
