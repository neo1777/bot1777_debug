import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/domain/entities/app_settings.dart';

abstract class ISettingsRepository {
  /// Recupera le impostazioni correnti.
  Future<Either<Failure, AppSettings>> getSettings();

  /// Aggiorna le impostazioni e restituisce quelle aggiornate dal server.
  /// Questo permette alla dashboard di mostrare immediatamente i valori effettivi salvati.
  Future<Either<Failure, AppSettings>> updateSettings(AppSettings settings);
}
