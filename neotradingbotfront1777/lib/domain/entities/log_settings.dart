import 'package:equatable/equatable.dart';

enum LogLevel {
  trace('TRACE'),
  debug('DEBUG'),
  info('INFO'),
  warning('WARNING'),
  error('ERROR'),
  fatal('FATAL');

  const LogLevel(this.value);

  final String value;

  static LogLevel fromString(String value) {
    return LogLevel.values.firstWhere(
      (level) => level.value == value.toUpperCase(),
      orElse: () => LogLevel.info,
    );
  }
}

class LogSettings extends Equatable {
  const LogSettings({
    required this.logLevel,
    required this.enableFileLogging,
    required this.enableConsoleLogging,
  });

  final LogLevel logLevel;
  final bool enableFileLogging;
  final bool enableConsoleLogging;

  @override
  List<Object?> get props => [
    logLevel,
    enableFileLogging,
    enableConsoleLogging,
  ];

  @override
  String toString() =>
      'LogSettings(logLevel: $logLevel, enableFileLogging: $enableFileLogging, enableConsoleLogging: $enableConsoleLogging)';

  LogSettings copyWith({
    LogLevel? logLevel,
    bool? enableFileLogging,
    bool? enableConsoleLogging,
  }) {
    return LogSettings(
      logLevel: logLevel ?? this.logLevel,
      enableFileLogging: enableFileLogging ?? this.enableFileLogging,
      enableConsoleLogging: enableConsoleLogging ?? this.enableConsoleLogging,
    );
  }
}
