import 'package:hive_ce/hive.dart';
import 'package:neotradingbotback1777/domain/entities/log_settings.dart';

part 'log_settings_hive_dto.g.dart';

@HiveType(typeId: 7)
class LogSettingsHiveDto extends HiveObject {
  @HiveField(0)
  String? logLevel;

  @HiveField(1)
  bool? enableFileLogging;

  @HiveField(2)
  bool? enableConsoleLogging;

  static LogSettingsHiveDto fromEntity(LogSettings entity) {
    return LogSettingsHiveDto()
      ..logLevel = entity.logLevel
      ..enableFileLogging = entity.enableFileLogging
      ..enableConsoleLogging = entity.enableConsoleLogging;
  }

  LogSettings toEntity() {
    return LogSettings(
      logLevel: logLevel ?? 'INFO',
      enableFileLogging: enableFileLogging ?? false,
      enableConsoleLogging: enableConsoleLogging ?? true,
    );
  }
}
