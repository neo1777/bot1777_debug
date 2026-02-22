import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neotradingbotback1777/application/use_cases/pause_trading_use_case.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/log_settings.dart';
import 'package:neotradingbotback1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotback1777/domain/repositories/strategy_state_repository.dart';
import 'package:test/test.dart';

class MockStrategyStateRepository extends Mock implements StrategyStateRepository {}

void main() {
  late PauseTrading useCase;
  late MockStrategyStateRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(AppStrategyState(symbol: 'BTCUSDT'));
    registerFallbackValue(AppSettings.initial());
    registerFallbackValue(LogSettings.defaultSettings());
  });

  setUp(() {
    mockRepository = MockStrategyStateRepository();
    useCase = PauseTrading(mockRepository);
  });

  group('PauseTrading Use Case', () {
        const tSymbol = 'BTCUSDT';
    
    test('should execute and return success state', () async {
      when(() => mockRepository.getStrategyState(any())).thenAnswer((_) async => Right(AppStrategyState(symbol: 'BTCUSDT', status: StrategyState.MONITORING_FOR_BUY)));
      when(() => mockRepository.saveStrategyState(any())).thenAnswer((_) async => Right(null));
      

      final result = await useCase(symbol: tSymbol);

      expect(result.isRight(), true);
    });

  });
}
