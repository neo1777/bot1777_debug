import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:neotradingbotback1777/application/use_cases/start_strategy_atomic_use_case.dart';
import 'package:neotradingbotback1777/application/managers/trading_loop_manager.dart';
import 'package:neotradingbotback1777/application/managers/atomic_state_manager.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';

class MockTradingLoopManager extends Mock implements TradingLoopManager {}

class MockAtomicStateManager extends Mock implements AtomicStateManager {}

void main() {
  late StartStrategyAtomic useCase;
  late MockTradingLoopManager mockTradingLoopManager;
  late MockAtomicStateManager mockAtomicStateManager;

  setUpAll(() {
    registerFallbackValue(
        AppStrategyState(symbol: 'BTCUSDT', status: StrategyState.IDLE));
    registerFallbackValue(AppSettings.initial());
  });

  setUp(() {
    mockTradingLoopManager = MockTradingLoopManager();
    mockAtomicStateManager = MockAtomicStateManager();
    useCase =
        StartStrategyAtomic(mockTradingLoopManager, mockAtomicStateManager);
  });

  group('StartStrategyAtomic', () {
    const tSymbol = 'BTCUSDT';
    final tSettings = AppSettings.initial();
    final tState =
        AppStrategyState(symbol: tSymbol, status: StrategyState.IDLE);

    test('should execute successfully', () async {
      // arrange
      when(() => mockAtomicStateManager.executeAtomicOperation(any(), any()))
          .thenAnswer((invocation) async {
        final callback = invocation.positionalArguments[1]
            as Future<Either<Failure, AppStrategyState>> Function(
                AppStrategyState);
        return await callback(tState);
      });

      when(() => mockTradingLoopManager.startAtomicLoopForSymbol(
          any(), any(), any())).thenAnswer((_) async => true);

      // act
      final result = await useCase(symbol: tSymbol, settings: tSettings);

      // assert
      expect(result.isRight(), true);
      verify(() => mockTradingLoopManager.startAtomicLoopForSymbol(
          tSymbol, tSettings, any())).called(1);
    });

    test('should return failure if atomic operation fails', () async {
      // arrange
      final tFailure = ServerFailure(message: 'Atomic Error');
      when(() => mockAtomicStateManager.executeAtomicOperation(any(), any()))
          .thenAnswer((_) async => Left(tFailure));

      // act
      final result = await useCase(symbol: tSymbol, settings: tSettings);

      // assert
      expect(result.isLeft(), true);
      expect(result.fold((l) => l, (r) => null), equals(tFailure));
    });
  });
}
