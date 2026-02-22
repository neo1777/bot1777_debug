import 'package:fixnum/fixnum.dart';
import 'package:neotradingbotback1777/domain/entities/account_info.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart'
    as entity_state;
import 'package:neotradingbotback1777/domain/entities/app_trade.dart';
import 'package:neotradingbotback1777/domain/entities/log_settings.dart';
import 'package:neotradingbotback1777/domain/entities/symbol_info.dart';
import 'package:neotradingbotback1777/domain/entities/strategy_state.dart'
    as domain_state;
import 'package:neotradingbotback1777/generated/proto/trading/v1/trading_service.pb.dart'
    as grpc;

extension AppSettingsGrpcMapper on AppSettings {
  grpc.Settings toGrpc() => grpc.Settings(
        tradeAmount: tradeAmount,
        fixedQuantityStr: fixedQuantity?.toString() ?? '',
        profitTargetPercentage: profitTargetPercentage,
        stopLossPercentage: stopLossPercentage,
        dcaDecrementPercentage: dcaDecrementPercentage,
        maxOpenTrades: maxOpenTrades,
        isTestMode: isTestMode,
        buyOnStart: buyOnStart,
        initialWarmupTicks: initialWarmupTicks,
        initialWarmupSecondsStr: initialWarmupSeconds.toString(),
        initialSignalThresholdPctStr: initialSignalThresholdPct.toString(),
        maxBuyOveragePctStr: maxBuyOveragePct.toString(),
        strictBudget: strictBudget,
        buyOnStartRespectWarmup: buyOnStartRespectWarmup,
        buyCooldownSecondsStr: buyCooldownSeconds.toString(),
        dcaCooldownSecondsStr: dcaCooldownSeconds.toString(),
        dustRetryCooldownSecondsStr: dustRetryCooldownSeconds.toString(),
        maxTradeAmountCapStr: maxTradeAmountCap.toString(),
        dcaCompareAgainstAverage: dcaCompareAgainstAverage,
        maxCycles: maxCycles,
        enableFeeAwareTrading: enableFeeAwareTrading,
        enableReBuy: enableReBuy,
        tradeAmountStr: tradeAmount.toString(),
        profitTargetPercentageStr: profitTargetPercentage.toString(),
        stopLossPercentageStr: stopLossPercentage.toString(),
        dcaDecrementPercentageStr: dcaDecrementPercentage.toString(),
      );
}

extension GrpcSettingsMapper on grpc.Settings {
  AppSettings toDomain() {
    double parse(String s, double fallback) {
      if (s.isEmpty) return fallback;
      return double.tryParse(s) ?? fallback;
    }

    return AppSettings(
      tradeAmount: parse(tradeAmountStr, tradeAmount),
      fixedQuantity:
          (fixedQuantityStr.isEmpty || double.tryParse(fixedQuantityStr) == 0.0)
              ? null
              : double.tryParse(fixedQuantityStr),
      profitTargetPercentage:
          parse(profitTargetPercentageStr, profitTargetPercentage),
      stopLossPercentage: parse(stopLossPercentageStr, stopLossPercentage),
      dcaDecrementPercentage:
          parse(dcaDecrementPercentageStr, dcaDecrementPercentage),
      maxOpenTrades: maxOpenTrades,
      isTestMode: isTestMode,
      buyOnStart: buyOnStart,
      initialWarmupTicks: initialWarmupTicks,
      initialWarmupSeconds: parse(initialWarmupSecondsStr, 0.0),
      initialSignalThresholdPct: parse(initialSignalThresholdPctStr, 0.0),
      maxBuyOveragePct: parse(maxBuyOveragePctStr, 0.03),
      strictBudget: strictBudget,
      buyOnStartRespectWarmup: buyOnStartRespectWarmup,
      buyCooldownSeconds: parse(buyCooldownSecondsStr, 2.0),
      dcaCooldownSeconds: parse(dcaCooldownSecondsStr, 3.0),
      dustRetryCooldownSeconds: parse(dustRetryCooldownSecondsStr, 15.0),
      maxTradeAmountCap: parse(maxTradeAmountCapStr, 100.0),
      dcaCompareAgainstAverage: dcaCompareAgainstAverage,
      maxCycles: maxCycles,
      enableFeeAwareTrading: enableFeeAwareTrading,
      enableReBuy: enableReBuy,
    );
  }
}

