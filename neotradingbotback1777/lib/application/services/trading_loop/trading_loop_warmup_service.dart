import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';

class TradingLoopWarmupService {
  final _log = LogManager.getLogger();

  int _tickCount = 0;
  DateTime? _startTime;
  double? _firstObservedPrice;
  double? _lastProcessedPrice;

  void reset() {
    _tickCount = 0;
    _startTime = DateTime.now();
    _firstObservedPrice = null;
    _lastProcessedPrice = null;
  }

  void onPriceUpdate(double currentPrice) {
    _lastProcessedPrice = currentPrice;
    _firstObservedPrice ??= currentPrice;
    _tickCount++;
  }

  bool canTriggerInitialBuy(AppSettings settings) {
    // Se buyOnStart e non richiesto il rispetto del warmup, consenti BUY immediato
    if (settings.buyOnStart && !settings.buyOnStartRespectWarmup) {
      return true;
    }

    // Se l'utente ha disattivato buyOnStart occorre che almeno UNA condizione di warm‑up/soglia sia abilitata,
    // altrimenti il primo BUY sarebbe consentito immediatamente.
    final hasWarmupRequirement = (settings.initialWarmupTicks > 0) ||
        (settings.initialWarmupSeconds > 0) ||
        (settings.initialSignalThresholdPct > 0);

    if (!hasWarmupRequirement) {
      // Config non valida per l'avvio ritardato: blocca sempre l'acquisto iniziale
      return false;
    }

    // Warm‑up basato su tick
    final ticksOk = _tickCount >= settings.initialWarmupTicks;

    // Warm‑up basato sul tempo
    final timeOk = _startTime != null &&
        DateTime.now().difference(_startTime!).inMilliseconds >=
            (settings.initialWarmupSeconds * 1000).round();

    // Soglia di segnale (variazione percentuale dal primo prezzo osservato)
    var signalOk = true;
    if (settings.initialSignalThresholdPct > 0 &&
        _firstObservedPrice != null &&
        _lastProcessedPrice != null) {
      final pct = ((_lastProcessedPrice! - _firstObservedPrice!) /
              _firstObservedPrice!) *
          100;
      signalOk = pct.abs() >= settings.initialSignalThresholdPct;
    }

    if ((ticksOk || timeOk) && signalOk) {
      _log.d(
          'Warmup condition met: ticks=$ticksOk (${_tickCount}/${settings.initialWarmupTicks}), time=$timeOk, signal=$signalOk');
    }

    // Richiedi warm‑up tick o tempo AND la soglia di segnale quando attiva
    return (ticksOk || timeOk) && signalOk;
  }
}
