import 'dart:math';

/// Enum per specificare la strategia di arrotondamento
enum RoundingStrategy {
  /// Arrotonda sempre per difetto (floor) - conservativo per buy orders
  floor,

  /// Arrotonda sempre per eccesso (ceil) - usato per sell per evitare dust
  ceil,

  /// Arrotonda al più vicino (round) - standard per calcoli generali
  round,
}

extension DoubleExtensions on double {
  /// Arrotonda un valore a una data precisione decimale usando la strategia specificata.
  ///
  /// FIX BUG #5: Implementazione corretta per calcoli finanziari
  /// - [precision]: numero di decimali (es. 8 per BTC, 2 per USDC)
  /// - [strategy]: strategia di arrotondamento appropriata per il contesto
  double roundToPrecision(int precision, RoundingStrategy strategy) {
    if (precision < 0) throw ArgumentError('Precision must be non-negative');

    final multiplier = pow(10, precision);
    final scaledValue = this * multiplier;

    late final double result;
    switch (strategy) {
      case RoundingStrategy.floor:
        result = scaledValue.floor() / multiplier;
        break;
      case RoundingStrategy.ceil:
        result = scaledValue.ceil() / multiplier;
        break;
      case RoundingStrategy.round:
        result = scaledValue.round() / multiplier;
        break;
    }

    return result;
  }

  /// Helper specifico per ordini di acquisto (round down per sicurezza)
  /// FIX BUG #5: Previene "insufficient balance" usando strategia conservativa
  double roundForBuyOrder(int precision) {
    return roundToPrecision(precision, RoundingStrategy.floor);
  }

  /// Helper specifico per ordini di vendita (round up per evitare dust)
  /// FIX BUG #5: Previene accumulo di dust amounts
  /// ATTENZIONE: Usa con cautela - può causare "insufficient balance" se applicato ciecamente
  double roundForSellOrder(int precision) {
    return roundToPrecision(precision, RoundingStrategy.ceil);
  }

  /// Helper per calcoli generali (round al più vicino)
  double roundForCalculation(int precision) {
    return roundToPrecision(precision, RoundingStrategy.round);
  }
}

extension StringExtensions on String {
  /// Calcola il numero di posizioni decimali da una stringa come "0.00001".
  int toDecimalPrecision() {
    if (!contains('.')) return 0;
    final decimalPart = split('.')[1];
    // Troviamo l'indice dell'ultimo carattere diverso da zero
    final lastNonZeroIndex = decimalPart.lastIndexOf(RegExp(r'[1-9]'));
    return lastNonZeroIndex + 1;
  }
}
