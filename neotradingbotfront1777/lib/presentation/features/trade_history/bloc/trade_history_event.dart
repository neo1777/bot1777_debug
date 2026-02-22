import 'package:equatable/equatable.dart';
import 'package:neotradingbotfront1777/domain/entities/app_trade.dart';

abstract class TradeHistoryEvent extends Equatable {
  const TradeHistoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadTradeHistory extends TradeHistoryEvent {
  const LoadTradeHistory();
}

class SubscribeToTradeHistory extends TradeHistoryEvent {
  const SubscribeToTradeHistory();
}

class FilterTradesBySymbol extends TradeHistoryEvent {
  const FilterTradesBySymbol(this.symbol);

  final String? symbol;

  @override
  List<Object?> get props => [symbol];
}

class FilterTradesByType extends TradeHistoryEvent {
  const FilterTradesByType(this.isBuy);

  final bool? isBuy;

  @override
  List<Object?> get props => [isBuy];
}

class FilterTradesByDateRange extends TradeHistoryEvent {
  const FilterTradesByDateRange({
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;
  final DateTime endDate;

  @override
  List<Object?> get props => [startDate, endDate];
}

class ClearFilters extends TradeHistoryEvent {
  const ClearFilters();
}

class RefreshTradeHistory extends TradeHistoryEvent {
  const RefreshTradeHistory();
}

class TradeHistoryUpdated extends TradeHistoryEvent {
  const TradeHistoryUpdated(this.trade);
  final AppTrade trade;

  @override
  List<Object?> get props => [trade];
}
