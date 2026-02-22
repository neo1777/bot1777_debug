import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotback1777/domain/services/volatility_service.dart';
import 'package:neotradingbotback1777/domain/services/fee_calculation_service.dart';
import 'package:neotradingbotback1777/core/locks/trading_lock_manager.dart';
import 'package:neotradingbotback1777/core/errors/unified_error_handler.dart';
import 'package:neotradingbotback1777/core/monitoring/business_metrics_monitor.dart';
import 'package:meta/meta.dart';
import 'package:decimal/decimal.dart';
import 'package:rational/rational.dart';
import 'package:neotradingbotback1777/core/utils/decimal_utils.dart';
import 'package:neotradingbotback1777/core/utils/decimal_compare.dart';

import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';

import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:neotradingbotback1777/core/logging/log_throttler.dart';

/// Enum per definire la priorità delle decisioni di trading
/// per prevenire decisioni contraddittorie in mercati volatili
enum TradingDecisionPriority {
  /// Vendita (TP/SL) - Priorità massima
  sell,

  /// DCA - Priorità media
  dca,

  /// Acquisto iniziale - Priorità minima
  initialBuy,
}

/// Servizio di dominio puro che fornisce primitive di valutazione per il trading.
///
/// Nota architetturale: l'orchestrazione delle decisioni (warm‑up iniziale,
/// gating degli acquisti, DCA e tempi di esecuzione) è demandata al loop
/// atomico (`StartTradingLoopAtomic`). Questa classe espone funzioni pure
/// riusabili per verifiche puntuali; non mantiene stato e non dipende
/// dall'infrastruttura. In particolare:
/// - L'acquisto iniziale è valutato via `shouldBuyInitial` o
///   `shouldBuyGuarded(..., allowInitialBuy)` ed eseguito dal loop quando le
///   condizioni di warm‑up sono soddisfatte.
/// - La DCA è orchestrata dal loop in stato
///   `POSITION_OPEN_MONITORING_FOR_SELL`; per chiarezza è disponibile anche la
///   primitiva `shouldDcaBuy` che esprime la condizione DCA di base.
/// - La logica di vendita (TP/SL) è valutata da `shouldSell`.
class TradeEvaluatorService {
  final VolatilityService _volatilityService;
  final FeeCalculationService _feeCalculationService;
  final TradingLockManager _tradingLockManager;
  final LogThrottler _logThrottler;
  final UnifiedErrorHandler _errorHandler;
  final BusinessMetricsMonitor _businessMetricsMonitor;

  TradeEvaluatorService({
    required FeeCalculationService feeCalculationService,
    required TradingLockManager tradingLockManager,
    required UnifiedErrorHandler errorHandler,
    required BusinessMetricsMonitor businessMetricsMonitor,
    VolatilityService? volatilityService,
    LogThrottler? logThrottler,
  })  : _volatilityService = volatilityService ?? VolatilityService(),
        _feeCalculationService = feeCalculationService,
        _tradingLockManager = tradingLockManager,
        _errorHandler = errorHandler,
        _businessMetricsMonitor = businessMetricsMonitor,
        _logThrottler = logThrottler ?? GlobalLogThrottler.instance;

  bool _validateInputs(double currentPrice, AppStrategyState state) {
    if (state.hasInconsistencies) {
      throw const FormatException('Corrupted state: invalid trades detected');
    }

    if (!currentPrice.isFinite ||
        currentPrice < 0.00000001 ||
        currentPrice > 100000000000.0) {
      return false;
    }

    return true;
  }

  /// Valuta esplicitamente se effettuare il primissimo acquisto (bootstrap).
  ///
  /// Contratto: questa funzione è pensata per il SOLO acquisto iniziale,
  /// quando non esistono `openTrades`. Richiede che il chiamante fornisca
  /// l'esito di gating/warmup già valutato (es. tick/tempo/soglia di segnale).
  /// In assenza di warmup o se lo stato non è idoneo, ritorna `false`.
  bool shouldBuyInitial({
    required double currentPrice,
    required AppStrategyState state,
    required AppSettings settings,
    required bool warmupSatisfied,
  }) {
    if (state.status != StrategyState.MONITORING_FOR_BUY) return false;
    if (!state.isInitialState) return false;
    if (!warmupSatisfied) return false;
    if (!currentPrice.isFinite || currentPrice <= 0) return false;
    if (settings.maxOpenTrades <= 0) return false;
    return true;
  }

