import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/strategy_state_repository.dart';

class GetStrategyState {
  final StrategyStateRepository _repository;
  GetStrategyState(this._repository);

  Future<Either<Failure, AppStrategyState?>> call({required String symbol}) {
    return _repository.getStrategyState(symbol);
  }
}
