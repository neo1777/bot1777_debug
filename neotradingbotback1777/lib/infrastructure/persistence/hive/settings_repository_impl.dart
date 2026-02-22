import 'package:fpdart/fpdart.dart';
import 'package:hive_ce/hive.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/settings_repository.dart';
import 'package:neotradingbotback1777/domain/services/i_trading_api_service.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/app_settings_hive_dto.dart';

/// Implementazione concreta di [SettingsRepository] che utilizza Hive.
class SettingsRepositoryImpl implements SettingsRepository {
  final Box<AppSettingsHiveDto> _settingsBox;
  final ITradingApiService _apiService;

  SettingsRepositoryImpl({
    required Box<AppSettingsHiveDto> settingsBox,
    required ITradingApiService apiService,
  })  : _settingsBox = settingsBox,
        _apiService = apiService;

  /// Restituisce la chiave della box in base alla modalità (Real/Test)
  String get _settingsKey =>
      _apiService.isTestMode ? 'test_app_settings' : 'real_app_settings';

  @override
  Future<Either<Failure, AppSettings>> getSettings() async {
    try {
      // Tenta di ottenere il DTO dalla box usando la chiave dinamica.
      final settingsDto = _settingsBox.get(_settingsKey);

      if (settingsDto != null) {
        // Se trovato, convertilo in entità e restituiscilo.
        return Right(settingsDto.toEntity());
      } else {
        // Se non trovato, restituisci le impostazioni di default.
        return Right(AppSettings.initial());
      }
    } on HiveError catch (e) {
      return Left(CacheFailure(
          message:
              'Errore Hive durante il recupero delle impostazioni: ${e.message}'));
    } catch (e) {
      return Left(CacheFailure(
          message:
              'Errore inaspettato durante il recupero delle impostazioni: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveSettings(AppSettings settings) async {
    try {
      // Converte l'entità in DTO
      final settingsDto = AppSettingsHiveDto.fromEntity(settings);
      // Salva il DTO nella box usando la chiave dinamica.
      await _settingsBox.put(_settingsKey, settingsDto);
      return const Right(null); // Successo
    } on HiveError catch (e) {
      return Left(CacheFailure(
          message:
              'Errore Hive durante il salvataggio delle impostazioni: ${e.message}'));
    } catch (e) {
      return Left(CacheFailure(
          message:
              'Errore inaspettato durante il salvataggio delle impostazioni: $e'));
    }
  }
}