  /// Valuta se le condizioni per un acquisto sono soddisfatte (escludendo il caso iniziale).
  ///
  /// IMPORTANTE: questa funzione è intenzionalmente restrittiva e non abilita
  /// alcun acquisto in produzione; esiste come primitiva a scopo di test/unit
  /// per verifiche mirate. In produzione usare sempre `shouldBuyGuarded`
  /// combinato con le regole di warm‑up nel loop atomico.
  ///
  /// Nota di progettazione (invariante): questa funzione NON consente l'acquisto
  /// nello stato iniziale (nessun trade aperto). Il gating dell'acquisto iniziale
  /// è responsabilità dell'orchestrazione tramite [`shouldBuyGuarded`] e le regole
  /// di warmup/soglia nel loop. Ciò evita acquisti prematuri in caso di riuso improprio.
  ///
  /// Ritorna `true` se si deve procedere con un acquisto (non iniziale), altrimenti `false`.
  ///
  /// Nota: questa funzione è destinata esclusivamente ai test/unit per valutazioni
  /// mirate di condizioni non iniziali. In produzione utilizzare sempre
  /// `shouldBuyGuarded` che gestisce correttamente il caso iniziale e il warm‑up.
  @visibleForTesting
  bool shouldBuyNonInitial({
    required double currentPrice,
    required AppStrategyState state,
    required AppSettings settings,
  }) {
    // Invariante esplicita: questa API non è pensata per l'acquisto iniziale.
    // Gli assert sono attivi solo in debug e aiutano a prevenire riusi impropri.
    assert(!state.isInitialState,
        'Uso improprio: shouldBuyNonInitial() non abilita l\'acquisto iniziale. Usare shouldBuyGuarded(..., allowInitialBuy: true) e rispettare il warmup.');
    // Validazione difensiva per evitare segnali su dati corrotti
    if (!_validateInputs(currentPrice, state)) {
      return false;
    }

    // Enforcement del massimale di trade amount per sicurezza
    if (settings.tradeAmount > settings.maxTradeAmountCap) {
      return false;
    }

    // Non si può acquistare se non si è in stato di monitoraggio per acquisto
    // o se si è raggiunto il numero massimo di trade aperti.
    if (state.status != StrategyState.MONITORING_FOR_BUY ||
        state.openTrades.length >= settings.maxOpenTrades) {
      return false;
    }

    if (state.hasInconsistencies) {
      throw const FormatException('Corrupted state: invalid trades detected');
    }

    // In stato iniziale non si autorizza il BUY da questa funzione base.
    // L'acquisto iniziale è abilitabile solo via shouldBuyGuarded(allowInitialBuy: true)
    // in combinazione con il gating di warmup dell'orchestrazione.
    if (state.isInitialState) return false;

    // ========================
    // enableReBuy: ri-acquisto automatico dopo un ciclo completo
    // ========================
    // Se abilitato, consente un nuovo acquisto quando:
    // 1. Il flag enableReBuy è attivo nelle impostazioni
    // 2. Siamo in MONITORING_FOR_BUY (verificato sopra)
    // 3. Non ci troviamo nello stato iniziale (verificato sopra)
    // 4. Non abbiamo raggiunto il massimo di trade aperti (verificato sopra)
    //
    // Protezione anti-loop: il buyCooldown gestito dal loop atomico
    // previene acquisti troppo ravvicinati.
    if (settings.enableReBuy) {
      return true;
    }

    // Nota architetturale: il DCA è deliberatamente gestito esclusivamente
    // nel ramo POSITION_OPEN_MONITORING_FOR_SELL dal loop atomico. In
    // MONITORING_FOR_BUY non vengono mai effettuati acquisti incrementali.
    return false;
  }

