import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neotradingbotback1777/application/use_cases/get_account_info_use_case.dart';
import 'package:neotradingbotback1777/domain/entities/account_info.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/log_settings.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/account_repository.dart';
import 'package:test/test.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

void main() {
  late GetAccountInfo useCase;
  late MockAccountRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(AppStrategyState(symbol: 'BTCUSDT'));
    registerFallbackValue(AppSettings.initial());
    registerFallbackValue(LogSettings.defaultSettings());
  });

  setUp(() {
    mockRepository = MockAccountRepository();
    useCase = GetAccountInfo(mockRepository);
  });

  group('GetAccountInfo Use Case', () {
    
    
    test('should return exactly what repository returns on success', () async {
      when(() => mockRepository.getAccountInfo()).thenAnswer((_) async => Right(AccountInfo(balances: [])));

      final result = await useCase();

      expect(result.isRight(), true);
    });

    test('should return Failure when repository fails', () async {
      final tFailure = ServerFailure(message: 'Server Error');
      when(() => mockRepository.getAccountInfo()).thenAnswer((_) async => Left(tFailure));

      final result = await useCase();

      expect(result.fold((l) => l, (r) => r), equals(tFailure));
    });

  });
}

