import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neotradingbotback1777/application/use_cases/get_strategy_state_use_case.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/log_settings.dart';
import 'package:neotradingbotback1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/strategy_state_repository.dart';
import 'package:test/test.dart';

class MockStrategyStateRepository extends Mock implements StrategyStateRepository {}

void main() {
  late GetStrategyState useCase;
  late MockStrategyStateRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(AppStrategyState(symbol: 'BTCUSDT'));
    registerFallbackValue(AppSettings.initial());
    registerFallbackValue(LogSettings.defaultSettings());
  });

  setUp(() {
    mockRepository = MockStrategyStateRepository();
    useCase = GetStrategyState(mockRepository);
  });

  group('GetStrategyState Use Case', () {
        const tSymbol = 'BTCUSDT';
    
    test('should return exactly what repository returns on success', () async {
      when(() => mockRepository.getStrategyState(any())).thenAnswer((_) async => Right(AppStrategyState(symbol: 'BTCUSDT', status: StrategyState.IDLE)));

      final result = await useCase(symbol: tSymbol);

      expect(result.isRight(), true);
    });

    test('should return Failure when repository fails', () async {
      final tFailure = ServerFailure(message: 'Server Error');
      when(() => mockRepository.getStrategyState(any())).thenAnswer((_) async => Left(tFailure));

      final result = await useCase(symbol: tSymbol);

      expect(result.fold((l) => l, (r) => r), equals(tFailure));
    });

  });
}

