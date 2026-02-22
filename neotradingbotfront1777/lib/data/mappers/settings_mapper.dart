import 'package:neotradingbotfront1777/domain/entities/app_settings.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pb.dart'
    as grpc;

/// Converte un DTO gRPC [grpc.Settings] nell'entità di dominio [AppSettings].
AppSettings settingsFromProto(grpc.Settings proto) {
  double parseDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  final m = proto.toProto3Json() as Map<String, dynamic>;
  return AppSettings(
    tradeAmount: parseDouble(m['tradeAmountStr'] ?? proto.tradeAmount),
    fixedQuantity:
        parseDouble(m['fixedQuantityStr']) == 0.0
            ? null
            : parseDouble(m['fixedQuantityStr']),
    profitTargetPercentage: parseDouble(
      m['profitTargetPercentageStr'] ?? proto.profitTargetPercentage,
    ),
    stopLossPercentage: parseDouble(
      m['stopLossPercentageStr'] ?? proto.stopLossPercentage,
    ),
    dcaDecrementPercentage: parseDouble(
      m['dcaDecrementPercentageStr'] ?? proto.dcaDecrementPercentage,
    ),
    maxOpenTrades: proto.maxOpenTrades,
    isTestMode: proto.isTestMode,
    buyOnStart: proto.buyOnStart,
    initialWarmupTicks: proto.initialWarmupTicks,
    initialWarmupSeconds: parseDouble(m['initialWarmupSecondsStr']),
    initialSignalThresholdPct: parseDouble(m['initialSignalThresholdPctStr']),
    dcaCooldownSeconds: parseDouble(m['dcaCooldownSecondsStr']),
    dustRetryCooldownSeconds: parseDouble(m['dustRetryCooldownSecondsStr']),
    maxTradeAmountCap: parseDouble(m['maxTradeAmountCapStr']),
    maxBuyOveragePct: parseDouble(m['maxBuyOveragePctStr']),
    strictBudget: proto.strictBudget,
    buyOnStartRespectWarmup: proto.buyOnStartRespectWarmup,
    buyCooldownSeconds: parseDouble(m['buyCooldownSecondsStr']),
    dcaCompareAgainstAverage: proto.dcaCompareAgainstAverage,

    maxCycles: proto.maxCycles,
    enableFeeAwareTrading: proto.enableFeeAwareTrading,
    enableReBuy: proto.enableReBuy,
  );
}

/// Converte un'entità di dominio [AppSettings] nel DTO gRPC [grpc.Settings].
grpc.Settings settingsToProto(AppSettings entity) {
  return grpc.Settings(
    // legacy doubles (ancora presenti)
    tradeAmount: entity.tradeAmount,
    fixedQuantityStr: entity.fixedQuantity?.toString() ?? '',
    profitTargetPercentage: entity.profitTargetPercentage,
    stopLossPercentage: entity.stopLossPercentage,
    dcaDecrementPercentage: entity.dcaDecrementPercentage,
    maxOpenTrades: entity.maxOpenTrades,
    isTestMode: entity.isTestMode,
    buyOnStart: entity.buyOnStart,
    initialWarmupTicks: entity.initialWarmupTicks,
    // nuovi campi string
    initialWarmupSecondsStr: entity.initialWarmupSeconds.toString(),
    initialSignalThresholdPctStr: entity.initialSignalThresholdPct.toString(),
    dcaCooldownSecondsStr: entity.dcaCooldownSeconds.toString(),
    dustRetryCooldownSecondsStr: entity.dustRetryCooldownSeconds.toString(),
    maxTradeAmountCapStr: entity.maxTradeAmountCap.toString(),
    maxBuyOveragePctStr: entity.maxBuyOveragePct.toString(),
    strictBudget: entity.strictBudget,
    buyOnStartRespectWarmup: entity.buyOnStartRespectWarmup,
    buyCooldownSecondsStr: entity.buyCooldownSeconds.toString(),
    dcaCompareAgainstAverage: entity.dcaCompareAgainstAverage,

    maxCycles: entity.maxCycles,
    enableFeeAwareTrading: entity.enableFeeAwareTrading,
    enableReBuy: entity.enableReBuy,
    // spec string principali
    tradeAmountStr: entity.tradeAmount.toString(),
    profitTargetPercentageStr: entity.profitTargetPercentage.toString(),
    stopLossPercentageStr: entity.stopLossPercentage.toString(),
    dcaDecrementPercentageStr: entity.dcaDecrementPercentage.toString(),
  );
}
