import 'package:hive_ce/hive.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';

part 'app_settings_hive_dto.g.dart'; // Assicurati di rigenerare questo file con build_runner

/// DTO (Data Transfer Object) per la persistenza di [AppSettings] con Hive.
@HiveType(typeId: 3) // Manteniamo lo stesso typeId per la compatibilità
class AppSettingsHiveDto extends HiveObject {
  @HiveField(0)
  double? tradeAmount;

  @HiveField(17)
  double? fixedQuantity;

  @HiveField(1)
  double? profitTargetPercentage;

  @HiveField(2)
  double? stopLossPercentage;

  @HiveField(3)
  double? dcaDecrementPercentage;

  @HiveField(4)
  int? maxOpenTrades;

  @HiveField(5)
  bool? isTestMode;

  // Nuovi campi avvio strategia
  @HiveField(6)
  bool? buyOnStart;

  @HiveField(7)
  int? initialWarmupTicks;

  @HiveField(8)
  double? initialWarmupSeconds;

  @HiveField(9)
  double? initialSignalThresholdPct;

  // Nuovi campi robustezza
  @HiveField(10)
  double? dcaCooldownSeconds;

  @HiveField(11)
  double? dustRetryCooldownSeconds;

  @HiveField(12)
  double? maxTradeAmountCap;

  @HiveField(14)
  double? maxBuyOveragePct;

  @HiveField(18)
  bool? strictBudget;

  @HiveField(19)
  bool? buyOnStartRespectWarmup;

  @HiveField(20)
  double? buyCooldownSeconds;

  // Nuovi campi strategia
  @HiveField(13)
  bool? dcaCompareAgainstAverage;

  // Numero massimo cicli (0 = infinito)
  @HiveField(15)
  int? maxCycles;

  // Trading con fee consapevoli
  @HiveField(16)
  bool? enableFeeAwareTrading;

  /// Converte un'entità di dominio [AppSettings] in un [AppSettingsHiveDto].
  static AppSettingsHiveDto fromEntity(AppSettings entity) {
    return AppSettingsHiveDto()
      ..tradeAmount = entity.tradeAmount
      ..fixedQuantity = entity.fixedQuantity
      ..profitTargetPercentage = entity.profitTargetPercentage
      ..stopLossPercentage = entity.stopLossPercentage
      ..dcaDecrementPercentage = entity.dcaDecrementPercentage
      ..maxOpenTrades = entity.maxOpenTrades
      ..isTestMode = entity.isTestMode
      ..buyOnStart = entity.buyOnStart
      ..initialWarmupTicks = entity.initialWarmupTicks
      ..initialWarmupSeconds = entity.initialWarmupSeconds
      ..initialSignalThresholdPct = entity.initialSignalThresholdPct
      ..dcaCooldownSeconds = entity.dcaCooldownSeconds
      ..dustRetryCooldownSeconds = entity.dustRetryCooldownSeconds
      ..maxTradeAmountCap = entity.maxTradeAmountCap
      ..maxBuyOveragePct = entity.maxBuyOveragePct
      ..strictBudget = entity.strictBudget
      ..buyOnStartRespectWarmup = entity.buyOnStartRespectWarmup
      ..buyCooldownSeconds = entity.buyCooldownSeconds
      ..dcaCompareAgainstAverage = entity.dcaCompareAgainstAverage
      ..maxCycles = entity.maxCycles
      ..enableFeeAwareTrading = entity.enableFeeAwareTrading;
  }

  /// Converte questo DTO in un'entità di dominio [AppSettings].
  AppSettings toEntity() {
    return AppSettings(
      tradeAmount: tradeAmount ?? 56.0,
      fixedQuantity: fixedQuantity,
      profitTargetPercentage: profitTargetPercentage ?? 0.5,
      stopLossPercentage: stopLossPercentage ?? 99.0,
      dcaDecrementPercentage: dcaDecrementPercentage ?? 0.77,
      maxOpenTrades: maxOpenTrades ?? 100,
      isTestMode: isTestMode ?? false,
      buyOnStart: buyOnStart ?? false,
      initialWarmupTicks: initialWarmupTicks ?? 1,
      initialWarmupSeconds: initialWarmupSeconds ?? 0.0,
      initialSignalThresholdPct: initialSignalThresholdPct ?? 0.0,
      dcaCooldownSeconds: dcaCooldownSeconds ?? 3.0,
      dustRetryCooldownSeconds: dustRetryCooldownSeconds ?? 15.0,
      maxTradeAmountCap: maxTradeAmountCap ?? 100.0,
      maxBuyOveragePct: maxBuyOveragePct ?? 0.03,
      strictBudget: strictBudget ?? false,
      buyOnStartRespectWarmup: buyOnStartRespectWarmup ?? true,
      buyCooldownSeconds: buyCooldownSeconds ?? 2.0,
      dcaCompareAgainstAverage: dcaCompareAgainstAverage ?? false,
      maxCycles: maxCycles ?? 0,
      enableFeeAwareTrading: enableFeeAwareTrading ?? true,
    );
  }
}
