import 'package:equatable/equatable.dart';

class AppTrade extends Equatable {
  const AppTrade({
    required this.symbol,
    required this.price,
    required this.quantity,
    required this.isBuy,
    required this.timestamp,
    required this.orderStatus,
    this.profit,
    this.id,
    this.orderId,
    this.fee,
    this.feeCurrency,
    this.isMaker = false,
  });

  final String symbol;
  final double price;
  final double quantity;
  final bool isBuy;
  final DateTime timestamp;
  final String orderStatus;
  final double? profit;
  final String? id;
  final String? orderId;
  final double? fee;
  final String? feeCurrency;
  final bool isMaker;

  String get side => isBuy ? 'BUY' : 'SELL';
  double get totalValue => price * quantity;
  bool get isCompleted => orderStatus == 'FILLED';

  @override
  List<Object?> get props => [
    symbol,
    price,
    quantity,
    isBuy,
    timestamp,
    orderStatus,
    profit,
    id,
    orderId,
    fee,
    feeCurrency,
    isMaker,
  ];

  @override
  String toString() =>
      'AppTrade(symbol: $symbol, price: $price, quantity: $quantity, isBuy: $isBuy, timestamp: $timestamp, orderStatus: $orderStatus, profit: $profit, id: $id, orderId: $orderId, fee: $fee, feeCurrency: $feeCurrency, isMaker: $isMaker)';

  AppTrade copyWith({
    String? symbol,
    double? price,
    double? quantity,
    bool? isBuy,
    DateTime? timestamp,
    String? orderStatus,
    double? profit,
    String? id,
    String? orderId,
    double? fee,
    String? feeCurrency,
    bool? isMaker,
  }) {
    return AppTrade(
      symbol: symbol ?? this.symbol,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      isBuy: isBuy ?? this.isBuy,
      timestamp: timestamp ?? this.timestamp,
      orderStatus: orderStatus ?? this.orderStatus,
      profit: profit ?? this.profit,
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      fee: fee ?? this.fee,
      feeCurrency: feeCurrency ?? this.feeCurrency,
      isMaker: isMaker ?? this.isMaker,
    );
  }
}
