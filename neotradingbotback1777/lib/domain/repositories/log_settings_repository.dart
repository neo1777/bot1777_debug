import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/entities/log_settings.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';

/// Repository astratto per la gestione della persistenza delle impostazioni di logging.
abstract class LogSettingsRepository {
  /// Salva le impostazioni di log.
  Future<Either<Failure, void>> saveSettings(LogSettings settings);

  /// Recupera le impostazioni di log.
  ///
  /// Se non vengono trovate impostazioni, restituisce quelle di default.
  Future<Either<Failure, LogSettings>> getSettings();
}