  /// Variante "guardata" che gestisce in modo sicuro l'acquisto in stato iniziale
  /// a seconda del flag [allowInitialBuy].
  ///
  /// Questa API è sicura da usare in contesti dove non si applica la politica
  /// di warmup del loop: evita acquisti immediati su first tick.
  bool shouldBuyGuarded({
    required double currentPrice,
    required AppStrategyState state,
    required AppSettings settings,
    bool allowInitialBuy = false,
    double? availableBalance,
  }) {
    // Se siamo nello stato iniziale, l'esito dipende esplicitamente dal flag
    if (state.isInitialState) {
      // Validiamo comunque gli input per rilevare corruption sui parametri price/state
      if (!_validateInputs(currentPrice, state)) {
        return false;
      }

      // Anche per l'acquisto iniziale rispettiamo il cap di tradeAmount
      if (settings.tradeAmount > settings.maxTradeAmountCap) {
        return false;
      }

      // NUOVO: Verifica bilancio se fornito
      if (availableBalance != null && availableBalance < settings.tradeAmount) {
        return false;
      }

      return allowInitialBuy;
    }
    // Per tutti gli altri casi, demanda alla logica standard privata
    return shouldBuyNonInitial(
      currentPrice: currentPrice,
      state: state,
      settings: settings,
    );
  }

  /// Valuta se le condizioni per una vendita sono soddisfatte.
  ///
  /// Ritorna `true` se si deve procedere con una vendita, altrimenti `false`.
  bool shouldSell({
    required double currentPrice,
    required AppStrategyState state,
    required AppSettings settings,
    bool inDustCooldown = false,
  }) {
    // Aggiunta guardia difensiva per prezzi non validi
    if (!_validateInputs(currentPrice, state)) {
      return false;
    }

    // Non si può vendere se non si è in stato di monitoraggio per vendita
    // o se non ci sono posizioni aperte.
    if (state.status != StrategyState.POSITION_OPEN_MONITORING_FOR_SELL ||
        state.isInitialState) {
      return false;
    }

    // Se siamo in cooldown per DUST, non valutare la vendita
    if (inDustCooldown) {
      return false;
    }

    // Usa il prezzo medio pre-calcolato dall'entità stato (cachato)
    final averageBuyPrice = state.averagePrice;
    if (averageBuyPrice <= 0 || !averageBuyPrice.isFinite) {
      return false;
    }

    // Calcolo P/L percentuale in Decimal per robustezza
    final dCur = DecimalUtils.dFromDouble(currentPrice);
    final dAvg = DecimalUtils.dFromDouble(averageBuyPrice);
    if (dAvg == Decimal.zero) return false;
    final dynamic ratio = (dCur - dAvg) / dAvg;
    final Decimal ratioDec = ratio is Decimal
        ? ratio
        : (ratio as Rational)
            .toDecimal(scaleOnInfinitePrecision: DecimalUtils.defaultScale);
    final pnlPercentDec = ratioDec * Decimal.fromInt(100);

    // Validazione delle impostazioni per evitare dati corrotti
    if (!settings.profitTargetPercentage.isFinite ||
        !settings.stopLossPercentage.isFinite) {
      return false;
    }

    final tp = DecimalUtils.dFromDouble(settings.profitTargetPercentage);
    final sl = DecimalUtils.dFromDouble(settings.stopLossPercentage);

    // Take Profit
    if (pnlPercentDec.compareTo(tp) >= 0) {
      return true;
    }
    // Stop Loss (pnl <= -sl)
    if (pnlPercentDec.compareTo(-sl) <= 0) {
      return true;
    }

    return false;
  }

