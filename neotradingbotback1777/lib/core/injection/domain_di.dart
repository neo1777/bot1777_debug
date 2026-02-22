import 'package:get_it/get_it.dart';
import 'package:neotradingbotback1777/domain/repositories/trading_repository_new.dart';
import 'package:neotradingbotback1777/domain/repositories/strategy_state_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/i_fee_repository.dart';
import 'package:neotradingbotback1777/domain/services/trading_transaction_manager.dart';
import 'package:neotradingbotback1777/domain/services/trade_evaluator_service.dart';
import 'package:neotradingbotback1777/domain/services/fee_calculation_service.dart';
import 'package:neotradingbotback1777/domain/services/profit_calculation_service.dart';
import 'package:neotradingbotback1777/domain/services/settings_validation_service.dart';
import 'package:neotradingbotback1777/domain/services/trade_validation_service.dart';
import 'package:neotradingbotback1777/infrastructure/services/trading_transaction_manager_impl.dart';
import 'package:neotradingbotback1777/core/locks/trading_lock_manager.dart';
import 'package:neotradingbotback1777/core/logging/log_throttler.dart';
import 'package:neotradingbotback1777/core/errors/unified_error_handler.dart';
import 'package:neotradingbotback1777/core/monitoring/business_metrics_monitor.dart';

Future<void> registerDomainDependencies(GetIt sl) async {
  sl.registerLazySingleton<TradingTransactionManager>(
      () => TradingTransactionManagerImpl(
            tradingRepository: sl<TradingRepository>(),
            strategyStateRepository: sl<StrategyStateRepository>(),
          ));

  sl.registerLazySingleton<UnifiedErrorHandler>(() => UnifiedErrorHandler());
  sl.registerLazySingleton<TradingLockManager>(() => TradingLockManager());
  sl.registerLazySingleton<LogThrottler>(() => LogThrottler());

  sl.registerLazySingleton<FeeCalculationService>(() => FeeCalculationService(
        feeRepository: sl<IFeeRepository>(),
        errorHandler: sl<UnifiedErrorHandler>(),
      ));

  sl.registerLazySingleton<TradeEvaluatorService>(() => TradeEvaluatorService(
        feeCalculationService: sl<FeeCalculationService>(),
        tradingLockManager: sl<TradingLockManager>(),
        logThrottler: sl<LogThrottler>(),
        errorHandler: sl<UnifiedErrorHandler>(),
        businessMetricsMonitor: sl<BusinessMetricsMonitor>(),
      ));
  sl.registerLazySingleton<ProfitCalculationService>(
      () => ProfitCalculationService());
  sl.registerLazySingleton<SettingsValidationService>(
      () => SettingsValidationService(errorHandler: sl<UnifiedErrorHandler>()));
  sl.registerLazySingleton<TradeValidationService>(
      () => TradeValidationService());
}
