import 'package:fixnum/fixnum.dart';
import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/domain/entities/order_status.dart';
import 'package:neotradingbotfront1777/domain/entities/symbol_limits.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_orders_repository.dart';
import 'package:neotradingbotfront1777/data/datasources/i_trading_remote_datasource.dart';
import 'package:neotradingbotfront1777/data/mappers/order_status_mapper.dart';
import 'package:neotradingbotfront1777/data/mappers/symbol_limits_mapper.dart';
import 'package:neotradingbotfront1777/data/repositories/base_repository.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pb.dart'
    as grpc;

class OrdersRepositoryImpl extends BaseRepository implements IOrdersRepository {
  final ITradingRemoteDatasource _remoteDatasource;

  OrdersRepositoryImpl({required ITradingRemoteDatasource remoteDatasource})
    : _remoteDatasource = remoteDatasource;

  @override
  Future<Either<Failure, List<OrderStatus>>> getOpenOrders(
    String symbol,
  ) async {
    try {
      final request = grpc.OpenOrdersRequest(symbol: symbol);
      final result = await _remoteDatasource.getOpenOrders(request);
      return result.fold(
        (failure) => Left<Failure, List<OrderStatus>>(failure),
        (data) => Right(data.orders.map((o) => o.toDomain()).toList()),
      );
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Errore imprevisto: $e'));
    }
  }

  @override
  Future<Either<Failure, SymbolLimits>> getSymbolLimits(String symbol) async {
    try {
      final request = grpc.SymbolLimitsRequest(symbol: symbol);
      final result = await _remoteDatasource.getSymbolLimits(request);
      return result.fold(
        (failure) => Left<Failure, SymbolLimits>(failure),
        (data) => Right(data.toDomain()),
      );
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Errore imprevisto: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> cancelOrder(String symbol, int orderId) async {
    try {
      final request = grpc.CancelOrderRequest(
        symbol: symbol,
        orderId: Int64(orderId),
      );
      final result = await _remoteDatasource.cancelOrder(request);
      return result.fold(
        (failure) => Left(failure),
        (response) => const Right(null),
      );
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Errore imprevisto: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> cancelAllOrders(String symbol) async {
    try {
      final request = grpc.OpenOrdersRequest(symbol: symbol);
      final result = await _remoteDatasource.cancelAllOrders(request);
      return result.fold(
        (failure) => Left(failure),
        (response) => const Right(null),
      );
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Errore imprevisto: $e'));
    }
  }
}
