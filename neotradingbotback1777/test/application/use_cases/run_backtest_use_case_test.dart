import 'package:fpdart/fpdart.dart';
import 'package:decimal/decimal.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:neotradingbotback1777/application/use_cases/run_backtest_use_case.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/entities/kline.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/services/i_trading_api_service.dart';
import 'package:test/test.dart';

import 'run_backtest_use_case_test.mocks.dart';

@GenerateMocks([ITradingApiService])
void main() {
  late RunBacktestUseCase useCase;
  late MockITradingApiService mockApiService;

  setUp(() {
    provideDummy<Either<Failure, List<Kline>>>(const Right([]));
    mockApiService = MockITradingApiService();
    useCase = RunBacktestUseCase(mockApiService);
  });

  group('RunBacktestUseCase', () {
    final testSettings = AppSettings(
      tradeAmount: 50.0,
      profitTargetPercentage: 1.0,
      stopLossPercentage: 2.0,
      dcaDecrementPercentage: 0.5,
      maxOpenTrades: 10,
      isTestMode: true,
      buyOnStart: true,
    );

    final mockKlines = [
      Kline(
        openTime: 1000,
        open: 100.0,
        high: 105.0,
        low: 99.0,
        close: 102.0,
        volume: 1000.0,
        closeTime: 2000,
        quoteAssetVolume: 100000.0,
        numberOfTrades: 10,
        takerBuyBaseAssetVolume: 500.0,
        takerBuyQuoteAssetVolume: 50000.0,
      ),
      Kline(
        openTime: 2000,
        open: 102.0,
        high: 104.0,
        low: 101.0,
        close: 103.0, // +1% profit - should trigger sell
        volume: 1000.0,
        closeTime: 3000,
        quoteAssetVolume: 100000.0,
        numberOfTrades: 10,
        takerBuyBaseAssetVolume: 500.0,
        takerBuyQuoteAssetVolume: 50000.0,
      ),
    ];

    test('should successfully run backtest with profit', () async {
      // Arrange
      when(mockApiService.getKlines(
        symbol: anyNamed('symbol'),
        interval: anyNamed('interval'),
        startTime: anyNamed('startTime'),
        endTime: anyNamed('endTime'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => Right(mockKlines));

      // Act
      final result = await useCase(
        symbol: 'BTCUSDT',
        startTime: 1000,
        endTime: 3000,
        interval: '1m',
        initialBalance: Decimal.parse('1000'),
        settings: testSettings,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (backtestResult) {
          expect(backtestResult.backtestId, isNotEmpty);
          expect(backtestResult.tradesCount, greaterThan(0));
          expect(backtestResult.totalProfit, isA<Decimal>());
          expect(backtestResult.profitPercentage, isA<Decimal>());
        },
      );

      verify(mockApiService.getKlines(
        symbol: 'BTCUSDT',
        interval: '1m',
        startTime: 1000,
        endTime: 3000,
        limit: 1000,
      )).called(1);
    });

    test('should handle stop-loss scenario correctly', () async {
      // Arrange
      final stopLossKlines = [
        Kline(
          openTime: 1000,
          open: 100.0,
          high: 105.0,
          low: 99.0,
          close: 100.0,
          volume: 1000.0,
          closeTime: 2000,
          quoteAssetVolume: 100000.0,
          numberOfTrades: 10,
          takerBuyBaseAssetVolume: 500.0,
          takerBuyQuoteAssetVolume: 50000.0,
        ),
        Kline(
          openTime: 2000,
          open: 100.0,
          high: 100.0,
          low: 95.0,
          close: 97.0, // -3% loss - should trigger stop loss
          volume: 1000.0,
          closeTime: 3000,
          quoteAssetVolume: 100000.0,
          numberOfTrades: 10,
          takerBuyBaseAssetVolume: 500.0,
          takerBuyQuoteAssetVolume: 50000.0,
        ),
      ];

      when(mockApiService.getKlines(
        symbol: anyNamed('symbol'),
        interval: anyNamed('interval'),
        startTime: anyNamed('startTime'),
        endTime: anyNamed('endTime'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => Right(stopLossKlines));

      // Act
      final result = await useCase(
        symbol: 'BTCUSDT',
        startTime: 1000,
        endTime: 3000,
        interval: '1m',
        initialBalance: Decimal.parse('1000'),
        settings: testSettings,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (backtestResult) {
          expect(backtestResult.totalProfit, lessThan(Decimal.zero));
        },
      );
    });

    test('should handle empty klines list', () async {
      // Arrange
      when(mockApiService.getKlines(
        symbol: anyNamed('symbol'),
        interval: anyNamed('interval'),
        startTime: anyNamed('startTime'),
        endTime: anyNamed('endTime'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => Right([]));

      // Act
      final result = await useCase(
        symbol: 'BTCUSDT',
        startTime: 1000,
        endTime: 3000,
        interval: '1m',
        initialBalance: Decimal.parse('1000'),
        settings: testSettings,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (backtestResult) {
          expect(backtestResult.tradesCount, 0);
          expect(backtestResult.totalProfit, Decimal.zero);
        },
      );
    });

    test('should propagate API failure', () async {
      // Arrange
      final testFailure = NetworkFailure(message: 'API error');
      when(mockApiService.getKlines(
        symbol: anyNamed('symbol'),
        interval: anyNamed('interval'),
        startTime: anyNamed('startTime'),
        endTime: anyNamed('endTime'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => Left(testFailure));

      // Act
      final result = await useCase(
        symbol: 'BTCUSDT',
        startTime: 1000,
        endTime: 3000,
        interval: '1m',
        initialBalance: Decimal.parse('1000'),
        settings: testSettings,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Should return failure'),
      );
    });

    test('should simulate DCA with multiple buys', () async {
      // Arrange - Price declining then recovering
      final dcaKlines = [
        Kline(
          openTime: 1000,
          open: 100.0,
          high: 100.0,
          low: 100.0,
          close: 100.0,
          volume: 1000.0,
          closeTime: 2000,
          quoteAssetVolume: 100000.0,
          numberOfTrades: 10,
          takerBuyBaseAssetVolume: 500.0,
          takerBuyQuoteAssetVolume: 50000.0,
        ),
        Kline(
          openTime: 2000,
          open: 100.0,
          high: 100.0,
          low: 99.0,
          close: 99.0, // Small dip
          volume: 1000.0,
          closeTime: 3000,
          quoteAssetVolume: 99000.0,
          numberOfTrades: 10,
          takerBuyBaseAssetVolume: 500.0,
          takerBuyQuoteAssetVolume: 49500.0,
        ),
        Kline(
          openTime: 3000,
          open: 99.0,
          high: 102.0,
          low: 99.0,
          close: 101.0, // Recovery to profit
          volume: 1000.0,
          closeTime: 4000,
          quoteAssetVolume: 101000.0,
          numberOfTrades: 10,
          takerBuyBaseAssetVolume: 500.0,
          takerBuyQuoteAssetVolume: 50500.0,
        ),
      ];

      when(mockApiService.getKlines(
        symbol: anyNamed('symbol'),
        interval: anyNamed('interval'),
        startTime: anyNamed('startTime'),
        endTime: anyNamed('endTime'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => Right(dcaKlines));

      // Act
      final result = await useCase(
        symbol: 'BTCUSDT',
        startTime: 1000,
        endTime: 4000,
        interval: '1m',
        initialBalance: Decimal.parse('1000'),
        settings: testSettings,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (backtestResult) {
          expect(backtestResult.backtestId, startsWith('BT_'));
          expect(backtestResult.trades, isNotEmpty);
        },
      );
    });
  });
}
