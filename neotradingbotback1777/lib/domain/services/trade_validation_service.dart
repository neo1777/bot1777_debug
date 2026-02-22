import 'dart:math';
import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/entities/symbol_info.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';

class TradeValidationService {
  /// Arrotonda la quantità al multiplo valido dello stepSize, sempre per eccesso (ceil).
  /// Utile per garantire che la quantità superi una soglia minima (es. minNotional).
  double roundUpToStep(SymbolInfo limits, double quantity) {
    if (limits.stepSize == 0) return quantity;
    final factor = 1 / limits.stepSize;
    return (quantity * factor).ceil() / factor;
  }

  /// Valida e formatta la quantità rispettando minQty, maxQty e stepSize.
  /// Se [isFixedQuantity] è true, usa il rounding più vicino, altrimenti floor (default).
  Either<Failure, double> validateAndFormatQuantity(
      SymbolInfo limits, double quantity,
      {bool isFixedQuantity = false}) {
    if (quantity < limits.minQty) {
      return Left(ValidationFailure(
          message:
              'Quantità ($quantity) inferiore al minimo consentito (${limits.minQty})'));
    }
    if (quantity > limits.maxQty) {
      return Left(ValidationFailure(
          message:
              'Quantità ($quantity) superiore al massimo consentito (${limits.maxQty})'));
    }

    if (limits.stepSize == 0) {
      return Right(quantity);
    }

    final factor = 1 / limits.stepSize;

    // FIX: Per quantità fisse, usa round() per rispettare l'intenzione dell'utente
    // Per quantità calcolate (budget based), usa floor() per sicurezza (non sforare il budget)
    final formattedQuantity = isFixedQuantity
        ? (quantity * factor).round() / factor
        : (quantity * factor).floor() / factor;

    final decimalPlaces = max(0, (log(factor) / log(10)).round());

    return Right(
        double.parse(formattedQuantity.toStringAsFixed(decimalPlaces)));
  }
}
