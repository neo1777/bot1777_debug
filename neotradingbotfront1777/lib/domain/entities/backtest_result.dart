import 'package:equatable/equatable.dart';
import 'package:neotradingbotfront1777/domain/entities/app_trade.dart';

class BacktestResult extends Equatable {
  final String backtestId;
  final double totalProfit;
  final double profitPercentage;
  final int tradesCount;
  final int dcaTradesCount;
  final double totalFees;
  final String totalProfitStr;
  final String profitPercentageStr;
  final String totalFeesStr;
  final List<AppTrade> trades;

  const BacktestResult({
    required this.backtestId,
    required this.totalProfit,
    required this.profitPercentage,
    required this.tradesCount,
    required this.dcaTradesCount,
    required this.totalFees,
    required this.totalProfitStr,
    required this.profitPercentageStr,
    required this.totalFeesStr,
    required this.trades,
  });

  @override
  List<Object?> get props => [
    backtestId,
    totalProfit,
    profitPercentage,
    tradesCount,
    dcaTradesCount,
    totalFees,
    totalProfitStr,
    profitPercentageStr,
    totalFeesStr,
    trades,
  ];
}
