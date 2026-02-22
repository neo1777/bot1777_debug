import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/domain/entities/order_status.dart';
import 'package:neotradingbotfront1777/domain/entities/symbol_limits.dart';

abstract class IOrdersRepository {
  Future<Either<Failure, List<OrderStatus>>> getOpenOrders(String symbol);
  Future<Either<Failure, SymbolLimits>> getSymbolLimits(String symbol);
  Future<Either<Failure, void>> cancelOrder(String symbol, int orderId);
  Future<Either<Failure, void>> cancelAllOrders(String symbol);
}
