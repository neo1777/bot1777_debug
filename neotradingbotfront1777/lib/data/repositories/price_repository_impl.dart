import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/domain/entities/price_data.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_price_repository.dart';
import 'package:neotradingbotfront1777/data/datasources/i_trading_remote_datasource.dart';
import 'package:neotradingbotfront1777/data/mappers/price_data_mapper.dart';
import 'package:neotradingbotfront1777/data/repositories/base_repository.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pb.dart'
    as grpc;

class PriceRepositoryImpl extends BaseRepository implements IPriceRepository {
  final ITradingRemoteDatasource _remoteDatasource;

  PriceRepositoryImpl({required ITradingRemoteDatasource remoteDatasource})
    : _remoteDatasource = remoteDatasource;

  @override
  Future<Either<Failure, PriceData>> getTickerInfo(String symbol) async {
    try {
      final request = grpc.StreamCurrentPriceRequest(symbol: symbol);
      final result = await _remoteDatasource.getTickerInfo(request);
      return result.fold(
        (failure) => Left<Failure, PriceData>(failure),
        (data) => Right(data.toDomain(symbol)),
      );
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Errore imprevisto: $e'));
    }
  }

  @override
  Stream<Either<Failure, PriceData>> streamCurrentPrice(String symbol) {
    final request = grpc.StreamCurrentPriceRequest(symbol: symbol);
    return _remoteDatasource
        .streamCurrentPrice(request)
        .map(
          (response) => response.fold(
            (failure) => Left<Failure, PriceData>(failure),
            (data) => Right(data.toDomain(symbol)),
          ),
        );
  }
}
