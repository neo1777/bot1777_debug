import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neotradingbotback1777/application/use_cases/get_trade_history_use_case.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/log_settings.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/trading_repository_new.dart';
import 'package:neotradingbotback1777/domain/services/profit_calculation_service.dart';
import 'package:test/test.dart';

class MockTradingRepository extends Mock implements TradingRepository {}
class MockProfitCalculationService extends Mock implements ProfitCalculationService {}

void main() {
  late GetTradeHistory useCase;
  late MockTradingRepository mockRepository;  late MockProfitCalculationService mockProfitCalculationService;

  setUpAll(() {
    registerFallbackValue(AppStrategyState(symbol: 'BTCUSDT'));
    registerFallbackValue(AppSettings.initial());
    registerFallbackValue(LogSettings.defaultSettings());
  });

  setUp(() {
    mockRepository = MockTradingRepository();    mockProfitCalculationService = MockProfitCalculationService();
    useCase = GetTradeHistory(mockRepository, mockProfitCalculationService);
  });

  group('GetTradeHistory Use Case', () {
    
    
    test('should return exactly what repository returns on success', () async {
      when(() => mockProfitCalculationService.calculateFifoProfit(any())).thenReturn([]);
      when(() => mockRepository.getAllTrades()).thenAnswer((_) async => Right([]));

      final result = await useCase();

      expect(result.isRight(), true);
    });

    test('should return Failure when repository fails', () async {
      final tFailure = ServerFailure(message: 'Server Error');
      when(() => mockRepository.getAllTrades()).thenAnswer((_) async => Left(tFailure));

      final result = await useCase();

      expect(result.fold((l) => l, (r) => r), equals(tFailure));
    });

  });
}
