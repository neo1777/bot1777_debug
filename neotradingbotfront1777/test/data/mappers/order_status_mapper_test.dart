import 'package:fixnum/fixnum.dart';
import 'package:neotradingbotfront1777/data/mappers/order_status_mapper.dart';
import 'package:neotradingbotfront1777/domain/entities/order_status.dart'
    as domain;
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pb.dart'
    as proto;
import 'package:test/test.dart';

void main() {
  group('OrderStatusMapper — toDomain', () {
    test('[OSM-01] maps all fields from proto to domain', () {
      final protoOrder = proto.OrderStatus(
        symbol: 'BTCUSDC',
        orderId: Int64(12345),
        clientOrderId: 'client_001',
        price: 45000.0,
        origQty: 0.5,
        executedQty: 0.5,
        status: 'FILLED',
        timeInForce: 'GTC',
        type: 'LIMIT',
        side: 'BUY',
        time: Int64(1700000000000),
        priceStr: '45000.00',
        origQtyStr: '0.50',
        executedQtyStr: '0.50',
      );

      final result = protoOrder.toDomain();

      expect(result, isA<domain.OrderStatus>());
      expect(result.symbol, 'BTCUSDC');
      expect(result.orderId, 12345);
      expect(result.clientOrderId, 'client_001');
      expect(result.price, 45000.0);
      expect(result.origQty, 0.5);
      expect(result.status, 'FILLED');
      expect(result.side, 'BUY');
      expect(result.time.millisecondsSinceEpoch, 1700000000000);
      expect(result.priceStr, '45000.00');
    });
  });

  group('OrderStatusMapper — toDto', () {
    test('[OSM-02] maps domain order status back to proto', () {
      final domainOrder = domain.OrderStatus(
        symbol: 'ETHUSDC',
        orderId: 67890,
        clientOrderId: 'client_002',
        price: 3000.0,
        origQty: 10.0,
        executedQty: 5.0,
        status: 'PARTIALLY_FILLED',
        timeInForce: 'GTC',
        type: 'LIMIT',
        side: 'SELL',
        time: DateTime.fromMillisecondsSinceEpoch(1700000001000),
        priceStr: '3000.00',
        origQtyStr: '10.00',
        executedQtyStr: '5.00',
      );

      final result = domainOrder.toDto();
      expect(result, isA<proto.OrderStatus>());
      expect(result.symbol, 'ETHUSDC');
      expect(result.orderId, Int64(67890));
      expect(result.time, Int64(1700000001000));
    });
  });

  group('OrderStatusMapper — OpenOrdersResponse', () {
    test('[OSM-03] maps list of orders', () {
      final response = proto.OpenOrdersResponse(
        orders: [
          proto.OrderStatus(
            symbol: 'BTCUSDC',
            orderId: Int64(1),
            status: 'NEW',
            time: Int64(0),
          ),
          proto.OrderStatus(
            symbol: 'ETHUSDC',
            orderId: Int64(2),
            status: 'PARTIALLY_FILLED',
            time: Int64(0),
          ),
        ],
      );

      final result = response.toDomain();
      expect(result.length, 2);
      expect(result[0].symbol, 'BTCUSDC');
      expect(result[1].symbol, 'ETHUSDC');
    });

    test('[OSM-04] handles empty orders list', () {
      final response = proto.OpenOrdersResponse(orders: []);

      final result = response.toDomain();
      expect(result, isEmpty);
    });
  });
}

