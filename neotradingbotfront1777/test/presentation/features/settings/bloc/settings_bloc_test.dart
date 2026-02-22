import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/domain/entities/app_settings.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_settings_repository.dart';
import 'package:neotradingbotfront1777/presentation/features/settings/bloc/settings_bloc.dart';

class MockSettingsRepository extends Mock implements ISettingsRepository {}

void main() {
  late MockSettingsRepository mockRepository;
  late SettingsBloc bloc;

  const tAppSettings = AppSettings(
    tradeAmount: 100.0,
    profitTargetPercentage: 1.0,
    stopLossPercentage: 5.0,
    dcaDecrementPercentage: 1.0,
    maxOpenTrades: 5,
    isTestMode: true,
  );

  setUpAll(() {
    registerFallbackValue(tAppSettings);
  });

  setUp(() {
    mockRepository = MockSettingsRepository();
    bloc = SettingsBloc(settingsRepository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state should be SettingsStatus.initial', () {
    expect(bloc.state.status, SettingsStatus.initial);
  });

  group('SettingsFetched', () {
    blocTest<SettingsBloc, SettingsState>(
      'emits [loading, success] when repository succeeds',
      build: () {
        when(
          () => mockRepository.getSettings(),
        ).thenAnswer((_) async => const Right(tAppSettings));
        return bloc;
      },
      act: (bloc) => bloc.add(const SettingsFetched()),
      expect:
          () => [
            const SettingsState(status: SettingsStatus.loading),
            const SettingsState(
              status: SettingsStatus.success,
              settings: tAppSettings,
            ),
          ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits [loading, failure] when repository fails',
      build: () {
        when(
          () => mockRepository.getSettings(),
        ).thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));
        return bloc;
      },
      act: (bloc) => bloc.add(const SettingsFetched()),
      expect:
          () => [
            const SettingsState(status: SettingsStatus.loading),
            const SettingsState(
              status: SettingsStatus.failure,
              failureMessage: 'Error',
            ),
          ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'does not emit if already loaded and not forced',
      build: () {
        when(
          () => mockRepository.getSettings(),
        ).thenAnswer((_) async => const Right(tAppSettings));
        return bloc;
      },
      seed:
          () => const SettingsState(
            status: SettingsStatus.success,
            settings: tAppSettings,
          ),
      act: (bloc) => bloc.add(const SettingsFetched()),
      expect: () => [],
      verify: (_) {
        verifyNever(() => mockRepository.getSettings());
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits [loading, success] if already loaded but forced',
      build: () {
        when(
          () => mockRepository.getSettings(),
        ).thenAnswer((_) async => const Right(tAppSettings));
        return bloc;
      },
      seed:
          () => const SettingsState(
            status: SettingsStatus.success,
            settings: tAppSettings,
          ),
      act: (bloc) => bloc.add(const SettingsFetched(force: true)),
      expect:
          () => [
            const SettingsState(
              status: SettingsStatus.loading,
              settings: tAppSettings,
            ),
            const SettingsState(
              status: SettingsStatus.success,
              settings: tAppSettings,
            ),
          ],
    );
  });

  group('SettingsUpdated', () {
    blocTest<SettingsBloc, SettingsState>(
      'emits [saving, saved] when repository succeeds',
      build: () {
        when(
          () => mockRepository.updateSettings(any()),
        ).thenAnswer((_) async => const Right(tAppSettings));
        return bloc;
      },
      act: (bloc) => bloc.add(const SettingsUpdated(tAppSettings)),
      expect:
          () => [
            const SettingsState(status: SettingsStatus.saving),
            const SettingsState(
              status: SettingsStatus.saved,
              settings: tAppSettings,
              infoMessage: 'Impostazioni salvate con successo.',
              warnings: [],
            ),
          ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits [saving, saved] with warnings when repository returns [WARN]',
      build: () {
        when(() => mockRepository.updateSettings(any())).thenAnswer(
          (_) async =>
              const Left(ServerFailure(message: '[WARN] Warning 1; Warning 2')),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const SettingsUpdated(tAppSettings)),
      expect:
          () => [
            const SettingsState(status: SettingsStatus.saving),
            const SettingsState(
              status: SettingsStatus.saved,
              settings: tAppSettings,
              infoMessage: 'Warning 1; Warning 2',
              warnings: ['Warning 1', 'Warning 2'],
            ),
          ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits [saving, failure] when repository fails',
      build: () {
        when(() => mockRepository.updateSettings(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Update Error')),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const SettingsUpdated(tAppSettings)),
      expect:
          () => [
            const SettingsState(status: SettingsStatus.saving),
            const SettingsState(
              status: SettingsStatus.failure,
              failureMessage: 'Update Error',
            ),
          ],
    );
  });
}

