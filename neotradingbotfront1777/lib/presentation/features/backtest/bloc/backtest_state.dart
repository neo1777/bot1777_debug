import 'package:equatable/equatable.dart';
import 'package:neotradingbotfront1777/domain/entities/backtest_result.dart';

abstract class BacktestState extends Equatable {
  const BacktestState();

  @override
  List<Object?> get props => [];
}

class BacktestInitial extends BacktestState {}

class BacktestLoading extends BacktestState {}

class BacktestRunning extends BacktestState {
  final String backtestId;
  const BacktestRunning(this.backtestId);

  @override
  List<Object?> get props => [backtestId];
}

class BacktestLoaded extends BacktestState {
  final BacktestResult result;

  const BacktestLoaded(this.result);

  @override
  List<Object?> get props => [result];
}

class BacktestError extends BacktestState {
  final String message;

  const BacktestError(this.message);

  @override
  List<Object?> get props => [message];
}
