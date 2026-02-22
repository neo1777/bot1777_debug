import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotfront1777/domain/entities/price_data.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_price_repository.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/presentation/blocs/price/price_event.dart';
import 'package:neotradingbotfront1777/presentation/blocs/price/price_state.dart';
import 'dart:async';

class PriceBlocReal extends Bloc<PriceEvent, PriceState> {
  PriceBlocReal({required IPriceRepository priceRepository})
    : _priceRepository = priceRepository,
      super(const PriceInitial()) {
    on<SubscribeToPriceUpdates>(
      _onSubscribeToPriceUpdates,
      transformer: restartable(),
    );
    on<UnsubscribeFromPriceUpdates>(_onUnsubscribeFromPriceUpdates);
    on<PriceUpdateReceived>(_onPriceUpdateReceived);
    on<ResetPriceState>(_onResetPriceState, transformer: restartable());
  }

  final IPriceRepository _priceRepository;

  @override
  Future<void> close() {
    return super.close();
  }

  Future<void> _onSubscribeToPriceUpdates(
    SubscribeToPriceUpdates event,
    Emitter<PriceState> emit,
  ) async {
    emit(const PriceLoading());

    try {
      // Use emit.forEach for clean stream management with Emitter
      await emit.forEach<Either<Failure, PriceData>>(
        _priceRepository.streamCurrentPrice(event.symbol),
        onData: (result) {
          return result.fold(
            (failure) => PriceError(failure.message),
            (priceData) => PriceLoaded(priceData),
          );
        },
        onError: (error, stackTrace) => PriceError(error.toString()),
      );
    } catch (e) {
      if (!emit.isDone) {
        emit(PriceError(e.toString()));
      }
    }
  }

  void _onUnsubscribeFromPriceUpdates(
    UnsubscribeFromPriceUpdates event,
    Emitter<PriceState> emit,
  ) {
    emit(const PriceInitial());
  }

  Future<void> _onPriceUpdateReceived(
    PriceUpdateReceived event,
    Emitter<PriceState> emit,
  ) async {
    if (emit.isDone) return;
    if (event.priceData is PriceData) {
      emit(PriceLoaded(event.priceData));
    }
  }

  void _onResetPriceState(ResetPriceState event, Emitter<PriceState> emit) {
    emit(const PriceInitial());
  }
}
