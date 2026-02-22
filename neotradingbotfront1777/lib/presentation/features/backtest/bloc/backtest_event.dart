import 'package:equatable/equatable.dart';

abstract class BacktestEvent extends Equatable {
  const BacktestEvent();

  @override
  List<Object?> get props => [];
}

class StartBacktest extends BacktestEvent {
  final String symbol;
  final String interval;
  final int period;
  final String strategyName;

  const StartBacktest({
    required this.symbol,
    required this.interval,
    required this.period,
    required this.strategyName,
  });

  @override
  List<Object?> get props => [symbol, interval, period, strategyName];
}
