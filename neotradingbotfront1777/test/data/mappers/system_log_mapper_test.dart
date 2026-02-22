import 'package:fixnum/fixnum.dart';
import 'package:neotradingbotfront1777/data/mappers/system_log_mapper.dart';
import 'package:neotradingbotfront1777/domain/entities/system_log.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pb.dart'
    as grpc;
import 'package:test/test.dart';

void main() {
  group('SystemLogMapper — systemLogFromProto', () {
    test('[SLM-01] maps all fields correctly', () {
      final proto = grpc.LogEntry(
        level: 'INFO',
        message: 'Bot started successfully',
        timestamp: Int64(1700000000000),
        serviceName: 'TradingEngine',
      );

      final result = systemLogFromProto(proto);

      expect(result, isA<SystemLog>());
      expect(result.level, LogLevel.info);
      expect(result.message, 'Bot started successfully');
      expect(result.timestamp.millisecondsSinceEpoch, 1700000000000);
      expect(result.serviceName, 'TradingEngine');
    });

    test('[SLM-02] maps all LogLevel enum values', () {
      final levels = {
        'TRACE': LogLevel.trace,
        'DEBUG': LogLevel.debug,
        'INFO': LogLevel.info,
        'WARNING': LogLevel.warning,
        'WARN': LogLevel.warning,
        'ERROR': LogLevel.error,
        'FATAL': LogLevel.fatal,
        'WTF': LogLevel.fatal,
        'UNKNOWN': LogLevel.unspecified,
      };

      levels.forEach((protoLevel, expectedLevel) {
        final proto = grpc.LogEntry(
          level: protoLevel,
          message: 'test',
          timestamp: Int64(0),
        );

        final result = systemLogFromProto(proto);
        expect(
          result.level,
          expectedLevel,
          reason: 'Failed for level: $protoLevel',
        );
      });
    });

    test('[SLM-03] handles missing serviceName', () {
      final proto = grpc.LogEntry(
        level: 'INFO',
        message: 'test',
        timestamp: Int64(0),
      );

      final result = systemLogFromProto(proto);
      expect(result.serviceName, isNull);
    });

    test('[SLM-04] case-insensitive level parsing', () {
      final proto = grpc.LogEntry(
        level: 'error',
        message: 'lower case',
        timestamp: Int64(0),
      );

      final result = systemLogFromProto(proto);
      expect(result.level, LogLevel.error);
    });
  });
}

