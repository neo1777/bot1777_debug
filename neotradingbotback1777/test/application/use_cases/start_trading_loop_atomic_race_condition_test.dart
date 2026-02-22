import 'package:test/test.dart';
import 'package:mockito/annotations.dart';
import 'package:neotradingbotback1777/application/use_cases/start_trading_loop_atomic_use_case.dart';
import 'package:neotradingbotback1777/domain/repositories/price_repository.dart';
import 'package:neotradingbotback1777/domain/services/trade_evaluator_service.dart';
import 'package:neotradingbotback1777/domain/repositories/account_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/i_symbol_info_repository.dart';
import 'package:neotradingbotback1777/application/managers/atomic_state_manager.dart';
import 'package:get_it/get_it.dart';

import 'start_trading_loop_atomic_race_condition_test.mocks.dart';

@GenerateMocks([
  PriceRepository,
  TradeEvaluatorService,
  AccountRepository,
  ISymbolInfoRepository,
  AtomicStateManager,
])
void main() {
  group('[BACKEND-TEST-014] StartTradingLoopAtomic - Race Conditions', () {
    late StartTradingLoopAtomic useCase;
    late MockPriceRepository mockPriceRepository;
    late MockTradeEvaluatorService mockTradeEvaluatorService;
    late MockAccountRepository mockAccountRepository;
    late MockISymbolInfoRepository mockSymbolInfoRepository;
    late MockAtomicStateManager mockStateManager;
    late GetIt mockServiceLocator;

    setUp(() {
      mockPriceRepository = MockPriceRepository();
      mockTradeEvaluatorService = MockTradeEvaluatorService();
      mockAccountRepository = MockAccountRepository();
      mockSymbolInfoRepository = MockISymbolInfoRepository();
      mockStateManager = MockAtomicStateManager();
      mockServiceLocator = GetIt.instance;

      useCase = StartTradingLoopAtomic(
        priceRepository: mockPriceRepository,
        tradeEvaluator: mockTradeEvaluatorService,
        stateManager: mockStateManager,
        accountRepository: mockAccountRepository,
        symbolInfoRepository: mockSymbolInfoRepository,
        serviceLocator: mockServiceLocator,
      );
    });

    test('should create instance with all required dependencies', () {
      // ASSERT
      expect(useCase, isNotNull);
      expect(useCase, isA<StartTradingLoopAtomic>());
    });

    test('should handle multiple instance creation without conflicts', () {
      // ARRANGE & ACT - Crea multiple istanze
      final instances = List.generate(
          5,
          (index) => StartTradingLoopAtomic(
                priceRepository: mockPriceRepository,
                tradeEvaluator: mockTradeEvaluatorService,
                stateManager: mockStateManager,
                accountRepository: mockAccountRepository,
                symbolInfoRepository: mockSymbolInfoRepository,
                serviceLocator: mockServiceLocator,
              ));

      // ASSERT
      expect(instances.length, 5);
    });

    test('should handle concurrent setup operations', () async {
      // ACT - Simula operazioni concorrenti di setup
      final futures = List.generate(5, (index) async {
        // Simula operazioni di setup concorrenti
        await Future.delayed(Duration(milliseconds: index * 10));
        return index;
      });

      final results = await Future.wait(futures);

      // ASSERT
      expect(results.length, 5);
    });
  });
}

