import 'dart:io';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:neotradingbotback1777/core/config/api_keys_config.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:neotradingbotback1777/core/monitoring/business_metrics_monitor.dart';
import 'package:neotradingbotback1777/domain/repositories/account_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/price_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/strategy_state_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/i_symbol_info_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/settings_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/log_settings_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/trading_repository_new.dart';
import 'package:neotradingbotback1777/domain/repositories/i_fee_repository.dart';
import 'package:neotradingbotback1777/domain/services/i_trading_api_service.dart';
import 'package:neotradingbotback1777/domain/services/trading_transaction_manager.dart';
import 'package:neotradingbotback1777/domain/services/trade_evaluator_service.dart';
import 'package:neotradingbotback1777/domain/services/fee_calculation_service.dart';
import 'package:neotradingbotback1777/domain/services/trade_validation_service.dart';
import 'package:neotradingbotback1777/infrastructure/network/binance/api_service.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/price_repository_impl.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/strategy_state_repository_impl.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/symbol_info_repository_impl.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/settings_repository_impl.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/log_settings_repository_impl.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/trading_repository_impl_new.dart'
    as new_impl;
import 'package:neotradingbotback1777/infrastructure/persistence/fee_repository_impl.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/account_repository_remote_only.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/price_repository_in_memory.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/symbol_info_repository_in_memory.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/noop_strategy_state_repository.dart';
import 'package:neotradingbotback1777/infrastructure/services/trading_transaction_manager_impl.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/app_settings_hive_dto.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/app_strategy_state_hive_dto.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/app_trade_hive_dto.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/fifo_app_trade_hive_dto.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/log_settings_hive_dto.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/symbol_info_hive_dto.dart';
import 'package:neotradingbotback1777/application/use_cases/get_and_validate_symbol_quantity_use_case.dart';
import 'package:neotradingbotback1777/application/use_cases/get_settings_use_case.dart';
import 'package:neotradingbotback1777/application/use_cases/get_strategy_state_use_case.dart';
import 'package:neotradingbotback1777/application/use_cases/start_trading_loop_atomic_use_case.dart';
import 'package:neotradingbotback1777/application/managers/atomic_state_manager.dart';
import 'package:neotradingbotback1777/core/locks/trading_lock_manager.dart';
import 'package:neotradingbotback1777/core/logging/log_throttler.dart';
import 'package:neotradingbotback1777/core/errors/unified_error_handler.dart';
import 'package:neotradingbotback1777/core/injection/database_di.dart';

Future<void> configureDependenciesForIsolate(GetIt isolateSl) async {
  isolateSl.registerSingleton<http.Client>(http.Client());
  final isolateId = isolateSl.hashCode.toString();
  final dbPath = p.join(Directory.current.path, 'hive_data_isolate_$isolateId');
  Hive.init(dbPath);

  await openAndRegisterBoxes(isolateSl);

  isolateSl.registerSingleton<ApiKeysConfig>(() {
    final result = ApiKeysConfig.loadFromEnv();
    return result.fold(
      (failure) => throw StateError('API keys non configurate in isolate.'),
      (config) => config,
    );
  }());

  isolateSl.registerLazySingleton<ApiService>(() => ApiService(
        apiKeysConfig: isolateSl<ApiKeysConfig>(),
        httpClient: isolateSl<http.Client>(),
        businessMetricsMonitor: isolateSl<BusinessMetricsMonitor>(),
      ));
  isolateSl
      .registerLazySingleton<ITradingApiService>(() => isolateSl<ApiService>());

  isolateSl.registerLazySingleton<AccountRepository>(() =>
      AccountRepositoryRemoteOnly(apiService: isolateSl<ITradingApiService>()));

  isolateSl.registerLazySingleton<PriceRepository>(() => PriceRepositoryImpl(
        priceBox: isolateSl<Box<double>>(),
        apiService: isolateSl<ITradingApiService>(),
      ));

  isolateSl.registerLazySingleton<StrategyStateRepository>(
      () => StrategyStateRepositoryImpl(
            strategyStateBox: isolateSl<Box<AppStrategyStateHiveDto>>(),
            fifoTradeBox: isolateSl<Box<FifoAppTradeHiveDto>>(),
            apiService: isolateSl<ITradingApiService>(),
          ));

  isolateSl.registerLazySingleton<ISymbolInfoRepository>(
      () => SymbolInfoRepositoryImpl(
            isolateSl<ApiService>(),
            isolateSl<Box<SymbolInfoHiveDto>>(),
          ));

  isolateSl.registerLazySingleton<IFeeRepository>(() => FeeRepositoryImpl(
        apiService: isolateSl<ITradingApiService>(),
      ));

  isolateSl.registerLazySingleton<TradingRepository>(
      () => new_impl.TradingRepositoryImpl(
            tradesBox: isolateSl<Box<AppTradeHiveDto>>(),
            apiService: isolateSl<ITradingApiService>(),
          ));

  isolateSl.registerLazySingleton<TradingTransactionManager>(
      () => TradingTransactionManagerImpl(
            tradingRepository: isolateSl<TradingRepository>(),
            strategyStateRepository: isolateSl<StrategyStateRepository>(),
          ));

  isolateSl
      .registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl(
            settingsBox: isolateSl<Box<AppSettingsHiveDto>>(),
            apiService: isolateSl<ITradingApiService>(),
          ));

  isolateSl.registerLazySingleton<LogSettingsRepository>(
      () => LogSettingsRepositoryImpl(
            logSettingsBox: isolateSl<Box<LogSettingsHiveDto>>(),
          ));

  isolateSl
      .registerLazySingleton<UnifiedErrorHandler>(() => UnifiedErrorHandler());
  isolateSl
      .registerLazySingleton<TradingLockManager>(() => TradingLockManager());
  isolateSl.registerLazySingleton<LogThrottler>(() => LogThrottler());

  isolateSl.registerLazySingleton<FeeCalculationService>(
      () => FeeCalculationService(feeRepository: isolateSl<IFeeRepository>()));

  isolateSl
      .registerLazySingleton<TradeEvaluatorService>(() => TradeEvaluatorService(
            feeCalculationService: isolateSl<FeeCalculationService>(),
            tradingLockManager: isolateSl<TradingLockManager>(),
            logThrottler: isolateSl<LogThrottler>(),
            errorHandler: isolateSl<UnifiedErrorHandler>(),
            businessMetricsMonitor: isolateSl<BusinessMetricsMonitor>(),
          ));

  isolateSl.registerFactory<GetAndValidateSymbolQuantityUseCase>(() =>
      GetAndValidateSymbolQuantityUseCase(isolateSl<ISymbolInfoRepository>()));

  isolateSl.registerFactory<GetSettings>(() => GetSettings(isolateSl()));
  isolateSl.registerFactory<GetStrategyState>(
      () => GetStrategyState(isolateSl<StrategyStateRepository>()));
}

