/// Servizio per la gestione e lo streaming dei log a livello di dominio/applicazione.
/// Questo servizio è disaccoppiato da gRPC per mantenere la Clean Architecture.
class LogEntry {
  final String level;
  final String message;
  final DateTime timestamp;
  final String? serviceName;
  final Map<String, String>? details;

  LogEntry({
    required this.level,
    required this.message,
    required this.timestamp,
    this.serviceName,
    this.details,
  });

  @override
  String toString() => '[$level] $timestamp - $serviceName: $message';
}
