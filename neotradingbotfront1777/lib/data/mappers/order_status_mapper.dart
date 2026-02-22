import 'package:fixnum/fixnum.dart';
import 'package:neotradingbotfront1777/domain/entities/order_status.dart'
    as domain;
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pb.dart'
    as proto;

extension OrderStatusMapper on proto.OrderStatus {
  domain.OrderStatus toDomain() {
    return domain.OrderStatus(
      symbol: symbol,
      orderId: orderId.toInt(),
      clientOrderId: clientOrderId,
      price: price,
      origQty: origQty,
      executedQty: executedQty,
      status: status,
      timeInForce: timeInForce,
      type: type,
      side: side,
      time: DateTime.fromMillisecondsSinceEpoch(time.toInt()),
      priceStr: priceStr,
      origQtyStr: origQtyStr,
      executedQtyStr: executedQtyStr,
    );
  }
}

extension OrderStatusToDtoMapper on domain.OrderStatus {
  proto.OrderStatus toDto() {
    return proto.OrderStatus(
      symbol: symbol,
      orderId: Int64(orderId),
      clientOrderId: clientOrderId,
      price: price,
      origQty: origQty,
      executedQty: executedQty,
      status: status,
      timeInForce: timeInForce,
      type: type,
      side: side,
      time: Int64(time.millisecondsSinceEpoch),
      priceStr: priceStr,
      origQtyStr: origQtyStr,
      executedQtyStr: executedQtyStr,
    );
  }
}

extension OpenOrdersMapper on proto.OpenOrdersResponse {
  List<domain.OrderStatus> toDomain() {
    return orders.map((order) => order.toDomain()).toList();
  }
}
