import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/domain/entities/account_info.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_account_repository.dart';
import 'package:neotradingbotfront1777/data/datasources/i_trading_remote_datasource.dart';
import 'package:neotradingbotfront1777/data/mappers/account_info_mapper.dart';
import 'package:neotradingbotfront1777/data/repositories/base_repository.dart';

class AccountRepositoryImpl extends BaseRepository
    implements IAccountRepository {
  final ITradingRemoteDatasource _remoteDatasource;

  AccountRepositoryImpl({required ITradingRemoteDatasource remoteDatasource})
    : _remoteDatasource = remoteDatasource;

  @override
  Future<Either<Failure, AccountInfo>> getAccountInfo() async {
    try {
      final result = await _remoteDatasource.getAccountInfo();
      return result.fold(
        (failure) => Left<Failure, AccountInfo>(failure),
        (data) => Right(data.toDomain()),
      );
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Errore imprevisto: $e'));
    }
  }

  @override
  Stream<Either<Failure, AccountInfo>> subscribeAccountInfo() {
    return _remoteDatasource.subscribeAccountInfo().map(
      (response) => response.fold(
        (failure) => Left<Failure, AccountInfo>(failure),
        (data) => Right(data.toDomain()),
      ),
    );
  }
}
