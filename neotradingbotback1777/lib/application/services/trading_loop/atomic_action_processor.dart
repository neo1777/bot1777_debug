import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:neotradingbotback1777/application/managers/atomic_state_manager.dart';
import 'package:neotradingbotback1777/application/services/trading_loop/trading_loop_communication_service.dart';
import 'package:neotradingbotback1777/application/use_cases/execute_buy_order_atomic_use_case.dart';
import 'package:neotradingbotback1777/application/use_cases/execute_sell_order_atomic_use_case.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:neotradingbotback1777/core/utils/circuit_breaker.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/app_trade.dart';
import 'package:neotradingbotback1777/domain/entities/fifo_app_trade.dart';
import 'package:neotradingbotback1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/account_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/i_symbol_info_repository.dart';
import 'package:neotradingbotback1777/domain/services/i_trading_api_service.dart';
import 'package:neotradingbotback1777/domain/services/i_notification_service.dart';
import 'package:neotradingbotback1777/domain/services/notification_formatter.dart';
import 'package:neotradingbotback1777/domain/value_objects/amounts.dart';
import 'package:decimal/decimal.dart';

class AtomicActionProcessor {
  final AtomicStateManager _stateManager;
  final TradingLoopCommunicationService _comm;
  final GetIt _sl;
  final _log = LogManager.getLogger();

  AtomicActionProcessor(this._stateManager, this._comm, this._sl);

  Future<Either<Failure, AppStrategyState>> processBuy(
    String symbol,
    AppSettings settings,
    double price,
    CircuitBreaker cb,
  ) async {
    final result = await cb.execute<Either<Failure, AppStrategyState>>(() {
      return _stateManager.executeAtomicOperation(symbol, (state) async {
        if (state.status != StrategyState.MONITORING_FOR_BUY) {
          return Right(state);
        }

        final exec = ExecuteBuyOrderAtomic(
          apiService: _sl<ITradingApiService>(),
          symbolInfoRepository: _sl<ISymbolInfoRepository>(),
          accountRepository: _sl<AccountRepository>(),
          symbol: symbol,
          price: price,
          tradeAmount: settings.tradeAmount,
          fixedQuantity: settings.fixedQuantity,
          isTestMode: settings.isTestMode,
          maxBuyOveragePct: settings.maxBuyOveragePct,
          strictBudget: settings.strictBudget,
        );

        final res = await exec();
        return res.fold(
          (f) => Left(f),
          (trade) {
            final fifo = FifoAppTrade(
              price: trade.price.value,
              quantity: trade.quantity.value,
              timestamp: trade.timestamp,
              roundId: state.currentRoundId,
            );
            final newState = state.copyWith(
              openTrades: [...state.openTrades, fifo],
              status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
            );
            _comm.sendTradeStateSync(symbol, trade, newState);
            _notify(NotificationFormatter.formatBuy(
              symbol: symbol,
              trade: trade,
              state: newState,
            ));
            return Right(newState);
          },
        );
      });
    });

    _logActionResult('BUY', symbol, result);
    final buyResult = result.result ??
        Left(UnexpectedFailure(message: 'CB Error: ${result.error}'));
    buyResult.fold(
      (f) => _notify(NotificationFormatter.formatError(
        symbol: symbol,
        action: 'BUY',
        errorMessage: f.message,
      )),
      (_) {},
    );
    return buyResult;
  }

