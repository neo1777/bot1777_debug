import 'package:equatable/equatable.dart';

/// Trade history entity representing a completed trade
class TradeHistory extends Equatable {
  const TradeHistory({
    required this.id,
    required this.symbol,
    required this.side,
    required this.quantity,
    required this.price,
    required this.executedQuantity,
    required this.timestamp,
    this.profit,
    this.fee,
    this.commission,
    this.status = 'FILLED',
  });

  final String id;
  final String symbol;
  final String side; // 'BUY' or 'SELL'
  final double quantity;
  final double price;
  final double executedQuantity;
  final DateTime timestamp;
  final double? profit; // Can be null for incomplete calculations
  final double? fee;
  final double? commission;
  final String status;

  @override
  List<Object?> get props => [
    id,
    symbol,
    side,
    quantity,
    price,
    executedQuantity,
    timestamp,
    profit,
    fee,
    commission,
    status,
  ];

  @override
  String toString() =>
      'TradeHistory(id: $id, symbol: $symbol, '
      'side: $side, quantity: $quantity, price: $price, '
      'profit: $profit, timestamp: $timestamp)';

  TradeHistory copyWith({
    String? id,
    String? symbol,
    String? side,
    double? quantity,
    double? price,
    double? executedQuantity,
    DateTime? timestamp,
    double? profit,
    double? fee,
    double? commission,
    String? status,
  }) {
    return TradeHistory(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      side: side ?? this.side,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      executedQuantity: executedQuantity ?? this.executedQuantity,
      timestamp: timestamp ?? this.timestamp,
      profit: profit ?? this.profit,
      fee: fee ?? this.fee,
      commission: commission ?? this.commission,
      status: status ?? this.status,
    );
  }

  /// Helper to check if trade was profitable
  bool get isProfitable => profit != null && profit! > 0;

  /// Helper to check if trade was a loss
  bool get isLoss => profit != null && profit! < 0;

  /// Helper to check if trade was a buy order
  bool get isBuy => side.toUpperCase() == 'BUY';

  /// Helper to check if trade was a sell order
  bool get isSell => side.toUpperCase() == 'SELL';

  /// Total value of the trade
  double get totalValue => quantity * price;
}
