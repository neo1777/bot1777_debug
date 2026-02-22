import 'package:equatable/equatable.dart';

/// Represents a price point for a specific symbol at a given time.
class Price extends Equatable {
  /// The trading symbol (e.g., 'BTCUSDC').
  final String symbol;

  /// The price value.
  final double price;

  /// The timestamp of the price data from the source.
  final DateTime timestamp;

  const Price({
    required this.symbol,
    required this.price,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [symbol, price, timestamp];

  @override
  String toString() {
    return 'Price(symbol: $symbol, price: $price, timestamp: $timestamp)';
  }
}
