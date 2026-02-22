import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/data/datasources/i_trading_remote_datasource.dart';
import 'package:neotradingbotfront1777/data/repositories/settings_repository_impl.dart';
import 'package:neotradingbotfront1777/domain/entities/app_settings.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pb.dart';
import 'package:test/test.dart';

class MockTradingRemoteDatasource extends Mock
    implements ITradingRemoteDatasource {}

class FakeUpdateSettingsRequest extends Fake implements UpdateSettingsRequest {}

void main() {
  late MockTradingRemoteDatasource mockDatasource;
  late SettingsRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(FakeUpdateSettingsRequest());
  });

  setUp(() {
    mockDatasource = MockTradingRemoteDatasource();
    repository = SettingsRepositoryImpl(remoteDatasource: mockDatasource);
  });

  group('SettingsRepositoryImpl — getSettings', () {
    test('[SR-01] returns AppSettings on success', () async {
      final settingsProto = Settings(
        tradeAmount: 100.0,
        profitTargetPercentage: 2.5,
        stopLossPercentage: 5.0,
        maxOpenTrades: 3,
        isTestMode: true,
      );
      final response = SettingsResponse(settings: settingsProto);

      when(
        () => mockDatasource.getSettings(),
      ).thenAnswer((_) async => Right(response));

      final result = await repository.getSettings();

      expect(result.isRight(), true);
      result.fold((_) => fail('Expected Right'), (settings) {
        expect(settings, isA<AppSettings>());
        expect(settings.tradeAmount, 100.0);
        expect(settings.maxOpenTrades, 3);
        expect(settings.isTestMode, true);
      });
    });

    test('[SR-02] returns Failure when datasource fails', () async {
      when(() => mockDatasource.getSettings()).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'Server down')),
      );

      final result = await repository.getSettings();

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Server down'),
        (_) => fail('Expected Left'),
      );
    });

    test('[SR-03] returns UnexpectedFailure on exception', () async {
      when(() => mockDatasource.getSettings()).thenThrow(Exception('DB error'));

      final result = await repository.getSettings();

      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<UnexpectedFailure>());
        expect(failure.message, contains('DB error'));
      }, (_) => fail('Expected Left'));
    });
  });

  group('SettingsRepositoryImpl — updateSettings', () {
    test('[SR-04] returns updated AppSettings on success', () async {
      final inputSettings = AppSettings(
        tradeAmount: 200.0,
        profitTargetPercentage: 3.0,
        stopLossPercentage: 7.0,
        dcaDecrementPercentage: 1.0,
        maxOpenTrades: 5,
        isTestMode: false,
        buyOnStart: true,
        initialWarmupTicks: 20,
      );

      final responseProto = Settings(
        tradeAmount: 200.0,
        profitTargetPercentage: 3.0,
        stopLossPercentage: 7.0,
        maxOpenTrades: 5,
        isTestMode: false,
      );
      final response = SettingsResponse(settings: responseProto);

      when(
        () => mockDatasource.updateSettings(any()),
      ).thenAnswer((_) async => Right(response));

      final result = await repository.updateSettings(inputSettings);

      expect(result.isRight(), true);
      result.fold((_) => fail('Expected Right'), (settings) {
        expect(settings.tradeAmount, 200.0);
        expect(settings.maxOpenTrades, 5);
      });
      verify(() => mockDatasource.updateSettings(any())).called(1);
    });

    test('[SR-05] returns Failure when update fails', () async {
      final settings = AppSettings(
        tradeAmount: 100.0,
        profitTargetPercentage: 2.5,
        stopLossPercentage: 5.0,
        dcaDecrementPercentage: 1.0,
        maxOpenTrades: 3,
        isTestMode: false,
        buyOnStart: false,
        initialWarmupTicks: 10,
      );

      when(() => mockDatasource.updateSettings(any())).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'Validation failed')),
      );

      final result = await repository.updateSettings(settings);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Validation failed'),
        (_) => fail('Expected Left'),
      );
    });
  });
}

