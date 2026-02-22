import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/strategy_state_repository.dart';

class ResumeTrading {
  final StrategyStateRepository _repository;
  ResumeTrading(this._repository);

  Future<Either<Failure, void>> call({required String symbol}) async {
    final stateResult = await _repository.getStrategyState(symbol);
    return stateResult.fold(
      (l) => Left(l),
      (state) async {
        if (state == null) {
          return Left(ValidationFailure(
              message: 'Nessuna strategia trovata per il simbolo $symbol'));
        }

        // Se la strategia non è PAUSED, segnala errore di validazione
        if (state.status != StrategyState.PAUSED) {
          return Left(ValidationFailure(
              message:
                  'Resume non applicabile: lo stato corrente è ${state.status.name}, atteso PAUSED'));
        }

        // Determina lo stato corretto in cui tornare
        final newState = state.isInitialState
            ? StrategyState.MONITORING_FOR_BUY
            : StrategyState.POSITION_OPEN_MONITORING_FOR_SELL;

        final resumedState = state.copyWith(status: newState);
        return await _repository.saveStrategyState(resumedState);
      },
    );
  }
}
