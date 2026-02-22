import 'package:flutter_test/flutter_test.dart';
import 'package:neotradingbotfront1777/data/mappers/backtest_result_mapper.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pb.dart'
    as proto;
import 'package:fixnum/fixnum.dart';

void main() {
  group('BacktestResultMapper', () {
    test(
      'fromProto should map BacktestResultsResponse to BacktestResult correctly',
      () {
        // arrange
        final tTradeProto =
            proto.Trade()
              ..symbol = 'BTCUSDC'
              ..price = 50000.0
              ..quantity = 0.5
              ..timestamp = Int64(1620000000000)
              ..isBuy = true
              ..orderStatus = 'FILLED'
              ..profit = 10.0;

        final tResponse =
            proto.BacktestResultsResponse()
              ..backtestId = 'test-id'
              ..totalProfit = 100.0
              ..profitPercentage = 5.0
              ..tradesCount = 10
              ..dcaTradesCount = 2
              ..totalFees = 0.5
              ..totalProfitStr = '100.0'
              ..profitPercentageStr = '5.0%'
              ..totalFeesStr = '0.5';
        tResponse.trades.add(tTradeProto);

        // act
        final result = BacktestResultMapper.fromProto(tResponse);

        // assert
        expect(result.backtestId, 'test-id');
        expect(result.totalProfit, 100.0);
        expect(result.profitPercentage, 5.0);
        expect(result.tradesCount, 10);
        expect(result.dcaTradesCount, 2);
        expect(result.totalFees, 0.5);
        expect(result.totalProfitStr, '100.0');
        expect(result.profitPercentageStr, '5.0%');
        expect(result.totalFeesStr, '0.5');

        expect(result.trades.length, 1);
        final trade = result.trades.first;
        expect(trade.symbol, 'BTCUSDC');
        expect(trade.price, 50000.0);
        expect(trade.quantity, 0.5);
        expect(trade.isBuy, true);
        expect(trade.orderStatus, 'FILLED');
        expect(trade.profit, 10.0);
        expect(
          trade.timestamp,
          DateTime.fromMillisecondsSinceEpoch(1620000000000),
        );
      },
    );

    test('should use defaults when mapping Trade with empty fields', () {
      // arrange
      final tTradeProto =
          proto.Trade()
            ..price = 50000.0
            ..quantity = 0.5
            ..timestamp = Int64(1620000000000);

      final tResponse = proto.BacktestResultsResponse()..backtestId = 'test-id';
      tResponse.trades.add(tTradeProto);

      // act
      final result = BacktestResultMapper.fromProto(tResponse);

      // assert
      final trade = result.trades.first;
      expect(trade.symbol, 'N/A');
      expect(trade.orderStatus, 'FILLED');
    });
  });
}

