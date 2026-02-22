import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/domain/entities/app_settings.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_settings_repository.dart';
import 'package:neotradingbotfront1777/data/datasources/i_trading_remote_datasource.dart';
import 'package:neotradingbotfront1777/data/mappers/settings_mapper.dart';
import 'package:neotradingbotfront1777/data/repositories/base_repository.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pb.dart';

class SettingsRepositoryImpl extends BaseRepository
    implements ISettingsRepository {
  final ITradingRemoteDatasource _remoteDatasource;

  SettingsRepositoryImpl({required ITradingRemoteDatasource remoteDatasource})
    : _remoteDatasource = remoteDatasource;

  @override
  Future<Either<Failure, AppSettings>> getSettings() async {
    try {
      final result = await _remoteDatasource.getSettings();
      return result.fold(
        (failure) => Left<Failure, AppSettings>(failure),
        (data) => Right(settingsFromProto(data.settings)),
      );
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Errore imprevisto: $e'));
    }
  }

  @override
  Future<Either<Failure, AppSettings>> updateSettings(
    AppSettings settings,
  ) async {
    try {
      final request = UpdateSettingsRequest(
        settings: settingsToProto(settings),
      );
      final result = await _remoteDatasource.updateSettings(request);

      return result.fold((failure) => Left<Failure, AppSettings>(failure), (
        response,
      ) {
        // Restituisci le impostazioni aggiornate dal server per assicurarti
        // che la dashboard mostri i valori effettivi salvati (inclusi eventuali clamp)
        final updatedSettings = settingsFromProto(response.settings);
        return Right(updatedSettings);
      });
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Errore imprevisto: $e'));
    }
  }
}
