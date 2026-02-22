import 'package:equatable/equatable.dart';
import 'package:neotradingbotfront1777/domain/entities/order_status.dart';
import 'package:neotradingbotfront1777/domain/entities/symbol_limits.dart';
import 'package:neotradingbotfront1777/presentation/features/orders/bloc/orders_event.dart';

abstract class OrdersState extends Equatable {
  const OrdersState();

  @override
  List<Object?> get props => [];
}

class OrdersInitial extends OrdersState {
  const OrdersInitial();
}

class OrdersLoading extends OrdersState {
  const OrdersLoading();
}

class OrdersLoaded extends OrdersState {
  const OrdersLoaded({
    required this.orders,
    required this.filteredOrders,
    this.symbolLimits,
    this.currentSymbol,
    this.typeFilter,
    this.sideFilter,
    this.statusFilter,
    this.sortType = OrderSortType.timeDesc,
    this.actionMessage,
    this.isActionLoading = false,
  });

  final List<OrderStatus> orders;
  final List<OrderStatus> filteredOrders;
  final SymbolLimits? symbolLimits;
  final String? currentSymbol;
  final String? typeFilter;
  final String? sideFilter;
  final String? statusFilter;
  final OrderSortType sortType;
  final String? actionMessage;
  final bool isActionLoading;

  // Calculated properties
  int get totalOrders => filteredOrders.length;

  int get buyOrders =>
      filteredOrders.where((order) => order.side == 'BUY').length;

  int get sellOrders =>
      filteredOrders.where((order) => order.side == 'SELL').length;

  int get pendingOrders =>
      filteredOrders.where((order) => order.isPending).length;

  int get completedOrders =>
      filteredOrders.where((order) => order.isCompleted).length;

  int get cancelledOrders =>
      filteredOrders.where((order) => order.isCancelled).length;

  double get totalOrderValue {
    return filteredOrders.fold(
      0.0,
      (sum, order) => sum + (order.price * order.origQty),
    );
  }

  double get totalExecutedValue {
    return filteredOrders.fold(
      0.0,
      (sum, order) => sum + (order.price * order.executedQty),
    );
  }

  double get averageFillPercentage {
    if (filteredOrders.isEmpty) return 0.0;
    final totalFillPercentage = filteredOrders.fold(
      0.0,
      (sum, order) => sum + order.filledPercentage,
    );
    return totalFillPercentage / filteredOrders.length;
  }

  List<String> get availableTypes {
    return orders.map((order) => order.type).toSet().toList()..sort();
  }

  List<String> get availableSides {
    return orders.map((order) => order.side).toSet().toList()..sort();
  }

  List<String> get availableStatuses {
    return orders.map((order) => order.status).toSet().toList()..sort();
  }

  @override
  List<Object?> get props => [
    orders,
    filteredOrders,
    symbolLimits,
    currentSymbol,
    typeFilter,
    sideFilter,
    statusFilter,
    sortType,
    actionMessage,
    isActionLoading,
  ];

  OrdersLoaded copyWith({
    List<OrderStatus>? orders,
    List<OrderStatus>? filteredOrders,
    SymbolLimits? symbolLimits,
    String? currentSymbol,
    String? typeFilter,
    String? sideFilter,
    String? statusFilter,
    OrderSortType? sortType,
    String? actionMessage,
    bool? isActionLoading,
  }) {
    return OrdersLoaded(
      orders: orders ?? this.orders,
      filteredOrders: filteredOrders ?? this.filteredOrders,
      symbolLimits: symbolLimits ?? this.symbolLimits,
      currentSymbol: currentSymbol ?? this.currentSymbol,
      typeFilter: typeFilter ?? this.typeFilter,
      sideFilter: sideFilter ?? this.sideFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      sortType: sortType ?? this.sortType,
      actionMessage: actionMessage ?? this.actionMessage,
      isActionLoading: isActionLoading ?? this.isActionLoading,
    );
  }
}

class OrdersError extends OrdersState {
  const OrdersError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