  /// Valuta se le condizioni per una vendita sono soddisfatte (CON FEE)
  Future<bool> shouldSellWithFees({
    required double currentPrice,
    required AppStrategyState state,
    required AppSettings settings,
    bool inDustCooldown = false,
  }) async {
    // Aggiunta guardia difensiva per prezzi non validi
    if (!currentPrice.isFinite || currentPrice <= 0) {
      return false;
    }

    // Non si può vendere se non si è in stato di monitoraggio per vendita
    // o se non ci sono posizioni aperte.
    if (state.status != StrategyState.POSITION_OPEN_MONITORING_FOR_SELL ||
        state.isInitialState) {
      return false;
    }

    // Se siamo in cooldown per DUST, non valutare la vendita
    if (inDustCooldown) {
      return false;
    }

    // Use pre-calculated average price from the state entity (cached)
    final averageBuyPrice = state.averagePrice;
    if (averageBuyPrice <= 0 || !averageBuyPrice.isFinite) {
      return false;
    }
    final totalQuantity = DecimalUtils.toDouble(state.totalQuantity);

    // Calcola P/L percentuale in Decimal per robustezza
    final dCur = DecimalUtils.dFromDouble(currentPrice);
    final dAvg = DecimalUtils.dFromDouble(averageBuyPrice);
    if (dAvg == Decimal.zero) return false;
    final dynamic ratio = (dCur - dAvg) / dAvg;
    final Decimal ratioDec = ratio is Decimal
        ? ratio
        : (ratio as Rational)
            .toDecimal(scaleOnInfinitePrecision: DecimalUtils.defaultScale);
    final pnlPercentDec = ratioDec * Decimal.fromInt(100);

    // Validazione delle impostazioni per evitare dati corrotti
    if (!settings.profitTargetPercentage.isFinite ||
        !settings.stopLossPercentage.isFinite) {
      return false;
    }

    final tp = DecimalUtils.dFromDouble(settings.profitTargetPercentage);
    final sl = DecimalUtils.dFromDouble(settings.stopLossPercentage);

    // Calcola profitto lordo in percentuale
    final grossProfitPercent = DecimalUtils.toDouble(pnlPercentDec);

    // Usa il servizio centralizzato per calcolare il profitto netto
    // Questo utilizzerà internamente il repository per ottenere le fee aggiornate o cachate
    final netProfitResult = await _feeCalculationService.calculateNetProfit(
      grossProfitPercent: grossProfitPercent,
      quantity: totalQuantity,
      price: currentPrice,
      symbol: state.symbol,
      isMaker: false, // Vendita è tipicamente taker
    );

    return netProfitResult.fold(
      (failure) {
        _logThrottler.logFeeCalculationThrottled(
            state.symbol, 'Failed to calculate net profit: ${failure.message}');
        // Fallback al calcolo senza fee
        return pnlPercentDec.compareTo(tp) >= 0 ||
            pnlPercentDec.compareTo(-sl) <= 0;
      },
      (netProfitPercent) {
        // Take Profit con fee considerate
        if (netProfitPercent >= settings.profitTargetPercentage) {
          return true;
        }
        // Stop Loss con fee considerate
        if (netProfitPercent <= -settings.stopLossPercentage) {
          return true;
        }
        return false;
      },
    );
  }

  /// Valuta la condizione DCA di base in funzione del decremento percentuale.
  ///
  /// [compareAgainstAverage]: se `true` il decremento è calcolato rispetto al
  /// prezzo medio (`validatedAveragePrice`), altrimenti rispetto all'ultimo prezzo di
  /// acquisto valido (`lastValidBuyPrice`). Questa funzione non applica cooldown né limiti
  /// di numero di trade: tali policy restano responsabilità dell'orchestrazione.
  bool shouldDcaBuy({
    required double currentPrice,
    required AppStrategyState state,
    required AppSettings settings,
    bool compareAgainstAverage = false,
    double? availableBalance,
  }) {
    // Validazione fondamentale: lo stato deve essere valido per DCA
    if (!state.isValidForDca) {
      return false;
    }

    if (state.status != StrategyState.POSITION_OPEN_MONITORING_FOR_SELL) {
      return false;
    }
    if (state.openTrades.length >= settings.maxOpenTrades) {
      return false;
    }

    // NUOVO: Rispettiamo il cap di tradeAmount anche per DCA (consistenza con shouldBuyGuarded)
    if (settings.tradeAmount > settings.maxTradeAmountCap) {
      return false;
    }

    // NUOVO: Verifica bilancio se fornito
    if (availableBalance != null && availableBalance < settings.tradeAmount) {
      return false;
    }

    // Utilizza i getter validati per evitare distorsioni dovute a trade falliti
    final referencePrice = compareAgainstAverage
        ? state.validatedAveragePrice
        : state.lastValidBuyPrice;

    if (!currentPrice.isFinite ||
        currentPrice <= 0 ||
        !referencePrice.isFinite ||
        referencePrice <= 0) {
      return false;
    }

    // Validazione delle impostazioni per evitare dati corrotti
    if (!settings.dcaDecrementPercentage.isFinite) {
      return false;
    }

    return DecimalCompare.percentDecrementReached(
      current: currentPrice,
      reference: referencePrice,
      thresholdPct: settings.dcaDecrementPercentage,
    );
  }

