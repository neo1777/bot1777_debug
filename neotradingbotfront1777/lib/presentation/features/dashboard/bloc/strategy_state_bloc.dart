import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:neotradingbotfront1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_trading_repository.dart';
import 'package:neotradingbotfront1777/core/utils/log_manager.dart';
import 'package:neotradingbotfront1777/core/di/injection.dart';
import 'package:neotradingbotfront1777/core/symbol/symbol_context.dart';
import 'package:neotradingbotfront1777/domain/usecases/manage_strategy_run_control_use_case.dart';

part 'strategy_state_event.dart';
part 'strategy_state_state.dart';

class StrategyStateBloc extends Bloc<StrategyStateEvent, StrategyStateState> {
  final ITradingRepository _tradingRepository;
  final ManageStrategyRunControlUseCase _manageStrategyRunControlUseCase;
  final _log = LogManager.getLogger();
  StreamSubscription? _strategyStateSubscription;

  StrategyStateBloc({
    required ITradingRepository tradingRepository,
    required ManageStrategyRunControlUseCase manageStrategyRunControlUseCase,
  }) : _tradingRepository = tradingRepository,
       _manageStrategyRunControlUseCase = manageStrategyRunControlUseCase,
       super(const StrategyStateState()) {
    on<StrategyStateSubscriptionRequested>(
      _onSubscriptionRequested,
      transformer: restartable(),
    );
    on<_StrategyStateUpdated>(
      (event, emit) => emit(
        state.copyWith(
          status: StrategyStateStatus.subscribed,
          strategyState: event.state,
          // Se arrivano nuovi dati validi, rimuovi eventuale messaggio d'errore precedente
          failureMessage: null,
        ),
      ),
    );
    on<_StrategyStateStreamFailed>(
      (event, emit) => emit(
        state.copyWith(
          status: StrategyStateStatus.failure,
          failureMessage: event.errorMessage,
        ),
      ),
    );
    on<SymbolChanged>(_onSymbolChanged);
  }

  Future<void> _onSubscriptionRequested(
    StrategyStateSubscriptionRequested event,
    Emitter<StrategyStateState> emit,
  ) async {
    emit(
      state.copyWith(
        status: StrategyStateStatus.loading,
        currentSymbol: event.symbol,
      ),
    );
    await _strategyStateSubscription?.cancel();

    try {
      final stateResult = await _tradingRepository.getStrategyState(
        event.symbol,
      );
      stateResult.fold((failure) {
        // Gestione robusta del NOT_FOUND tipizzato dal repository
        if (failure is NotFoundFailure) {
          _log.i(
            'Nessuno stato strategia trovato per ${event.symbol}. Inizializzazione a stato di default.',
          );
          add(
            _StrategyStateUpdated(StrategyState.initial(symbol: event.symbol)),
          );
          return;
        }
        _log.e(
          'Errore durante il recupero dello stato strategia per ${event.symbol}: ${failure.message}',
        );
        add(_StrategyStateStreamFailed(failure.message));
      }, (initialState) => add(_StrategyStateUpdated(initialState)));

      _strategyStateSubscription = _tradingRepository
          .subscribeToStrategyState(event.symbol)
          .listen(
            (result) async {
              await result.fold(
                (failure) async {
                  add(_StrategyStateStreamFailed(failure.message));
                },
                (newState) async {
                  add(_StrategyStateUpdated(newState));
                  // Delegate run-control logic to Use Case
                  await _manageStrategyRunControlUseCase(newState);
                },
              );
            },
            onError:
                (error) => add(
                  _StrategyStateStreamFailed('Errore di connessione: $error'),
                ),
            onDone:
                () => add(
                  const _StrategyStateStreamFailed(
                    'Connessione al backend interrotta',
                  ),
                ),
          );
    } catch (e) {
      add(
        _StrategyStateStreamFailed(
          'Errore di connessione durante il caricamento: $e',
        ),
      );
    }
  }

  void _onSymbolChanged(SymbolChanged event, Emitter<StrategyStateState> emit) {
    // Persisti il simbolo attivo per coerenza cross-session
    try {
      sl<SymbolContext>().setActiveSymbol(event.symbol);
    } catch (_) {}
    add(StrategyStateSubscriptionRequested(event.symbol));
  }

  @override
  Future<void> close() {
    _strategyStateSubscription?.cancel();
    return super.close();
  }
}
