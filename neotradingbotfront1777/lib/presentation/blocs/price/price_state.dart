import 'package:equatable/equatable.dart';
import 'package:neotradingbotfront1777/domain/entities/price_data.dart';

abstract class PriceState extends Equatable {
  const PriceState();

  @override
  List<Object?> get props => [];
}

class PriceInitial extends PriceState {
  const PriceInitial();
}

class PriceLoading extends PriceState {
  const PriceLoading();
}

class PriceLoaded extends PriceState {
  const PriceLoaded(this.priceData);

  final PriceData priceData;

  @override
  List<Object?> get props => [priceData];
}

class PriceError extends PriceState {
  const PriceError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
