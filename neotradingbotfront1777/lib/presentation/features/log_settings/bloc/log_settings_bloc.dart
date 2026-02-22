import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_log_settings_repository.dart';
import 'package:neotradingbotfront1777/presentation/features/log_settings/bloc/log_settings_event.dart';
import 'package:neotradingbotfront1777/presentation/features/log_settings/bloc/log_settings_state.dart';

class LogSettingsBloc extends Bloc<LogSettingsEvent, LogSettingsState> {
  final ILogSettingsRepository _repository;

  LogSettingsBloc({required ILogSettingsRepository repository})
    : _repository = repository,
      super(const LogSettingsState()) {
    on<LogSettingsFetched>(_onLogSettingsFetched);
    on<LogSettingsUpdated>(_onLogSettingsUpdated);
  }

  Future<void> _onLogSettingsFetched(
    LogSettingsFetched event,
    Emitter<LogSettingsState> emit,
  ) async {
    emit(state.copyWith(status: LogSettingsStatus.loading));
    final result = await _repository.getLogSettings();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: LogSettingsStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (settings) => emit(
        state.copyWith(status: LogSettingsStatus.success, settings: settings),
      ),
    );
  }

  Future<void> _onLogSettingsUpdated(
    LogSettingsUpdated event,
    Emitter<LogSettingsState> emit,
  ) async {
    emit(state.copyWith(status: LogSettingsStatus.loading));
    final result = await _repository.updateLogSettings(event.settings);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: LogSettingsStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (settings) => emit(
        state.copyWith(status: LogSettingsStatus.success, settings: settings),
      ),
    );
  }
}
