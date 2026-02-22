import 'dart:async';
import 'dart:developer' as developer;
import 'package:neotradingbotfront1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_trading_repository.dart';
// Note: Ideally RunControlPrefs should be behind a Repository interface,
// but for this refactor we access it directly to limit scope drift.
import 'package:neotradingbotfront1777/core/config/run_control_prefs.dart';

class ManageStrategyRunControlUseCase {
  final ITradingRepository _tradingRepository;

  ManageStrategyRunControlUseCase(this._tradingRepository);

  Future<void> call(StrategyState newState) async {
    try {
      final symbol = newState.symbol;

      // Base round id: se non impostato (>0), inizializzalo al primo stato ricevuto
      var baseRoundId = await RunControlPrefs.getBaseRoundId(symbol);
      if (baseRoundId == null || baseRoundId <= 0) {
        await RunControlPrefs.setBaseRoundId(symbol, newState.currentRoundId);
        baseRoundId = newState.currentRoundId;
      }

      // Se STOP alla prossima vendita è attivo: quando currentRoundId avanza, invia STOP
      final stopAfterNext = await RunControlPrefs.getStopAfterNextSell(symbol);
      if (stopAfterNext) {
        if (newState.currentRoundId > baseRoundId) {
          // Reset flag e invia STOP una sola volta
          await RunControlPrefs.setStopAfterNextSell(symbol, false);
          // Non bloccare lo stream: invia comando asincrono lato repo
          unawaited(_tradingRepository.stopStrategy(symbol));
        }
      }

      // Controllo max cicli (0 = infinito): stop quando superiamo baseRoundId + maxCycles
      final maxCycles = await RunControlPrefs.getMaxCycles(symbol);
      if (maxCycles > 0 && newState.currentRoundId >= baseRoundId + maxCycles) {
        // Ferma e resetta baseRoundId per prossima sessione
        unawaited(_tradingRepository.stopStrategy(symbol));
        await RunControlPrefs.setBaseRoundId(symbol, newState.currentRoundId);
      }
    } catch (e, stackTrace) {
      // Log dell'errore per diagnostica — non deve mai crashare l'app.
      developer.log(
        'ManageStrategyRunControlUseCase: errore nella gestione run control',
        error: e,
        stackTrace: stackTrace,
        name: 'ManageStrategyRunControlUseCase',
      );
    }
  }
}
