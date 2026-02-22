import 'package:equatable/equatable.dart';

class AppSettings extends Equatable {
  final double tradeAmount;
  final double? fixedQuantity;
  final double profitTargetPercentage;
  final double stopLossPercentage;
  final double dcaDecrementPercentage;
  final int maxOpenTrades;
  final bool isTestMode;
  // Nuovi campi avvio strategia
  final bool buyOnStart;
  final int initialWarmupTicks;
  final double initialWarmupSeconds;
  final double initialSignalThresholdPct;
  // Nuovi parametri di robustezza (client-side mirror)
  final double dcaCooldownSeconds;
  final double dustRetryCooldownSeconds;
  final double maxTradeAmountCap;
  final double maxBuyOveragePct;
  final bool strictBudget;
  final bool buyOnStartRespectWarmup;
  final double buyCooldownSeconds;

  // Nuovi parametri strategia (mirror backend)
  final bool dcaCompareAgainstAverage;
  // Esecuzione backend: numero massimo di cicli (0 = infinito)
  final int maxCycles;

  // Se true, utilizza le fee reali di Binance per calcolare il profitto netto
  // nelle decisioni di trading (take profit e stop loss).
  // Se false, utilizza il calcolo tradizionale senza considerare le fee.
  final bool enableFeeAwareTrading;

  /// Se true, il bot riprende automaticamente ad acquistare dopo un ciclo
  /// completo (acquisto→vendita). Default: false.
  final bool enableReBuy;

  const AppSettings({
    required this.tradeAmount,
    required this.profitTargetPercentage,
    required this.stopLossPercentage,
    required this.dcaDecrementPercentage,
    required this.maxOpenTrades,
    required this.isTestMode,
    this.fixedQuantity,
    this.buyOnStart = false,
    this.initialWarmupTicks = 1,
    this.initialWarmupSeconds = 0.0,
    this.initialSignalThresholdPct = 0.0,
    this.dcaCooldownSeconds = 3.0,
    this.dustRetryCooldownSeconds = 15.0,
    this.maxTradeAmountCap = 100.0,
    this.maxBuyOveragePct = 0.03,
    this.strictBudget = false,
    this.buyOnStartRespectWarmup = true,
    this.buyCooldownSeconds = 2.0,
    this.dcaCompareAgainstAverage = false,
    this.maxCycles = 0,
    this.enableFeeAwareTrading = true,
    this.enableReBuy = false,
  });

  factory AppSettings.initial() => const AppSettings(
    tradeAmount: 100.0,
    profitTargetPercentage: 2.0,
    stopLossPercentage: 5.0,
    dcaDecrementPercentage: 1.0,
    maxOpenTrades: 5,
    isTestMode: false,
  );

  @override
  List<Object?> get props => [
    tradeAmount,
    fixedQuantity,
    profitTargetPercentage,
    stopLossPercentage,
    dcaDecrementPercentage,
    maxOpenTrades,
    isTestMode,
    buyOnStart,
    initialWarmupTicks,
    initialWarmupSeconds,
    initialSignalThresholdPct,
    dcaCooldownSeconds,
    dustRetryCooldownSeconds,
    maxTradeAmountCap,
    maxBuyOveragePct,
    strictBudget,
    buyOnStartRespectWarmup,
    buyCooldownSeconds,
    dcaCompareAgainstAverage,

    maxCycles,
    enableFeeAwareTrading,
    enableReBuy,
  ];

  /// Crea una copia dell'oggetto con i campi specificati aggiornati
  AppSettings copyWith({
    double? tradeAmount,
    double? fixedQuantity,
    double? profitTargetPercentage,
    double? stopLossPercentage,
    double? dcaDecrementPercentage,
    int? maxOpenTrades,
    bool? isTestMode,
    bool? buyOnStart,
    int? initialWarmupTicks,
    double? initialWarmupSeconds,
    double? initialSignalThresholdPct,
    double? dcaCooldownSeconds,
    double? dustRetryCooldownSeconds,
    double? maxTradeAmountCap,
    double? maxBuyOveragePct,
    bool? strictBudget,
    bool? buyOnStartRespectWarmup,
    double? buyCooldownSeconds,
    bool? dcaCompareAgainstAverage,

    int? maxCycles,
    bool? enableFeeAwareTrading,
    bool? enableReBuy,
  }) {
    return AppSettings(
      tradeAmount: tradeAmount ?? this.tradeAmount,
      fixedQuantity: fixedQuantity ?? this.fixedQuantity,
      profitTargetPercentage:
          profitTargetPercentage ?? this.profitTargetPercentage,
      stopLossPercentage: stopLossPercentage ?? this.stopLossPercentage,
      dcaDecrementPercentage:
          dcaDecrementPercentage ?? this.dcaDecrementPercentage,
      maxOpenTrades: maxOpenTrades ?? this.maxOpenTrades,
      isTestMode: isTestMode ?? this.isTestMode,
      buyOnStart: buyOnStart ?? this.buyOnStart,
      initialWarmupTicks: initialWarmupTicks ?? this.initialWarmupTicks,
      initialWarmupSeconds: initialWarmupSeconds ?? this.initialWarmupSeconds,
      initialSignalThresholdPct:
          initialSignalThresholdPct ?? this.initialSignalThresholdPct,
      dcaCooldownSeconds: dcaCooldownSeconds ?? this.dcaCooldownSeconds,
      dustRetryCooldownSeconds:
          dustRetryCooldownSeconds ?? this.dustRetryCooldownSeconds,
      maxTradeAmountCap: maxTradeAmountCap ?? this.maxTradeAmountCap,
      maxBuyOveragePct: maxBuyOveragePct ?? this.maxBuyOveragePct,
      strictBudget: strictBudget ?? this.strictBudget,
      buyOnStartRespectWarmup:
          buyOnStartRespectWarmup ?? this.buyOnStartRespectWarmup,
      buyCooldownSeconds: buyCooldownSeconds ?? this.buyCooldownSeconds,
      dcaCompareAgainstAverage:
          dcaCompareAgainstAverage ?? this.dcaCompareAgainstAverage,

      maxCycles: maxCycles ?? this.maxCycles,
      enableFeeAwareTrading:
          enableFeeAwareTrading ?? this.enableFeeAwareTrading,
      enableReBuy: enableReBuy ?? this.enableReBuy,
    );
  }
}
