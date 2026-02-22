import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:neotradingbotfront1777/domain/entities/app_settings.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_settings_repository.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final ISettingsRepository _settingsRepository;

  SettingsBloc({required ISettingsRepository settingsRepository})
    : _settingsRepository = settingsRepository,
      super(const SettingsState()) {
    on<SettingsFetched>(_onSettingsFetched);
    on<SettingsUpdated>(_onSettingsUpdated);
    on<SettingsDirtyChanged>(_onSettingsDirtyChanged);
  }

  /// Gestisce l'evento di caricamento delle impostazioni.
  Future<void> _onSettingsFetched(
    SettingsFetched event,
    Emitter<SettingsState> emit,
  ) async {
    // Evita di ricaricare se le impostazioni sono già caricate (a meno che force=true)
    if (!event.force &&
        state.status == SettingsStatus.success &&
        state.settings != null) {
      return;
    }

    // Evita di ricaricare se è già in corso un caricamento
    if (state.status == SettingsStatus.loading) {
      return;
    }

    emit(state.copyWith(status: SettingsStatus.loading));

    final result = await _settingsRepository.getSettings();

    // .fold è un modo pulito per gestire il risultato di Either<Failure, Success>
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: SettingsStatus.failure,
          failureMessage: failure.message,
        ),
      ),
      (settings) => emit(
        state.copyWith(status: SettingsStatus.success, settings: settings),
      ),
    );
  }

  /// Gestisce l'evento di aggiornamento delle impostazioni.
  Future<void> _onSettingsUpdated(
    SettingsUpdated event,
    Emitter<SettingsState> emit,
  ) async {
    // Inizia un nuovo salvataggio: resettiamo i messaggi e manterremo
    // i warnings aggiornati solo al termine.
    emit(state.copyWith(status: SettingsStatus.saving, infoMessage: null));

    final result = await _settingsRepository.updateSettings(event.settings);

    result.fold(
      (failure) {
        // Trattiamo [WARN] come successo informativo e persistiamo i warnings
        if (failure.message.startsWith('[WARN]')) {
          final raw = failure.message.replaceFirst('[WARN] ', '');
          final warnings =
              raw
                  .split(';')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
          final newState = state.copyWith(
            status: SettingsStatus.saved,
            settings: event.settings,
            infoMessage: raw,
            warnings: warnings,
          );
          emit(newState);
          return;
        }
        emit(
          state.copyWith(
            status: SettingsStatus.failure,
            failureMessage: failure.message,
          ),
        );
      },
      (updatedSettings) {
        // Aggiorna immediatamente le impostazioni con quelle restituite dal server
        // per assicurarsi che la dashboard mostri i valori effettivi salvati
        final newState = state.copyWith(
          status: SettingsStatus.saved,
          settings:
              updatedSettings, // Usa le impostazioni restituite dal repository
          // Nessun warning esplicito dal server
          infoMessage: 'Impostazioni salvate con successo.',
          warnings: const [],
        );
        emit(newState);
      },
    );
  }

  void _onSettingsDirtyChanged(
    SettingsDirtyChanged event,
    Emitter<SettingsState> emit,
  ) {
    emit(state.copyWith(isDirty: event.isDirty));
  }
}
