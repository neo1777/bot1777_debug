import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/strategy_state_repository.dart';

class PauseTrading {
  final StrategyStateRepository _repository;
  PauseTrading(this._repository);

  Future<Either<Failure, void>> call({required String symbol}) async {
    final stateResult = await _repository.getStrategyState(symbol);
    return stateResult.fold(
      (l) => Left(l),
      (state) async {
        if (state == null) {
          return Left(ValidationFailure(
              message: 'Nessuna strategia trovata per il simbolo $symbol'));
        }
        // Imposta lo stato su 'paused' per sospendere il trading
        final pausedState = state.copyWith(status: StrategyState.PAUSED);
        return await _repository.saveStrategyState(pausedState);
      },
    );
  }
}
