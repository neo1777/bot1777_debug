import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:neotradingbotback1777/domain/services/trading_transaction_manager.dart';
import 'package:neotradingbotback1777/infrastructure/services/trading_transaction_manager_impl.dart';
import 'package:neotradingbotback1777/domain/services/i_trading_api_service.dart';
import 'package:neotradingbotback1777/infrastructure/network/binance/api_service.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/app_trade_hive_dto.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/fifo_app_trade_hive_dto.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/app_strategy_state_hive_dto.dart';
import 'package:neotradingbotback1777/domain/repositories/settings_repository.dart';

import 'package:neotradingbotback1777/presentation/grpc/health_service.dart';
import 'package:neotradingbotback1777/presentation/grpc/trading_service_impl.dart';

import 'package:neotradingbotback1777/core/injection/database_di.dart';
import 'package:neotradingbotback1777/core/injection/infrastructure_di.dart';
import 'package:neotradingbotback1777/core/injection/domain_di.dart';
import 'package:neotradingbotback1777/core/injection/application_di.dart';
import 'package:neotradingbotback1777/core/injection/isolate_di.dart'
    as isolate;

export 'package:neotradingbotback1777/core/injection/isolate_di.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // 1. Database
  await initDatabase(sl);

  // 2. Infrastructure
  await registerInfrastructureDependencies(sl);

  // Inizializza la modalità corretta (Real vs Testnet) basata sui settings salvati
  try {
    final settingsRepo = sl<SettingsRepository>();
    final settingsEither = await settingsRepo.getSettings();
    final isTestMode = settingsEither.fold((_) => false, (s) => s.isTestMode);
    sl<ITradingApiService>().updateMode(isTestMode: isTestMode);
  } catch (e) {
    LogManager.getLogger().w('Impossibile inizializzare modalità test: $e');
  }

  await sl<ITradingApiService>().initialize();

  // 3. Domain
  await registerDomainDependencies(sl);

  // 4. Application
  await registerApplicationDependencies(sl);

  // 5. Presentation
  sl.registerLazySingleton<HealthServiceImpl>(() => HealthServiceImpl());
  sl.registerLazySingleton<TradingServiceImpl>(() => TradingServiceImpl());

  // 6. Post-Initialization (Recovery)
  await _runBootRecovery();
}

Future<void> configureDependenciesForIsolate(GetIt isolateSl) =>
    isolate.configureDependenciesForIsolate(isolateSl);

Future<void> configureAtomicIsolateDependencies(GetIt isolateSl) =>
    isolate.configureAtomicIsolateDependencies(isolateSl);

Future<void> _runBootRecovery() async {
  try {
    final txn = sl<TradingTransactionManager>();
    final report = await txn.getTransactionStatistics();
    await report.fold((_) async {}, (_) async {
      final rec = await (sl<TradingTransactionManager>()
              as TradingTransactionManagerImpl)
          .scanAndRepairJournalOnBoot();
      rec.fold(
        (f) => LogManager.getLogger()
            .w('[BOOT] Journal recovery failed: ${f.message}'),
        (ok) => LogManager.getLogger().i('[BOOT] Journal recovery report: $ok'),
      );
    });
  } catch (e, s) {
    LogManager.getLogger()
        .w('[BOOT] Journal recovery check skipped: $e', stackTrace: s);
  }
}

void performGracefulShutdown(String reason) {
  final log = LogManager.getLogger();
  log.w('Graceful shutdown initiated due to: $reason');

  try {
    if (sl.isRegistered<ITradingApiService>()) {
      final apiService = sl<ITradingApiService>();
      if (apiService is ApiService) apiService.dispose();
    }

    if (sl.isRegistered<Box<AppTradeHiveDto>>())
      sl<Box<AppTradeHiveDto>>().close();
    if (sl.isRegistered<Box<FifoAppTradeHiveDto>>())
      sl<Box<FifoAppTradeHiveDto>>().close();
    if (sl.isRegistered<Box<AppStrategyStateHiveDto>>())
      sl<Box<AppStrategyStateHiveDto>>().close();

    log.i('Resources cleaned up. Terminating process.');
  } catch (e) {
    log.e('Error during cleanup: $e');
  }
}
