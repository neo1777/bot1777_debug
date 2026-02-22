import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';

/// Repository astratto per la gestione della persistenza delle impostazioni dell'applicazione.
///
/// Definisce il contratto per salvare e recuperare l'oggetto [AppSettings].
abstract class SettingsRepository {
  /// Salva le impostazioni dell'applicazione.
  ///
  /// Restituisce:
  /// - `Right(unit)` in caso di successo.
  /// - `Left(CacheFailure)` in caso di errore durante la scrittura su disco.
  Future<Either<Failure, void>> saveSettings(AppSettings settings);

  /// Recupera le impostazioni dell'applicazione.
  ///
  /// Se non vengono trovate impostazioni salvate (es. al primo avvio),
  /// dovrebbe restituire le impostazioni di default [AppSettings.initial()].
  ///
  /// Restituisce:
  /// - `Right(AppSettings)` con le impostazioni salvate o di default.
  /// - `Left(CacheFailure)` in caso di errore grave durante la lettura dal disco.
  Future<Either<Failure, AppSettings>> getSettings();
}
