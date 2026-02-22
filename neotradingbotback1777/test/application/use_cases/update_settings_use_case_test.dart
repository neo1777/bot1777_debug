import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neotradingbotback1777/application/use_cases/update_settings_use_case.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/log_settings.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/settings_repository.dart';
import 'package:test/test.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late UpdateSettings useCase;
  late MockSettingsRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(AppStrategyState(symbol: 'BTCUSDT'));
    registerFallbackValue(AppSettings.initial());
    registerFallbackValue(LogSettings.defaultSettings());
  });

  setUp(() {
    mockRepository = MockSettingsRepository();
    useCase = UpdateSettings(mockRepository);
  });

  group('UpdateSettings Use Case', () {
        final tSettings = AppSettings.initial();
    
    test('should return exactly what repository returns on success', () async {
      when(() => mockRepository.saveSettings(any())).thenAnswer((_) async => Right(null));

      final result = await useCase(tSettings);

      expect(result.isRight(), true);
    });

    test('should return Failure when repository fails', () async {
      final tFailure = ServerFailure(message: 'Server Error');
      when(() => mockRepository.saveSettings(any())).thenAnswer((_) async => Left(tFailure));

      final result = await useCase(tSettings);

      final failure = result.fold((l) => l, (r) => null);
      expect(failure, equals(tFailure));
    });

  });
}
