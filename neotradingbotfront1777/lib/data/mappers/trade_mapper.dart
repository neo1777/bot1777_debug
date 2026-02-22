import 'package:neotradingbotfront1777/domain/entities/app_trade.dart';
import 'package:neotradingbotfront1777/domain/entities/trade_history.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pb.dart'
    as grpc;

List<TradeHistory> tradeHistoryFromProto(grpc.TradeHistoryResponse response) {
  return response.trades.map((trade) => tradeFromProto(trade)).toList();
}

TradeHistory tradeFromProto(grpc.Trade trade) {
  // Preferisci i nuovi campi string se presenti
  double num(grpc.Trade t, double legacy, String? s) {
    if (s != null && s.isNotEmpty) {
      final v = double.tryParse(s);
      if (v != null && v.isFinite) return v;
    }
    return legacy;
  }

  String? priceStr;
  String? qtyStr;
  try {
    final map = (trade.toProto3Json() as Map<String, dynamic>);
    priceStr = map['priceStr'] as String?;
    qtyStr = map['quantityStr'] as String?;
  } catch (_) {}
  final ts = trade.timestamp.toInt();
  final side = trade.isBuy ? 'BUY' : 'SELL';
  final qty = num(trade, trade.quantity, qtyStr);
  // ID robusto basato su più dimensioni (no collisione su symbol-only)
  final id = '${trade.symbol}:$ts:${trade.isBuy ? 1 : 0}:$qty';
  return TradeHistory(
    id: id,
    symbol: trade.symbol,
    side: side,
    quantity: qty,
    price: num(trade, trade.price, priceStr),
    executedQuantity: qty,
    timestamp: DateTime.fromMillisecondsSinceEpoch(ts),
    status: trade.orderStatus,
  );
}

AppTrade appTradeFromProto(grpc.Trade trade) {
  double num(grpc.Trade t, double legacy, String? s) {
    if (s != null && s.isNotEmpty) {
      final v = double.tryParse(s);
      if (v != null && v.isFinite) return v;
    }
    return legacy;
  }

  String? priceStr;
  String? qtyStr;
  String? profitStr;
  try {
    final map = (trade.toProto3Json() as Map<String, dynamic>);
    priceStr = map['priceStr'] as String?;
    qtyStr = map['quantityStr'] as String?;
    profitStr = map['profitStr'] as String?;
  } catch (_) {}
  return AppTrade(
    symbol: trade.symbol,
    price: num(trade, trade.price, priceStr),
    quantity: num(trade, trade.quantity, qtyStr),
    isBuy: trade.isBuy,
    timestamp: DateTime.fromMillisecondsSinceEpoch(trade.timestamp.toInt()),
    orderStatus: trade.orderStatus,
    profit:
        trade.hasProfit()
            ? trade.profit
            : (profitStr != null ? double.tryParse(profitStr) : null),
  );
}
