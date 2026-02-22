class TickerInfo {
  final double priceChange;
  final double priceChangePercent;
  final double highPrice;
  final double lowPrice;
  final double volume;

  TickerInfo({
    required this.priceChange,
    required this.priceChangePercent,
    required this.highPrice,
    required this.lowPrice,
    required this.volume,
  });

  factory TickerInfo.fromJson(Map<String, dynamic> json) {
    return TickerInfo(
      priceChange: double.parse(json['priceChange']),
      priceChangePercent: double.parse(json['priceChangePercent']),
      highPrice: double.parse(json['highPrice']),
      lowPrice: double.parse(json['lowPrice']),
      volume: double.parse(json['volume']),
    );
  }
}