  Future<Either<Failure, AppStrategyState>> processSell(
    String symbol,
    AppSettings settings,
    double price,
    CircuitBreaker cb,
  ) async {
    final result = await cb.execute<Either<Failure, AppStrategyState>>(() {
      return _stateManager.executeAtomicOperation(symbol, (state) async {
        if (state.status != StrategyState.POSITION_OPEN_MONITORING_FOR_SELL) {
          return Right(state);
        }

        final quantityToSell = state.totalQuantity;
        if (quantityToSell <= Decimal.zero) {
          return Right(state.copyWith(
              status: StrategyState.MONITORING_FOR_BUY, openTrades: []));
        }

        final exec = ExecuteSellOrderAtomic(
          apiService: _sl<ITradingApiService>(),
          symbolInfoRepository: _sl<ISymbolInfoRepository>(),
          symbol: symbol,
          quantityToSell: quantityToSell.toDouble(),
          price: price,
          isTestMode: settings.isTestMode,
        );

        final res = await exec();
        return res.fold(
          (f) {
            if (f is BusinessLogicFailure && f.code == 'DUST_UNSELLABLE') {
              return _handleDustDiscard(symbol, price, state);
            }
            return Left(f);
          },
          (sellTrade) {
            final newState = _finalizeSellState(state, sellTrade, settings);
            _comm.sendTradeStateSync(symbol, sellTrade, newState);

            // Calcola P/L % per la notifica
            final avgPrice = state.averagePrice;
            final sellPrice = sellTrade.price.toDouble();
            final profitPct =
                avgPrice > 0 ? ((sellPrice - avgPrice) / avgPrice) * 100 : 0.0;
            _notify(NotificationFormatter.formatSell(
              symbol: symbol,
              trade: sellTrade,
              state: newState,
              profitPercent: profitPct,
            ));
            return Right(newState);
          },
        );
      });
    });

    _logActionResult('SELL', symbol, result);
    final sellResult = result.result ??
        Left(UnexpectedFailure(message: 'CB Error: ${result.error}'));
    sellResult.fold(
      (f) => _notify(NotificationFormatter.formatError(
        symbol: symbol,
        action: 'SELL',
        errorMessage: f.message,
      )),
      (_) {},
    );
    return sellResult;
  }

  Future<Either<Failure, AppStrategyState>> processDca(
    String symbol,
    AppSettings settings,
    double price,
    CircuitBreaker cb,
  ) async {
    final result = await cb.execute<Either<Failure, AppStrategyState>>(() {
      return _stateManager.executeAtomicOperation(symbol, (state) async {
        if (state.status != StrategyState.POSITION_OPEN_MONITORING_FOR_SELL) {
          return Right(state);
        }

        final exec = ExecuteBuyOrderAtomic(
          apiService: _sl<ITradingApiService>(),
          symbolInfoRepository: _sl<ISymbolInfoRepository>(),
          accountRepository: _sl<AccountRepository>(),
          symbol: symbol,
          price: price,
          tradeAmount: settings.tradeAmount,
          fixedQuantity: settings.fixedQuantity,
          isTestMode: settings.isTestMode,
          maxBuyOveragePct: settings.maxBuyOveragePct,
          strictBudget: settings.strictBudget,
        );

        final res = await exec();
        return res.fold(
          (f) => Left(f),
          (trade) {
            final fifo = FifoAppTrade(
              price: trade.price.value,
              quantity: trade.quantity.value,
              timestamp: trade.timestamp,
              roundId: state.currentRoundId,
            );
            final newState = state.copyWith(
              openTrades: [...state.openTrades, fifo],
            );
            _comm.sendTradeStateSync(symbol, trade, newState);
            _notify(NotificationFormatter.formatDca(
              symbol: symbol,
              trade: trade,
              state: newState,
            ));
            return Right(newState);
          },
        );
      });
    });

    _logActionResult('DCA', symbol, result);
    final dcaResult = result.result ??
        Left(UnexpectedFailure(message: 'CB Error: ${result.error}'));
    dcaResult.fold(
      (f) => _notify(NotificationFormatter.formatError(
        symbol: symbol,
        action: 'DCA',
        errorMessage: f.message,
      )),
      (_) {},
    );
    return dcaResult;
  }

