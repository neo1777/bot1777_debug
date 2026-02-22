import 'package:decimal/decimal.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/fifo_app_trade.dart';
import 'package:neotradingbotback1777/domain/entities/strategy_state.dart';

/// Builder per [AppSettings]
class AppSettingsBuilder {
  AppSettings _state = AppSettings.initial();

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

  AppSettingsBuilder buyOnStart(bool val) {
    _state = _state.copyWith(buyOnStart: val);
    return this;
  }

  AppSettings build() => _state;
}

/// Builder per [FifoAppTrade]
class FifoAppTradeBuilder {
  FifoAppTrade _state = FifoAppTrade(
    price: Decimal.parse('100.0'),
    quantity: Decimal.parse('1.0'),
    timestamp: DateTime.now().millisecondsSinceEpoch,
    roundId: 1,
  );

  FifoAppTradeBuilder price(Decimal val) {
    _state = _state.copyWith(price: val);
    return this;
  }

  FifoAppTradeBuilder quantity(Decimal val) {
    _state = _state.copyWith(quantity: val);
    return this;
  }

  FifoAppTradeBuilder timestamp(int val) {
    _state = _state.copyWith(timestamp: val);
    return this;
  }

  FifoAppTradeBuilder roundId(int val) {
    _state = _state.copyWith(roundId: val);
    return this;
  }

  FifoAppTradeBuilder status(String val) {
    _state = _state.copyWith(orderStatus: val);
    return this;
  }

  FifoAppTrade build() => _state;
}

/// Builder per [AppStrategyState]
class AppStrategyStateBuilder {
  AppStrategyState _state = AppStrategyState(
    symbol: 'BTCUSDC',
    status: StrategyState.IDLE,
    openTrades: [],
    currentRoundId: 1,
  );

  AppStrategyStateBuilder symbol(String val) {
    _state = _state.copyWith(symbol: val);
    return this;
  }

  AppStrategyStateBuilder status(StrategyState val) {
    _state = _state.copyWith(status: val);
    return this;
  }

  AppStrategyStateBuilder openTrades(List<FifoAppTrade> val) {
    _state = _state.copyWith(openTrades: val);
    return this;
  }

  AppStrategyStateBuilder roundId(int val) {
    _state = _state.copyWith(currentRoundId: val);
    return this;
  }

  AppStrategyStateBuilder profit(double val) {
    _state = _state.copyWith(cumulativeProfit: val);
    return this;
  }

  AppStrategyState build() => _state;
}