  /// Valuta tutte le decisioni di trading in ordine di priorità per prevenire
  /// decisioni contraddittorie in mercati volatili.
  ///
  /// Ritorna la decisione con priorità più alta, o null se nessuna azione è richiesta.
  TradingDecision? evaluateTradingDecisions({
    required double currentPrice,
    required AppStrategyState state,
    required AppSettings settings,
    bool allowInitialBuy = false,
  }) {
    // 1. PRIORITÀ MASSIMA: Valuta vendita (TP/SL)
    if (shouldSell(
      currentPrice: currentPrice,
      state: state,
      settings: settings,
    )) {
      return TradingDecision(
        action: TradingAction.sell,
        priority: TradingDecisionPriority.sell,
        reason: _determineSellReason(currentPrice, state, settings),
      );
    }

    // 2. PRIORITÀ MEDIA: Valuta DCA solo se non ci sono decisioni di vendita
    if (state.status == StrategyState.POSITION_OPEN_MONITORING_FOR_SELL &&
        shouldDcaBuy(
          currentPrice: currentPrice,
          state: state,
          settings: settings,
          compareAgainstAverage: settings.dcaCompareAgainstAverage,
        )) {
      return TradingDecision(
        action: TradingAction.dcaBuy,
        priority: TradingDecisionPriority.dca,
        reason:
            'DCA triggered: price dropped ${settings.dcaDecrementPercentage}% below reference',
      );
    }

    // 3. PRIORITÀ MINIMA: Valuta acquisto iniziale solo se non ci sono altre decisioni
    if (state.status == StrategyState.MONITORING_FOR_BUY &&
        shouldBuyGuarded(
          currentPrice: currentPrice,
          state: state,
          settings: settings,
          allowInitialBuy: allowInitialBuy,
        )) {
      return TradingDecision(
        action: TradingAction.initialBuy,
        priority: TradingDecisionPriority.initialBuy,
        reason: 'Initial buy conditions met',
      );
    }

    return null; // Nessuna azione richiesta
  }

  /// Valuta tutte le decisioni di trading con fee considerate (NUOVO METODO)
  Future<Either<Failure, TradingDecision?>> evaluateTradingDecisionsWithFees({
    required double currentPrice,
    required AppStrategyState state,
    required AppSettings settings,
    bool allowInitialBuy = false,
  }) async {
    return await _errorHandler.handleTradingOperation(
      () async {
        return await _tradingLockManager.executeTradingOperation(
          state.symbol,
          () async {
            // Validazione di consistenza post-acquisizione lock
            final currentState = await _validateStateConsistency(state);
            if (currentState == null) {
              LogManager.getLogger().w(
                  'State consistency validation failed for ${state.symbol}, skipping evaluation');
              return null;
            }

            // 1. PRIORITÀ MASSIMA: Valuta vendita (TP/SL) con fee
            final sellDecisionResult = await _evaluateSellDecisionWithFees(
              currentPrice: currentPrice,
              state: currentState,
              settings: settings,
            );

            if (sellDecisionResult.isRight()) {
              final sellDecision = sellDecisionResult.getOrElse((_) => null);
              if (sellDecision != null) {
                // Registra la decisione di trading
                _businessMetricsMonitor.recordTradingDecision(
                  currentState.symbol,
                  'SELL',
                  0.7, // Confidence media per vendita
                );
                return sellDecision;
              }
            }

            // 2. PRIORITÀ MEDIA: Valuta DCA solo se non ci sono decisioni di vendita
            if (currentState.status ==
                    StrategyState.POSITION_OPEN_MONITORING_FOR_SELL &&
                shouldDcaBuy(
                  currentPrice: currentPrice,
                  state: currentState,
                  settings: settings,
                  compareAgainstAverage: settings.dcaCompareAgainstAverage,
                )) {
              final dcaDecision = TradingDecision(
                action: TradingAction.dcaBuy,
                priority: TradingDecisionPriority.dca,
                reason:
                    'DCA triggered: price dropped ${settings.dcaDecrementPercentage}% below reference',
              );

              // Registra la decisione di trading
              _businessMetricsMonitor.recordTradingDecision(
                currentState.symbol,
                'DCA_BUY',
                0.8, // Confidence alta per DCA
              );

              return dcaDecision;
            }

            // 3. PRIORITÀ MINIMA: Valuta acquisto iniziale solo se non ci sono altre decisioni
            if (currentState.status == StrategyState.MONITORING_FOR_BUY &&
                shouldBuyGuarded(
                  currentPrice: currentPrice,
                  state: currentState,
                  settings: settings,
                  allowInitialBuy: allowInitialBuy,
                )) {
              final initialBuyDecision = TradingDecision(
                action: TradingAction.initialBuy,
                priority: TradingDecisionPriority.initialBuy,
                reason: 'Initial buy conditions met',
              );

              // Registra la decisione di trading
              _businessMetricsMonitor.recordTradingDecision(
                currentState.symbol,
                'INITIAL_BUY',
                0.9, // Confidence molto alta per acquisto iniziale
              );

              return initialBuyDecision;
            }

            return null; // Nessuna azione richiesta
          },
        );
      },
      operationName: 'evaluateTradingDecisionsWithFees',
      allowRetry: false, // Non retry per operazioni di trading critiche
    );
  }

