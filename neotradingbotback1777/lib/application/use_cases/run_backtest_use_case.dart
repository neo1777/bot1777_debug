import 'package:fpdart/fpdart.dart';
import 'package:decimal/decimal.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:neotradingbotback1777/core/utils/decimal_utils.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/entities/app_trade.dart';
import 'package:neotradingbotback1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/services/i_trading_api_service.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/fifo_app_trade.dart';
import 'package:neotradingbotback1777/domain/entities/fee_info.dart';
import 'package:neotradingbotback1777/domain/value_objects/amounts.dart';
import 'package:neotradingbotback1777/domain/entities/kline.dart';
import 'package:rational/rational.dart';

class BacktestResult {
  final String backtestId;
  final Decimal totalProfit;
  final Decimal profitPercentage;
  final int tradesCount;
  final List<AppTrade> trades;

  /// Fee totali pagate durante il backtest (somma di fee buy + sell).
  final Decimal totalFees;

  /// Numero di trade DCA eseguiti (acquisti incrementali, escluso il primo buy).
  final int dcaTradesCount;

  BacktestResult({
    required this.backtestId,
    required this.totalProfit,
    required this.profitPercentage,
    required this.tradesCount,
    required this.trades,
    Decimal? totalFees,
    this.dcaTradesCount = 0,
  }) : totalFees = totalFees ?? Decimal.zero;
}

class RunBacktestUseCase {
  final ITradingApiService apiService;
  final _log = LogManager.getLogger();

  /// Max klines per Binance API request.
  static const int _klinePageSize = 1000;

  RunBacktestUseCase(this.apiService);

  Future<Either<Failure, BacktestResult>> call({
    required String symbol,
    required int startTime,
    required int endTime,
    required String interval,
    required Decimal initialBalance,
    required AppSettings settings,
  }) async {
    try {
      _log.i('Starting backtest for $symbol from $startTime to $endTime');

      // 1. Fetch historical data (klines) with pagination
      final klinesResult = await _fetchAllKlines(
        symbol: symbol,
        interval: interval,
        startTime: startTime,
        endTime: endTime,
      );

      return await klinesResult.fold(
        (failure) async => Left(failure),
        (klines) async {
          _log.i('Fetched ${klines.length} klines for backtest');

          // 2. Preparazione fee (default Binance 0.1% maker/taker)
          final feeInfo = FeeInfo.defaultBinance(symbol: symbol);

          if (!settings.buyOnStart && !settings.enableReBuy) {
            return Left(ValidationFailure(
              message:
                  'Backtest requires buyOnStart=true or enableReBuy=true to execute any trades.',
            ));
          }

          // 3. Simulate trading loop con DCA e fee
          Decimal cumulativeProfit = Decimal.zero;
          Decimal totalFees = Decimal.zero;
          int dcaTradesCount = 0;
          List<AppTrade> tradeHistory = [];

          AppStrategyState state = AppStrategyState(
            symbol: symbol,
            status: StrategyState.MONITORING_FOR_BUY,
            openTrades: [],
            currentRoundId: 1,
          );

          final profitTarget =
              DecimalUtils.dFromDouble(settings.profitTargetPercentage);
          final stopLoss =
              DecimalUtils.dFromDouble(settings.stopLossPercentage);
          final tradeAmount = DecimalUtils.dFromDouble(settings.tradeAmount);
          final dcaDecrement =
              DecimalUtils.dFromDouble(settings.dcaDecrementPercentage);
          final hundred = Decimal.fromInt(100);

          for (Kline kline in klines) {
            final price = DecimalUtils.dFromDouble(kline.close);
            final timestamp = kline.closeTime;

            if (state.status == StrategyState.MONITORING_FOR_BUY) {
              if (settings.buyOnStart ||
                  (settings.enableReBuy && !state.isInitialState)) {
                // ─── BUY con fee ───
                final qty = _decimalDiv(tradeAmount, price);
                final buyFee = _calculateFee(
                  feeInfo: feeInfo,
                  quantity: qty,
                  price: price,
                  isMaker: true,
                );
                totalFees += buyFee;

                final buyTrade =
                    _createSimulatedTrade(symbol, price, qty, true, timestamp);
                tradeHistory.add(buyTrade);

                final fifo = FifoAppTrade(
                  price: price,
                  quantity: qty,
                  timestamp: timestamp,
                  roundId: state.currentRoundId,
                );

                state = state.copyWith(
                  openTrades: [...state.openTrades, fifo],
                  status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL,
                );
              }
            } else if (state.status ==
                StrategyState.POSITION_OPEN_MONITORING_FOR_SELL) {
              // ─── DCA: verifica condizione di acquisto incrementale ───
              if (state.openTrades.length < settings.maxOpenTrades) {
                final refPrice = settings.dcaCompareAgainstAverage
                    ? DecimalUtils.dFromDouble(state.averagePrice)
                    : DecimalUtils.dFromDouble(state.lastBuyPrice);

                if (refPrice > Decimal.zero && price > Decimal.zero) {
                  // dropPct = (refPrice - price) / refPrice * 100
                  final dropPct =
                      _decimalDiv((refPrice - price) * hundred, refPrice);

                  if (dropPct >= dcaDecrement) {
                    final dcaQty = _decimalDiv(tradeAmount, price);
                    final dcaFee = _calculateFee(
                      feeInfo: feeInfo,
                      quantity: dcaQty,
                      price: price,
                      isMaker: true,
                    );
                    totalFees += dcaFee;
                    dcaTradesCount++;

                    final dcaTrade = _createSimulatedTrade(
                        symbol, price, dcaQty, true, timestamp);
                    tradeHistory.add(dcaTrade);

                    final fifo = FifoAppTrade(
                      price: price,
                      quantity: dcaQty,
                      timestamp: timestamp,
                      roundId: state.currentRoundId,
                    );

                    state = state.copyWith(
                      openTrades: [...state.openTrades, fifo],
                    );
                  }
                }
              }

              // ─── SELL: verifica TP/SL ───
              final avgPrice = state.averagePrice;
              final avgPriceD = DecimalUtils.dFromDouble(avgPrice);

              // profitPct = (price - avgPriceD) / avgPriceD * 100
              final priceDiff = price - avgPriceD;
              final profitPct = _decimalDiv(priceDiff * hundred, avgPriceD);

              bool shouldSell = false;
              if (profitPct >= profitTarget) {
                shouldSell = true;
              } else if (profitPct <= -stopLoss) {
                shouldSell = true;
              }

              if (shouldSell) {
                final totalQty = state.totalQuantity;
                final sellFee = _calculateFee(
                  feeInfo: feeInfo,
                  quantity: totalQty,
                  price: price,
                  isMaker: false, // sell = taker
                );
                totalFees += sellFee;

                final sellTrade = _createSimulatedTrade(
                    symbol, price, totalQty, false, timestamp);
                tradeHistory.add(sellTrade);

                // Profitto netto = (prezzo vendita - prezzo medio) * qty - fee sell
                // Le fee di acquisto sono già state contabilizzate in totalFees ma NON sottratte dal profitto
                // qui per coerenza col profitto lordo. Il totalFees separato consente confronto lordo/netto.
                final realizedProfit = priceDiff * totalQty;
                cumulativeProfit += realizedProfit;

                state = state.copyWith(
                  openTrades: [],
                  status: StrategyState.MONITORING_FOR_BUY,
                  currentRoundId: state.currentRoundId + 1,
                  cumulativeProfit: state.cumulativeProfit +
                      DecimalUtils.toDouble(realizedProfit),
                );
              }
            }
          }

          // Profitto netto = profitto lordo - fee totali
          final netProfit = cumulativeProfit - totalFees;
          final profitPct = initialBalance == Decimal.zero
              ? Decimal.zero
              : _decimalDiv(netProfit * hundred, initialBalance);

          final result = BacktestResult(
            backtestId: 'BT_${DateTime.now().millisecondsSinceEpoch}',
            totalProfit: netProfit,
            profitPercentage: profitPct,
            tradesCount: tradeHistory.length,
            trades: tradeHistory,
            totalFees: totalFees,
            dcaTradesCount: dcaTradesCount,
          );

          _log.i(
              'Backtest finished: ${result.tradesCount} trades (DCA: $dcaTradesCount), '
              'profit: ${result.totalProfit}, fees: ${result.totalFees}');
          return Right(result);
        },
      );
    } catch (e, s) {
      _log.e('Error during backtest: $e', stackTrace: s);
      return Left(UnexpectedFailure(message: 'Backtest failed: $e'));
    }
  }

