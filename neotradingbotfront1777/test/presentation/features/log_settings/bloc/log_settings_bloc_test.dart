import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/domain/entities/log_settings.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_log_settings_repository.dart';
import 'package:neotradingbotfront1777/presentation/features/log_settings/bloc/log_settings_bloc.dart';
import 'package:neotradingbotfront1777/presentation/features/log_settings/bloc/log_settings_event.dart';
import 'package:neotradingbotfront1777/presentation/features/log_settings/bloc/log_settings_state.dart';

class MockLogSettingsRepository extends Mock
    implements ILogSettingsRepository {}

void main() {
  late MockLogSettingsRepository mockRepository;
  late LogSettingsBloc bloc;

  final tLogSettings = LogSettings(
    logLevel: LogLevel.info,
    enableFileLogging: true,
    enableConsoleLogging: true,
  );

  setUpAll(() {
    registerFallbackValue(tLogSettings);
  });

  setUp(() {
    mockRepository = MockLogSettingsRepository();
    bloc = LogSettingsBloc(repository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state should be LogSettingsStatus.initial', () {
    expect(bloc.state.status, LogSettingsStatus.initial);
  });

  group('LogSettingsFetched', () {
    blocTest<LogSettingsBloc, LogSettingsState>(
      'emits [loading, success] when repository succeeds',
      build: () {
        when(
          () => mockRepository.getLogSettings(),
        ).thenAnswer((_) async => Right(tLogSettings));
        return bloc;
      },
      act: (bloc) => bloc.add(LogSettingsFetched()),
      expect:
          () => [
            const LogSettingsState(status: LogSettingsStatus.loading),
            LogSettingsState(
              status: LogSettingsStatus.success,
              settings: tLogSettings,
            ),
          ],
    );

    blocTest<LogSettingsBloc, LogSettingsState>(
      'emits [loading, failure] when repository fails',
      build: () {
        when(
          () => mockRepository.getLogSettings(),
        ).thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));
        return bloc;
      },
      act: (bloc) => bloc.add(LogSettingsFetched()),
      expect:
          () => [
            const LogSettingsState(status: LogSettingsStatus.loading),
            const LogSettingsState(
              status: LogSettingsStatus.failure,
              errorMessage: 'Error',
            ),
          ],
    );
  });

  group('LogSettingsUpdated', () {
    blocTest<LogSettingsBloc, LogSettingsState>(
      'emits [loading, success] when repository succeeds',
      build: () {
        when(
          () => mockRepository.updateLogSettings(any()),
        ).thenAnswer((_) async => Right(tLogSettings));
        return bloc;
      },
      act: (bloc) => bloc.add(LogSettingsUpdated(tLogSettings)),
      expect:
          () => [
            const LogSettingsState(status: LogSettingsStatus.loading),
            LogSettingsState(
              status: LogSettingsStatus.success,
              settings: tLogSettings,
            ),
          ],
    );

    blocTest<LogSettingsBloc, LogSettingsState>(
      'emits [loading, failure] when repository fails',
      build: () {
        when(() => mockRepository.updateLogSettings(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Update Error')),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(LogSettingsUpdated(tLogSettings)),
      expect:
          () => [
            const LogSettingsState(status: LogSettingsStatus.loading),
            const LogSettingsState(
              status: LogSettingsStatus.failure,
              errorMessage: 'Update Error',
            ),
          ],
    );
  });
}