  /// Valida la consistenza dello stato dopo l'acquisizione del lock
  Future<AppStrategyState?> _validateStateConsistency(
      AppStrategyState state) async {
    return (await _errorHandler.handleAsyncOperation(
      () async {
        // Verifica che lo stato sia ancora valido
        if (state.symbol.isEmpty) {
          throw const FormatException('Symbol is empty');
        }

        // Verifica che i trade aperti siano consistenti
        final validTrades = state.openTrades
            .where((trade) =>
                trade.price > Decimal.zero && trade.quantity > Decimal.zero)
            .toList();

        // Se ci sono trade non validi, filtra lo stato
        if (validTrades.length != state.openTrades.length) {
          LogManager.getLogger().w(
              'Found ${state.openTrades.length - validTrades.length} invalid trades in state for ${state.symbol}');

          // Crea un nuovo stato con solo i trade validi
          return state.copyWith(openTrades: validTrades);
        }

        return state;
      },
      operationName: 'validateStateConsistency',
    ))
        .fold(
      (failure) {
        LogManager.getLogger()
            .e('State consistency validation error: ${failure.message}');
        return null;
      },
      (validatedState) => validatedState,
    );
  }

  /// Valuta la volatilità del mercato e aggiorna lo stato di conseguenza
  ///
  /// Questo metodo implementa la logica di freeze del prezzo medio durante
  /// condizioni di alta volatilità per prevenire decisioni di trading errate
  AppStrategyState evaluateVolatilityAndUpdateState({
    required double currentPrice,
    required AppStrategyState state,
    required AppSettings settings,
  }) {
    // Aggiorna la cronologia prezzi
    final updatedState = state.updatePriceHistory(currentPrice);

    // Valuta se attivare o mantenere il freeze del prezzo
    if (_volatilityService.shouldFreezePrice(
      volatilityLevel: updatedState.currentVolatilityLevel,
      isCurrentlyFrozen: updatedState.isPriceFrozen,
      lastFreezeTime: updatedState.lastPriceFreezeTime,
    )) {
      // Se non è già congelato, congelalo
      if (!updatedState.isPriceFrozen) {
        return updatedState.freezePrice();
      }
      // Se è già congelato, mantienilo
      return updatedState;
    } else {
      // Se non dovrebbe essere congelato e attualmente lo è, sbloccalo
      if (updatedState.isPriceFrozen) {
        return updatedState.unfreezePrice();
      }
      // Se non è congelato, mantieni lo stato
      return updatedState;
    }
  }

