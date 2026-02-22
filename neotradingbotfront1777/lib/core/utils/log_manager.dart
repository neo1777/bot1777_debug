import 'package:logger/logger.dart';

class LogManager {
  static Logger? _logger;

  static Logger getLogger() {
    _logger ??= _initializeLogger();
    return _logger!;
  }

  static Logger _initializeLogger() {
    // In Flutter, usiamo la costante kReleaseMode per distinguere l'ambiente.
    // Riduciamo il rumore in entrambi gli ambienti e usiamo un formatter compatto.
    Logger.level = Level.info;
    return Logger(printer: SimplePrinter(printTime: true, colors: false));
  }

  /// Permette di cambiare dinamicamente il livello di logging per l'intera applicazione.
  static void setLogLevel(Level newLevel) {
    final oldLevel = Logger.level;
    Logger.level = newLevel;
    getLogger().i(
      'Livello di log cambiato da ${oldLevel.name} a ${newLevel.name}',
    );
  }
}
