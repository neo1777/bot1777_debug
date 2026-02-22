import 'package:equatable/equatable.dart';

abstract class OrdersEvent extends Equatable {
  const OrdersEvent();

  @override
  List<Object?> get props => [];
}

class LoadOpenOrders extends OrdersEvent {
  const LoadOpenOrders(this.symbol);

  final String symbol;

  @override
  List<Object?> get props => [symbol];
}

class LoadSymbolLimits extends OrdersEvent {
  const LoadSymbolLimits(this.symbol);

  final String symbol;

  @override
  List<Object?> get props => [symbol];
}

class RefreshOrders extends OrdersEvent {
  const RefreshOrders();
}

class FilterOrdersByType extends OrdersEvent {
  const FilterOrdersByType(this.orderType);

  final String? orderType;

  @override
  List<Object?> get props => [orderType];
}

class FilterOrdersBySide extends OrdersEvent {
  const FilterOrdersBySide(this.side);

  final String? side;

  @override
  List<Object?> get props => [side];
}

class FilterOrdersByStatus extends OrdersEvent {
  const FilterOrdersByStatus(this.status);

  final String? status;

  @override
  List<Object?> get props => [status];
}

class ClearOrderFilters extends OrdersEvent {
  const ClearOrderFilters();
}

enum OrderSortType {
  timeAsc,
  timeDesc,
  priceAsc,
  priceDesc,
  quantityAsc,
  quantityDesc,
  fillAsc,
  fillDesc,
  sideAsc,
  sideDesc,
  statusAsc,
  statusDesc,
}

class SortOrders extends OrdersEvent {
  const SortOrders(this.sortType);

  final OrderSortType sortType;

  @override
  List<Object?> get props => [sortType];
}

class CancelOrder extends OrdersEvent {
  const CancelOrder({required this.symbol, required this.orderId});

  final String symbol;
  final int orderId;

  @override
  List<Object?> get props => [symbol, orderId];
}

class CancelAllOrders extends OrdersEvent {
  const CancelAllOrders({required this.symbol});

  final String symbol;

  @override
  List<Object?> get props => [symbol];
}
