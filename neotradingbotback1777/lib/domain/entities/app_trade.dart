import 'package:equatable/equatable.dart';
import 'package:neotradingbotback1777/domain/value_objects/amounts.dart';

/// Rappresenta un'operazione di trading (acquisto o vendita) eseguita e conclusa.
/// Questa entità è utilizzata principalmente per la storicizzazione e l'analisi.
class AppTrade extends Equatable {
  final String symbol;
  final MoneyAmount price;
  final QuantityAmount quantity;
  final bool isBuy;
  final int timestamp;
  final String orderStatus;
  final MoneyAmount? profit; // Aggiunto per il calcolo dei profitti

  const AppTrade({
    required this.symbol,
    required this.price,
    required this.quantity,
    required this.isBuy,
    required this.timestamp,
    required this.orderStatus,
    this.profit,
  });

  @override
  List<Object?> get props =>
      [symbol, price, quantity, isBuy, timestamp, orderStatus, profit];

  AppTrade copyWith({
    String? symbol,
    MoneyAmount? price,
    QuantityAmount? quantity,
    bool? isBuy,
    int? timestamp,
    String? orderStatus,
    MoneyAmount? profit,
  }) {
    return AppTrade(
      symbol: symbol ?? this.symbol,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      isBuy: isBuy ?? this.isBuy,
      timestamp: timestamp ?? this.timestamp,
      orderStatus: orderStatus ?? this.orderStatus,
      profit: profit ?? this.profit,
    );
  }
}
