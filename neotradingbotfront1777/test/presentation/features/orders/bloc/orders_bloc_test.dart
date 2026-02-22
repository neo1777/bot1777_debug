import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/domain/entities/order_status.dart';
import 'package:neotradingbotfront1777/domain/entities/symbol_limits.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_orders_repository.dart';
import 'package:neotradingbotfront1777/presentation/features/orders/bloc/orders_bloc.dart';
import 'package:neotradingbotfront1777/presentation/features/orders/bloc/orders_event.dart';
import 'package:neotradingbotfront1777/presentation/features/orders/bloc/orders_state.dart';

class MockOrdersRepository extends Mock implements IOrdersRepository {}

void main() {
  late MockOrdersRepository mockOrdersRepository;
  late OrdersBloc ordersBloc;

  final tOrderStatus = OrderStatus(
    symbol: 'BTCUSDC',
    orderId: 1,
    clientOrderId: 'client_1',
    price: 50000.0,
    origQty: 1.0,
    executedQty: 0.5,
    status: 'PARTIALLY_FILLED',
    timeInForce: 'GTC',
    type: 'LIMIT',
    side: 'BUY',
    time: DateTime(2026, 1, 1),
  );

  final tOrderStatus2 = OrderStatus(
    symbol: 'BTCUSDC',
    orderId: 2,
    clientOrderId: 'client_2',
    price: 51000.0,
    origQty: 2.0,
    executedQty: 2.0,
    status: 'FILLED',
    timeInForce: 'GTC',
    type: 'MARKET',
    side: 'SELL',
    time: DateTime(2026, 1, 2),
  );

  final tOrders = [tOrderStatus, tOrderStatus2];

  final tSymbolLimits = const SymbolLimits(
    symbol: 'BTCUSDC',
    minQty: 0.001,
    maxQty: 100.0,
    stepSize: 0.001,
    minNotional: 10.0,
  );

  setUp(() {
    mockOrdersRepository = MockOrdersRepository();
    ordersBloc = OrdersBloc(ordersRepository: mockOrdersRepository);
  });

  tearDown(() {
    ordersBloc.close();
  });

  test('initial state should be OrdersInitial', () {
    expect(ordersBloc.state, const OrdersInitial());
  });

  group('LoadOpenOrders', () {
    blocTest<OrdersBloc, OrdersState>(
      'should emit [OrdersLoading, OrdersLoaded] when both repository calls succeed',
      build: () {
        when(
          () => mockOrdersRepository.getOpenOrders(any()),
        ).thenAnswer((_) async => Right(tOrders));
        when(
          () => mockOrdersRepository.getSymbolLimits(any()),
        ).thenAnswer((_) async => Right(tSymbolLimits));
        return ordersBloc;
      },
      act: (bloc) => bloc.add(const LoadOpenOrders('BTCUSDC')),
      expect:
          () => [
            const OrdersLoading(),
            OrdersLoaded(
              orders: tOrders,
              filteredOrders: tOrders,
              symbolLimits: tSymbolLimits,
              currentSymbol: 'BTCUSDC',
            ),
          ],
    );

    blocTest<OrdersBloc, OrdersState>(
      'should emit [OrdersLoading, OrdersLoaded] even if getSymbolLimits fails',
      build: () {
        when(
          () => mockOrdersRepository.getOpenOrders(any()),
        ).thenAnswer((_) async => Right(tOrders));
        when(
          () => mockOrdersRepository.getSymbolLimits(any()),
        ).thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));
        return ordersBloc;
      },
      act: (bloc) => bloc.add(const LoadOpenOrders('BTCUSDC')),
      expect:
          () => [
            const OrdersLoading(),
            OrdersLoaded(
              orders: tOrders,
              filteredOrders: tOrders,
              currentSymbol: 'BTCUSDC',
            ),
          ],
    );

    blocTest<OrdersBloc, OrdersState>(
      'should emit [OrdersLoading, OrdersError] when getOpenOrders fails',
      build: () {
        when(() => mockOrdersRepository.getOpenOrders(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Orders Error')),
        );
        when(
          () => mockOrdersRepository.getSymbolLimits(any()),
        ).thenAnswer((_) async => Right(tSymbolLimits));
        return ordersBloc;
      },
      act: (bloc) => bloc.add(const LoadOpenOrders('BTCUSDC')),
      expect: () => [const OrdersLoading(), const OrdersError('Orders Error')],
    );
    group('Filters and Sorting', () {
      final baseState = OrdersLoaded(
        orders: tOrders,
        filteredOrders: tOrders,
        symbolLimits: tSymbolLimits,
        currentSymbol: 'BTCUSDC',
      );

      blocTest<OrdersBloc, OrdersState>(
        'should filter by type',
        build: () => ordersBloc,
        seed: () => baseState,
        act: (bloc) => bloc.add(const FilterOrdersByType('LIMIT')),
        expect:
            () => [
              baseState.copyWith(
                typeFilter: 'LIMIT',
                filteredOrders: [tOrderStatus],
              ),
            ],
      );

      blocTest<OrdersBloc, OrdersState>(
        'should filter by side',
        build: () => ordersBloc,
        seed: () => baseState,
        act: (bloc) => bloc.add(const FilterOrdersBySide('SELL')),
        expect:
            () => [
              baseState.copyWith(
                sideFilter: 'SELL',
                filteredOrders: [tOrderStatus2],
              ),
            ],
      );

      blocTest<OrdersBloc, OrdersState>(
        'should filter by status',
        build: () => ordersBloc,
        seed: () => baseState,
        act: (bloc) => bloc.add(const FilterOrdersByStatus('FILLED')),
        expect:
            () => [
              baseState.copyWith(
                statusFilter: 'FILLED',
                filteredOrders: [tOrderStatus2],
              ),
            ],
      );

      blocTest<OrdersBloc, OrdersState>(
        'should clear filters',
        build: () => ordersBloc,
        seed:
            () => baseState.copyWith(
              typeFilter: 'LIMIT',
              filteredOrders: [tOrderStatus],
            ),
        act: (bloc) => bloc.add(const ClearOrderFilters()),
        expect:
            () => [
              baseState.copyWith(typeFilter: null, filteredOrders: tOrders),
            ],
      );

      blocTest<OrdersBloc, OrdersState>(
        'should sort orders by priceAsc',
        build: () => ordersBloc,
        seed: () => baseState,
        act: (bloc) => bloc.add(const SortOrders(OrderSortType.priceAsc)),
        expect:
            () => [
              baseState.copyWith(
                sortType: OrderSortType.priceAsc,
                filteredOrders: [tOrderStatus, tOrderStatus2],
              ),
            ],
      );

      blocTest<OrdersBloc, OrdersState>(
        'should sort orders by priceDesc',
        build: () => ordersBloc,
        seed: () => baseState,
        act: (bloc) => bloc.add(const SortOrders(OrderSortType.priceDesc)),
        expect:
            () => [
              baseState.copyWith(
                sortType: OrderSortType.priceDesc,
                filteredOrders: [tOrderStatus2, tOrderStatus],
              ),
            ],
      );
    });

    group('CancelOrder', () {
      final baseState = OrdersLoaded(
        orders: tOrders,
        filteredOrders: tOrders,
        symbolLimits: tSymbolLimits,
        currentSymbol: 'BTCUSDC',
      );

      blocTest<OrdersBloc, OrdersState>(
        'should emit [isActionLoading: true, isActionLoading: false, success] when cancel succeeds',
        build: () {
          when(
            () => mockOrdersRepository.cancelOrder(any(), any()),
          ).thenAnswer((_) async => const Right(null));
          when(
            () => mockOrdersRepository.getOpenOrders(any()),
          ).thenAnswer((_) async => Right([tOrderStatus2]));
          when(
            () => mockOrdersRepository.getSymbolLimits(any()),
          ).thenAnswer((_) async => Right(tSymbolLimits));
          return ordersBloc;
        },
        seed: () => baseState,
        act:
            (bloc) =>
                bloc.add(const CancelOrder(symbol: 'BTCUSDC', orderId: 1)),
        expect:
            () => [
              baseState.copyWith(isActionLoading: true),
              baseState.copyWith(
                isActionLoading: false,
                actionMessage: 'Ordine cancellato con successo',
              ),
              // Verification that LoadOpenOrders is added
              const OrdersLoading(),
              OrdersLoaded(
                orders: [tOrderStatus2],
                filteredOrders: [tOrderStatus2],
                symbolLimits: tSymbolLimits,
                currentSymbol: 'BTCUSDC',
              ),
            ],
      );

      blocTest<OrdersBloc, OrdersState>(
        'should emit [isActionLoading: true, isActionLoading: false, error] when cancel fails',
        build: () {
          when(() => mockOrdersRepository.cancelOrder(any(), any())).thenAnswer(
            (_) async => const Left(ServerFailure(message: 'Cancel Fail')),
          );
          return ordersBloc;
        },
        seed: () => baseState,
        act:
            (bloc) =>
                bloc.add(const CancelOrder(symbol: 'BTCUSDC', orderId: 1)),
        expect:
            () => [
              baseState.copyWith(isActionLoading: true),
              baseState.copyWith(
                isActionLoading: false,
                actionMessage: 'Errore durante la cancellazione: Cancel Fail',
              ),
            ],
      );
    });

    group('CancelAllOrders', () {
      final baseState = OrdersLoaded(
        orders: tOrders,
        filteredOrders: tOrders,
        symbolLimits: tSymbolLimits,
        currentSymbol: 'BTCUSDC',
      );

      blocTest<OrdersBloc, OrdersState>(
        'should emit [isActionLoading: true, isActionLoading: false, success] when cancel all succeeds',
        build: () {
          when(
            () => mockOrdersRepository.cancelAllOrders(any()),
          ).thenAnswer((_) async => const Right(null));
          when(
            () => mockOrdersRepository.getOpenOrders(any()),
          ).thenAnswer((_) async => const Right([]));
          when(
            () => mockOrdersRepository.getSymbolLimits(any()),
          ).thenAnswer((_) async => Right(tSymbolLimits));
          return ordersBloc;
        },
        seed: () => baseState,
        act: (bloc) => bloc.add(const CancelAllOrders(symbol: 'BTCUSDC')),
        expect:
            () => [
              baseState.copyWith(isActionLoading: true),
              baseState.copyWith(
                isActionLoading: false,
                actionMessage: 'Tutti gli ordini sono stati cancellati',
              ),
              const OrdersLoading(),
              OrdersLoaded(
                orders: const [],
                filteredOrders: const [],
                symbolLimits: tSymbolLimits,
                currentSymbol: 'BTCUSDC',
              ),
            ],
      );
    });
  });
}

