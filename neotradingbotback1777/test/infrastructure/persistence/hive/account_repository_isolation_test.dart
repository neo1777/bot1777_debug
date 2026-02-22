import 'dart:io';
import 'package:test/test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/core/config/constants.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/account_repository_impl.dart';
import 'package:neotradingbotback1777/domain/entities/account_info.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/account_info_hive_dto.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/balance_hive_dto.dart';
import 'package:neotradingbotback1777/domain/services/i_trading_api_service.dart';

import 'account_repository_isolation_test.mocks.dart';

@GenerateMocks([ITradingApiService])
void main() {
  provideDummy<Either<Failure, AccountInfo>>(
      Right(AccountInfo(totalEstimatedValueUSDC: 0, balances: [])));
  provideDummy<Stream<Either<Failure, AccountInfo>>>(Stream.empty());

  group('AccountRepository Isolation Test - Real vs Testnet', () {
    late AccountRepositoryImpl repository;
    late Box<AccountInfoHiveDto> accountInfoBox;
    late Box<BalanceHiveDto> balanceBox;
    late MockITradingApiService mockApiService;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('account_isolation_test');
      Hive.init(tempDir.path);

      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(AccountInfoHiveDtoAdapter());
      }
      if (!Hive.isAdapterRegistered(6)) {
        Hive.registerAdapter(BalanceHiveDtoAdapter());
      }

      accountInfoBox =
          await Hive.openBox<AccountInfoHiveDto>(Constants.accountInfoBoxName);
      balanceBox = await Hive.openBox<BalanceHiveDto>(Constants.balanceBoxName);
      mockApiService = MockITradingApiService();

      repository = AccountRepositoryImpl(
        accountInfoBox: accountInfoBox,
        balanceBox: balanceBox,
        apiService: mockApiService,
      );
    });

    tearDown(() async {
      await Hive.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('should strictly isolate Real and Testnet account data', () async {
      final realAccount = AccountInfo(
        totalEstimatedValueUSDC: 1000.0,
        balances: [],
      );

      // stub subscribe stream to avoid MissingDummyValue if called
      when(mockApiService.subscribeToAccountInfoStream())
          .thenAnswer((_) => Stream.empty());

      // 1. SAVE IN REAL MODE
      when(mockApiService.isTestMode).thenReturn(false);
      await repository.saveAccountInfo(realAccount);

      expect(accountInfoBox.containsKey('real_account_info'), isTrue);
      expect(accountInfoBox.containsKey('test_account_info'), isFalse);

      // 2. CHECK ISOLATION IN TEST MODE
      when(mockApiService.isTestMode).thenReturn(true);
      // Stub refresh to return a specific test value if called (due to cache miss)
      when(mockApiService.getAccountInfo()).thenAnswer((_) async =>
          Right(AccountInfo(totalEstimatedValueUSDC: 0.1, balances: [])));

      final testFetchEmpty = await repository.getAccountInfo();
      expect(testFetchEmpty.isRight(), isTrue);
      testFetchEmpty.fold((_) => fail("Expected success"),
          (r) => expect(r?.totalEstimatedValueUSDC, 0.1));

      // 3. SAVE IN TEST MODE
      final testAccount = AccountInfo(
        totalEstimatedValueUSDC: 50.0,
        balances: [],
      );
      // Ensure Mockito respects the new mode for subsequent calls
      when(mockApiService.isTestMode).thenReturn(true);

      await repository.saveAccountInfo(testAccount);
      expect(accountInfoBox.containsKey('test_account_info'), isTrue);

      final rawTestValue = accountInfoBox.get('test_account_info');
      expect(rawTestValue?.toEntity().totalEstimatedValueUSDC, 50.0);

      // 4. VERIFY INDEPENDENT ACCESS
      final testResult = await repository.getAccountInfo();
      expect(testResult.isRight(), isTrue);
      expect(
          testResult
              .getOrElse((_) => throw Exception())!
              .totalEstimatedValueUSDC,
          50.0);

      when(mockApiService.isTestMode).thenReturn(false);
      final realResult = await repository.getAccountInfo();
      expect(realResult.isRight(), isTrue);
      expect(
          realResult
              .getOrElse((_) => throw Exception())!
              .totalEstimatedValueUSDC,
          1000.0);
    });
  });
}

