part of 'strategy_state_bloc.dart';

enum StrategyStateStatus { initial, loading, subscribed, failure }

class StrategyStateState extends Equatable {
  const StrategyStateState({
    this.status = StrategyStateStatus.initial,
    this.strategyState,
    this.currentSymbol = '',
    this.failureMessage,
  });

  final StrategyStateStatus status;
  final StrategyState? strategyState;
  final String currentSymbol;
  final String? failureMessage;

  StrategyStateState copyWith({
    StrategyStateStatus? status,
    StrategyState? strategyState,
    String? currentSymbol,
    String? failureMessage,
  }) {
    return StrategyStateState(
      status: status ?? this.status,
      strategyState: strategyState ?? this.strategyState,
      currentSymbol: currentSymbol ?? this.currentSymbol,
      failureMessage: failureMessage ?? this.failureMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    strategyState,
    currentSymbol,
    failureMessage,
  ];
}
