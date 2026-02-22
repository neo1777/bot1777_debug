import 'package:neotradingbotfront1777/domain/entities/backtest_result.dart';
import 'package:neotradingbotfront1777/domain/entities/app_trade.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pb.dart'
    as proto;

class BacktestResultMapper {
  static BacktestResult fromProto(proto.BacktestResultsResponse protoData) {
    return BacktestResult(
      backtestId: protoData.backtestId,
      totalProfit: protoData.totalProfit,
      profitPercentage: protoData.profitPercentage,
      tradesCount: protoData.tradesCount,
      dcaTradesCount: protoData.dcaTradesCount,
      totalFees: protoData.totalFees,
      totalProfitStr: protoData.totalProfitStr,
      profitPercentageStr: protoData.profitPercentageStr,
      totalFeesStr: protoData.totalFeesStr,
      trades: protoData.trades.map(_mapTrade).toList(),
    );
  }

  static AppTrade _mapTrade(proto.Trade t) {
    return AppTrade(
      symbol: t.symbol.isEmpty ? 'N/A' : t.symbol,
      price: t.price,
      quantity: t.quantity,
      // Timestamps da Binance API sono in millisecondi
      timestamp: DateTime.fromMillisecondsSinceEpoch(t.timestamp.toInt()),
      isBuy: t.isBuy,
      orderStatus: t.orderStatus.isEmpty ? 'FILLED' : t.orderStatus,
      profit: t.profit,
    );
  }
}
