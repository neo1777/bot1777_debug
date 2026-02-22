import 'package:get_it/get_it.dart';
import 'package:neotradingbotback1777/application/use_cases/cancel_all_orders_use_case.dart';
import 'package:neotradingbotback1777/application/use_cases/cancel_order_use_case.dart';
import 'package:neotradingbotback1777/application/use_cases/run_backtest_use_case.dart';
import 'package:neotradingbotback1777/domain/repositories/backtest_result_repository.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/in_memory/in_memory_backtest_result_repository.dart';
import 'package:neotradingbotback1777/domain/services/i_trading_api_service.dart';
import 'package:neotradingbotback1777/application/use_cases/get_log_settings_use_case.dart';
import 'package:neotradingbotback1777/application/use_cases/get_open_orders_use_case.dart';
import 'package:neotradingbotback1777/application/use_cases/get_trade_history_use_case.dart';
import 'package:neotradingbotback1777/application/use_cases/pause_trading_use_case.dart';
import 'package:neotradingbotback1777/application/use_cases/resume_trading_use_case.dart';
import 'package:neotradingbotback1777/application/use_cases/stop_strategy_use_case.dart';
import 'package:neotradingbotback1777/application/use_cases/update_log_settings_use_case.dart';
import 'package:neotradingbotback1777/application/use_cases/get_and_validate_symbol_quantity_use_case.dart';
import 'package:neotradingbotback1777/application/use_cases/get_account_info_use_case.dart';
import 'package:neotradingbotback1777/application/use_cases/get_settings_use_case.dart';
import 'package:neotradingbotback1777/application/use_cases/get_strategy_state_use_case.dart';
import 'package:neotradingbotback1777/application/use_cases/update_settings_use_case.dart';
import 'package:neotradingbotback1777/application/use_cases/send_status_report_use_case.dart';
import 'package:neotradingbotback1777/application/managers/atomic_state_manager.dart';
import 'package:neotradingbotback1777/application/services/trading_loop/atomic_action_processor.dart';
import 'package:neotradingbotback1777/application/use_cases/start_strategy_atomic_use_case.dart';
import 'package:neotradingbotback1777/application/services/trading_loop/trading_loop_communication_service.dart';
import 'package:neotradingbotback1777/application/managers/trading_loop_manager.dart';
import 'package:neotradingbotback1777/application/use_cases/get_symbol_limits_use_case.dart';
import 'package:neotradingbotback1777/domain/repositories/strategy_state_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/i_symbol_info_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/account_repository.dart';
import 'package:neotradingbotback1777/domain/services/trading_signal_analyzer.dart';
import 'package:neotradingbotback1777/domain/services/trade_evaluator_service.dart';

Future<void> registerApplicationDependencies(GetIt sl) async {
  sl.registerLazySingleton<TradingLoopManager>(() => TradingLoopManager());
  sl.registerLazySingleton<AtomicStateManager>(
      () => AtomicStateManager(sl<StrategyStateRepository>()));

  sl.registerLazySingleton<TradingSignalAnalyzer>(
      () => TradingSignalAnalyzer(sl<TradeEvaluatorService>()));

  sl.registerLazySingleton<AtomicActionProcessor>(() => AtomicActionProcessor(
      sl<AtomicStateManager>(), TradingLoopCommunicationService(), sl));

  sl.registerFactory<GetSettings>(() => GetSettings(sl()));
  sl.registerFactory<UpdateSettings>(() => UpdateSettings(sl()));
  sl.registerFactory<GetStrategyState>(
      () => GetStrategyState(sl<StrategyStateRepository>()));
  sl.registerFactory<StopStrategy>(() =>
      StopStrategy(sl<StrategyStateRepository>(), sl<TradingLoopManager>()));
  sl.registerFactory<PauseTrading>(
      () => PauseTrading(sl<StrategyStateRepository>()));
  sl.registerFactory<ResumeTrading>(
      () => ResumeTrading(sl<StrategyStateRepository>()));
  sl.registerFactory<GetTradeHistory>(() => GetTradeHistory(sl(), sl()));
  sl.registerFactory<GetAccountInfo>(
      () => GetAccountInfo(sl<AccountRepository>()));
  sl.registerFactory<GetSymbolLimits>(
      () => GetSymbolLimits(sl<ISymbolInfoRepository>()));
  sl.registerFactory<GetOpenOrders>(() => GetOpenOrders(sl()));
  sl.registerFactory<GetLogSettings>(() => GetLogSettings(sl()));
  sl.registerFactory<UpdateLogSettings>(() => UpdateLogSettings(sl()));
  sl.registerFactory<CancelOrderUseCase>(() => CancelOrderUseCase(sl()));
  sl.registerFactory<CancelAllOrdersUseCase>(
      () => CancelAllOrdersUseCase(sl()));
  sl.registerFactory<StartStrategyAtomic>(() =>
      StartStrategyAtomic(sl<TradingLoopManager>(), sl<AtomicStateManager>()));
  sl.registerFactory<GetAndValidateSymbolQuantityUseCase>(
      () => GetAndValidateSymbolQuantityUseCase(sl<ISymbolInfoRepository>()));
  sl.registerFactory<SendStatusReport>(
      () => SendStatusReport(sl(), sl(), sl(), sl()));

  // Backtest
  sl.registerLazySingleton<BacktestResultRepository>(
      () => InMemoryBacktestResultRepository());
  sl.registerFactory<RunBacktestUseCase>(
      () => RunBacktestUseCase(sl<ITradingApiService>()));
}
