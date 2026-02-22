import 'package:neotradingbotfront1777/data/mappers/symbol_limits_mapper.dart';
import 'package:neotradingbotfront1777/domain/entities/symbol_limits.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pb.dart';
import 'package:test/test.dart';

void main() {
  group('SymbolLimitsMapper — toDomain', () {
    test('[SYM-01] maps all fields from proto to domain', () {
      final proto = SymbolLimitsResponse(
        symbol: 'BTCUSDC',
        minQty: 0.00001,
        maxQty: 9000.0,
        stepSize: 0.00001,
        minNotional: 10.0,
      );

      final result = proto.toDomain();

      expect(result, isA<SymbolLimits>());
      expect(result.symbol, 'BTCUSDC');
      expect(result.minQty, 0.00001);
      expect(result.maxQty, 9000.0);
      expect(result.stepSize, 0.00001);
      expect(result.minNotional, 10.0);
    });
  });

  group('SymbolLimitsMapper — toDto', () {
    test('[SYM-02] maps domain to proto correctly', () {
      final domain = SymbolLimits(
        symbol: 'ETHUSDC',
        minQty: 0.001,
        maxQty: 100000.0,
        stepSize: 0.001,
        minNotional: 5.0,
      );

      final result = domain.toDto();
      expect(result, isA<SymbolLimitsResponse>());
      expect(result.symbol, 'ETHUSDC');
      expect(result.minNotional, 5.0);
    });
  });

  group('SymbolLimitsMapper — round-trip', () {
    test('[SYM-03] domain → dto → domain preserves all values', () {
      final original = SymbolLimits(
        symbol: 'BTCUSDC',
        minQty: 0.00001,
        maxQty: 9000.0,
        stepSize: 0.00001,
        minNotional: 10.0,
      );

      final dto = original.toDto();
      final restored = dto.toDomain();

      expect(restored.symbol, original.symbol);
      expect(restored.minQty, original.minQty);
      expect(restored.maxQty, original.maxQty);
      expect(restored.stepSize, original.stepSize);
      expect(restored.minNotional, original.minNotional);
    });
  });
}
