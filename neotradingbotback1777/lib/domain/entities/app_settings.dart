import 'package:equatable/equatable.dart';
import 'package:neotradingbotback1777/generated/proto/trading/v1/trading_service.pb.dart'
    as grpc;

/// Rappresenta le impostazioni immutabili che configurano la strategia di trading.
///
/// Questa classe è un'entità di dominio pura e non ha dipendenze esterne.
/// I suoi valori sono tipicamente definiti dall'utente e caricati all'avvio.
class AppSettings extends Equatable {
  /// L'importo di base, in valuta quote (es. USDC), per ogni operazione di acquisto.
  final double tradeAmount;

  /// Quantità fissa da acquistare (es. 0.0001 BTC). Se specificata, sovrascrive tradeAmount.
  /// Utile per evitare problemi di arrotondamento e dust.
  final double? fixedQuantity;

  /// La percentuale di profitto desiderata che, se raggiunta, innesca una vendita.
  /// Esempio: un valore di 1.5 significa un target di profitto del +1.5%.
  final double profitTargetPercentage;

  /// La percentuale di perdita massima che, se raggiunta, innesca una vendita (stop-loss).
  /// Esempio: un valore di 5.0 significa uno stop-loss al -5.0%.
  final double stopLossPercentage;

  /// La soglia di decremento percentuale rispetto all'ultimo acquisto che,
  /// se raggiunta, innesca un nuovo acquisto per mediare il prezzo (DCA).
  /// Esempio: un valore di 2.0 significa un nuovo acquisto al -2.0% dall'ultimo.
  final double dcaDecrementPercentage;

  /// Il numero massimo di operazioni di acquisto (trade) che possono essere
  /// aperti contemporaneamente prima di una vendita.
  final int maxOpenTrades;

  /// Indica se l'applicazione è in modalità di test.
  /// Se `true`, non verranno eseguiti ordini reali.
  final bool isTestMode;

  // --- Avvio strategia ---
  final bool buyOnStart;
  final int initialWarmupTicks;
  final double initialWarmupSeconds;
  final double initialSignalThresholdPct;

  // --- Nuovi parametri di robustezza/controllo rischio ---
  /// Cooldown tra acquisti DCA, in secondi (0 = disabilitato -> usa default interno)
  final double dcaCooldownSeconds;

  /// Cooldown tra tentativi di SELL quando notional < minNotional (dust), in secondi
  final double dustRetryCooldownSeconds;

  /// Massimale consentito per tradeAmount; il server fa enforcement del min(newCap, absoluteCap)
  final double maxTradeAmountCap;

  /// Percentuale massima di overage consentita per superare minNotional/minQty (es. 0.03 = +3%).
  /// Se 0, nessun overage consentito.
  final double maxBuyOveragePct;

  /// Se true, inibisce qualsiasi overage e richiede che tradeAmount sia sufficiente senza aggiustamenti.
  final bool strictBudget;

  /// Se true, anche con buyOnStart=true, viene rispettato il warmup iniziale prima del primo BUY.
  final bool buyOnStartRespectWarmup;

  /// Cooldown tra BUY consecutivi (initial o DCA), in secondi
  final double buyCooldownSeconds;

  /// Se true, la condizione DCA confronta il decremento vs averagePrice anziché lastBuyPrice
  final bool dcaCompareAgainstAverage;

  /// Numero massimo di cicli completi (compra→vendi→ricomincia) prima di fermarsi automaticamente.
  /// 0 = infinito.
  final int maxCycles;

  /// Se true, utilizza le fee reali di Binance per calcolare il profitto netto
  /// nelle decisioni di trading (take profit e stop loss).
  /// Se false, utilizza il calcolo tradizionale senza considerare le fee.
  final bool enableFeeAwareTrading;

  /// Se true, il bot riprende automaticamente ad acquistare dopo un ciclo
  /// completo (acquisto→vendita). Se false, dopo la vendita rimane in
  /// MONITORING_FOR_BUY senza effettuare nuovi acquisti.
  /// Default: false (comportamento conservativo).
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
    this.initialWarmupTicks = 1, //sufficiente per la strategia dca
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

  /// Costruttore di fabbrica per creare un'istanza con valori di default.
  factory AppSettings.initial() {
    return const AppSettings(
      tradeAmount: 56.0,
      profitTargetPercentage: 0.5,
      stopLossPercentage: 99.0,
      dcaDecrementPercentage: 0.77,
      maxOpenTrades: 100,
      isTestMode: false,
      buyOnStart: false,
      initialWarmupTicks: 1,
      initialWarmupSeconds: 0.0,
      initialSignalThresholdPct: 0.0,
      dcaCooldownSeconds: 3.0,
      dustRetryCooldownSeconds: 15.0,
      maxTradeAmountCap: 100.0,
      maxBuyOveragePct: 0.03,
      strictBudget: false,
      buyOnStartRespectWarmup: true,
      buyCooldownSeconds: 2.0,
      maxCycles: 0,
      enableFeeAwareTrading: true,
      enableReBuy: false,
    );
  }

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

  factory AppSettings.fromGrpc(grpc.Settings? s) {
    if (s == null) return AppSettings.initial();
    return AppSettings(
      tradeAmount: s.tradeAmount,
      fixedQuantity: s.fixedQuantityStr.isNotEmpty
          ? double.tryParse(s.fixedQuantityStr)
          : null,
      profitTargetPercentage: s.profitTargetPercentage,
      stopLossPercentage: s.stopLossPercentage,
      dcaDecrementPercentage: s.dcaDecrementPercentage,
      maxOpenTrades: s.maxOpenTrades,
      isTestMode: s.isTestMode,
      buyOnStart: s.buyOnStart,
      initialWarmupTicks: s.initialWarmupTicks,
      initialWarmupSeconds: double.tryParse(s.initialWarmupSecondsStr) ?? 0.0,
      initialSignalThresholdPct:
          double.tryParse(s.initialSignalThresholdPctStr) ?? 0.0,
      dcaCooldownSeconds: double.tryParse(s.dcaCooldownSecondsStr) ?? 3.0,
      dustRetryCooldownSeconds:
          double.tryParse(s.dustRetryCooldownSecondsStr) ?? 15.0,
      maxTradeAmountCap: double.tryParse(s.maxTradeAmountCapStr) ?? 100.0,
      maxBuyOveragePct: double.tryParse(s.maxBuyOveragePctStr) ?? 0.03,
      strictBudget: s.strictBudget,
      buyOnStartRespectWarmup: s.buyOnStartRespectWarmup,
      buyCooldownSeconds: double.tryParse(s.buyCooldownSecondsStr) ?? 2.0,
      dcaCompareAgainstAverage: s.dcaCompareAgainstAverage,
      maxCycles: s.maxCycles,
      enableFeeAwareTrading: s.enableFeeAwareTrading,
      enableReBuy: s.enableReBuy,
    );
  }
}
