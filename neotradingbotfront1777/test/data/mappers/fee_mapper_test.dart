import 'package:neotradingbotfront1777/data/mappers/fee_mapper.dart';
import 'package:neotradingbotfront1777/domain/entities/fee_info.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pb.dart';
import 'package:test/test.dart';
import 'package:fixnum/fixnum.dart';

void main() {
  group('FeeMapper — toDomain', () {
    test('[FM-01] maps all fields from proto to domain', () {
      final now = DateTime.now();
      final proto =
          SymbolFeesResponse()
            ..symbol = 'BTCUSDC'
            ..makerFee = 0.001
            ..takerFee = 0.002
            ..feeCurrency = 'BNB'
            ..isDiscountActive = true
            ..discountPercentage = 0.25
            ..lastUpdated = Int64(now.millisecondsSinceEpoch);

      final result = proto.toDomain();

      expect(result.symbol, 'BTCUSDC');
      expect(result.makerFee, 0.001);
      expect(result.takerFee, 0.002);
      expect(result.feeCurrency, 'BNB');
      expect(result.isDiscountActive, true);
      expect(result.discountPercentage, 0.25);
      expect(
        result.lastUpdated.millisecondsSinceEpoch,
        now.millisecondsSinceEpoch,
      );
    });
  });

  group('FeeMapper — toDto', () {
    test('[FM-02] maps domain entity back to proto', () {
      final now = DateTime.now();
      final entity = FeeInfo(
        symbol: 'ETHUSDC',
        makerFee: 0.0005,
        takerFee: 0.001,
        feeCurrency: 'USDC',
        isDiscountActive: false,
        discountPercentage: 0.0,
        lastUpdated: now,
      );

      final result = entity.toDto();

      expect(result.symbol, 'ETHUSDC');
      expect(result.makerFee, 0.0005);
      expect(result.takerFee, 0.001);
      expect(result.feeCurrency, 'USDC');
      expect(result.isDiscountActive, false);
      expect(result.discountPercentage, 0.0);
      expect(result.lastUpdated, Int64(now.millisecondsSinceEpoch));
    });
  });
}

