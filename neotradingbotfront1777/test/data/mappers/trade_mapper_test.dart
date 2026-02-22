import 'package:fixnum/fixnum.dart';
import 'package:neotradingbotfront1777/data/mappers/trade_mapper.dart';
import 'package:neotradingbotfront1777/domain/entities/app_trade.dart';
import 'package:neotradingbotfront1777/domain/entities/trade_history.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pb.dart'
    as grpc;
import 'package:test/test.dart';

void main() {
  group('TradeMapper — tradeFromProto', () {
    test('[TM-01] maps basic fields correctly', () {
      final proto = grpc.Trade(
        symbol: 'BTCUSDC',
        price: 45000.0,
        quantity: 0.5,
        isBuy: true,
        timestamp: Int64(1700000000000),
        orderStatus: 'FILLED',
      );

      final result = tradeFromProto(proto);

      expect(result, isA<TradeHistory>());
      expect(result.symbol, 'BTCUSDC');
      expect(result.price, 45000.0);
      expect(result.quantity, 0.5);
      expect(result.side, 'BUY');
      expect(result.status, 'FILLED');
      expect(result.timestamp.millisecondsSinceEpoch, 1700000000000);
    });

    test('[TM-02] maps SELL side correctly', () {
      final proto = grpc.Trade(
        symbol: 'ETHUSDC',
        isBuy: false,
        timestamp: Int64(1700000000000),
      );

      final result = tradeFromProto(proto);
      expect(result.side, 'SELL');
    });

    test('[TM-03] generates unique ID from symbol:timestamp:side:qty', () {
      final proto = grpc.Trade(
        symbol: 'BTCUSDC',
        quantity: 0.1,
        isBuy: true,
        timestamp: Int64(1700000000000),
      );

      final result = tradeFromProto(proto);
      expect(result.id, 'BTCUSDC:1700000000000:1:0.1');
    });
  });

  group('TradeMapper — appTradeFromProto', () {
    test('[TM-04] maps basic AppTrade fields', () {
      final proto = grpc.Trade(
        symbol: 'BTCUSDC',
        price: 45000.0,
        quantity: 0.5,
        isBuy: true,
        timestamp: Int64(1700000000000),
        orderStatus: 'FILLED',
      );

      final result = appTradeFromProto(proto);

      expect(result, isA<AppTrade>());
      expect(result.symbol, 'BTCUSDC');
      expect(result.price, 45000.0);
      expect(result.quantity, 0.5);
      expect(result.isBuy, true);
      expect(result.orderStatus, 'FILLED');
    });

    test('[TM-05] handles profit from proto field', () {
      final proto = grpc.Trade(
        symbol: 'BTCUSDC',
        price: 46000.0,
        quantity: 0.5,
        isBuy: false,
        timestamp: Int64(1700000000000),
        profit: 500.0,
      );

      final result = appTradeFromProto(proto);
      expect(result.profit, 500.0);
    });

    test('[TM-06] handles null profit gracefully', () {
      final proto = grpc.Trade(
        symbol: 'BTCUSDC',
        price: 45000.0,
        quantity: 0.5,
        isBuy: true,
        timestamp: Int64(1700000000000),
      );

      final result = appTradeFromProto(proto);
      expect(result.profit, isNull);
    });
  });

  group('TradeMapper — tradeHistoryFromProto', () {
    test('[TM-07] maps list of trades from response', () {
      final response = grpc.TradeHistoryResponse(
        trades: [
          grpc.Trade(
            symbol: 'BTCUSDC',
            price: 45000.0,
            quantity: 0.5,
            isBuy: true,
            timestamp: Int64(1700000000000),
          ),
          grpc.Trade(
            symbol: 'ETHUSDC',
            price: 3000.0,
            quantity: 2.0,
            isBuy: false,
            timestamp: Int64(1700000001000),
          ),
        ],
      );

      final result = tradeHistoryFromProto(response);

      expect(result.length, 2);
      expect(result[0].symbol, 'BTCUSDC');
      expect(result[1].symbol, 'ETHUSDC');
    });

    test('[TM-08] handles empty trades list', () {
      final response = grpc.TradeHistoryResponse(trades: []);

      final result = tradeHistoryFromProto(response);
      expect(result, isEmpty);
    });
  });
}

