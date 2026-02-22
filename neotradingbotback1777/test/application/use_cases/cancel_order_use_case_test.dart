import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neotradingbotback1777/application/use_cases/cancel_order_use_case.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/log_settings.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/services/i_trading_api_service.dart';
import 'package:test/test.dart';

class MockITradingApiService extends Mock implements ITradingApiService {}

void main() {
  late CancelOrderUseCase useCase;
  late MockITradingApiService mockRepository;

  setUpAll(() {
    registerFallbackValue(AppStrategyState(symbol: 'BTCUSDT'));
    registerFallbackValue(AppSettings.initial());
    registerFallbackValue(LogSettings.defaultSettings());
  });

  setUp(() {
    mockRepository = MockITradingApiService();
    useCase = CancelOrderUseCase(mockRepository);
  });

  group('CancelOrderUseCase Use Case', () {
        const tSymbol = 'BTCUSDT';
    const tOrderid = 123;
    
    test('should return exactly what repository returns on success', () async {
      when(() => mockRepository.cancelOrder(symbol: any(named: 'symbol'), orderId: any(named: 'orderId'))).thenAnswer((_) async => Right(null));

      final result = await useCase(symbol: tSymbol, orderId: tOrderid);

      expect(result.isRight(), true);
    });

    test('should return Failure when repository fails', () async {
      final tFailure = ServerFailure(message: 'Server Error');
      when(() => mockRepository.cancelOrder(symbol: any(named: 'symbol'), orderId: any(named: 'orderId'))).thenAnswer((_) async => Left(tFailure));

      final result = await useCase(symbol: tSymbol, orderId: tOrderid);

      final failure = result.fold((l) => l, (r) => null);
      expect(failure, equals(tFailure));
    });

  });
}
