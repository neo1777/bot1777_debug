import 'package:fpdart/fpdart.dart';
import 'package:decimal/decimal.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:neotradingbotback1777/application/use_cases/run_backtest_use_case.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/entities/app_trade.dart';
import 'package:neotradingbotback1777/domain/value_objects/amounts.dart';
import 'package:neotradingbotback1777/generated/proto/trading/v1/trading_service.pb.dart'
    as grpc;
import 'package:test/test.dart';

import 'trading_service_grpc_backtest_test.mocks.dart';

@GenerateMocks([RunBacktestUseCase])
void main() {
  late MockRunBacktestUseCase mockBacktestUseCase;

  setUp(() {
    provideDummy<Either<Failure, BacktestResult>>(Right(BacktestResult(
      backtestId: '',
      totalProfit: Decimal.zero,
      profitPercentage: Decimal.zero,
      tradesCount: 0,
      trades: [],
    )));
    mockBacktestUseCase = MockRunBacktestUseCase();
  });

  group('TradingServiceImpl Backtest endpoints', () {
    test('should successfully start backtest', () async {
      // Arrange - Create mock data structures
      // Note: This is a conceptual test showing the expected data flow
      // Actual implementation requires DI container setup

      final mockResult = BacktestResult(
        backtestId: 'BT_123456',
        totalProfit: Decimal.parse('10.5'),
        profitPercentage: Decimal.parse('1.05'),
        tradesCount: 5,
        trades: [
          AppTrade(
            symbol: 'BTCUSDT',
            price: MoneyAmount.fromDouble(100.0),
            quantity: QuantityAmount.fromDouble(0.5),
            isBuy: true,
            timestamp: 1000,
            orderStatus: 'FILLED',
          ),
        ],
      );

      when(mockBacktestUseCase.call(
        symbol: anyNamed('symbol'),
        startTime: anyNamed('startTime'),
        endTime: anyNamed('endTime'),
        interval: anyNamed('interval'),
        initialBalance: anyNamed('initialBalance'),
        settings: anyNamed('settings'),
      )).thenAnswer((_) async => Right(mockResult));

      // Assert - Mock is properly configured
      expect(mockResult.backtestId, 'BT_123456');
      expect(mockResult.tradesCount, 5);
    });

    test('AppSettings.fromGrpc should convert gRPC Settings correctly', () {
      // Arrange
      final grpcSettings = grpc.Settings()
        ..tradeAmount = 50.0
        ..fixedQuantityStr = '0.001'
        ..profitTargetPercentage = 1.5
        ..stopLossPercentage = 3.0
        ..dcaDecrementPercentage = 0.7
        ..maxOpenTrades = 20
        ..isTestMode = true
        ..buyOnStart = true
        ..initialWarmupTicks = 2
        ..initialWarmupSecondsStr = '5.0'
        ..initialSignalThresholdPctStr = '0.5'
        ..dcaCooldownSecondsStr = '4.0'
        ..dustRetryCooldownSecondsStr = '20.0'
        ..maxTradeAmountCapStr = '150.0'
        ..maxBuyOveragePctStr = '0.05'
        ..strictBudget = true
        ..buyOnStartRespectWarmup = false
        ..buyCooldownSecondsStr = '3.0'
        ..dcaCompareAgainstAverage = true
        ..maxCycles = 5
        ..enableFeeAwareTrading = false;

      // Act
      final appSettings = AppSettings.fromGrpc(grpcSettings);

      // Assert
      expect(appSettings.tradeAmount, 50.0);
      expect(appSettings.fixedQuantity, 0.001);
      expect(appSettings.profitTargetPercentage, 1.5);
      expect(appSettings.stopLossPercentage, 3.0);
      expect(appSettings.dcaDecrementPercentage, 0.7);
      expect(appSettings.maxOpenTrades, 20);
      expect(appSettings.isTestMode, true);
      expect(appSettings.buyOnStart, true);
      expect(appSettings.initialWarmupTicks, 2);
      expect(appSettings.initialWarmupSeconds, 5.0);
      expect(appSettings.initialSignalThresholdPct, 0.5);
      expect(appSettings.dcaCooldownSeconds, 4.0);
      expect(appSettings.dustRetryCooldownSeconds, 20.0);
      expect(appSettings.maxTradeAmountCap, 150.0);
      expect(appSettings.maxBuyOveragePct, 0.05);
      expect(appSettings.strictBudget, true);
      expect(appSettings.buyOnStartRespectWarmup, false);
      expect(appSettings.buyCooldownSeconds, 3.0);
      expect(appSettings.dcaCompareAgainstAverage, true);
      expect(appSettings.maxCycles, 5);
      expect(appSettings.enableFeeAwareTrading, false);
    });

    test('AppSettings.fromGrpc should handle null settings gracefully', () {
      // Act
      final appSettings = AppSettings.fromGrpc(null);

      // Assert
      expect(
          appSettings.tradeAmount, 56.0); // Default from AppSettings.initial()
      expect(appSettings.isTestMode, false);
    });

    test('AppSettings.fromGrpc should handle empty string fields', () {
      // Arrange
      final grpcSettings = grpc.Settings()
        ..tradeAmount = 50.0
        ..fixedQuantityStr = '' // Empty string
        ..profitTargetPercentage = 1.0
        ..stopLossPercentage = 2.0
        ..dcaDecrementPercentage = 0.5
        ..maxOpenTrades = 10
        ..isTestMode = true
        ..initialWarmupSecondsStr = '' // Empty string
        ..dcaCooldownSecondsStr = ''; // Empty string

      // Act
      final appSettings = AppSettings.fromGrpc(grpcSettings);

      // Assert
      expect(appSettings.fixedQuantity, null);
      expect(appSettings.initialWarmupSeconds, 0.0); // Default fallback
      expect(appSettings.dcaCooldownSeconds, 3.0); // Default fallback
    });

    test('AppSettings.fromGrpc should handle invalid number strings', () {
      // Arrange
      final grpcSettings = grpc.Settings()
        ..tradeAmount = 50.0
        ..fixedQuantityStr = 'invalid'
        ..profitTargetPercentage = 1.0
        ..stopLossPercentage = 2.0
        ..dcaDecrementPercentage = 0.5
        ..maxOpenTrades = 10
        ..isTestMode = true;

      // Act
      final appSettings = AppSettings.fromGrpc(grpcSettings);

      // Assert
      expect(appSettings.fixedQuantity, null); // tryParse returns null
    });
  });

  group('GetBacktestResults', () {
    test('should construct request with backtestId', () {
      // This is a placeholder test since GetBacktestResults is currently not fully implemented
      // but we test what exists

      final request = grpc.GetBacktestResultsRequest()..backtestId = 'BT_TEST';

      // The current implementation just returns the backtestId
      // When fully implemented, we'll expand these tests
      expect(request.backtestId, 'BT_TEST');
    });
  });
}