Future<void> configureAtomicIsolateDependencies(GetIt isolateSl) async {
  isolateSl.registerSingleton<http.Client>(http.Client());
  isolateSl.registerSingleton<ApiKeysConfig>(() {
    final result = ApiKeysConfig.loadFromEnv();
    return result.fold(
      (failure) =>
          throw StateError('API keys non configurate in atomic isolate.'),
      (config) => config,
    );
  }());

  isolateSl.registerLazySingleton<ApiService>(() => ApiService(
        apiKeysConfig: isolateSl<ApiKeysConfig>(),
        httpClient: isolateSl<http.Client>(),
        businessMetricsMonitor: isolateSl<BusinessMetricsMonitor>(),
      ));
  isolateSl
      .registerLazySingleton<ITradingApiService>(() => isolateSl<ApiService>());

  isolateSl.registerLazySingleton<AccountRepository>(() =>
      AccountRepositoryRemoteOnly(apiService: isolateSl<ITradingApiService>()));

  isolateSl.registerLazySingleton<PriceRepository>(() =>
      PriceRepositoryInMemory(apiService: isolateSl<ITradingApiService>()));

  isolateSl.registerLazySingleton<StrategyStateRepository>(
      () => StrategyStateRepositoryNoop());

  isolateSl.registerLazySingleton<ISymbolInfoRepository>(
      () => SymbolInfoRepositoryInMemory(isolateSl<ITradingApiService>()));

  isolateSl.registerLazySingleton<IFeeRepository>(() => FeeRepositoryImpl(
        apiService: isolateSl<ITradingApiService>(),
      ));

  isolateSl.registerLazySingleton<TradeValidationService>(
      () => TradeValidationService());

  // 0. Core Services (Logger, ErrorHandler, Locks, Metrics)
  isolateSl
      .registerLazySingleton<UnifiedErrorHandler>(() => UnifiedErrorHandler());
  isolateSl
      .registerLazySingleton<TradingLockManager>(() => TradingLockManager());
  isolateSl.registerLazySingleton<LogThrottler>(() => LogThrottler());
  isolateSl.registerLazySingleton<BusinessMetricsMonitor>(
      () => BusinessMetricsMonitor());

  isolateSl.registerLazySingleton<FeeCalculationService>(
      () => FeeCalculationService(feeRepository: isolateSl<IFeeRepository>()));

  isolateSl
      .registerLazySingleton<TradeEvaluatorService>(() => TradeEvaluatorService(
            feeCalculationService: isolateSl<FeeCalculationService>(),
            tradingLockManager: isolateSl<TradingLockManager>(),
            logThrottler: isolateSl<LogThrottler>(),
            errorHandler: isolateSl<UnifiedErrorHandler>(),
            businessMetricsMonitor: isolateSl<BusinessMetricsMonitor>(),
          ));

  isolateSl.registerLazySingleton<AtomicStateManager>(() => AtomicStateManager(
        isolateSl<StrategyStateRepository>(),
        persistChanges: false,
      ));

  isolateSl
      .registerFactory<StartTradingLoopAtomic>(() => StartTradingLoopAtomic(
            priceRepository: isolateSl<PriceRepository>(),
            tradeEvaluator: isolateSl<TradeEvaluatorService>(),
            stateManager: isolateSl<AtomicStateManager>(),
            accountRepository: isolateSl<AccountRepository>(),
            symbolInfoRepository: isolateSl<ISymbolInfoRepository>(),
            serviceLocator: isolateSl,
          ));

  final log = LogManager.getLogger();
  log.i('Populating SymbolInfo cache for atomic isolate...');
  final result =
      await isolateSl<ISymbolInfoRepository>().refreshSymbolInfoCache();
  result.fold(
    (f) => log.e('Failed to populate cache in isolate: $f'),
    (_) => log.i('Cache populated in isolate.'),
  );
}
