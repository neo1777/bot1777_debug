import 'package:fpdart/fpdart.dart';
import 'package:hive_ce/hive.dart';
import 'package:neotradingbotback1777/domain/repositories/log_settings_repository.dart';
import 'package:neotradingbotback1777/domain/entities/log_settings.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/log_settings_hive_dto.dart';

/// Implementazione concreta di [LogSettingsRepository] che utilizza Hive.
class LogSettingsRepositoryImpl implements LogSettingsRepository {
  static const String _logSettingsKey = 'log_settings';
  final Box<LogSettingsHiveDto> _logSettingsBox;

  LogSettingsRepositoryImpl({required Box<LogSettingsHiveDto> logSettingsBox})
      : _logSettingsBox = logSettingsBox;

  @override
  Future<Either<Failure, LogSettings>> getSettings() async {
    try {
      final dto = _logSettingsBox.get(_logSettingsKey);
      if (dto != null) {
        return Right(dto.toEntity());
      } else {
        return Right(LogSettings.defaultSettings());
      }
    } on HiveError catch (e) {
      return Left(CacheFailure(
          message:
              'Errore Hive durante il recupero delle impostazioni di log: ${e.message}'));
    } catch (e) {
      return Left(CacheFailure(
          message:
              'Errore inaspettato durante il recupero delle impostazioni di log: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveSettings(LogSettings settings) async {
    try {
      final dto = LogSettingsHiveDto.fromEntity(settings);
      await _logSettingsBox.put(_logSettingsKey, dto);
      return const Right(null);
    } on HiveError catch (e) {
      return Left(CacheFailure(
          message:
              'Errore Hive durante il salvataggio delle impostazioni di log: ${e.message}'));
    } catch (e) {
      return Left(CacheFailure(
          message:
              'Errore inaspettato durante il salvataggio delle impostazioni di log: $e'));
    }
  }
}
