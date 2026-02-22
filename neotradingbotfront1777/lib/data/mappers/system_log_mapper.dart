import 'package:neotradingbotfront1777/domain/entities/system_log.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pb.dart'
    as grpc;

/// Converte una risposta gRPC [grpc.LogEntry] in un'entità di dominio [SystemLog].
SystemLog systemLogFromProto(grpc.LogEntry response) {
  return SystemLog(
    level: _logLevelFromString(response.level),
    message: response.message,
    // Il timestamp arriva come Int64 da fixnum, va convertito.
    timestamp: DateTime.fromMillisecondsSinceEpoch(response.timestamp.toInt()),
    serviceName: response.hasServiceName() ? response.serviceName : null,
  );
}

LogLevel _logLevelFromString(String level) {
  switch (level.toUpperCase()) {
    case 'TRACE':
      return LogLevel.trace;
    case 'DEBUG':
      return LogLevel.debug;
    case 'INFO':
      return LogLevel.info;
    case 'WARNING':
    case 'WARN':
      return LogLevel.warning;
    case 'ERROR':
      return LogLevel.error;
    case 'FATAL':
    case 'WTF': // retrocompatibilità
      return LogLevel.fatal;
    default:
      return LogLevel.unspecified;
  }
}