  /// Determina il motivo specifico della vendita (TP o SL)
  String _determineSellReason(
      double currentPrice, AppStrategyState state, AppSettings settings) {
    if (state.isInitialState) return 'No open positions';

    // Utilizza il prezzo medio effettivo (congelato se necessario)
    final avgPrice = state.effectiveAveragePrice;

    if (avgPrice <= 0) return 'Invalid average price';

    final pnlPercent = ((currentPrice - avgPrice) / avgPrice) * 100;

    if (pnlPercent >= settings.profitTargetPercentage) {
      return 'Take Profit: +${pnlPercent.toStringAsFixed(2)}%';
    } else if (pnlPercent <= -settings.stopLossPercentage) {
      return 'Stop Loss: ${pnlPercent.toStringAsFixed(2)}%';
    }

    return 'Unknown sell reason';
  }

  /// Valuta la decisione di vendita con fee considerate
  Future<Either<Failure, TradingDecision?>> _evaluateSellDecisionWithFees({
    required double currentPrice,
    required AppStrategyState state,
    required AppSettings settings,
  }) async {
    return await _errorHandler.handleTradingOperation(
      () async {
        // Validazioni di base
        if (!currentPrice.isFinite || currentPrice <= 0) return null;
        if (state.status != StrategyState.POSITION_OPEN_MONITORING_FOR_SELL ||
            state.isInitialState) {
          return null;
        }

        // Usa il prezzo medio pre-calcolato dall'entità stato (cachato)
        final averageBuyPrice = state.averagePrice;
        if (averageBuyPrice <= 0 || !averageBuyPrice.isFinite) return null;

        final totalQuantity = DecimalUtils.toDouble(state.totalQuantity);

        // Calcola profitto lordo
        final grossProfitPercent =
            ((currentPrice - averageBuyPrice) / averageBuyPrice) * 100;

        // Calcola profitto netto usando il servizio centralizzato
        final netProfitResult = await _feeCalculationService.calculateNetProfit(
          grossProfitPercent: grossProfitPercent,
          quantity: totalQuantity,
          price: currentPrice,
          symbol: state.symbol,
          isMaker: false, // Vendita è tipicamente taker
        );

        return netProfitResult.fold(
          (failure) {
            _logThrottler.logFeeCalculationThrottled(state.symbol,
                'Failed to calculate net profit: ${failure.message}');
            // Fallback al calcolo senza fee
            if (grossProfitPercent >= settings.profitTargetPercentage ||
                grossProfitPercent <= -settings.stopLossPercentage) {
              return TradingDecision(
                action: TradingAction.sell,
                priority: TradingDecisionPriority.sell,
                reason: _determineSellReason(currentPrice, state, settings),
              );
            }
            return null;
          },
          (netProfitPercent) {
            // Take Profit con fee considerate
            if (netProfitPercent >= settings.profitTargetPercentage) {
              return TradingDecision(
                action: TradingAction.sell,
                priority: TradingDecisionPriority.sell,
                reason:
                    'Take Profit (Net): +${netProfitPercent.toStringAsFixed(2)}% (Gross: +${grossProfitPercent.toStringAsFixed(2)}%)',
              );
            }
            // Stop Loss con fee considerate
            if (netProfitPercent <= -settings.stopLossPercentage) {
              return TradingDecision(
                action: TradingAction.sell,
                priority: TradingDecisionPriority.sell,
                reason:
                    'Stop Loss (Net): ${netProfitPercent.toStringAsFixed(2)}% (Gross: ${grossProfitPercent.toStringAsFixed(2)}%)',
              );
            }
            return null;
          },
        );
      },
      operationName: '_evaluateSellDecisionWithFees',
      allowRetry: false,
    );
  }
}

/// Rappresenta una decisione di trading con priorità e motivazione
class TradingDecision {
  final TradingAction action;
  final TradingDecisionPriority priority;
  final String reason;
  final DateTime timestamp;

  TradingDecision({
    required this.action,
    required this.priority,
    required this.reason,
  }) : timestamp = DateTime.now();

  @override
  String toString() {
    return 'TradingDecision(${action.name}, ${priority.name}, "$reason", $timestamp)';
  }
}

/// Enum per le azioni di trading disponibili
enum TradingAction {
  sell,
  dcaBuy,
  initialBuy,
}
