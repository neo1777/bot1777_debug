import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

/// Rappresenta un singolo lotto di acquisto all'interno di un round di trading.
/// Questa entità è fondamentale per la gestione dello stato della strategia
/// e per i calcoli del prezzo medio e del P/L.
class FifoAppTrade extends Equatable {
  final Decimal price;
  final Decimal quantity;
  final int timestamp;
  final int roundId;

  /// Stato dell'ordine (FILLED, PARTIALLY_FILLED, CANCELLED, REJECTED)
  final String orderStatus;

  /// Flag che indica se il trade è stato eseguito completamente e con successo
  final bool isExecuted;

  const FifoAppTrade({
    required this.price,
    required this.quantity,
    required this.timestamp,
    required this.roundId,
    this.orderStatus = 'FILLED',
    this.isExecuted = true,
  });

  /// Crea una copia del trade con valori aggiornati
  FifoAppTrade copyWith({
    Decimal? price,
    Decimal? quantity,
    int? timestamp,
    int? roundId,
    String? orderStatus,
    bool? isExecuted,
  }) {
    return FifoAppTrade(
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      timestamp: timestamp ?? this.timestamp,
      roundId: roundId ?? this.roundId,
      orderStatus: orderStatus ?? this.orderStatus,
      isExecuted: isExecuted ?? this.isExecuted,
    );
  }

  @override
  List<Object> get props =>
      [price, quantity, timestamp, roundId, orderStatus, isExecuted];
}
