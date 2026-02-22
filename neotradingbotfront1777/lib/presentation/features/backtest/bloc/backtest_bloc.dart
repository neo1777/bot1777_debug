import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_backtest_repository.dart';
import 'package:neotradingbotfront1777/presentation/features/backtest/bloc/backtest_event.dart';
import 'package:neotradingbotfront1777/presentation/features/backtest/bloc/backtest_state.dart';

class BacktestBloc extends Bloc<BacktestEvent, BacktestState> {
  final IBacktestRepository repository;

  BacktestBloc(this.repository) : super(BacktestInitial()) {
    on<StartBacktest>(_onStartBacktest);
  }

  Future<void> _onStartBacktest(
    StartBacktest event,
    Emitter<BacktestState> emit,
  ) async {
    emit(BacktestLoading());

    final startResult = await repository.startBacktest(
      symbol: event.symbol,
      interval: event.interval,
      period: event.period,
      strategyName: event.strategyName,
    );

    await startResult.fold((failure) async => emit(BacktestError(failure.message)), (
      backtestId,
    ) async {
      emit(BacktestRunning(backtestId));
      // Immediately try to fetch results. In a real scenario, this might need polling or streaming.
      // Assuming synchronous backtest for now or quick enough.
      // Or we might want to wait a bit or use a loop.
      // For this implementation, let's try to fetch once.
      // If it's long running, we should handle differently (e.g. status checks).
      // Let's assume it returns properly or we call getBacktestResult which blocks until done?
      // gRPC usually has timeouts.

      // Actually, let's call getBacktestResult immediately.
      final resultEither = await repository.getBacktestResults(backtestId);
      resultEither.fold(
        (failure) => emit(BacktestError(failure.message)),
        (result) => emit(BacktestLoaded(result)),
      );
    });
  }
}
