import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neotradingbotback1777/application/use_cases/get_settings_use_case.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/log_settings.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/settings_repository.dart';
import 'package:test/test.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late GetSettings useCase;
  late MockSettingsRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(AppStrategyState(symbol: 'BTCUSDT'));
    registerFallbackValue(AppSettings.initial());
    registerFallbackValue(LogSettings.defaultSettings());
  });

  setUp(() {
    mockRepository = MockSettingsRepository();
    useCase = GetSettings(mockRepository);
  });

  group('GetSettings Use Case', () {
    
    
    test('should return exactly what repository returns on success', () async {
      when(() => mockRepository.getSettings()).thenAnswer((_) async => Right(AppSettings.initial()));

      final result = await useCase();

      expect(result.isRight(), true);
    });

    test('should return Failure when repository fails', () async {
      final tFailure = ServerFailure(message: 'Server Error');
      when(() => mockRepository.getSettings()).thenAnswer((_) async => Left(tFailure));

      final result = await useCase();

      expect(result.fold((l) => l, (r) => r), equals(tFailure));
    });

  });
}
