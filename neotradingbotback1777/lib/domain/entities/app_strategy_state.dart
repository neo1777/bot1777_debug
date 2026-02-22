/// [AUDIT-PHASE-9]
import 'package:equatable/equatable.dart';
import 'package:decimal/decimal.dart';
import 'package:neotradingbotback1777/domain/entities/fifo_app_trade.dart';
import 'package:neotradingbotback1777/domain/entities/strategy_state.dart';

class AppStrategyState extends Equatable {
  final String symbol;
  final List<FifoAppTrade> openTrades;
  final StrategyState status;
  final int currentRoundId;
  final double cumulativeProfit;
  final int successfulRounds;
  final int failedRounds;
  final int? targetRoundId;
  final bool isPriceFrozen;
  final DateTime? lastPriceFreezeTime;
  final double? frozenAveragePrice;
  final double currentVolatilityLevel;
  final List<double> priceHistory;

  AppStrategyState({
    required this.symbol,
    List<FifoAppTrade> openTrades = const [],
    this.status = StrategyState.IDLE,
    this.currentRoundId = 1,
    this.cumulativeProfit = 0.0,
    this.successfulRounds = 0,
    this.failedRounds = 0,
    this.targetRoundId,
    this.isPriceFrozen = false,
    this.lastPriceFreezeTime,
    this.frozenAveragePrice,
    this.currentVolatilityLevel = 0.0,
    this.priceHistory = const [],
  }) : openTrades = List.unmodifiable(openTrades);

  // Cache statico rimosso per evitare memory leaks e test interference.
  // Utilizziamo memoizzazione a livello di istanza tramite late final.

  bool get isInitialState => openTrades.isEmpty;

  late final Decimal totalQuantity = _calculateTotalQuantity();

  Decimal _calculateTotalQuantity() {
    if (isInitialState) {
      return Decimal.zero;
    }
    return openTrades
        .map<Decimal>(
            (t) => Decimal.tryParse(t.quantity.toString()) ?? Decimal.zero)
        .fold<Decimal>(Decimal.zero, (Decimal sum, Decimal v) => sum + v);
  }

  late final double totalInvested = _calculateTotalInvested();

  double _calculateTotalInvested() {
    if (isInitialState) {
      return 0.0;
    }
    return openTrades
        .map((t) =>
            Decimal.parse(t.price.toString()) *
            Decimal.parse(t.quantity.toString()))
        .fold(Decimal.zero, (sum, v) => sum + v)
        .toDouble();
  }

  late final double averagePrice = _calculateAveragePrice();

  double _calculateAveragePrice() {
    if (isInitialState) {
      return 0.0;
    }
    final qty = totalQuantity;
    if (qty <= Decimal.zero) {
      return 0.0;
    }
    // Calcola totalInvested direttamente in Decimal per evitare
    // la perdita di precisione double→String→Decimal
    final investedDecimal = openTrades
        .map((t) =>
            Decimal.parse(t.price.toString()) *
            Decimal.parse(t.quantity.toString()))
        .fold(Decimal.zero, (sum, v) => sum + v);
    final value = (investedDecimal / qty).toDouble();
    return value.isFinite ? value : 0.0;
  }

  late final double validatedAveragePrice = _calculateValidatedAveragePrice();

  double _calculateValidatedAveragePrice() {
    if (isInitialState) {
      return 0.0;
    }
    final validTrades = openTrades
        .where((t) => t.isExecuted && t.orderStatus == 'FILLED')
        .toList();
    if (validTrades.isEmpty) {
      return 0.0;
    }

    final validQuantity = validTrades
        .map((t) => Decimal.parse(t.quantity.toString()))
        .fold(Decimal.zero, (sum, v) => sum + v);

    if (validQuantity <= Decimal.zero) {
      return 0.0;
    }

    final validInvested = validTrades
        .map((t) =>
            Decimal.parse(t.price.toString()) *
            Decimal.parse(t.quantity.toString()))
        .fold(Decimal.zero, (sum, v) => sum + v);

    final value = (validInvested / validQuantity).toDouble();
    return value.isFinite ? value : 0.0;
  }

