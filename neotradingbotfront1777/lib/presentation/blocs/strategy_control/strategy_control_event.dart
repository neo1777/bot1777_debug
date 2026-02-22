part of 'strategy_control_bloc.dart';

abstract class StrategyControlEvent extends Equatable {
  const StrategyControlEvent();

  @override
  List<Object> get props => [];
}

class StartStrategyRequested extends StrategyControlEvent {
  const StartStrategyRequested(this.symbol);
  final String symbol;

  @override
  List<Object> get props => [symbol];
}

class StopStrategyRequested extends StrategyControlEvent {
  const StopStrategyRequested(this.symbol);
  final String symbol;

  @override
  List<Object> get props => [symbol];
}

class PauseStrategyRequested extends StrategyControlEvent {
  const PauseStrategyRequested(this.symbol);
  final String symbol;

  @override
  List<Object> get props => [symbol];
}

class ResumeStrategyRequested extends StrategyControlEvent {
  const ResumeStrategyRequested(this.symbol);
  final String symbol;

  @override
  List<Object> get props => [symbol];
}

class StatusReportRequested extends StrategyControlEvent {
  const StatusReportRequested();
}
