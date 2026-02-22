import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neotradingbotfront1777/core/di/injection.dart';
import 'package:neotradingbotfront1777/app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neotradingbotfront1777/core/api/grpc_client.dart';
import 'package:neotradingbotfront1777/presentation/features/trade_history/bloc/trade_history_bloc.dart';
import 'package:neotradingbotfront1777/presentation/features/trade_history/bloc/trade_history_state.dart';
import 'package:neotradingbotfront1777/presentation/features/trade_history/bloc/trade_history_event.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';

class MockGrpcClientManager extends Mock implements GrpcClientManager {}

class MockTradeHistoryBloc
    extends MockBloc<TradeHistoryEvent, TradeHistoryState>
    implements TradeHistoryBloc {}

void main() {
  late MockGrpcClientManager mockGrpcClientManager;
  late MockTradeHistoryBloc mockTradeHistoryBloc;

  setUpAll(() {
    registerFallbackValue(const LoadTradeHistory());
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    mockGrpcClientManager = MockGrpcClientManager();
    mockTradeHistoryBloc = MockTradeHistoryBloc();

    when(
      () => mockTradeHistoryBloc.state,
    ).thenReturn(const TradeHistoryInitial());
    when(() => mockGrpcClientManager.shutdown()).thenAnswer((_) async {});

    await sl.reset();
    sl.registerSingleton<GrpcClientManager>(mockGrpcClientManager);
    sl.registerFactory<TradeHistoryBloc>(() => mockTradeHistoryBloc);

    // Forniamo un router minimo fittizio per evitare di montare
    // AppDependenciesProvider e le DashboardPage con i loro timer
    final fakeRouter = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder:
              (context, state) => const Scaffold(body: Text('Dummy Route')),
        ),
      ],
    );
    sl.registerSingleton<GoRouter>(fakeRouter);
  });

  testWidgets('App smoke test - renders MyApp shell', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(MultiBlocProvider), findsWidgets);
    expect(find.text('Dummy Route'), findsOneWidget);
  });
}
