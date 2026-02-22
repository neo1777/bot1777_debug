import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/domain/entities/price_data.dart';

abstract class IPriceRepository {
  Stream<Either<Failure, PriceData>> streamCurrentPrice(String symbol);
  Future<Either<Failure, PriceData>> getTickerInfo(String symbol);
}
