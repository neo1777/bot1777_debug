/// DTO per i dettagli di un trade completato
class TradeCompletionInfo {
  final String symbol;
  final bool isBuy;
  final double quantity;
  final double price;
  final double profit;
  final DateTime timestamp;

  TradeCompletionInfo({
    required this.symbol,
    required this.isBuy,
    required this.quantity,
    required this.price,
    required this.profit,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMetadata() {
    return {
      'isBuy': isBuy,
      'quantity': quantity,
      'price': price,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}
