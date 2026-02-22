import 'package:equatable/equatable.dart';

/// Entità per gestire le informazioni sulle fee di trading
///
/// Include fee maker/taker, valuta, sconti e metodi di calcolo
class FeeInfo extends Equatable {
  final double makerFee;
  final double takerFee;
  final String feeCurrency;
  final bool isDiscountActive;
  final double discountPercentage;
  final DateTime lastUpdated;
  final String symbol;

  const FeeInfo({
    required this.makerFee,
    required this.takerFee,
    required this.feeCurrency,
    required this.isDiscountActive,
    required this.discountPercentage,
    required this.lastUpdated,
    required this.symbol,
  });

  /// Factory per creare fee di default Binance
  factory FeeInfo.defaultBinance({required String symbol}) {
    return FeeInfo(
      makerFee: 0.001, // 0.1%
      takerFee: 0.001, // 0.1%
      feeCurrency: 'USDT',
      isDiscountActive: false,
      discountPercentage: 0.0,
      lastUpdated: DateTime.now(),
      symbol: symbol,
    );
  }

  /// Factory per creare fee con sconto BNB
  factory FeeInfo.withBnbDiscount({
    required String symbol,
    required double baseFee,
    required double discountPercentage,
  }) {
    final discountedFee = baseFee * (1 - discountPercentage);
    return FeeInfo(
      makerFee: discountedFee,
      takerFee: discountedFee,
      feeCurrency: 'BNB',
      isDiscountActive: true,
      discountPercentage: discountPercentage,
      lastUpdated: DateTime.now(),
      symbol: symbol,
    );
  }

  /// Calcola le fee totali per una transazione
  double calculateTotalFees({
    required double quantity,
    required double price,
    required bool isMaker,
    bool useDiscount = true,
  }) {
    final baseFee = isMaker ? makerFee : takerFee;
    final effectiveFee = useDiscount && isDiscountActive
        ? baseFee * (1 - discountPercentage)
        : baseFee;

    return quantity * price * effectiveFee;
  }

  /// Calcola le fee in percentuale
  double getEffectiveFeePercentage(
      {required bool isMaker, bool useDiscount = true}) {
    final baseFee = isMaker ? makerFee : takerFee;
    return useDiscount && isDiscountActive
        ? baseFee * (1 - discountPercentage)
        : baseFee;
  }

  /// Copia l'oggetto aggiornando i timestamp
  FeeInfo copyWith({
    double? makerFee,
    double? takerFee,
    String? feeCurrency,
    bool? isDiscountActive,
    double? discountPercentage,
    DateTime? lastUpdated,
    String? symbol,
  }) {
    return FeeInfo(
      makerFee: makerFee ?? this.makerFee,
      takerFee: takerFee ?? this.takerFee,
      feeCurrency: feeCurrency ?? this.feeCurrency,
      isDiscountActive: isDiscountActive ?? this.isDiscountActive,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      lastUpdated: lastUpdated ?? DateTime.now(),
      symbol: symbol ?? this.symbol,
    );
  }

  @override
  List<Object?> get props => [
        makerFee,
        takerFee,
        feeCurrency,
        isDiscountActive,
        discountPercentage,
        lastUpdated,
        symbol,
      ];

  @override
  String toString() {
    return 'FeeInfo('
        'symbol: $symbol, '
        'makerFee: ${(makerFee * 100).toStringAsFixed(3)}%, '
        'takerFee: ${(takerFee * 100).toStringAsFixed(3)}%, '
        'currency: $feeCurrency, '
        'discount: ${isDiscountActive ? "${(discountPercentage * 100).toStringAsFixed(1)}%" : "none"}'
        ')';
  }
}
