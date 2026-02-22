import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_trading_repository.dart';
import 'package:neotradingbotfront1777/core/utils/log_manager.dart';

part 'strategy_control_event.dart';
part 'strategy_control_state.dart';

class StrategyControlBloc
    extends Bloc<StrategyControlEvent, StrategyControlState> {
  final ITradingRepository _tradingRepository;
  final _log = LogManager.getLogger();

  StrategyControlBloc({required ITradingRepository tradingRepository})
    : _tradingRepository = tradingRepository,
      super(const StrategyControlState()) {
    // Usa restartable per evitare accodamento e perdita eventi su start multipli ravvicinati
    on<StartStrategyRequested>(_onStartStrategy, transformer: restartable());
    on<StopStrategyRequested>(_onStopStrategy, transformer: droppable());
    on<PauseStrategyRequested>(_onPauseStrategy, transformer: droppable());
    on<ResumeStrategyRequested>(_onResumeStrategy, transformer: droppable());
    on<StatusReportRequested>(
      _onStatusReportRequested,
      transformer: droppable(),
    );
  }

  Future<void> _onStartStrategy(
    StartStrategyRequested event,
    Emitter<StrategyControlState> emit,
  ) async {
    await _handleStrategyOperation(
      emitter: emit,
      operation: () => _tradingRepository.startStrategy(event.symbol),
    );
  }

  Future<void> _onStopStrategy(
    StopStrategyRequested event,
    Emitter<StrategyControlState> emit,
  ) async {
    await _handleStrategyOperation(
      emitter: emit,
      operation: () => _tradingRepository.stopStrategy(event.symbol),
    );
  }

  Future<void> _onPauseStrategy(
    PauseStrategyRequested event,
    Emitter<StrategyControlState> emit,
  ) async {
    await _handleStrategyOperation(
      emitter: emit,
      operation: () => _tradingRepository.pauseTrading(event.symbol),
    );
  }

  Future<void> _onResumeStrategy(
    ResumeStrategyRequested event,
    Emitter<StrategyControlState> emit,
  ) async {
    await _handleStrategyOperation(
      emitter: emit,
      operation: () => _tradingRepository.resumeTrading(event.symbol),
    );
  }

  Future<void> _onStatusReportRequested(
    StatusReportRequested event,
    Emitter<StrategyControlState> emit,
  ) async {
    await _handleStrategyOperation(
      emitter: emit,
      operation: () => _tradingRepository.sendStatusReport(),
    );
  }

  Future<void> _handleStrategyOperation({
    required Emitter<StrategyControlState> emitter,
    required Future<Either<Failure, Unit>> Function() operation,
  }) async {
    emitter(const StrategyControlState(status: OperationStatus.inProgress));
    try {
      final result = await operation();
      result.fold(
        (failure) => emitter(
          state.copyWith(
            status: OperationStatus.failure,
            errorMessage: failure.message,
          ),
        ),
        (_) => emitter(
          const StrategyControlState(status: OperationStatus.success),
        ),
      );
    } catch (e) {
      _log.e('Errore imprevisto durante operazione strategia: $e');
      emitter(
        state.copyWith(
          status: OperationStatus.failure,
          errorMessage: 'Errore imprevisto: $e',
        ),
      );
    }
  }
}