  /// Restituisce il prezzo dell'ultimo ordine di acquisto (indipendente dallo stato)
  double get lastBuyPrice =>
      isInitialState ? 0.0 : openTrades.last.price.toDouble();

  late final double lastValidBuyPrice = _calculateLastValidBuyPrice();

  double _calculateLastValidBuyPrice() {
    if (isInitialState) {
      return 0.0;
    }
    for (int i = openTrades.length - 1; i >= 0; i--) {
      final trade = openTrades[i];
      if (trade.isExecuted && trade.orderStatus == 'FILLED') {
        return trade.price.toDouble();
      }
    }
    return 0.0;
  }

  bool get isValidForDca => openTrades.any((t) => t.isExecuted);

  // === Membri reintrodotti per compatibilità ===

  double get effectiveAveragePrice =>
      isPriceFrozen ? (frozenAveragePrice ?? averagePrice) : averagePrice;

  int get validTradesCount => openTrades
      .where((t) =>
          t.isExecuted &&
          t.orderStatus == 'FILLED' &&
          t.price > Decimal.zero &&
          t.quantity > Decimal.zero)
      .length;

  int get invalidTradesCount => openTrades.length - validTradesCount;

  bool get hasInconsistencies => invalidTradesCount > 0;

  AppStrategyState updatePriceHistory(double currentPrice,
      {int historyLimit = 100}) {
    final newHistory = List<double>.from(priceHistory)..add(currentPrice);
    if (newHistory.length > historyLimit) {
      return copyWith(
          priceHistory: newHistory.sublist(newHistory.length - historyLimit));
    }
    return copyWith(priceHistory: newHistory);
  }

  AppStrategyState freezePrice() {
    return copyWith(
      isPriceFrozen: true,
      frozenAveragePrice: averagePrice,
      lastPriceFreezeTime: DateTime.now(),
    );
  }

  AppStrategyState unfreezePrice() {
    return copyWith(
      isPriceFrozen: false,
      frozenAveragePrice: null,
      lastPriceFreezeTime: null,
    );
  }

  // === Fine membri reintrodotti ===

  AppStrategyState copyWith({
    String? symbol,
    List<FifoAppTrade>? openTrades,
    StrategyState? status,
    int? currentRoundId,
    double? cumulativeProfit,
    int? successfulRounds,
    int? failedRounds,
    int? targetRoundId,
    bool? isPriceFrozen,
    DateTime? lastPriceFreezeTime,
    double? frozenAveragePrice,
    double? currentVolatilityLevel,
    List<double>? priceHistory,
  }) {
    return AppStrategyState(
      symbol: symbol ?? this.symbol,
      openTrades: openTrades ?? this.openTrades,
      status: status ?? this.status,
      currentRoundId: currentRoundId ?? this.currentRoundId,
      cumulativeProfit: cumulativeProfit ?? this.cumulativeProfit,
      successfulRounds: successfulRounds ?? this.successfulRounds,
      failedRounds: failedRounds ?? this.failedRounds,
      targetRoundId: targetRoundId ?? this.targetRoundId,
      isPriceFrozen: isPriceFrozen ?? this.isPriceFrozen,
      lastPriceFreezeTime: lastPriceFreezeTime ?? this.lastPriceFreezeTime,
      frozenAveragePrice: frozenAveragePrice ?? this.frozenAveragePrice,
      currentVolatilityLevel:
          currentVolatilityLevel ?? this.currentVolatilityLevel,
      priceHistory: priceHistory ?? this.priceHistory,
    );
  }

  @override
  List<Object?> get props => [
        symbol,
        openTrades,
        status,
        currentRoundId,
        cumulativeProfit,
        successfulRounds,
        failedRounds,
        targetRoundId,
        isPriceFrozen,
        lastPriceFreezeTime,
        frozenAveragePrice,
        currentVolatilityLevel,
        priceHistory,
      ];
}
