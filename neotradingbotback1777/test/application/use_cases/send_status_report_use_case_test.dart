import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neotradingbotback1777/application/use_cases/send_status_report_use_case.dart';
import 'package:neotradingbotback1777/domain/entities/account_info.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotback1777/domain/repositories/account_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/price_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/strategy_state_repository.dart';
import 'package:neotradingbotback1777/domain/services/i_notification_service.dart';
import 'package:test/test.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

class MockStrategyStateRepository extends Mock
    implements StrategyStateRepository {}

class MockPriceRepository extends Mock implements PriceRepository {}

class MockNotificationService extends Mock implements INotificationService {}

void main() {
  late SendStatusReport useCase;
  late MockAccountRepository mockAccountRepository;
  late MockStrategyStateRepository mockStrategyStateRepository;
  late MockPriceRepository mockPriceRepository;
  late MockNotificationService mockNotificationService;

  setUp(() {
    mockAccountRepository = MockAccountRepository();
    mockStrategyStateRepository = MockStrategyStateRepository();
    mockPriceRepository = MockPriceRepository();
    mockNotificationService = MockNotificationService();
    useCase = SendStatusReport(
      mockAccountRepository,
      mockStrategyStateRepository,
      mockPriceRepository,
      mockNotificationService,
    );
  });

  group('SendStatusReport', () {
    test('should fetch data and send notification', () async {
      // arrange
      final tAccountInfo = AccountInfo(balances: []);
      final tStates = <String, AppStrategyState>{
        'BTCUSDT':
            AppStrategyState(symbol: 'BTCUSDT', status: StrategyState.IDLE)
      };

      when(() => mockAccountRepository.getAccountInfo())
          .thenAnswer((_) async => Right(tAccountInfo));
      when(() => mockStrategyStateRepository.getAllStrategyStates())
          .thenAnswer((_) async => Right(tStates));
      when(() => mockPriceRepository.getCurrentPrice(any()))
          .thenAnswer((_) async => Right(50000.0));
      when(() => mockNotificationService.sendMessage(any()))
          .thenAnswer((_) async => const Right(null));

      // act
      final result = await useCase();

      // assert
      expect(result.isRight(), true);
      verify(() => mockAccountRepository.getAccountInfo()).called(1);
      verify(() => mockStrategyStateRepository.getAllStrategyStates())
          .called(1);
      verify(() => mockNotificationService.sendMessage(any())).called(1);
    });
  });
}
