import 'package:equatable/equatable.dart';
import 'package:neotradingbotfront1777/domain/entities/log_settings.dart';

sealed class LogSettingsEvent extends Equatable {
  const LogSettingsEvent();

  @override
  List<Object> get props => [];
}

final class LogSettingsFetched extends LogSettingsEvent {}

final class LogSettingsUpdated extends LogSettingsEvent {
  final LogSettings settings;

  const LogSettingsUpdated(this.settings);

  @override
  List<Object> get props => [settings];
}
