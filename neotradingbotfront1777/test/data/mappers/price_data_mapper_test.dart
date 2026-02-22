import 'package:neotradingbotfront1777/data/mappers/price_data_mapper.dart';
import 'package:neotradingbotfront1777/domain/entities/price_data.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pb.dart';
import 'package:test/test.dart';

void main() {
  group('PriceDataMapper — toDomain', () {
    test('[PDM-01] maps all fields from PriceResponse to PriceData', () {
      final proto = PriceResponse(
        price: 45000.0,
        priceChange24h: 2.5,
        priceChangeAbsolute24h: 1125.0,
        highPrice24h: 46000.0,
        lowPrice24h: 44000.0,
        volume24h: 1000.0,
        priceStr: '45000.00',
        priceChange24hStr: '2.50',
        priceChangeAbsolute24hStr: '1125.00',
        highPrice24hStr: '46000.00',
        lowPrice24hStr: '44000.00',
        volume24hStr: '1000.00',
      );

      final result = proto.toDomain('BTCUSDC');

      expect(result.symbol, 'BTCUSDC');
      expect(result.price, 45000.0);
      expect(result.priceChange24h, 2.5);
      expect(result.priceChangeAbsolute24h, 1125.0);
      expect(result.highPrice24h, 46000.0);
      expect(result.lowPrice24h, 44000.0);
      expect(result.volume24h, 1000.0);
      expect(result.priceStr, '45000.00');
    });

    test('[PDM-02] toDomain sets timestamp to current time', () {
      final before = DateTime.now();
      final proto = PriceResponse(price: 45000.0);
      final result = proto.toDomain('BTCUSDC');
      final after = DateTime.now();

      expect(
        result.timestamp.isAfter(before.subtract(Duration(seconds: 1))),
        true,
      );
      expect(result.timestamp.isBefore(after.add(Duration(seconds: 1))), true);
    });
  });

  group('PriceDataMapper — toDto', () {
    test('[PDM-03] maps all fields from PriceData to PriceResponse', () {
      final priceData = PriceData(
        symbol: 'BTCUSDC',
        price: 45000.0,
        timestamp: DateTime.now(),
        priceChange24h: 2.5,
        priceChangeAbsolute24h: 1125.0,
        highPrice24h: 46000.0,
        lowPrice24h: 44000.0,
        volume24h: 1000.0,
        priceStr: '45000.00',
        priceChange24hStr: '2.50',
        priceChangeAbsolute24hStr: '1125.00',
        highPrice24hStr: '46000.00',
        lowPrice24hStr: '44000.00',
        volume24hStr: '1000.00',
      );

      final result = priceData.toDto();

      expect(result, isA<PriceResponse>());
      expect(result.price, 45000.0);
      expect(result.priceChange24h, 2.5);
      expect(result.volume24h, 1000.0);
      expect(result.priceStr, '45000.00');
    });
  });

  group('PriceDataMapper — round-trip', () {
    test('[PDM-04] domain → dto → domain preserves values', () {
      final original = PriceData(
        symbol: 'ETHUSDC',
        price: 3000.0,
        timestamp: DateTime.now(),
        priceChange24h: -1.5,
        priceChangeAbsolute24h: -45.0,
        highPrice24h: 3100.0,
        lowPrice24h: 2900.0,
        volume24h: 5000.0,
        priceStr: '3000.00',
        priceChange24hStr: '-1.50',
        priceChangeAbsolute24hStr: '-45.00',
        highPrice24hStr: '3100.00',
        lowPrice24hStr: '2900.00',
        volume24hStr: '5000.00',
      );

      final dto = original.toDto();
      final restored = dto.toDomain('ETHUSDC');

      expect(restored.price, original.price);
      expect(restored.priceChange24h, original.priceChange24h);
      expect(restored.volume24h, original.volume24h);
      expect(restored.priceStr, original.priceStr);
    });
  });
}
