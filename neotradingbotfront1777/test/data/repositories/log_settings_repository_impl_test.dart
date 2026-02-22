import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/data/repositories/log_settings_repository_impl.dart';
import 'package:neotradingbotfront1777/domain/entities/log_settings.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pbgrpc.dart';

import '../../mocks/mocks.dart';

void main() {
  late LogSettingsRepositoryImpl repository;
  late MockTradingRemoteDatasource mockRemoteDatasource;

  setUpAll(() {
    registerFallbackValue(UpdateLogSettingsRequest());
  });

  setUp(() {
    mockRemoteDatasource = MockTradingRemoteDatasource();
    repository = LogSettingsRepositoryImpl(
      remoteDatasource: mockRemoteDatasource,
    );
  });

  group('LogSettingsRepositoryImpl - getLogSettings', () {
    final tLogSettingsDto =
        LogSettingsProto()
          ..logLevel = 'INFO'
          ..enableFileLogging = true
          ..enableConsoleLogging = true;

    final tLogSettingsResponse =
        LogSettingsResponse()..logSettings = tLogSettingsDto;

    test(
      'should return LogSettings when remote datasource call is successful',
      () async {
        // arrange
        when(
          () => mockRemoteDatasource.getLogSettings(),
        ).thenAnswer((_) async => Right(tLogSettingsResponse));

        // act
        final result = await repository.getLogSettings();

        // assert
        expect(result.isRight(), true);
        final settings = result.getOrElse((_) => throw Exception());
        expect(settings.logLevel, LogLevel.info);
        expect(settings.enableFileLogging, true);
        verify(() => mockRemoteDatasource.getLogSettings()).called(1);
      },
    );

    test('should return Failure when remote datasource call fails', () async {
      // arrange
      final tFailure = ServerFailure(message: 'Error');
      when(
        () => mockRemoteDatasource.getLogSettings(),
      ).thenAnswer((_) async => Left(tFailure));

      // act
      final result = await repository.getLogSettings();

      // assert
      expect(result.isLeft(), true);
      expect(result.fold((l) => l, (r) => null), equals(tFailure));
    });
  });

  group('LogSettingsRepositoryImpl - updateLogSettings', () {
    const tLogSettings = LogSettings(
      logLevel: LogLevel.debug,
      enableFileLogging: false,
      enableConsoleLogging: false,
    );

    final tLogSettingsDto =
        LogSettingsProto()
          ..logLevel = 'DEBUG'
          ..enableFileLogging = false
          ..enableConsoleLogging = false;

    final tLogSettingsResponse =
        LogSettingsResponse()..logSettings = tLogSettingsDto;

    test('should return updated LogSettings when successful', () async {
      // arrange
      when(
        () => mockRemoteDatasource.updateLogSettings(any()),
      ).thenAnswer((_) async => Right(tLogSettingsResponse));

      // act
      final result = await repository.updateLogSettings(tLogSettings);

      // assert
      expect(result.isRight(), true);
      final settings = result.getOrElse((_) => throw Exception());
      expect(settings.logLevel, LogLevel.debug);
      verify(() => mockRemoteDatasource.updateLogSettings(any())).called(1);
    });

    test('should return Failure when update fails', () async {
      // arrange
      final tFailure = ServerFailure(message: 'Update Failed');
      when(
        () => mockRemoteDatasource.updateLogSettings(any()),
      ).thenAnswer((_) async => Left(tFailure));

      // act
      final result = await repository.updateLogSettings(tLogSettings);

      // assert
      expect(result.isLeft(), true);
      expect(result.fold((l) => l, (r) => null), equals(tFailure));
    });
  });
}
