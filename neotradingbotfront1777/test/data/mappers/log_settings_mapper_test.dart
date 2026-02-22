import 'package:neotradingbotfront1777/data/mappers/log_settings_mapper.dart';
import 'package:neotradingbotfront1777/domain/entities/log_settings.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pb.dart';
import 'package:test/test.dart';

void main() {
  group('LogSettingsMapper — toDomain', () {
    test('[LSM-01] maps all fields from proto to domain', () {
      final proto = LogSettingsProto(
        logLevel: 'INFO',
        enableFileLogging: true,
        enableConsoleLogging: false,
      );

      final result = proto.toDomain();

      expect(result, isA<LogSettings>());
      expect(result.logLevel, LogLevel.fromString('INFO'));
      expect(result.enableFileLogging, true);
      expect(result.enableConsoleLogging, false);
    });
  });

  group('LogSettingsMapper — toDto', () {
    test('[LSM-02] maps domain to proto correctly', () {
      final domain = LogSettings(
        logLevel: LogLevel.fromString('DEBUG'),
        enableFileLogging: false,
        enableConsoleLogging: true,
      );

      final result = domain.toDto();
      expect(result, isA<LogSettingsProto>());
      expect(result.enableFileLogging, false);
      expect(result.enableConsoleLogging, true);
    });
  });

  group('LogSettingsMapper — LogSettingsResponseMapper', () {
    test('[LSM-03] maps response wrapper to domain', () {
      final response = LogSettingsResponse(
        logSettings: LogSettingsProto(
          logLevel: 'ERROR',
          enableFileLogging: true,
          enableConsoleLogging: true,
        ),
      );

      final result = response.toDomain();
      expect(result.enableFileLogging, true);
      expect(result.enableConsoleLogging, true);
    });
  });

  group('LogSettingsMapper — round-trip', () {
    test('[LSM-04] domain → dto → domain preserves all fields', () {
      final original = LogSettings(
        logLevel: LogLevel.fromString('WARN'),
        enableFileLogging: true,
        enableConsoleLogging: false,
      );

      final dto = original.toDto();
      final restored = dto.toDomain();

      expect(restored.enableFileLogging, original.enableFileLogging);
      expect(restored.enableConsoleLogging, original.enableConsoleLogging);
    });
  });
}

