import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neotradingbotfront1777/domain/entities/app_trade.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_trade_history_repository.dart';
import 'package:neotradingbotfront1777/presentation/features/trade_history/bloc/trade_history_event.dart';
import 'package:neotradingbotfront1777/presentation/features/trade_history/bloc/trade_history_state.dart';

class TradeHistoryBloc extends Bloc<TradeHistoryEvent, TradeHistoryState> {
  final ITradeHistoryRepository _tradeHistoryRepository;
  StreamSubscription<AppTrade>? _tradeHistorySubscription;

  TradeHistoryBloc({required ITradeHistoryRepository tradeHistoryRepository})
    : _tradeHistoryRepository = tradeHistoryRepository,
      super(const TradeHistoryInitial()) {
    on<LoadTradeHistory>(_onLoadTradeHistory);
    on<SubscribeToTradeHistory>(_onSubscribeToTradeHistory);
    on<TradeHistoryUpdated>(_onTradeHistoryUpdated);
    on<FilterTradesBySymbol>(_onFilterTradesBySymbol);
    on<FilterTradesByType>(_onFilterTradesByType);
    on<FilterTradesByDateRange>(_onFilterTradesByDateRange);
    on<ClearFilters>(_onClearFilters);
    on<RefreshTradeHistory>(_onRefreshTradeHistory);
  }

  @override
  Future<void> close() {
    _tradeHistorySubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadTradeHistory(
    LoadTradeHistory event,
    Emitter<TradeHistoryState> emit,
  ) async {
    emit(const TradeHistoryLoading());

    final result = await _tradeHistoryRepository.getTradeHistory();

    result.fold((failure) => emit(TradeHistoryError(failure.message)), (
      trades,
    ) {
      emit(TradeHistoryLoaded(trades: trades, filteredTrades: trades));
      // Automatically subscribe after loading initial data
      add(const SubscribeToTradeHistory());
    });
  }

  void _onSubscribeToTradeHistory(
    SubscribeToTradeHistory event,
    Emitter<TradeHistoryState> emit,
  ) {
    final currentState = state;
    if (currentState is TradeHistoryLoaded && !currentState.isStreaming) {
      emit(currentState.copyWith(isStreaming: true));
      _tradeHistorySubscription?.cancel();
      final streamResult = _tradeHistoryRepository.subscribeToTradeHistory();

      streamResult.fold((failure) => emit(TradeHistoryError(failure.message)), (
        stream,
      ) {
        _tradeHistorySubscription = stream.listen((trade) {
          add(TradeHistoryUpdated(trade));
        }, onError: (error) => emit(TradeHistoryError(error.toString())));
      });
    }
  }

  void _onTradeHistoryUpdated(
    TradeHistoryUpdated event,
    Emitter<TradeHistoryState> emit,
  ) {
    final currentState = state;
    if (currentState is TradeHistoryLoaded) {
      final updatedTrades = [event.trade, ...currentState.trades];
      final filteredTrades = _applyFilters(
        updatedTrades,
        currentState.symbolFilter,
        currentState.typeFilter,
        currentState.startDateFilter,
        currentState.endDateFilter,
      );
      emit(
        currentState.copyWith(
          trades: updatedTrades,
          filteredTrades: filteredTrades,
        ),
      );
    }
  }

  Future<void> _onFilterTradesBySymbol(
    FilterTradesBySymbol event,
    Emitter<TradeHistoryState> emit,
  ) async {
    final currentState = state;
    if (currentState is TradeHistoryLoaded) {
      final filteredTrades = _applyFilters(
        currentState.trades,
        event.symbol,
        currentState.typeFilter,
        currentState.startDateFilter,
        currentState.endDateFilter,
      );

      emit(
        currentState.copyWith(
          symbolFilter: event.symbol,
          filteredTrades: filteredTrades,
        ),
      );
    }
  }

  Future<void> _onFilterTradesByType(
    FilterTradesByType event,
    Emitter<TradeHistoryState> emit,
  ) async {
    final currentState = state;
    if (currentState is TradeHistoryLoaded) {
      final filteredTrades = _applyFilters(
        currentState.trades,
        currentState.symbolFilter,
        event.isBuy,
        currentState.startDateFilter,
        currentState.endDateFilter,
      );

      emit(
        currentState.copyWith(
          typeFilter: event.isBuy,
          filteredTrades: filteredTrades,
        ),
      );
    }
  }

  Future<void> _onFilterTradesByDateRange(
    FilterTradesByDateRange event,
    Emitter<TradeHistoryState> emit,
  ) async {
    final currentState = state;
    if (currentState is TradeHistoryLoaded) {
      final filteredTrades = _applyFilters(
        currentState.trades,
        currentState.symbolFilter,
        currentState.typeFilter,
        event.startDate,
        event.endDate,
      );

      emit(
        currentState.copyWith(
          startDateFilter: event.startDate,
          endDateFilter: event.endDate,
          filteredTrades: filteredTrades,
        ),
      );
    }
  }

  Future<void> _onClearFilters(
    ClearFilters event,
    Emitter<TradeHistoryState> emit,
  ) async {
    final currentState = state;
    if (currentState is TradeHistoryLoaded) {
      emit(
        currentState.copyWith(
          symbolFilter: null,
          typeFilter: null,
          startDateFilter: null,
          endDateFilter: null,
          filteredTrades: currentState.trades,
        ),
      );
    }
  }

  Future<void> _onRefreshTradeHistory(
    RefreshTradeHistory event,
    Emitter<TradeHistoryState> emit,
  ) async {
    add(const LoadTradeHistory());
  }

  List<AppTrade> _applyFilters(
    List<AppTrade> trades,
    String? symbolFilter,
    bool? typeFilter,
    DateTime? startDateFilter,
    DateTime? endDateFilter,
  ) {
    var filtered = trades.toList();

    if (symbolFilter != null && symbolFilter.isNotEmpty) {
      filtered =
          filtered.where((trade) => trade.symbol == symbolFilter).toList();
    }

    if (typeFilter != null) {
      filtered = filtered.where((trade) => trade.isBuy == typeFilter).toList();
    }

    if (startDateFilter != null) {
      filtered =
          filtered
              .where(
                (trade) =>
                    trade.timestamp.isAfter(startDateFilter) ||
                    trade.timestamp.isAtSameMomentAs(startDateFilter),
              )
              .toList();
    }

    if (endDateFilter != null) {
      filtered =
          filtered
              .where(
                (trade) =>
                    trade.timestamp.isBefore(endDateFilter) ||
                    trade.timestamp.isAtSameMomentAs(endDateFilter),
              )
              .toList();
    }

    // Sort by timestamp descending (newest first)
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return filtered;
  }
}
