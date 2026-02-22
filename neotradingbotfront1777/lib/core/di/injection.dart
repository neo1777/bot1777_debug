import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:grpc/grpc.dart' show ClientInterceptor;
import 'package:neotradingbotfront1777/core/api/api_key_client_interceptor.dart';
import 'package:neotradingbotfront1777/core/api/grpc_client.dart';
import 'package:neotradingbotfront1777/core/config/app_config.dart';
import 'package:neotradingbotfront1777/core/symbol/symbol_context.dart';
import 'package:neotradingbotfront1777/core/routing/app_router.dart';
import 'package:neotradingbotfront1777/data/datasources/i_trading_remote_datasource.dart';
import 'package:neotradingbotfront1777/domain/usecases/manage_strategy_run_control_use_case.dart';
import 'package:neotradingbotfront1777/data/repositories/account_repository_impl.dart';
import 'package:neotradingbotfront1777/data/repositories/log_settings_repository_impl.dart';
import 'package:neotradingbotfront1777/data/repositories/orders_repository_impl.dart';
import 'package:neotradingbotfront1777/data/repositories/price_repository_impl.dart';
import 'package:neotradingbotfront1777/data/repositories/settings_repository_impl.dart';
import 'package:neotradingbotfront1777/data/repositories/trade_history_repository_impl.dart';
import 'package:neotradingbotfront1777/data/repositories/trading_repository_impl.dart';
import 'package:neotradingbotfront1777/data/repositories/fee_repository_impl.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_account_repository.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_log_settings_repository.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_orders_repository.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_price_repository.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_settings_repository.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_trade_history_repository.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_trading_repository.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_fee_repository.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pbgrpc.dart';
import 'package:neotradingbotfront1777/presentation/features/account/bloc/account_bloc.dart';
import 'package:neotradingbotfront1777/presentation/features/dashboard/bloc/strategy_state_bloc.dart';
import 'package:neotradingbotfront1777/presentation/features/orders/bloc/orders_bloc.dart';
import 'package:neotradingbotfront1777/presentation/blocs/price/price_bloc_real.dart';
import 'package:neotradingbotfront1777/presentation/features/settings/bloc/settings_bloc.dart';
import 'package:neotradingbotfront1777/presentation/features/trade_history/bloc/trade_history_bloc.dart';
import 'package:neotradingbotfront1777/presentation/blocs/system_log/system_log_bloc.dart';
import 'package:neotradingbotfront1777/presentation/blocs/strategy_control/strategy_control_bloc.dart';
import 'package:neotradingbotfront1777/data/datasources/trading_remote_datasource.dart';
import 'package:neotradingbotfront1777/presentation/features/log_settings/bloc/log_settings_bloc.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_backtest_repository.dart';
import 'package:neotradingbotfront1777/data/repositories/backtest_repository_impl.dart';
import 'package:neotradingbotfront1777/presentation/features/backtest/bloc/backtest_bloc.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  // --- Core ---

  // Router
  sl.registerLazySingleton<GoRouter>(() => AppRouter().router);

  // Auth rimossa: il server non implementa autenticazione.
  // Se in futuro si abiliterà auth, reintrodurre ITokenStorage, TokenStorage e AuthInterceptor qui.

  // gRPC Client Manager & Client
  final grpcManager = GrpcClientManager();

  // Host: usa GRPC_HOST da env per produzione (es: GRPC_HOST=5.45.126.177).
  // Default: localhost per development locale.
  const String defaultHost = 'localhost';

  const envHost = String.fromEnvironment('GRPC_HOST', defaultValue: '');
  final host = envHost.isNotEmpty ? envHost : defaultHost;

  const port = int.fromEnvironment(
    'GRPC_PORT',
    defaultValue: kIsWeb ? 9090 : 8080,
  );

  // Env variables per configurazione gRPC
  const allowInsecure = String.fromEnvironment(
    'GRPC_ALLOW_INSECURE',
    defaultValue: kDebugMode ? 'true' : 'false',
  );

  // Se GRPC_ALLOW_INSECURE=true, forziamo connessione insicura (per test locale)
  // Altrimenti usiamo default sicuro: web=false (via Envoy proxy), mobile/desktop=true (TLS)
  final bool isInsecureMode = allowInsecure.toLowerCase() == 'true';
  final bool isSecure = isInsecureMode ? false : (kIsWeb ? false : true);

  if (isInsecureMode) {
    // ignore: avoid_print
    print(
      '⚠️  [SECURITY] GRPC_ALLOW_INSECURE=true — '
      'connessione non cifrata. NON usare in produzione!',
    );
  }

  // API Key gRPC: letta da compile-time env. Se configurata, viene inviata
  // come header `x-api-key` su ogni chiamata gRPC.
  const grpcApiKey = String.fromEnvironment('GRPC_API_KEY', defaultValue: '');
  final interceptors = <ClientInterceptor>[
    if (grpcApiKey.isNotEmpty) ApiKeyClientInterceptor(grpcApiKey),
  ];

  if (grpcApiKey.isNotEmpty) {
    // ignore: avoid_print
    print('[AUTH] API key configurata — header x-api-key verrà inviato.');
  }

  await grpcManager.initialize(
    host: host,
    port: port,
    secure: isSecure,
    certAssetPath: 'assets/certs/server.crt',
    interceptors: interceptors,
  );

  // Symbol context: persistenza e gestione simbolo attivo (prepara multi-strategia futura)
  final symbolContext = SymbolContext();
  await symbolContext.initialize(defaultSymbol: AppConfig.defaultSymbol);
  sl.registerSingleton<SymbolContext>(symbolContext);

  sl.registerSingleton<GrpcClientManager>(grpcManager);
  sl.registerLazySingleton<TradingServiceClient>(() => grpcManager.client);

  // --- Data Layer ---
  sl.registerLazySingleton<ITradingRemoteDatasource>(
    () => TradingRemoteDatasource(client: sl()),
  );

  // Repositories
  sl.registerLazySingleton<ISettingsRepository>(
    () => SettingsRepositoryImpl(remoteDatasource: sl()),
  );
  sl.registerLazySingleton<ITradingRepository>(
    () => TradingRepositoryImpl(remoteDatasource: sl()),
  );
  sl.registerLazySingleton<IFeeRepository>(
    () => FeeRepositoryImpl(datasource: sl<ITradingRemoteDatasource>()),
  );
  sl.registerLazySingleton<IAccountRepository>(
    () => AccountRepositoryImpl(remoteDatasource: sl()),
  );
  sl.registerLazySingleton<ITradeHistoryRepository>(
    () => TradeHistoryRepositoryImpl(remoteDatasource: sl()),
  );
  sl.registerLazySingleton<IOrdersRepository>(
    () => OrdersRepositoryImpl(remoteDatasource: sl()),
  );
  sl.registerLazySingleton<ILogSettingsRepository>(
    () => LogSettingsRepositoryImpl(remoteDatasource: sl()),
  );
  sl.registerLazySingleton<IPriceRepository>(
    () => PriceRepositoryImpl(remoteDatasource: sl()),
  );

  // --- Presentation Layer - BLoCs ---
  sl.registerFactory<SettingsBloc>(
    () => SettingsBloc(settingsRepository: sl()),
  );
  sl.registerFactory<LogSettingsBloc>(() => LogSettingsBloc(repository: sl()));
  sl.registerFactory<TradeHistoryBloc>(
    () => TradeHistoryBloc(tradeHistoryRepository: sl()),
  );
  sl.registerFactory<AccountBloc>(() => AccountBloc(accountRepository: sl()));
  sl.registerFactory<OrdersBloc>(() => OrdersBloc(ordersRepository: sl()));
  sl.registerFactory<PriceBlocReal>(() => PriceBlocReal(priceRepository: sl()));
  // UseCases
  sl.registerLazySingleton(() => ManageStrategyRunControlUseCase(sl()));

  // BLoCs refattorizzati
  sl.registerFactory<StrategyStateBloc>(
    () => StrategyStateBloc(
      tradingRepository: sl(),
      manageStrategyRunControlUseCase: sl(),
    ),
  );
  sl.registerFactory<SystemLogBloc>(
    () => SystemLogBloc(tradingRepository: sl()),
  );
  sl.registerFactory<StrategyControlBloc>(
    () => StrategyControlBloc(tradingRepository: sl()),
  );

  // Backtest
  sl.registerLazySingleton<IBacktestRepository>(
    () => BacktestRepositoryImpl(sl()),
  );
  sl.registerFactory<BacktestBloc>(() => BacktestBloc(sl()));
}
