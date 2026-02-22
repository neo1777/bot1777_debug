import 'dart:io';
import 'package:logger/logger.dart';
import 'package:neotradingbotback1777/core/logging/stream_log_output.dart'; // Importa il nuovo output

class LogManager {
  static Logger? _logger;

  static Logger getLogger() {
    _logger ??= _initializeLogger();
    return _logger!;
  }

  static Logger _initializeLogger() {
    // Approccio idiomatico per determinare la modalità di esecuzione in Dart.
    // 'assert' viene eseguito solo in modalità debug.

    // Uniformiamo: livello info e SimplePrinter per log compatti in ogni ambiente.
    Logger.level = Level.info;
    return Logger(
      output: MultiOutput([
        ConsoleOutput(),
        StreamLogOutput(),
        FileOutput(file: File('neotradbot_execution.log')),
      ]),
      printer: SimplePrinter(
        printTime: true,
        colors: false,
      ),
    );
  }

  /// Permette di cambiare dinamicamente il livello di logging per l'intera applicazione.
  ///
  /// Utile per aumentare temporaneamente la verbosità in un ambiente di produzione
  /// per diagnosticare un problema senza dover fare un nuovo deploy.
  ///
  /// [newLevel]: Il nuovo [Level] da impostare (es. Level.info, Level.warning).
  static void setLogLevel(Level newLevel) {
    final oldLevel = Logger.level;
    Logger.level = newLevel;

    // Logga sempre il cambiamento di livello, usando il nuovo livello.
    // Questo garantisce che la notifica sia visibile se il nuovo livello è abbastanza permissivo.
    getLogger()
        .i('Livello di log cambiato da ${oldLevel.name} a ${newLevel.name}');
  }
}