  /// Fetches all klines for the given range, paginating in batches of [_klinePageSize].
  Future<Either<Failure, List<Kline>>> _fetchAllKlines({
    required String symbol,
    required String interval,
    required int startTime,
    required int endTime,
  }) async {
    final allKlines = <Kline>[];
    int currentStart = startTime;

    while (currentStart < endTime) {
      final result = await apiService.getKlines(
        symbol: symbol,
        interval: interval,
        startTime: currentStart,
        endTime: endTime,
        limit: _klinePageSize,
      );

      final either = result.fold(
        (failure) => Left<Failure, List<Kline>>(failure),
        (klines) => Right<Failure, List<Kline>>(klines),
      );

      if (either.isLeft()) return either;

      final klines = either.getOrElse((_) => []);
      if (klines.isEmpty) break;

      allKlines.addAll(klines);

      // Move start to after the last fetched kline
      currentStart = klines.last.closeTime + 1;

      // If we got fewer than the page size, we've reached the end
      if (klines.length < _klinePageSize) break;
    }

    return Right(allKlines);
  }

  AppTrade _createSimulatedTrade(
      String symbol, Decimal price, Decimal qty, bool isBuy, int timestamp) {
    return AppTrade(
      symbol: symbol,
      price: MoneyAmount.fromDecimal(price),
      quantity: QuantityAmount.fromDecimal(qty),
      isBuy: isBuy,
      timestamp: timestamp,
      orderStatus: 'FILLED',
    );
  }

  /// Calcola la fee per una transazione usando FeeInfo.
  Decimal _calculateFee({
    required FeeInfo feeInfo,
    required Decimal quantity,
    required Decimal price,
    required bool isMaker,
  }) {
    final fee = feeInfo.calculateTotalFees(
      quantity: DecimalUtils.toDouble(quantity),
      price: DecimalUtils.toDouble(price),
      isMaker: isMaker,
    );
    return DecimalUtils.dFromDouble(fee);
  }

  /// Safe Decimal division that handles infinite-precision results.
  static Decimal _decimalDiv(Decimal a, Decimal b) {
    final dynamic result = a / b;
    if (result is Decimal) return result;
    return (result as Rational)
        .toDecimal(scaleOnInfinitePrecision: DecimalUtils.defaultScale);
  }
}
