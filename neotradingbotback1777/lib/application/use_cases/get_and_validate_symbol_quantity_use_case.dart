import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/core/extensions/double_extensions.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/i_symbol_info_repository.dart';

class GetAndValidateSymbolQuantityUseCase {
  final ISymbolInfoRepository _symbolInfoRepository;

  GetAndValidateSymbolQuantityUseCase(this._symbolInfoRepository);

  Future<Either<Failure, double>> call({
    required String symbol,
    required double rawQuantity,
    required bool isBuyOrder,
  }) async {
    final symbolInfoResult = await _symbolInfoRepository.getSymbolInfo(symbol);

    return await symbolInfoResult.fold(
      (failure) => Left(failure),
      (symbolInfo) async {
        // symbolInfo cannot be null here due to the logic in the repository
        final int precision =
            symbolInfo.stepSize.toString().toDecimalPrecision();

        // FIX BUG #5: Usa strategia di arrotondamento appropriata per tipo di ordine
        final double formattedQuantity = isBuyOrder
            ? rawQuantity.roundForBuyOrder(
                precision) // Floor per buy orders (conservativo)
            : rawQuantity.roundForCalculation(
                precision); // Round per sell orders (bilanciato)

        // Validazione aggiuntiva per prevenire errori di precisione
        if (formattedQuantity.isNaN || formattedQuantity.isInfinite) {
          return Left(ValidationFailure(
              message:
                  'Calcolo della quantità ha prodotto un valore non valido: $formattedQuantity'));
        }

        if (isBuyOrder) {
          if (formattedQuantity < symbolInfo.minQty) {
            return Left(ValidationFailure(
                message:
                    'La quantità calcolata ($formattedQuantity) è inferiore alla minima consentita (${symbolInfo.minQty}). Aumentare il tradeAmount.'));
          }
        } else {
          // Sell Order
          if (formattedQuantity <= 0 || formattedQuantity < symbolInfo.minQty) {
            return Left(ValidationFailure(
                message:
                    'La quantità da vendere calcolata ($formattedQuantity) è inferiore alla minima consentita (${symbolInfo.minQty}) o nulla. Impossibile procedere con la vendita.'));
          }
        }

        return Right(formattedQuantity);
      },
    );
  }
}
