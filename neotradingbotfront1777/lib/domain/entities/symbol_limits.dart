import 'package:equatable/equatable.dart';

class SymbolLimits extends Equatable {
  const SymbolLimits({
    required this.symbol,
    required this.minQty,
    required this.maxQty,
    required this.stepSize,
    required this.minNotional,
    this.makerFee = 0.001,
    this.takerFee = 0.001,
    this.feeCurrency = 'BNB',
    this.isDiscountActive = false,
    this.discountPercentage = 0.0,
    this.lastUpdated,
  });

  final String symbol;
  final double minQty;
  final double maxQty;
  final double stepSize;
  final double minNotional;
  final double makerFee;
  final double takerFee;
  final String feeCurrency;
  final bool isDiscountActive;
  final double discountPercentage;
  final DateTime? lastUpdated;

  @override
  List<Object?> get props => [
    symbol,
    minQty,
    maxQty,
    stepSize,
    minNotional,
    makerFee,
    takerFee,
    feeCurrency,
    isDiscountActive,
    discountPercentage,
    lastUpdated,
  ];

  @override
  String toString() =>
      'SymbolLimits(symbol: $symbol, minQty: $minQty, maxQty: $maxQty, stepSize: $stepSize, minNotional: $minNotional)';

  SymbolLimits copyWith({
    String? symbol,
    double? minQty,
    double? maxQty,
    double? stepSize,
    double? minNotional,
    double? makerFee,
    double? takerFee,
    String? feeCurrency,
    bool? isDiscountActive,
    double? discountPercentage,
    DateTime? lastUpdated,
  }) {
    return SymbolLimits(
      symbol: symbol ?? this.symbol,
      minQty: minQty ?? this.minQty,
      maxQty: maxQty ?? this.maxQty,
      stepSize: stepSize ?? this.stepSize,
      minNotional: minNotional ?? this.minNotional,
      makerFee: makerFee ?? this.makerFee,
      takerFee: takerFee ?? this.takerFee,
      feeCurrency: feeCurrency ?? this.feeCurrency,
      isDiscountActive: isDiscountActive ?? this.isDiscountActive,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
