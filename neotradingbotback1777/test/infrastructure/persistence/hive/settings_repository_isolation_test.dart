import 'dart:io';
import 'package:test/test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:neotradingbotback1777/core/config/constants.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/settings_repository_impl.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/app_settings_hive_dto.dart';
import 'package:neotradingbotback1777/domain/services/i_trading_api_service.dart';

import 'settings_repository_isolation_test.mocks.dart';

@GenerateMocks([ITradingApiService])
void main() {
  group('SettingsRepository Isolation Test - Real vs Testnet', () {
    late SettingsRepositoryImpl repository;
    late Box<AppSettingsHiveDto> settingsBox;
    late MockITradingApiService mockApiService;
    late Directory tempDir;

    setUp(() async {
      tempDir =
          await Directory.systemTemp.createTemp('settings_isolation_test');
      Hive.init(tempDir.path);

      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(AppSettingsHiveDtoAdapter());
      }

      settingsBox =
          await Hive.openBox<AppSettingsHiveDto>(Constants.appSettingsBoxName);
      mockApiService = MockITradingApiService();

      repository = SettingsRepositoryImpl(
        settingsBox: settingsBox,
        apiService: mockApiService,
      );
    });

    tearDown(() async {
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('should strictly isolate Real and Testnet settings data', () async {
      // 1. SAVE IN REAL MODE
      when(mockApiService.isTestMode).thenReturn(false);
      final realSettings = AppSettings.initial().copyWith(tradeAmount: 123.45);
      await repository.saveSettings(realSettings);

      expect(settingsBox.containsKey('real_app_settings'), isTrue);
      expect(settingsBox.containsKey('test_app_settings'), isFalse);

      // 2. CHECK ISOLATION IN TEST MODE
      when(mockApiService.isTestMode).thenReturn(true);
      final testFetch = await repository.getSettings();
      expect(testFetch.isRight(), isTrue);

      // Default tradeAmount is 56.0 in AppSettings.initial() - let's verify
      testFetch.fold((_) => null,
          (r) => expect(r.tradeAmount, AppSettings.initial().tradeAmount));

      // 3. SAVE IN TEST MODE
      final testSettings = AppSettings.initial().copyWith(tradeAmount: 9.99);
      await repository.saveSettings(testSettings);
      expect(settingsBox.containsKey('test_app_settings'), isTrue);

      // 4. VERIFY INDEPENDENT ACCESS
      final testResult = await repository.getSettings();
      expect(testResult.getOrElse((_) => throw Exception()).tradeAmount, 9.99);

      when(mockApiService.isTestMode).thenReturn(false);
      final realResult = await repository.getSettings();
      expect(
          realResult.getOrElse((_) => throw Exception()).tradeAmount, 123.45);
    });
  });
}
