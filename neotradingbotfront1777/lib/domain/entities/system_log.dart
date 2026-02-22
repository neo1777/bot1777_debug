import 'package:equatable/equatable.dart';

enum LogLevel { trace, debug, info, warning, error, fatal, unspecified }

class SystemLog extends Equatable {
  final LogLevel level;
  final String message;
  final DateTime timestamp;
  final String? serviceName;

  const SystemLog({
    required this.level,
    required this.message,
    required this.timestamp,
    this.serviceName,
  });

  @override
  List<Object?> get props => [level, message, timestamp, serviceName];
}
