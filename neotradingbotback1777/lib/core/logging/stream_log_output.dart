import 'package:logger/logger.dart';
import 'package:neotradingbotback1777/core/logging/log_stream_service.dart';
import 'package:neotradingbotback1777/domain/entities/log_entry.dart';

/// Un LogOutput personalizzato che inoltra i log al LogStreamService.
class StreamLogOutput extends LogOutput {
  final LogStreamService _logStreamService = LogStreamService();

  @override
  void output(OutputEvent event) {
    // Non loggare i messaggi provenienti dal servizio gRPC stesso per evitare loop
    final message = event.lines.join('\n');
    if (message.contains('gRPC Call Started')) {
      return;
    }

    // Mappa il livello di log a una stringa
    final levelString = event.level.toString().split('.').last.toUpperCase();

    // Crea il LogEntry di dominio
    final logEntry = LogEntry(
      level: levelString,
      message: message,
      timestamp: DateTime.now(),
      serviceName: "BackendLogger", // Aggiungi contesto
    );

    _logStreamService.addLog(logEntry);
  }
}
