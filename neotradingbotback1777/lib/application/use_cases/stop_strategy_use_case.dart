import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/strategy_state_repository.dart';
import 'package:neotradingbotback1777/application/managers/trading_loop_manager.dart';

class StopStrategy {
  final StrategyStateRepository _strategyStateRepository;
  final TradingLoopManager _tradingLoopManager;

  StopStrategy(this._strategyStateRepository, this._tradingLoopManager);

  Future<Either<Failure, void>> call({required String symbol}) async {
    try {
      // Ferma il loop di ascolto dei prezzi
      await _tradingLoopManager.stopAndRemoveLoop(symbol);

      // Aggiorna lo stato su disco
      final stateResult =
          await _strategyStateRepository.getStrategyState(symbol);
      return await stateResult.fold(
        (failure) => Left(failure),
        (state) async {
          if (state != null) {
            // Imposta lo stato su 'idle' per fermare la strategia
            final inactiveState = state.copyWith(status: StrategyState.IDLE);
            await _strategyStateRepository.saveStrategyState(inactiveState);
          }
          return const Right(null);
        },
      );
    } catch (e) {
      return Left(UnexpectedFailure(
          message: 'Errore durante l\'arresto della strategia: $e'));
    }
  }
}
