import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neotradingbotback1777/application/use_cases/get_current_price_use_case.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/log_settings.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/price_repository.dart';
import 'package:test/test.dart';

class MockPriceRepository extends Mock implements PriceRepository {}

void main() {
  late GetCurrentPrice useCase;
  late MockPriceRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(AppStrategyState(symbol: 'BTCUSDT'));
    registerFallbackValue(AppSettings.initial());
    registerFallbackValue(LogSettings.defaultSettings());
  });

  setUp(() {
    mockRepository = MockPriceRepository();
    useCase = GetCurrentPrice(mockRepository);
  });

  group('GetCurrentPrice Use Case', () {
        const tSymbol = 'BTCUSDT';
    
    test('should return exactly what repository returns on success', () async {
      when(() => mockRepository.getCurrentPrice(any())).thenAnswer((_) async => Right(50000.0));

      final result = await useCase(symbol: tSymbol);

      expect(result.isRight(), true);
    });

    test('should return Failure when repository fails', () async {
      final tFailure = ServerFailure(message: 'Server Error');
      when(() => mockRepository.getCurrentPrice(any())).thenAnswer((_) async => Left(tFailure));

      final result = await useCase(symbol: tSymbol);

      expect(result.fold((l) => l, (r) => r), equals(tFailure));
    });

  });
}

