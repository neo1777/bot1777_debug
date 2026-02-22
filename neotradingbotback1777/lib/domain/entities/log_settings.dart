import 'package:equatable/equatable.dart';

/// Rappresenta le impostazioni di logging dell'applicazione.
class LogSettings extends Equatable {
  final String logLevel;
  final bool enableFileLogging;
  final bool enableConsoleLogging;

  const LogSettings({
    required this.logLevel,
    required this.enableFileLogging,
    required this.enableConsoleLogging,
  });

  /// Impostazioni di default: livello INFO, logging su console abilitato.
  factory LogSettings.defaultSettings() {
    return const LogSettings(
      logLevel: 'INFO',
      enableFileLogging: false, // Di default non scriviamo su file
      enableConsoleLogging: true,
    );
  }

  @override
  List<Object?> get props =>
      [logLevel, enableFileLogging, enableConsoleLogging];
}
