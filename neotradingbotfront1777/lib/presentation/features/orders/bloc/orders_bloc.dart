import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neotradingbotfront1777/domain/entities/order_status.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_orders_repository.dart';
import 'package:neotradingbotfront1777/presentation/features/orders/bloc/orders_event.dart';
import 'package:neotradingbotfront1777/presentation/features/orders/bloc/orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final IOrdersRepository _ordersRepository;

  OrdersBloc({required IOrdersRepository ordersRepository})
    : _ordersRepository = ordersRepository,
      super(const OrdersInitial()) {
    on<LoadOpenOrders>(_onLoadOpenOrders);
    on<LoadSymbolLimits>(_onLoadSymbolLimits);
    on<RefreshOrders>(_onRefreshOrders);
    on<FilterOrdersByType>(_onFilterOrdersByType);
    on<FilterOrdersBySide>(_onFilterOrdersBySide);
    on<FilterOrdersByStatus>(_onFilterOrdersByStatus);
    on<ClearOrderFilters>(_onClearOrderFilters);
    on<SortOrders>(_onSortOrders);
    on<CancelOrder>(_onCancelOrder);
    on<CancelAllOrders>(_onCancelAllOrders);
  }

  Future<void> _onLoadOpenOrders(
    LoadOpenOrders event,
    Emitter<OrdersState> emit,
  ) async {
    emit(const OrdersLoading());

    final ordersResult = await _ordersRepository.getOpenOrders(event.symbol);
    final limitsResult = await _ordersRepository.getSymbolLimits(event.symbol);

    ordersResult.fold((failure) => emit(OrdersError(failure.message)), (
      orders,
    ) {
      limitsResult.fold(
        (failure) {
          // Even if limits fail, we can still show orders
          emit(
            OrdersLoaded(
              orders: orders,
              filteredOrders: orders,
              currentSymbol: event.symbol,
            ),
          );
        },
        (limits) {
          emit(
            OrdersLoaded(
              orders: orders,
              filteredOrders: orders,
              symbolLimits: limits,
              currentSymbol: event.symbol,
            ),
          );
        },
      );
    });
  }

  Future<void> _onLoadSymbolLimits(
    LoadSymbolLimits event,
    Emitter<OrdersState> emit,
  ) async {
    final currentState = state;
    if (currentState is OrdersLoaded) {
      final result = await _ordersRepository.getSymbolLimits(event.symbol);

      result.fold(
        (failure) {
          // Log errore caricamento limiti simbolo per diagnostica
          // ignore: avoid_print
          print(
            '[OrdersBloc] Failed to load symbol limits for ${event.symbol}: ${failure.message}',
          );
        },
        (limits) {
          emit(
            currentState.copyWith(
              symbolLimits: limits,
              currentSymbol: event.symbol,
            ),
          );
        },
      );
    }
  }

  Future<void> _onRefreshOrders(
    RefreshOrders event,
    Emitter<OrdersState> emit,
  ) async {
    final currentState = state;
    if (currentState is OrdersLoaded && currentState.currentSymbol != null) {
      add(LoadOpenOrders(currentState.currentSymbol!));
    }
  }

  Future<void> _onFilterOrdersByType(
    FilterOrdersByType event,
    Emitter<OrdersState> emit,
  ) async {
    final currentState = state;
    if (currentState is OrdersLoaded) {
      final filteredOrders = _applyFilters(
        currentState.orders,
        event.orderType,
        currentState.sideFilter,
        currentState.statusFilter,
      );

      emit(
        currentState.copyWith(
          typeFilter: event.orderType,
          filteredOrders: filteredOrders,
        ),
      );
    }
  }

  Future<void> _onFilterOrdersBySide(
    FilterOrdersBySide event,
    Emitter<OrdersState> emit,
  ) async {
    final currentState = state;
    if (currentState is OrdersLoaded) {
      final filteredOrders = _applyFilters(
        currentState.orders,
        currentState.typeFilter,
        event.side,
        currentState.statusFilter,
      );

      emit(
        currentState.copyWith(
          sideFilter: event.side,
          filteredOrders: filteredOrders,
        ),
      );
    }
  }

  Future<void> _onFilterOrdersByStatus(
    FilterOrdersByStatus event,
    Emitter<OrdersState> emit,
  ) async {
    final currentState = state;
    if (currentState is OrdersLoaded) {
      final filteredOrders = _applyFilters(
        currentState.orders,
        currentState.typeFilter,
        currentState.sideFilter,
        event.status,
      );

      emit(
        currentState.copyWith(
          statusFilter: event.status,
          filteredOrders: filteredOrders,
        ),
      );
    }
  }

  Future<void> _onClearOrderFilters(
    ClearOrderFilters event,
    Emitter<OrdersState> emit,
  ) async {
    final currentState = state;
    if (currentState is OrdersLoaded) {
      emit(
        OrdersLoaded(
          orders: currentState.orders,
          filteredOrders: currentState.orders,
          symbolLimits: currentState.symbolLimits,
          currentSymbol: currentState.currentSymbol,
          sortType: currentState.sortType,
          typeFilter: null,
          sideFilter: null,
          statusFilter: null,
        ),
      );
    }
  }

  List<OrderStatus> _applyFilters(
    List<OrderStatus> orders,
    String? typeFilter,
    String? sideFilter,
    String? statusFilter,
  ) {
    var filtered = orders.toList();

    if (typeFilter != null && typeFilter.isNotEmpty) {
      filtered = filtered.where((order) => order.type == typeFilter).toList();
    }

    if (sideFilter != null && sideFilter.isNotEmpty) {
      filtered = filtered.where((order) => order.side == sideFilter).toList();
    }

    if (statusFilter != null && statusFilter.isNotEmpty) {
      filtered =
          filtered.where((order) => order.status == statusFilter).toList();
    }

    return filtered;
  }

  void _onSortOrders(SortOrders event, Emitter<OrdersState> emit) {
    final currentState = state;
    if (currentState is! OrdersLoaded) return;

    final sortedOrders = _applySorting(
      currentState.filteredOrders,
      event.sortType,
    );

    emit(
      currentState.copyWith(
        filteredOrders: sortedOrders,
        sortType: event.sortType,
      ),
    );
  }

  List<OrderStatus> _applySorting(
    List<OrderStatus> orders,
    OrderSortType sortType,
  ) {
    final sorted = orders.toList();

    switch (sortType) {
      case OrderSortType.timeAsc:
        sorted.sort((a, b) => a.time.compareTo(b.time));
        break;
      case OrderSortType.timeDesc:
        sorted.sort((a, b) => b.time.compareTo(a.time));
        break;
      case OrderSortType.priceAsc:
        sorted.sort((a, b) => a.price.compareTo(b.price));
        break;
      case OrderSortType.priceDesc:
        sorted.sort((a, b) => b.price.compareTo(a.price));
        break;
      case OrderSortType.quantityAsc:
        sorted.sort((a, b) => a.origQty.compareTo(b.origQty));
        break;
      case OrderSortType.quantityDesc:
        sorted.sort((a, b) => b.origQty.compareTo(a.origQty));
        break;
      case OrderSortType.fillAsc:
        sorted.sort((a, b) => a.filledPercentage.compareTo(b.filledPercentage));
        break;
      case OrderSortType.fillDesc:
        sorted.sort((a, b) => b.filledPercentage.compareTo(a.filledPercentage));
        break;
      case OrderSortType.sideAsc:
        sorted.sort((a, b) => a.side.compareTo(b.side));
        break;
      case OrderSortType.sideDesc:
        sorted.sort((a, b) => b.side.compareTo(a.side));
        break;
      case OrderSortType.statusAsc:
        sorted.sort((a, b) => a.status.compareTo(b.status));
        break;
      case OrderSortType.statusDesc:
        sorted.sort((a, b) => b.status.compareTo(a.status));
        break;
    }

    return sorted;
  }

  Future<void> _onCancelOrder(
    CancelOrder event,
    Emitter<OrdersState> emit,
  ) async {
    final currentState = state;
    if (currentState is! OrdersLoaded) return;

    emit(currentState.copyWith(isActionLoading: true, actionMessage: null));

    final result = await _ordersRepository.cancelOrder(
      event.symbol,
      event.orderId,
    );

    result.fold(
      (failure) => emit(
        currentState.copyWith(
          isActionLoading: false,
          actionMessage: 'Errore durante la cancellazione: ${failure.message}',
        ),
      ),
      (_) {
        emit(
          currentState.copyWith(
            isActionLoading: false,
            actionMessage: 'Ordine cancellato con successo',
          ),
        );
        // Ricarica gli ordini dopo la cancellazione
        add(LoadOpenOrders(event.symbol));
      },
    );
  }

  Future<void> _onCancelAllOrders(
    CancelAllOrders event,
    Emitter<OrdersState> emit,
  ) async {
    final currentState = state;
    if (currentState is! OrdersLoaded) return;

    emit(currentState.copyWith(isActionLoading: true, actionMessage: null));

    final result = await _ordersRepository.cancelAllOrders(event.symbol);

    result.fold(
      (failure) => emit(
        currentState.copyWith(
          isActionLoading: false,
          actionMessage:
              'Errore durante la cancellazione di tutti gli ordini: ${failure.message}',
        ),
      ),
      (_) {
        emit(
          currentState.copyWith(
            isActionLoading: false,
            actionMessage: 'Tutti gli ordini sono stati cancellati',
          ),
        );
        // Ricarica gli ordini dopo la cancellazione
        add(LoadOpenOrders(event.symbol));
      },
    );
  }
}
