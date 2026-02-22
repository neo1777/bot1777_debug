import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/domain/entities/log_settings.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_log_settings_repository.dart';
import 'package:neotradingbotfront1777/data/datasources/i_trading_remote_datasource.dart';
import 'package:neotradingbotfront1777/data/mappers/log_settings_mapper.dart';
import 'package:neotradingbotfront1777/data/repositories/base_repository.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pb.dart';

class LogSettingsRepositoryImpl extends BaseRepository
    implements ILogSettingsRepository {
  final ITradingRemoteDatasource _remoteDatasource;

  LogSettingsRepositoryImpl({
    required ITradingRemoteDatasource remoteDatasource,
  }) : _remoteDatasource = remoteDatasource;

  @override
  Future<Either<Failure, LogSettings>> getLogSettings() async {
    try {
      final result = await _remoteDatasource.getLogSettings();
      return result.fold(
        (failure) => Left<Failure, LogSettings>(failure),
        (data) => Right(data.toDomain()),
      );
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Errore imprevisto: $e'));
    }
  }

  @override
  Future<Either<Failure, LogSettings>> updateLogSettings(
    LogSettings settings,
  ) async {
    try {
      final request = UpdateLogSettingsRequest(logSettings: settings.toDto());
      final result = await _remoteDatasource.updateLogSettings(request);
      return result.fold(
        (failure) => Left<Failure, LogSettings>(failure),
        (data) => Right(data.toDomain()),
      );
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Errore imprevisto: $e'));
    }
  }
}
