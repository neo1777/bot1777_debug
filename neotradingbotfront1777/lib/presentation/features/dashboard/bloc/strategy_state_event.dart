part of 'strategy_state_bloc.dart';

abstract class StrategyStateEvent extends Equatable {
  const StrategyStateEvent();

  @override
  List<Object> get props => [];
}

class StrategyStateSubscriptionRequested extends StrategyStateEvent {
  const StrategyStateSubscriptionRequested(this.symbol);
  final String symbol;

  @override
  List<Object> get props => [symbol];
}

class _StrategyStateUpdated extends StrategyStateEvent {
  const _StrategyStateUpdated(this.state);
  final StrategyState state;

  @override
  List<Object> get props => [state];
}

class _StrategyStateStreamFailed extends StrategyStateEvent {
  const _StrategyStateStreamFailed(this.errorMessage);
  final String errorMessage;

  @override
  List<Object> get props => [errorMessage];
}

class SymbolChanged extends StrategyStateEvent {
  const SymbolChanged(this.symbol);
  final String symbol;

  @override
  List<Object> get props => [symbol];
}
