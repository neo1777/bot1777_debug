import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:neotradingbotfront1777/domain/entities/system_log.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_trading_repository.dart';

part 'system_log_event.dart';
part 'system_log_state.dart';

class SystemLogBloc extends Bloc<SystemLogEvent, SystemLogState> {
  final ITradingRepository _tradingRepository;
  StreamSubscription? _systemLogsSubscription;

  SystemLogBloc({required ITradingRepository tradingRepository})
    : _tradingRepository = tradingRepository,
      super(const SystemLogState()) {
    on<SystemLogSubscriptionRequested>(
      _onSubscriptionRequested,
      transformer:
          restartable(), // Usa restartable per gestire la ri-sottoscrizione
    );
    on<_SystemLogReceived>(_onLogReceived, transformer: sequential());
    on<_SystemLogStreamFailed>(_onStreamFailed);
    on<SystemLogFilterChanged>(_onFilterChanged);
    on<SystemLogClearRequested>(_onClearRequested);
    on<SystemLogLoadMoreRequested>(_onLoadMoreRequested);
    on<SystemLogToggleAutoScroll>(_onToggleAutoScrollRequested);
  }

  Future<void> _onSubscriptionRequested(
    SystemLogSubscriptionRequested event,
    Emitter<SystemLogState> emit,
  ) async {
    await _systemLogsSubscription?.cancel();
    emit(state.copyWith(status: SystemLogStatus.loading));

    _systemLogsSubscription = _tradingRepository.subscribeToSystemLogs().listen(
      (result) => result.fold(
        (failure) => add(_SystemLogStreamFailed(failure.message)),
        (newLog) => add(_SystemLogReceived(newLog)),
      ),
      onError:
          (error) => add(
            _SystemLogStreamFailed('Errore nello stream dei log: $error'),
          ),
      onDone:
          () => add(const _SystemLogStreamFailed('Connessione log interrotta')),
    );

    emit(state.copyWith(status: SystemLogStatus.subscribed));
  }

  void _onLogReceived(_SystemLogReceived event, Emitter<SystemLogState> emit) {
    final updatedLogs = List<SystemLog>.from(state.logs)..insert(0, event.log);
    final bounded = updatedLogs.take(5000).toList(); // cap buffer a 5000
    emit(state.copyWith(logs: bounded));
  }

  void _onStreamFailed(
    _SystemLogStreamFailed event,
    Emitter<SystemLogState> emit,
  ) {
    emit(
      state.copyWith(
        status: SystemLogStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  void _onFilterChanged(
    SystemLogFilterChanged event,
    Emitter<SystemLogState> emit,
  ) {
    final newLevels = event.levels ?? state.activeLevels;
    final newQuery = event.query ?? state.query;
    emit(state.copyWith(activeLevels: newLevels, query: newQuery));
  }

  void _onClearRequested(
    SystemLogClearRequested event,
    Emitter<SystemLogState> emit,
  ) {
    emit(state.copyWith(logs: const [], visibleCount: state.pageSize));
  }

  void _onLoadMoreRequested(
    SystemLogLoadMoreRequested event,
    Emitter<SystemLogState> emit,
  ) {
    final next = (state.visibleCount + state.pageSize).clamp(
      0,
      state.logs.length,
    );
    emit(state.copyWith(visibleCount: next));
  }

  void _onToggleAutoScrollRequested(
    SystemLogToggleAutoScroll event,
    Emitter<SystemLogState> emit,
  ) {
    emit(state.copyWith(autoScroll: event.enabled));
  }

  @override
  Future<void> close() {
    _systemLogsSubscription?.cancel();
    return super.close();
  }
}
