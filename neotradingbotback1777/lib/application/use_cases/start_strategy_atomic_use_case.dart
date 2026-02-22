import 'dart:async';
import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart'; // FIX BUG #8: Logger per rollback
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/application/managers/trading_loop_manager.dart';
import 'package:neotradingbotback1777/application/managers/atomic_state_manager.dart';

import 'package:neotradingbotback1777/core/errors/unified_error_handler.dart';

/// Versione atomica del caso d'uso per avviare una strategia di trading.
/// Utilizza AtomicStateManager per prevenire race conditions.
class StartStrategyAtomic {
  final TradingLoopManager _tradingLoopManager;
  final AtomicStateManager _stateManager;
  final UnifiedErrorHandler _errorHandler;
  final _logger = LogManager.getLogger();

  StartStrategyAtomic(this._tradingLoopManager, this._stateManager,
      [UnifiedErrorHandler? errorHandler])
      : _errorHandler = errorHandler ?? GlobalUnifiedErrorHandler.instance;

  /// Avvia una strategia di trading in modo atomico per il simbolo specificato.
  ///
  /// [symbol] Il simbolo da tradare (es. "BTCUSDC")
  /// [settings] Le impostazioni di trading da applicare
  ///
  /// Returns: Either&lt;Failure, void&gt;
  Future<Either<Failure, void>> call({
    required String symbol,
    required AppSettings settings,
  }) async {
    return _errorHandler.handleAsyncOperation(
      () async {
        _logger.i('Tentativo di avvio strategia per il simbolo: $symbol');

        // Esegue l'operazione atomicamente utilizzando l'AtomicStateManager
        final result = await _stateManager.executeAtomicOperation(
          symbol,
          (currentState) async {
            final nextStatus = currentState.openTrades.isNotEmpty
                ? StrategyState.POSITION_OPEN_MONITORING_FOR_SELL
                : StrategyState.IDLE;
            final activeState = currentState.copyWith(status: nextStatus);
            return Right(activeState);
          },
        );

        return await result.fold(
          (failure) async {
            _logger.e('Fallimento atomico per $symbol: $failure');
            throw failure;
          },
          (updatedState) async {
            bool started = false;
            try {
              started = await _tradingLoopManager.startAtomicLoopForSymbol(
                symbol,
                settings,
                updatedState,
              );
            } catch (e) {
              _logger.e('Eccezione durante startAtomicLoop: $e');
              rethrow;
            }

            if (!started) {
              await _tradingLoopManager.stopAndRemoveLoop(symbol);
              await _stateManager.forceUpdateState(
                updatedState.copyWith(status: StrategyState.IDLE),
              );
              throw BusinessLogicFailure(
                message: 'LOOP_START_FAILED per $symbol',
              );
            }

            _logger.i('Strategia per $symbol avviata.');
            return null;
          },
        );
      },
      operationName: 'StartStrategyAtomic',
    );
  }
}
