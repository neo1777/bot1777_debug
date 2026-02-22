import 'package:equatable/equatable.dart';

class OrderStatus extends Equatable {
  const OrderStatus({
    required this.symbol,
    required this.orderId,
    required this.clientOrderId,
    required this.price,
    required this.origQty,
    required this.executedQty,
    required this.status,
    required this.timeInForce,
    required this.type,
    required this.side,
    required this.time,
    this.priceStr = '',
    this.origQtyStr = '',
    this.executedQtyStr = '',
  });

  final String symbol;
  final int orderId;
  final String clientOrderId;
  final double price;
  final double origQty;
  final double executedQty;
  final String status;
  final String timeInForce;
  final String type;
  final String side;
  final DateTime time;
  final String priceStr;
  final String origQtyStr;
  final String executedQtyStr;

  double get remainingQty => origQty - executedQty;
  double get filledPercentage => executedQty / origQty * 100;
  bool get isCompleted => status == 'FILLED';
  bool get isCancelled => status == 'CANCELED';
  bool get isPending => status == 'NEW' || status == 'PARTIALLY_FILLED';

  @override
  List<Object?> get props => [
    symbol,
    orderId,
    clientOrderId,
    price,
    origQty,
    executedQty,
    status,
    timeInForce,
    type,
    side,
    time,
    priceStr,
    origQtyStr,
    executedQtyStr,
  ];

  @override
  String toString() =>
      'OrderStatus(symbol: $symbol, orderId: $orderId, status: $status, side: $side, price: $price, origQty: $origQty, executedQty: $executedQty)';

  OrderStatus copyWith({
    String? symbol,
    int? orderId,
    String? clientOrderId,
    double? price,
    double? origQty,
    double? executedQty,
    String? status,
    String? timeInForce,
    String? type,
    String? side,
    DateTime? time,
    String? priceStr,
    String? origQtyStr,
    String? executedQtyStr,
  }) {
    return OrderStatus(
      symbol: symbol ?? this.symbol,
      orderId: orderId ?? this.orderId,
      clientOrderId: clientOrderId ?? this.clientOrderId,
      price: price ?? this.price,
      origQty: origQty ?? this.origQty,
      executedQty: executedQty ?? this.executedQty,
      status: status ?? this.status,
      timeInForce: timeInForce ?? this.timeInForce,
      type: type ?? this.type,
      side: side ?? this.side,
      time: time ?? this.time,
      priceStr: priceStr ?? this.priceStr,
      origQtyStr: origQtyStr ?? this.origQtyStr,
      executedQtyStr: executedQtyStr ?? this.executedQtyStr,
    );
  }
}
