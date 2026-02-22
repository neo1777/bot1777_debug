import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:hive_ce/hive.dart';
import 'package:neotradingbotback1777/core/config/api_keys_config.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:neotradingbotback1777/domain/repositories/account_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/price_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/strategy_state_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/i_symbol_info_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/settings_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/log_settings_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/trading_repository_new.dart';
import 'package:neotradingbotback1777/domain/repositories/i_fee_repository.dart';
import 'package:neotradingbotback1777/domain/services/i_notification_service.dart';
import 'package:neotradingbotback1777/core/monitoring/business_metrics_monitor.dart';
import 'package:neotradingbotback1777/core/logging/log_stream_service.dart';
import 'package:neotradingbotback1777/domain/services/i_trading_api_service.dart';
import 'package:neotradingbotback1777/infrastructure/notification/telegram_service.dart';
import 'package:neotradingbotback1777/infrastructure/network/binance/api_service.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/account_repository_impl.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/price_repository_impl.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/strategy_state_repository_impl.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/symbol_info_repository_impl.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/settings_repository_impl.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/log_settings_repository_impl.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/trading_repository_impl_new.dart'
    as new_impl;
import 'package:neotradingbotback1777/infrastructure/persistence/fee_repository_impl.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/account_info_hive_dto.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/app_settings_hive_dto.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/app_strategy_state_hive_dto.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/app_trade_hive_dto.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/balance_hive_dto.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/fifo_app_trade_hive_dto.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/log_settings_hive_dto.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/symbol_info_hive_dto.dart';

Future<void> registerInfrastructureDependencies(GetIt sl) async {
  sl.registerSingleton<http.Client>(http.Client());

  sl.registerSingleton<ApiKeysConfig>(() {
    final result = ApiKeysConfig.loadFromEnv();
    return result.fold(
      (failure) {
        LogManager.getLogger()
            .f('Configurazione API keys fallita: ${failure.message}');
        throw StateError('API keys non configurate.');
      },
      (config) => config,
    );
  }());

  // Servizi
  sl.registerLazySingleton<LogStreamService>(() => LogStreamService());
  sl.registerLazySingleton<BusinessMetricsMonitor>(
      () => BusinessMetricsMonitor());

  // Crea ApiService con la modalità iniziale dalle impostazioni salvate
  // Note: la modalità iniziale viene sincronizzata correttamente in initDependencies()
  // dopo che tutti i repository sono registrati e inizializzati.
  sl.registerLazySingleton<ApiService>(() {
    final initialTestMode = false;

    return ApiService(
      apiKeysConfig: sl<ApiKeysConfig>(),
      httpClient: sl<http.Client>(),
      businessMetricsMonitor: sl<BusinessMetricsMonitor>(),
      initialTestMode: initialTestMode,
    );
  });
  sl.registerLazySingleton<ITradingApiService>(() => sl<ApiService>());

  sl.registerLazySingleton<AccountRepository>(() => AccountRepositoryImpl(
        accountInfoBox: sl<Box<AccountInfoHiveDto>>(),
        balanceBox: sl<Box<BalanceHiveDto>>(),
        apiService: sl<ITradingApiService>(),
      ));
  sl.registerLazySingleton<PriceRepository>(() => PriceRepositoryImpl(
        priceBox: sl<Box<double>>(),
        apiService: sl<ITradingApiService>(),
      ));
  sl.registerLazySingleton<StrategyStateRepository>(
      () => StrategyStateRepositoryImpl(
            strategyStateBox: sl<Box<AppStrategyStateHiveDto>>(),
            fifoTradeBox: sl<Box<FifoAppTradeHiveDto>>(),
            apiService: sl<ITradingApiService>(),
          ));
  sl.registerLazySingleton<ISymbolInfoRepository>(
      () => SymbolInfoRepositoryImpl(
            sl<ApiService>(),
            sl<Box<SymbolInfoHiveDto>>(),
          ));
  sl.registerLazySingleton<TradingRepository>(
      () => new_impl.TradingRepositoryImpl(
            tradesBox: sl<Box<AppTradeHiveDto>>(),
            apiService: sl<ITradingApiService>(),
          ));
  sl.registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl(
        settingsBox: sl<Box<AppSettingsHiveDto>>(),
        apiService: sl<ITradingApiService>(),
      ));
  sl.registerLazySingleton<LogSettingsRepository>(
      () => LogSettingsRepositoryImpl(
            logSettingsBox: sl<Box<LogSettingsHiveDto>>(),
          ));
  sl.registerLazySingleton<IFeeRepository>(() => FeeRepositoryImpl(
        apiService: sl<ITradingApiService>(),
      ));

  // Telegram config separata — isolamento delle credenziali
  sl.registerSingleton<TelegramConfig>(TelegramConfig.loadFromEnv());

  sl.registerLazySingleton<INotificationService>(() => TelegramService(
        botToken: sl<TelegramConfig>().botToken,
        chatId: sl<TelegramConfig>().chatId,
        httpClient: sl<http.Client>(),
      ));
}
