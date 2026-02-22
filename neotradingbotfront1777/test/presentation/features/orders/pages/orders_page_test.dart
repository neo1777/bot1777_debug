import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neotradingbotfront1777/core/di/injection.dart';
import 'package:neotradingbotfront1777/presentation/features/orders/bloc/orders_bloc.dart';
import 'package:neotradingbotfront1777/presentation/features/orders/bloc/orders_event.dart';
import 'package:neotradingbotfront1777/presentation/features/orders/bloc/orders_state.dart';
import 'package:neotradingbotfront1777/domain/entities/order_status.dart';
import 'package:neotradingbotfront1777/presentation/features/orders/widgets/orders_overview_card.dart';
import 'package:neotradingbotfront1777/presentation/features/orders/widgets/orders_filters.dart';
import 'package:neotradingbotfront1777/presentation/features/orders/widgets/orders_list.dart';
import 'package:neotradingbotfront1777/presentation/features/orders/pages/orders_page.dart';

import 'package:neotradingbotfront1777/presentation/features/settings/bloc/settings_bloc.dart';

class MockOrdersBloc extends MockBloc<OrdersEvent, OrdersState>
    implements OrdersBloc {}

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

void main() {
  late MockOrdersBloc mockOrdersBloc;
  late MockSettingsBloc mockSettingsBloc;

  setUpAll(() {
    registerFallbackValue(const OrdersInitial());
    registerFallbackValue(const LoadOpenOrders('BTCUSDC'));
    registerFallbackValue(const SettingsFetched());
  });

  setUp(() async {
    mockOrdersBloc = MockOrdersBloc();
    mockSettingsBloc = MockSettingsBloc();

    // Default settings state
    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());

    // Sl setup
    await sl.reset();
    sl.registerFactory<OrdersBloc>(() => mockOrdersBloc);
    sl.registerFactory<SettingsBloc>(() => mockSettingsBloc);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<SettingsBloc>(
        create: (context) => mockSettingsBloc,
        child: const OrdersPage(symbol: 'BTCUSDC'),
      ),
    );
  }

  testWidgets('renders OrdersLoading when state is OrdersLoading', (
    tester,
  ) async {
    when(() => mockOrdersBloc.state).thenReturn(const OrdersLoading());

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders OrdersError when state is OrdersError', (tester) async {
    when(
      () => mockOrdersBloc.state,
    ).thenReturn(const OrdersError('Test Error'));

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Errore Ordini'), findsOneWidget);
    expect(find.text('Test Error'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget); // Riprova button icon
  });

  testWidgets('adds RefreshOrders when Riprova is pressed on Error state', (
    tester,
  ) async {
    when(
      () => mockOrdersBloc.state,
    ).thenReturn(const OrdersError('Test Error'));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.tap(find.text('Riprova'));
    await tester.pump();

    verify(() => mockOrdersBloc.add(const RefreshOrders())).called(1);
  });

  testWidgets('renders OrdersLoaded with list of orders', (tester) async {
    final tOrder = OrderStatus(
      symbol: 'BTCUSDC',
      orderId: 1,
      clientOrderId: 'c1',
      price: 50000.0,
      origQty: 0.1,
      executedQty: 0.0,
      status: 'NEW',
      timeInForce: 'GTC',
      type: 'LIMIT',
      side: 'BUY',
      time: DateTime.now(),
    );

    when(() => mockOrdersBloc.state).thenReturn(
      OrdersLoaded(
        orders: [tOrder],
        filteredOrders: [tOrder],
        currentSymbol: 'BTCUSDC',
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('ORDINI APERTI'), findsOneWidget);
    expect(find.byType(OrdersOverviewCard), findsOneWidget);
    expect(find.byType(OrdersFilters), findsOneWidget);
    expect(find.byType(OrdersList), findsOneWidget);
    expect(find.text('BTCUSDC'), findsAtLeastNWidgets(1));
  });

  testWidgets('shows cancel all dialog when cancel all menu item is selected', (
    tester,
  ) async {
    final tOrder = OrderStatus(
      symbol: 'BTCUSDC',
      orderId: 1,
      clientOrderId: 'c1',
      price: 50000.0,
      origQty: 0.1,
      executedQty: 0.0,
      status: 'NEW',
      timeInForce: 'GTC',
      type: 'LIMIT',
      side: 'BUY',
      time: DateTime.now(),
    );

    when(() => mockOrdersBloc.state).thenReturn(
      OrdersLoaded(
        orders: [tOrder],
        filteredOrders: [tOrder],
        currentSymbol: 'BTCUSDC',
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());

    // Open menu
    await tester.tap(find.byTooltip('Azioni'));
    await tester.pumpAndSettle();

    // Tap Cancel All in popup menu (specifically PopupMenuItem)
    await tester.tap(find.text('Cancella Tutti').last);
    await tester.pumpAndSettle();

    expect(find.text('Cancella Tutti gli Ordini'), findsOneWidget);
    expect(
      find.textContaining('Sei sicuro di voler cancellare'),
      findsOneWidget,
    );

    // Verify Annulla closes dialog
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(find.text('Cancella Tutti gli Ordini'), findsNothing);
  });
}

