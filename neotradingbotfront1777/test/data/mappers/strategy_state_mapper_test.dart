import 'package:neotradingbotfront1777/data/mappers/strategy_state_mapper.dart';
import 'package:neotradingbotfront1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pb.dart'
    as grpc;
import 'package:test/test.dart';

void main() {
  group('StrategyStateMapper', () {
    test('should map correctly when all string fields are provided', () {
      // ARRANGE
      final proto = grpc.StrategyStateResponse(
        symbol: 'BTCUSDC',
        status: grpc.StrategyStatus.STRATEGY_STATUS_RUNNING,
        openTradesCount: 2,
        currentRoundId: 5,
        successfulRounds: 3,
        failedRounds: 1,
        averagePriceStr: '45000.50',
        totalQuantityStr: '0.5',
        lastBuyPriceStr: '46000.0',
        cumulativeProfitStr: '1250.75',
      );

      // ACT
      final result = strategyStateFromProto(proto);

      // ASSERT
      expect(result.symbol, 'BTCUSDC');
      expect(result.status, StrategyStatus.running);
      expect(result.openTradesCount, 2);
      expect(result.averagePrice, 45000.50);
      expect(result.totalQuantity, 0.5);
      expect(result.lastBuyPrice, 46000.0);
      expect(result.cumulativeProfit, 1250.75);
      expect(result.currentRoundId, 5);
      expect(result.successfulRounds, 3);
      expect(result.failedRounds, 1);
    });

    test('should map correctly using legacy double fields as fallback', () {
      // ARRANGE
      final proto = grpc.StrategyStateResponse(
        symbol: 'BTCUSDC',
        status: grpc.StrategyStatus.STRATEGY_STATUS_PAUSED,
        openTradesCount: 1,
        averagePrice: 40000.0,
        totalQuantity: 0.2,
        lastBuyPrice: 41000.0,
        cumulativeProfit: -50.0,
      );

      // ACT
      final result = strategyStateFromProto(proto);

      // ASSERT
      expect(result.status, StrategyStatus.paused);
      expect(result.averagePrice, 40000.0);
      expect(result.totalQuantity, 0.2);
      expect(result.lastBuyPrice, 41000.0);
      expect(result.cumulativeProfit, -50.0);
    });

    test('should prioritize string fields over legacy double fields', () {
      // ARRANGE
      final proto = grpc.StrategyStateResponse(
        symbol: 'BTCUSDC',
        status: grpc.StrategyStatus.STRATEGY_STATUS_IDLE,
        averagePrice: 1.0, // Legacy, should be ignored
        averagePriceStr: '50000.0', // New, should be used
      );

      // ACT
      final result = strategyStateFromProto(proto);

      // ASSERT
      expect(result.averagePrice, 50000.0);
    });

    test('should handle all enum status values correctly', () {
      // ARRANGE
      final statusMap = {
        grpc.StrategyStatus.STRATEGY_STATUS_IDLE: StrategyStatus.idle,
        grpc.StrategyStatus.STRATEGY_STATUS_RUNNING: StrategyStatus.running,
        grpc.StrategyStatus.STRATEGY_STATUS_PAUSED: StrategyStatus.paused,
        grpc.StrategyStatus.STRATEGY_STATUS_ERROR: StrategyStatus.error,
        grpc.StrategyStatus.STRATEGY_STATUS_RECOVERING:
            StrategyStatus.recovering,
        grpc.StrategyStatus.STRATEGY_STATUS_UNSPECIFIED:
            StrategyStatus.unspecified,
      };

      statusMap.forEach((protoStatus, domainStatus) {
        final proto = grpc.StrategyStateResponse(status: protoStatus);

        // ACT
        final result = strategyStateFromProto(proto);

        // ASSERT
        expect(result.status, domainStatus, reason: 'Failed for $protoStatus');
      });
    });
  });
}
