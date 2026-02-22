import 'package:equatable/equatable.dart';

class PriceData extends Equatable {
  const PriceData({
    required this.symbol,
    required this.price,
    required this.timestamp,
    this.priceChange24h = 0.0,
    this.priceChangeAbsolute24h = 0.0,
    this.highPrice24h = 0.0,
    this.lowPrice24h = 0.0,
    this.volume24h = 0.0,
    this.priceStr = '',
    this.priceChange24hStr = '',
    this.priceChangeAbsolute24hStr = '',
    this.highPrice24hStr = '',
    this.lowPrice24hStr = '',
    this.volume24hStr = '',
  });

  final String symbol;
  final double price;
  final DateTime timestamp;
  final double priceChange24h; // Percentage change in 24h
  final double priceChangeAbsolute24h; // Absolute change in 24h
  final double highPrice24h; // Highest price in 24h
  final double lowPrice24h; // Lowest price in 24h
  final double volume24h; // Trading volume in 24h
  final String priceStr;
  final String priceChange24hStr;
  final String priceChangeAbsolute24hStr;
  final String highPrice24hStr;
  final String lowPrice24hStr;
  final String volume24hStr;

  // Alias for backward compatibility
  double get currentPrice => price;

  @override
  List<Object?> get props => [
    symbol,
    price,
    timestamp,
    priceChange24h,
    priceChangeAbsolute24h,
    highPrice24h,
    lowPrice24h,
    volume24h,
    priceStr,
    priceChange24hStr,
    priceChangeAbsolute24hStr,
    highPrice24hStr,
    lowPrice24hStr,
    volume24hStr,
  ];

  @override
  String toString() =>
      'PriceData(symbol: $symbol, price: $price, '
      'priceChange24h: $priceChange24h%, timestamp: $timestamp)';

  PriceData copyWith({
    String? symbol,
    double? price,
    DateTime? timestamp,
    double? priceChange24h,
    double? priceChangeAbsolute24h,
    double? highPrice24h,
    double? lowPrice24h,
    double? volume24h,
    String? priceStr,
    String? priceChange24hStr,
    String? priceChangeAbsolute24hStr,
    String? highPrice24hStr,
    String? lowPrice24hStr,
    String? volume24hStr,
  }) {
    return PriceData(
      symbol: symbol ?? this.symbol,
      price: price ?? this.price,
      timestamp: timestamp ?? this.timestamp,
      priceChange24h: priceChange24h ?? this.priceChange24h,
      priceChangeAbsolute24h:
          priceChangeAbsolute24h ?? this.priceChangeAbsolute24h,
      highPrice24h: highPrice24h ?? this.highPrice24h,
      lowPrice24h: lowPrice24h ?? this.lowPrice24h,
      volume24h: volume24h ?? this.volume24h,
      priceStr: priceStr ?? this.priceStr,
      priceChange24hStr: priceChange24hStr ?? this.priceChange24hStr,
      priceChangeAbsolute24hStr:
          priceChangeAbsolute24hStr ?? this.priceChangeAbsolute24hStr,
      highPrice24hStr: highPrice24hStr ?? this.highPrice24hStr,
      lowPrice24hStr: lowPrice24hStr ?? this.lowPrice24hStr,
      volume24hStr: volume24hStr ?? this.volume24hStr,
    );
  }
}
