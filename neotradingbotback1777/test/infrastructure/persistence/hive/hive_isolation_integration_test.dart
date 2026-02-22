import 'dart:io';
import 'package:test/test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/strategy_state_repository_impl.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/app_strategy_state_hive_dto.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/fifo_app_trade_hive_dto.dart';
import 'package:neotradingbotback1777/domain/services/i_trading_api_service.dart';

import 'hive_isolation_integration_test.mocks.dart';

@GenerateMocks([ITradingApiService])
void main() {
  group('Hive Isolation Integration Test - Real vs Testnet', () {
    late StrategyStateRepositoryImpl repository;
    late Box<AppStrategyStateHiveDto> strategyStateBox;
    late Box<FifoAppTradeHiveDto> fifoTradeBox;
    late MockITradingApiService mockApiService;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_isolation_test');
      Hive.init(tempDir.path);

      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(AppStrategyStateHiveDtoAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(FifoAppTradeHiveDtoAdapter());
      }

      strategyStateBox =
          await Hive.openBox<AppStrategyStateHiveDto>('strategyStateBox');
      fifoTradeBox = await Hive.openBox<FifoAppTradeHiveDto>('fifoTradeBox');
      mockApiService = MockITradingApiService();

      repository = StrategyStateRepositoryImpl(
        strategyStateBox: strategyStateBox,
        fifoTradeBox: fifoTradeBox,
        apiService: mockApiService,
      );
    });

    tearDown(() async {
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('should strictly isolate Real and Testnet data via key prefixing',
        () async {
      final symbol = 'BTCUSDC';
      final realState = AppStrategyState(
        symbol: symbol,
        status: StrategyState.MONITORING_FOR_BUY,
        openTrades: [],
      );

      // 1. SAVE IN REAL MODE
      when(mockApiService.isTestMode).thenReturn(false);
      await repository.saveStrategyState(realState);

      // Verify physical key in Hive
      expect(strategyStateBox.containsKey('real_$symbol'), isTrue,
          reason: 'Real key should have real_ prefix');
      expect(strategyStateBox.containsKey('test_$symbol'), isFalse);

      // 2. CHECK VISIBILITY IN TEST MODE (Should be isolated)
      when(mockApiService.isTestMode).thenReturn(true);
      final testResult = await repository.getStrategyState(symbol);

      expect(testResult.isRight(), isTrue);
      testResult.fold(
        (l) => fail('Should not return failure'),
        (r) => expect(r, isNull,
            reason: 'Real data should NOT be visible in Test mode'),
      );

      // 3. SAVE IN TEST MODE
      final testState = realState.copyWith(
          status: StrategyState.POSITION_OPEN_MONITORING_FOR_SELL);
      await repository.saveStrategyState(testState);

      expect(strategyStateBox.containsKey('test_$symbol'), isTrue,
          reason: 'Test key should have test_ prefix');

      // 4. VERIFY BOTH PERSIST BUT ARE ACCESSED CORRELY
      // Access Test
      final testFetch = await repository.getStrategyState(symbol);
      expect(testFetch.getOrElse((_) => throw Exception())!.status,
          StrategyState.POSITION_OPEN_MONITORING_FOR_SELL);

      // Access Real
      when(mockApiService.isTestMode).thenReturn(false);
      final realFetch = await repository.getStrategyState(symbol);
      expect(realFetch.getOrElse((_) => throw Exception())!.status,
          StrategyState.MONITORING_FOR_BUY);

      // 5. DELETE IN ONE MODE SHOULD NOT AFFECT OTHER
      await repository.deleteStrategyState(symbol);
      expect(strategyStateBox.containsKey('real_$symbol'), isFalse);
      expect(strategyStateBox.containsKey('test_$symbol'), isTrue,
          reason: 'Deleting Real should not delete Test');
    });
  });
}

