import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neotradingbotback1777/application/use_cases/get_and_validate_symbol_quantity_use_case.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/log_settings.dart';
import 'package:neotradingbotback1777/domain/entities/symbol_info.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/i_symbol_info_repository.dart';
import 'package:test/test.dart';

class MockISymbolInfoRepository extends Mock implements ISymbolInfoRepository {}

void main() {
  late GetAndValidateSymbolQuantityUseCase useCase;
  late MockISymbolInfoRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(AppStrategyState(symbol: 'BTCUSDT'));
    registerFallbackValue(AppSettings.initial());
    registerFallbackValue(LogSettings.defaultSettings());
  });

  setUp(() {
    mockRepository = MockISymbolInfoRepository();
    useCase = GetAndValidateSymbolQuantityUseCase(mockRepository);
  });

  group('GetAndValidateSymbolQuantityUseCase Use Case', () {
        const tSymbol = 'BTCUSDT';
    const tRawquantity = 10.0;
    const tIsbuyorder = true;
    
    test('should return exactly what repository returns on success', () async {
      when(() => mockRepository.getSymbolInfo(any())).thenAnswer((_) async => Right(SymbolInfo(symbol: 'BTCUSDT', minQty: 0.001, maxQty: 100, stepSize: 0.001, minNotional: 10)));

      final result = await useCase(symbol: tSymbol, rawQuantity: tRawquantity, isBuyOrder: tIsbuyorder);

      expect(result.isRight(), true);
    });

    test('should return Failure when repository fails', () async {
      final tFailure = ServerFailure(message: 'Server Error');
      when(() => mockRepository.getSymbolInfo(any())).thenAnswer((_) async => Left(tFailure));

      final result = await useCase(symbol: tSymbol, rawQuantity: tRawquantity, isBuyOrder: tIsbuyorder);

      expect(result.fold((l) => l, (r) => r), equals(tFailure));
    });

  });
}
