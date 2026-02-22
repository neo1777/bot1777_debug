import 'package:neotradingbotfront1777/domain/entities/log_settings.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pb.dart';

extension LogSettingsMapper on LogSettingsProto {
  LogSettings toDomain() {
    return LogSettings(
      logLevel: LogLevel.fromString(logLevel),
      enableFileLogging: enableFileLogging,
      enableConsoleLogging: enableConsoleLogging,
    );
  }
}

extension LogSettingsToDtoMapper on LogSettings {
  LogSettingsProto toDto() {
    return LogSettingsProto(
      logLevel: logLevel.value,
      enableFileLogging: enableFileLogging,
      enableConsoleLogging: enableConsoleLogging,
    );
  }
}

extension LogSettingsResponseMapper on LogSettingsResponse {
  LogSettings toDomain() {
    return logSettings.toDomain();
  }
}
