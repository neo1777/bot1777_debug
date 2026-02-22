import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/strategy_state.dart';

import 'package:neotradingbotback1777/domain/services/trade_evaluator_service.dart';
import 'package:neotradingbotback1777/core/utils/decimal_compare.dart';
import 'package:neotradingbotback1777/core/utils/decimal_utils.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:decimal/decimal.dart';

class TradingSignalAnalyzer {
  final TradeEvaluatorService _tradeEvaluator;
  final _log = LogManager.getLogger();

  TradingSignalAnalyzer(this._tradeEvaluator);

  bool shouldBuy(
    double currentPrice,
    AppStrategyState state,
    AppSettings settings,
    bool inCooldown,
    bool warmupDone, {
    double? availableBalance,
  }) {
    if (!warmupDone) return false;
    if (inCooldown) return false;
    if (state.status != StrategyState.MONITORING_FOR_BUY) return false;

    return _tradeEvaluator.shouldBuyGuarded(
      currentPrice: currentPrice,
      state: state,
      settings: settings,
      allowInitialBuy: true,
      availableBalance: availableBalance,
    );
  }

  Future<bool> shouldSell(double currentPrice, AppStrategyState state,
      AppSettings settings, bool inDustCooldown) async {
    if (state.status != StrategyState.POSITION_OPEN_MONITORING_FOR_SELL)
      return false;

    if (settings.enableFeeAwareTrading) {
      return await _tradeEvaluator.shouldSellWithFees(
        currentPrice: currentPrice,
        state: state,
        settings: settings,
        inDustCooldown: inDustCooldown,
      );
    }

    return _tradeEvaluator.shouldSell(
      currentPrice: currentPrice,
      state: state,
      settings: settings,
      inDustCooldown: inDustCooldown,
    );
  }

  bool shouldDca(
    double currentPrice,
    AppStrategyState state,
    AppSettings settings,
    bool inDcaCooldown, {
    double? availableBalance,
  }) {
    if (inDcaCooldown) return false;

    final conditionMet = _tradeEvaluator.shouldDcaBuy(
      currentPrice: currentPrice,
      state: state,
      settings: settings,
      compareAgainstAverage: settings.dcaCompareAgainstAverage,
      availableBalance: availableBalance,
    );

    if (!conditionMet) {
      final referencePrice = settings.dcaCompareAgainstAverage
          ? state.validatedAveragePrice
          : state.lastValidBuyPrice;
      if (referencePrice > 0) {
        _logDcaDiagnostic(currentPrice, referencePrice, state, settings);
      }
    }

    return conditionMet;
  }

  void _logDcaDiagnostic(double currentPrice, double referencePrice,
      AppStrategyState state, AppSettings settings) {
    final Decimal decPct = referencePrice > 0
        ? DecimalCompare.percentChange(currentPrice, referencePrice)
        : Decimal.zero;

    _log.d(
        '[DCA_DIAG] No DCA signal | decrement ${DecimalUtils.toDouble(decPct).toStringAsFixed(4)}% > -${settings.dcaDecrementPercentage}% | reference=$referencePrice');
  }
}