  Either<Failure, AppStrategyState> _handleDustDiscard(
      String symbol, double price, AppStrategyState state) {
    final dustQty = state.totalQuantity;
    final dustNotional = (dustQty * Decimal.parse(price.toString())).toDouble();

    final newState = state.copyWith(
      openTrades: [],
      status: StrategyState.MONITORING_FOR_BUY,
      currentRoundId: state.currentRoundId + 1,
      failedRounds: state.failedRounds + 1,
    );

    final dustTrade = AppTrade(
      symbol: symbol,
      price: MoneyAmount.fromDecimal(Decimal.parse(price.toString())),
      quantity: QuantityAmount.fromDecimal(dustQty),
      isBuy: false,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      orderStatus: 'DUST_DISCARDED',
      profit:
          MoneyAmount.fromDecimal(Decimal.parse((-dustNotional).toString())),
    );

    _comm.sendTradeStateSync(symbol, dustTrade, newState);
    _notify(NotificationFormatter.formatDustDiscard(
      symbol: symbol,
      price: price,
    ));
    return Right(newState);
  }

  AppStrategyState _finalizeSellState(
      AppStrategyState state, AppTrade sellTrade, AppSettings settings) {
    double quantityToMatch = sellTrade.quantity.toDouble();
    Decimal totalCostDec = Decimal.zero;
    final List<FifoAppTrade> remainingBuys = [];

    for (final buyTrade in state.openTrades) {
      if (quantityToMatch <= 0) {
        remainingBuys.add(buyTrade);
        continue;
      }

      final buyQty = buyTrade.quantity.toDouble();
      if (buyQty <= quantityToMatch) {
        totalCostDec += buyTrade.quantity * buyTrade.price;
        quantityToMatch -= buyQty;
      } else {
        totalCostDec +=
            Decimal.parse(quantityToMatch.toString()) * buyTrade.price;
        final remainingQty =
            buyTrade.quantity - Decimal.parse(quantityToMatch.toString());
        quantityToMatch = 0.0;
        remainingBuys.add(FifoAppTrade(
          price: buyTrade.price,
          quantity: remainingQty,
          timestamp: buyTrade.timestamp,
          roundId: buyTrade.roundId,
        ));
      }
    }

    final realizedRevenueDec = Decimal.parse(
        (sellTrade.price.toDouble() * sellTrade.quantity.toDouble())
            .toString());
    final realizedProfitDec = realizedRevenueDec - totalCostDec;
    final realizedProfit = double.parse(realizedProfitDec.toString());
    final bool fullyClosed = remainingBuys.isEmpty;

    var newState = state.copyWith(
      openTrades: remainingBuys,
      cumulativeProfit: state.cumulativeProfit + realizedProfit,
      status: fullyClosed
          ? StrategyState.MONITORING_FOR_BUY
          : StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
      currentRoundId:
          fullyClosed ? state.currentRoundId + 1 : state.currentRoundId,
      successfulRounds: fullyClosed && realizedProfit > 0
          ? state.successfulRounds + 1
          : state.successfulRounds,
      failedRounds: fullyClosed && realizedProfit < 0
          ? state.failedRounds + 1
          : state.failedRounds,
    );

    if (fullyClosed &&
        newState.targetRoundId != null &&
        newState.currentRoundId >= newState.targetRoundId!) {
      newState = newState.copyWith(status: StrategyState.IDLE);
    }

    return newState;
  }

  void _logActionResult(String action, String symbol,
      CircuitBreakerResult<Either<Failure, AppStrategyState>> result) {
    if (result.rejectedByCircuitBreaker) {
      _log.w('$action for $symbol rejected by CB: ${result.error}');
    } else if (!result.success) {
      _log.e('$action for $symbol failed (exception): ${result.error}');
    } else {
      result.result?.fold(
        (f) => _log.e('$action for $symbol logic error: ${f.message}'),
        (s) => _log.i('$action for $symbol success. Status: ${s.status.name}'),
      );
    }
  }

  /// Invia una notifica Telegram in modalità fire-and-forget.
  /// Non blocca mai il loop di trading: eventuali errori sono loggati.
  void _notify(String message) {
    try {
      if (_sl.isRegistered<INotificationService>()) {
        _sl<INotificationService>().sendMessage(message).catchError((e) {
          _log.w('Notifica Telegram fallita: $e');
        });
      }
    } catch (e) {
      _log.w('Errore risoluzione INotificationService: $e');
    }
  }
}
