import 'package:neotradingbotfront1777/domain/entities/app_settings.dart';
import 'package:neotradingbotfront1777/domain/entities/app_trade.dart';
import 'package:neotradingbotfront1777/domain/entities/strategy_state.dart';

/// Builder per [AppSettings] Frontend
class AppSettingsBuilder {
  AppSettings _state = const AppSettings(
    tradeAmount: 100.0,
    profitTargetPercentage: 1.5,
    stopLossPercentage: 5.0,
    dcaDecrementPercentage: 2.0,
    maxOpenTrades: 5,
    isTestMode: true,
  );

  AppSettingsBuilder tradeAmount(double val) {
    _state = _state.copyWith(tradeAmount: val);
    return this;
  }

  AppSettingsBuilder profitTarget(double val) {
    _state = _state.copyWith(profitTargetPercentage: val);
    return this;
  }

  AppSettingsBuilder stopLoss(double val) {
    _state = _state.copyWith(stopLossPercentage: val);
    return this;
  }

  AppSettingsBuilder dcaDecrement(double val) {
    _state = _state.copyWith(dcaDecrementPercentage: val);
    return this;
  }

  AppSettingsBuilder maxTrades(int val) {
    _state = _state.copyWith(maxOpenTrades: val);
    return this;
  }

  AppSettingsBuilder testMode(bool val) {
    _state = _state.copyWith(isTestMode: val);
    return this;
  }

  AppSettings build() => _state;
}

/// Builder per [AppTrade] Frontend
class AppTradeBuilder {
  AppTrade _state = AppTrade(
    symbol: 'BTCUSDC',
    price: 100.0,
    quantity: 1.0,
    isBuy: true,
    timestamp: DateTime.now(),
    orderStatus: 'FILLED',
  );

  AppTradeBuilder symbol(String val) {
    _state = _state.copyWith(symbol: val);
    return this;
  }

  AppTradeBuilder price(double val) {
    _state = _state.copyWith(price: val);
    return this;
  }

  AppTradeBuilder quantity(double val) {
    _state = _state.copyWith(quantity: val);
    return this;
  }

  AppTradeBuilder isBuy(bool val) {
    _state = _state.copyWith(isBuy: val);
    return this;
  }

  AppTradeBuilder timestamp(DateTime val) {
    _state = _state.copyWith(timestamp: val);
    return this;
  }

  AppTradeBuilder status(String val) {
    _state = _state.copyWith(orderStatus: val);
    return this;
  }

  AppTrade build() => _state;
}

/// Builder per [StrategyState] Frontend
class StrategyStateBuilder {
  StrategyState _state = const StrategyState(
    symbol: 'BTCUSDC',
    status: StrategyStatus.idle,
    openTradesCount: 0,
    averagePrice: 0.0,
    totalQuantity: 0.0,
    lastBuyPrice: 0.0,
    currentRoundId: 0,
    cumulativeProfit: 0.0,
    successfulRounds: 0,
    failedRounds: 0,
  );

  StrategyStateBuilder symbol(String val) {
    _state = _state.copyWith(symbol: val);
    return this;
  }

  StrategyStateBuilder status(StrategyStatus val) {
    _state = _state.copyWith(status: val);
    return this;
  }

  StrategyStateBuilder openTradesCount(int val) {
    _state = _state.copyWith(openTradesCount: val);
    return this;
  }

  StrategyStateBuilder averagePrice(double val) {
    _state = _state.copyWith(averagePrice: val);
    return this;
  }

  StrategyStateBuilder totalQuantity(double val) {
    _state = _state.copyWith(totalQuantity: val);
    return this;
  }

  StrategyStateBuilder lastBuyPrice(double val) {
    _state = _state.copyWith(lastBuyPrice: val);
    return this;
  }

  StrategyStateBuilder currentRoundId(int val) {
    _state = _state.copyWith(currentRoundId: val);
    return this;
  }

  StrategyStateBuilder cumulativeProfit(double val) {
    _state = _state.copyWith(cumulativeProfit: val);
    return this;
  }

  StrategyState build() => _state;
}
