import 'package:equatable/equatable.dart';
import 'package:neotradingbotfront1777/domain/entities/log_settings.dart';

enum LogSettingsStatus { initial, loading, success, failure }

final class LogSettingsState extends Equatable {
  final LogSettingsStatus status;
  final LogSettings? settings;
  final String? errorMessage;

  const LogSettingsState({
    this.status = LogSettingsStatus.initial,
    this.settings,
    this.errorMessage,
  });

  LogSettingsState copyWith({
    LogSettingsStatus? status,
    LogSettings? settings,
    String? errorMessage,
  }) {
    return LogSettingsState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, settings, errorMessage];
}
