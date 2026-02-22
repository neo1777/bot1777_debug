class Kline {
  final int openTime;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final int closeTime;
  final double quoteAssetVolume;
  final int numberOfTrades;
  final double takerBuyBaseAssetVolume;
  final double takerBuyQuoteAssetVolume;

  Kline({
    required this.openTime,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.closeTime,
    required this.quoteAssetVolume,
    required this.numberOfTrades,
    required this.takerBuyBaseAssetVolume,
    required this.takerBuyQuoteAssetVolume,
  }) {
    if (openTime >= closeTime) {
      throw ArgumentError('Open time must be before close time');
    }
    if (high < low) {
      throw ArgumentError('High price cannot be lower than low price');
    }
    if (high < open || high < close) {
      throw ArgumentError(
          'High price must be greater than or equal to open and close prices');
    }
    if (low > open || low > close) {
      throw ArgumentError(
          'Low price must be less than or equal to open and close prices');
    }
    if (volume < 0) {
      throw ArgumentError('Volume cannot be negative');
    }
    if (open < 0 || high < 0 || low < 0 || close < 0) {
      throw ArgumentError('Prices cannot be negative');
    }
  }
}
