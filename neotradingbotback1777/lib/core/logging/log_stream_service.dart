import 'dart:async';
import 'package:neotradingbotback1777/domain/entities/log_entry.dart';

/// Un servizio singleton per trasmettere i log di sistema in tutta l'applicazione.
/// Utilizza l'entità di dominio LogEntry per mantenere l'indipendenza dai layer esterni.
class LogStreamService {
  // Singleton instance
  static final LogStreamService _instance = LogStreamService._internal();
  factory LogStreamService() => _instance;
  LogStreamService._internal();

  // StreamController che trasmette gli oggetti LogEntry di dominio
  final _logStreamController = StreamController<LogEntry>.broadcast();

  /// Lo stream a cui i listener (come il servizio gRPC) possono sottoscriversi.
  Stream<LogEntry> get logStream => _logStreamController.stream;

  /// Aggiunge un nuovo log allo stream.
  void addLog(LogEntry log) {
    _logStreamController.add(log);
  }

  /// Chiude lo stream controller quando l'applicazione si arresta.
  void dispose() {
    if (!_logStreamController.isClosed) {
      _logStreamController.close();
    }
  }
}
