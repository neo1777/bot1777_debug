import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotback1777/domain/services/i_trading_api_service.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/app_strategy_state_hive_dto.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/fifo_app_trade_hive_dto.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/strategy_state_repository_impl.dart';
import 'package:test/test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:hive_ce/hive.dart';
import 'dart:io';

import '../../../helpers/mockito_dummy_registrations.dart';
import 'strategy_state_repository_cache_test.mocks.dart';

@GenerateMocks([ITradingApiService])
void main() {
  group('StrategyStateRepository Cache Tests', () {
    late StrategyStateRepositoryImpl repository;
    late Box<AppStrategyStateHiveDto> strategyStateBox;
    late Box<FifoAppTradeHiveDto> fifoTradeBox;
    late MockITradingApiService mockApiService;
    late Directory tempDir;

    setUp(() async {
      registerMockitoDummies();
      tempDir = await Directory.systemTemp.createTemp('hive_cache_test');
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
      when(mockApiService.isTestMode)
          .thenReturn(true); // Test Mode prefixed keys

      repository = StrategyStateRepositoryImpl(
        strategyStateBox: strategyStateBox,
        fifoTradeBox: fifoTradeBox,
        apiService: mockApiService,
      );
    });

    tearDown(() async {
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    test('should serve from memory cache after first load', () async {
      final symbol = 'BTCUSDC';
      final state = AppStrategyState(
          symbol: symbol, status: StrategyState.MONITORING_FOR_BUY);

      // 1. Initial Save
      await repository.saveStrategyState(state);

      // 2. Manipulate Hive directly (simulate external change or drift,
      //    though mostly to prove we are IGNORING it in favor of cache)
      final key = 'test_$symbol';
      final hackedState = state.copyWith(status: StrategyState.PAUSED);
      final hackedDto = AppStrategyStateHiveDto.fromEntity(
          hackedState, HiveList(fifoTradeBox));
      await strategyStateBox.put(key, hackedDto);

      // 3. Get State -> Should return ORIGINAL state from MEMORY, ignoring Hive hack
      final result = await repository.getStrategyState(symbol);

      expect(result.isRight(), true);
      final retrievedState = result.getOrElse((_) => null);

      // Should match original, NOT hacked
      expect(retrievedState?.status, StrategyState.MONITORING_FOR_BUY);
      expect(retrievedState?.status, isNot(StrategyState.PAUSED));
    });

    test('should update cache on save', () async {
      final symbol = 'ETHUSDC';
      var state = AppStrategyState(symbol: symbol, status: StrategyState.IDLE);

      await repository.saveStrategyState(state);

      // Verify in cache
      var result = await repository.getStrategyState(symbol);
      expect(result.getOrElse((_) => null)?.status, StrategyState.IDLE);

      // Update
      state = state.copyWith(status: StrategyState.MONITORING_FOR_BUY);
      await repository.saveStrategyState(state);

      // Verify updated in cache
      result = await repository.getStrategyState(symbol);
      expect(result.getOrElse((_) => null)?.status,
          StrategyState.MONITORING_FOR_BUY);
    });

    test('should remove from cache on delete', () async {
      final symbol = 'SOLUSDC';
      final state = AppStrategyState(symbol: symbol);
      await repository.saveStrategyState(state);

      // Verify exists
      var result = await repository.getStrategyState(symbol);
      expect(result.getOrElse((_) => null), isNotNull);

      // Delete
      await repository.deleteStrategyState(symbol);

      // Verify gone (cache miss -> Hive empty -> null)
      result = await repository.getStrategyState(symbol);
      expect(result.getOrElse((_) => throw Exception('Fail')), isNull);
    });

    test('should populate cache on first read from Hive', () async {
      final symbol = 'BNBUSDC';
      final state =
          AppStrategyState(symbol: symbol, status: StrategyState.IDLE);

      // Write to Hive MANUALLY (bypassing repo cache population)
      final key = 'test_$symbol';
      final dto =
          AppStrategyStateHiveDto.fromEntity(state, HiveList(fifoTradeBox));
      await strategyStateBox.put(key, dto);

      // Repo has empty cache now.
      // 1. First read -> Reads from Hive, Populates Cache
      var result = await repository.getStrategyState(symbol);
      expect(result.getOrElse((_) => null)?.status, StrategyState.IDLE);

      // 2. Manipulate Hive
      final hackedState = state.copyWith(status: StrategyState.PAUSED);
      final hackedDto = AppStrategyStateHiveDto.fromEntity(
          hackedState, HiveList(fifoTradeBox));
      await strategyStateBox.put(key, hackedDto);

      // 3. Second read -> Should come from CACHE (IDLE), ignoring Hive (PAUSED)
      result = await repository.getStrategyState(symbol);
      expect(result.getOrElse((_) => null)?.status, StrategyState.IDLE);
    });
  });
}
