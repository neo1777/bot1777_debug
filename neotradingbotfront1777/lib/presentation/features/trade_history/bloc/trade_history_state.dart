import 'package:equatable/equatable.dart';
import 'package:neotradingbotfront1777/domain/entities/app_trade.dart';

abstract class TradeHistoryState extends Equatable {
  const TradeHistoryState();

  @override
  List<Object?> get props => [];
}

class TradeHistoryInitial extends TradeHistoryState {
  const TradeHistoryInitial();
}

class TradeHistoryLoading extends TradeHistoryState {
  const TradeHistoryLoading();
}

class TradeHistoryLoaded extends TradeHistoryState {
  const TradeHistoryLoaded({
    required this.trades,
    required this.filteredTrades,
    this.symbolFilter,
    this.typeFilter,
    this.startDateFilter,
    this.endDateFilter,
    this.isStreaming = false,
  });

  final List<AppTrade> trades;
  final List<AppTrade> filteredTrades;
  final String? symbolFilter;
  final bool? typeFilter;
  final DateTime? startDateFilter;
  final DateTime? endDateFilter;
  final bool isStreaming;

  // Calculated properties
  double get totalProfit {
    return filteredTrades.fold(0.0, (sum, trade) {
      // Prioritize explicit profit field if available, otherwise fallback to balance delta
      return sum +
          (trade.profit ??
              (trade.isBuy ? -trade.totalValue : trade.totalValue));
    });
  }

  int get totalTrades => filteredTrades.length;

  int get buyTrades => filteredTrades.where((trade) => trade.isBuy).length;

  int get sellTrades => filteredTrades.where((trade) => !trade.isBuy).length;

  double get totalVolume {
    return filteredTrades.fold(0.0, (sum, trade) => sum + trade.totalValue);
  }

  List<String> get symbols {
    return filteredTrades.map((trade) => trade.symbol).toSet().toList()..sort();
  }

  @override
  List<Object?> get props => [
    trades,
    filteredTrades,
    symbolFilter,
    typeFilter,
    startDateFilter,
    endDateFilter,
    isStreaming,
  ];

  static const _sentinel = _Sentinel();

  TradeHistoryLoaded copyWith({
    List<AppTrade>? trades,
    List<AppTrade>? filteredTrades,
    Object? symbolFilter = _sentinel,
    Object? typeFilter = _sentinel,
    Object? startDateFilter = _sentinel,
    Object? endDateFilter = _sentinel,
    bool? isStreaming,
  }) {
    return TradeHistoryLoaded(
      trades: trades ?? this.trades,
      filteredTrades: filteredTrades ?? this.filteredTrades,
      symbolFilter:
          identical(symbolFilter, _sentinel)
              ? this.symbolFilter
              : symbolFilter as String?,
      typeFilter:
          identical(typeFilter, _sentinel)
              ? this.typeFilter
              : typeFilter as bool?,
      startDateFilter:
          identical(startDateFilter, _sentinel)
              ? this.startDateFilter
              : startDateFilter as DateTime?,
      endDateFilter:
          identical(endDateFilter, _sentinel)
              ? this.endDateFilter
              : endDateFilter as DateTime?,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}

/// Private sentinel class to distinguish "not provided" from `null`.
class _Sentinel {
  const _Sentinel();
}

class TradeHistoryError extends TradeHistoryState {
  const TradeHistoryError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
