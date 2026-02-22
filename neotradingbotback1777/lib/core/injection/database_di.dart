import 'dart:io';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;
import 'package:neotradingbotback1777/core/config/constants.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/entities/log_settings.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/account_info_hive_dto.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/app_settings_hive_dto.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/app_strategy_state_hive_dto.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/app_trade_hive_dto.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/balance_hive_dto.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/fifo_app_trade_hive_dto.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/log_settings_hive_dto.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/symbol_info_hive_dto.dart';

Future<void> initDatabase(GetIt sl) async {
  final dbPath = p.join(Directory.current.path, 'hive_data');
  Hive.init(dbPath);

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(AppTradeHiveDtoAdapter());
    Hive.registerAdapter(FifoAppTradeHiveDtoAdapter());
    Hive.registerAdapter(AppStrategyStateHiveDtoAdapter());
    Hive.registerAdapter(AppSettingsHiveDtoAdapter());
    Hive.registerAdapter(SymbolInfoHiveDtoAdapter());
    Hive.registerAdapter(AccountInfoHiveDtoAdapter());
    Hive.registerAdapter(BalanceHiveDtoAdapter());
    Hive.registerAdapter(LogSettingsHiveDtoAdapter());
  }

  await openAndRegisterBoxes(sl);
}

Future<void> openAndRegisterBoxes(GetIt currentSl) async {
  final tradesBox =
      await Hive.openBox<AppTradeHiveDto>(Constants.tradesHistoryBoxName);
  currentSl.registerSingleton<Box<AppTradeHiveDto>>(tradesBox);

  final fifoBox =
      await Hive.openBox<FifoAppTradeHiveDto>(Constants.fifoTradesBoxName);
  currentSl.registerSingleton<Box<FifoAppTradeHiveDto>>(fifoBox);

  final strategyStateBox = await Hive.openBox<AppStrategyStateHiveDto>(
      Constants.tradingRepositoryBoxName);
  currentSl.registerSingleton<Box<AppStrategyStateHiveDto>>(strategyStateBox);

  final settingsBox =
      await Hive.openBox<AppSettingsHiveDto>(Constants.appSettingsBoxName);
  currentSl.registerSingleton<Box<AppSettingsHiveDto>>(settingsBox);

  final logSettingsBox =
      await Hive.openBox<LogSettingsHiveDto>(Constants.logSettingsBoxName);
  currentSl.registerSingleton<Box<LogSettingsHiveDto>>(logSettingsBox);

  final symbolInfoBox =
      await Hive.openBox<SymbolInfoHiveDto>(Constants.symbolInfoBoxName);
  currentSl.registerSingleton<Box<SymbolInfoHiveDto>>(symbolInfoBox);

  final accountInfoBox =
      await Hive.openBox<AccountInfoHiveDto>(Constants.accountInfoBoxName);
  currentSl.registerSingleton<Box<AccountInfoHiveDto>>(accountInfoBox);

  final balanceBox =
      await Hive.openBox<BalanceHiveDto>(Constants.balanceBoxName);
  currentSl.registerSingleton<Box<BalanceHiveDto>>(balanceBox);

  currentSl.registerSingleton<Box<double>>(
      await Hive.openBox<double>(Constants.priceBoxName));
  currentSl.registerSingleton<Box<Map>>(
      await Hive.openBox<Map>(Constants.transactionJournalBoxName));

  // Default setup
  if (!settingsBox.containsKey(Constants.appSettingsKey)) {
    await settingsBox.put(Constants.appSettingsKey,
        AppSettingsHiveDto.fromEntity(AppSettings.initial()));
    LogManager.getLogger().i('Impostazioni di default create.');
  }
  if (!logSettingsBox.containsKey(Constants.logSettingsKey)) {
    await logSettingsBox.put(Constants.logSettingsKey,
        LogSettingsHiveDto.fromEntity(LogSettings.defaultSettings()));
    LogManager.getLogger().i('Impostazioni di log di default create.');
  }
}