extension AppStrategyStateGrpcMapper on entity_state.AppStrategyState {
  grpc.StrategyStateResponse toGrpc() => grpc.StrategyStateResponse(
        symbol: symbol,
        status: _mapStrategyStatusToGrpc(status),
        openTradesCount: openTrades.length,
        averagePrice: averagePrice,
        totalQuantity: totalQuantity.toDouble(),
        lastBuyPrice: lastBuyPrice,
        currentRoundId: currentRoundId,
        cumulativeProfit: cumulativeProfit,
        successfulRounds: successfulRounds,
        failedRounds: failedRounds,
        averagePriceStr: averagePrice.toString(),
        totalQuantityStr: totalQuantity.toString(),
        lastBuyPriceStr: lastBuyPrice.toString(),
        cumulativeProfitStr: cumulativeProfit.toString(),
      );
}

extension AppTradeGrpcMapper on AppTrade {
  grpc.Trade toGrpc() => grpc.Trade(
        symbol: symbol,
        price: price.toDouble(),
        quantity: quantity.toDouble(),
        isBuy: isBuy,
        timestamp: Int64(timestamp),
        orderStatus: orderStatus,
        profit: profit?.toDouble(),
        priceStr: price.toDouble().toString(),
        quantityStr: quantity.toDouble().toString(),
        profitStr: profit != null ? profit!.toDouble().toString() : '',
      );
}

extension SymbolInfoGrpcMapper on SymbolInfo {
  grpc.SymbolLimitsResponse toGrpc() => grpc.SymbolLimitsResponse(
        symbol: symbol,
        minQty: minQty,
        maxQty: maxQty,
        stepSize: stepSize,
        minNotional: minNotional,
      );
}

extension AccountInfoGrpcMapper on AccountInfo {
  grpc.AccountInfoResponse toGrpc() => grpc.AccountInfoResponse(
        balances: balances
            .map((b) => grpc.BalanceProto(
                  asset: b.asset,
                  free: b.free,
                  locked: b.locked,
                  estimatedValueUSDC: b.estimatedValueUSDC,
                  freeStr: b.free.toString(),
                  lockedStr: b.locked.toString(),
                  estimatedValueUSDCStr: b.estimatedValueUSDC.toString(),
                ))
            .toList(),
        totalEstimatedValueUSDC: totalEstimatedValueUSDC,
        totalEstimatedValueUSDCStr: totalEstimatedValueUSDC.toString(),
      );
}

extension LogSettingsGrpcMapper on LogSettings {
  grpc.LogSettingsProto toGrpc() => grpc.LogSettingsProto(
        logLevel: logLevel,
        enableFileLogging: enableFileLogging,
        enableConsoleLogging: enableConsoleLogging,
      );
}

// Private helper for status mapping (needed by strategy state mapper)
grpc.StrategyStatus _mapStrategyStatusToGrpc(
    domain_state.StrategyState status) {
  switch (status) {
    case domain_state.StrategyState.IDLE:
      return grpc.StrategyStatus.STRATEGY_STATUS_IDLE;
    case domain_state.StrategyState.MONITORING_FOR_BUY:
    case domain_state.StrategyState.POSITION_OPEN_MONITORING_FOR_SELL:
    case domain_state.StrategyState.BUY_ORDER_PLACED:
    case domain_state.StrategyState.SELL_ORDER_PLACED:
      return grpc.StrategyStatus.STRATEGY_STATUS_RUNNING;
    case domain_state.StrategyState.PAUSED:
      return grpc.StrategyStatus.STRATEGY_STATUS_PAUSED;
  }
}
