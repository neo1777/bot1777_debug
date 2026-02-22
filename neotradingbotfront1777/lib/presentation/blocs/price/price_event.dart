import 'package:equatable/equatable.dart';

abstract class PriceEvent extends Equatable {
  const PriceEvent();

  @override
  List<Object?> get props => [];
}

class SubscribeToPriceUpdates extends PriceEvent {
  const SubscribeToPriceUpdates(this.symbol);

  final String symbol;

  @override
  List<Object?> get props => [symbol];
}

class UnsubscribeFromPriceUpdates extends PriceEvent {
  const UnsubscribeFromPriceUpdates();
}

class PriceUpdateReceived extends PriceEvent {
  const PriceUpdateReceived(this.priceData);

  final dynamic priceData; // Will be mapped to PriceData in bloc

  @override
  List<Object?> get props => [priceData];
}

class ResetPriceState extends PriceEvent {
  const ResetPriceState();
}
