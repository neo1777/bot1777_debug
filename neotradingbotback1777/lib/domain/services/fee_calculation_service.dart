import 'package:neotradingbotback1777/domain/entities/fee_info.dart';
import 'package:neotradingbotback1777/domain/repositories/i_fee_repository.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:logger/logger.dart';
import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/core/errors/unified_error_handler.dart';

/// Servizio centralizzato per il calcolo delle fee
///
/// Elimina la duplicazione di logica tra repository e service layer
/// fornendo un'interfaccia unificata per tutti i calcoli relativi alle fee
class FeeCalculationService {
  final IFeeRepository _feeRepository;
  final UnifiedErrorHandler _errorHandler;
  final Logger _log;

  FeeCalculationService({
    required IFeeRepository feeRepository,
    UnifiedErrorHandler? errorHandler,
    Logger? logger,
  })  : _feeRepository = feeRepository,
        _errorHandler = errorHandler ?? UnifiedErrorHandler(),
        _log = logger ?? LogManager.getLogger();

  /// Calcola le fee totali per una transazione
  ///
  /// [quantity]: Quantità della transazione
  /// [price]: Prezzo della transazione
  /// [isMaker]: Se la transazione è maker o taker
  /// [useDiscount]: Se applicare sconti disponibili
  /// [symbol]: Simbolo per recuperare le fee specifiche
  Future<Either<Failure, double>> calculateTotalFees({
    required double quantity,
    required double price,
    required bool isMaker,
    required String symbol,
    bool useDiscount = true,
  }) async {
    return await _errorHandler.handleAsyncOperation(
      () async {
        // Recupera le fee per il simbolo
        final feesResult = await _feeRepository.getSymbolFeesIfNeeded(symbol);

        return feesResult.fold(
          (failure) {
            _log.w('Failed to get fees for $symbol: ${failure.message}');
            // Fallback su fee di default
            final defaultFees = FeeInfo.defaultBinance(symbol: symbol);
            return _calculateFeesFromInfo(
              quantity: quantity,
              price: price,
              isMaker: isMaker,
              feeInfo: defaultFees,
              useDiscount: useDiscount,
            );
          },
          (feeInfo) => _calculateFeesFromInfo(
            quantity: quantity,
            price: price,
            isMaker: isMaker,
            feeInfo: feeInfo,
            useDiscount: useDiscount,
          ),
        );
      },
      operationName: 'calculateTotalFees',
    );
  }

  /// Calcola le fee da un FeeInfo
  double _calculateFeesFromInfo({
    required double quantity,
    required double price,
    required bool isMaker,
    required FeeInfo feeInfo,
    required bool useDiscount,
  }) {
    // Seleziona la fee appropriata (maker o taker)
    double feeRate = isMaker ? feeInfo.makerFee : feeInfo.takerFee;

    // Applica sconto se disponibile
    if (useDiscount && feeInfo.isDiscountActive) {
      feeRate = feeRate * (1 - feeInfo.discountPercentage);
    }

    // Calcola fee totale
    final totalValue = quantity * price;
    return totalValue * feeRate;
  }

  /// Calcola il profitto netto dopo le fee
  ///
  /// [grossProfitPercent]: Profitto lordo in percentuale
  /// [quantity]: Quantità totale
  /// [price]: Prezzo corrente
  /// [symbol]: Simbolo per le fee
  /// [isMaker]: Se la vendita è maker o taker
  Future<Either<Failure, double>> calculateNetProfit({
    required double grossProfitPercent,
    required double quantity,
    required double price,
    required String symbol,
    bool isMaker = false,
  }) async {
    return await _errorHandler.handleAsyncOperation(
      () async {
        // Calcola profitto lordo in valore assoluto
        final grossProfitValue =
            (grossProfitPercent / 100) * (quantity * price);

        // Calcola fee totali per la vendita
        final feesResult = await calculateTotalFees(
          quantity: quantity,
          price: price,
          isMaker: isMaker,
          symbol: symbol,
          useDiscount: true,
        );

        return feesResult.fold(
          (failure) => throw failure, // Rilancia failure per essere catturata
          (totalFees) {
            // Calcola profitto netto
            final netProfitValue = grossProfitValue - totalFees;

            // Converti in percentuale
            final totalValue = quantity * price;
            final netProfitPercent =
                totalValue > 0 ? (netProfitValue / totalValue) * 100 : 0.0;

            return netProfitPercent;
          },
        );
      },
      operationName: 'calculateNetProfit',
    );
  }

  /// Calcola il costo totale di un acquisto (prezzo + fee)
  ///
  /// [quantity]: Quantità da acquistare
  /// [price]: Prezzo di acquisto
  /// [symbol]: Simbolo per le fee
  /// [isMaker]: Se l'acquisto è maker o taker
  Future<Either<Failure, double>> calculateTotalCost({
    required double quantity,
    required double price,
    required String symbol,
    bool isMaker = true, // Gli acquisti sono tipicamente maker
  }) async {
    return await _errorHandler.handleAsyncOperation(
      () async {
        final feesResult = await calculateTotalFees(
          quantity: quantity,
          price: price,
          isMaker: isMaker,
          symbol: symbol,
          useDiscount: true,
        );

        return feesResult.fold(
          (failure) => throw failure,
          (totalFees) {
            final totalCost = (quantity * price) + totalFees;
            return totalCost;
          },
        );
      },
      operationName: 'calculateTotalCost',
    );
  }

  /// Calcola la quantità effettiva acquistabile con un budget
  ///
  /// [budget]: Budget disponibile
  /// [price]: Prezzo corrente
  /// [symbol]: Simbolo per le fee
  /// [isMaker]: Se l'acquisto è maker o taker
  Future<Either<Failure, double>> calculateAffordableQuantity({
    required double budget,
    required double price,
    required String symbol,
    bool isMaker = true,
  }) async {
    return await _errorHandler.handleAsyncOperation(
      () async {
        final feesResult = await calculateTotalFees(
          quantity: 1.0, // Quantità unitaria per calcolare la fee rate
          price: price,
          isMaker: isMaker,
          symbol: symbol,
          useDiscount: true,
        );

        return feesResult.fold(
          (failure) => throw failure,
          (totalFees) {
            // Calcola la fee rate per unità
            final feeRate = totalFees / price;

            // Calcola quantità acquistabile considerando le fee
            final affordableQuantity = budget / (price * (1 + feeRate));

            return affordableQuantity;
          },
        );
      },
      operationName: 'calculateAffordableQuantity',
    );
  }

  /// Valida se una transazione è profittevole considerando le fee
  ///
  /// [buyPrice]: Prezzo di acquisto
  /// [sellPrice]: Prezzo di vendita
  /// [quantity]: Quantità
  /// [symbol]: Simbolo per le fee
  Future<Either<Failure, bool>> isTransactionProfitable({
    required double buyPrice,
    required double sellPrice,
    required double quantity,
    required String symbol,
  }) async {
    return await _errorHandler.handleAsyncOperation(
      () async {
        // Calcola fee per acquisto (tipicamente maker)
        final buyFeesResult = await calculateTotalFees(
          quantity: quantity,
          price: buyPrice,
          isMaker: true,
          symbol: symbol,
          useDiscount: true,
        );

        // Calcola fee per vendita (tipicamente taker)
        // Nota: usiamo await qui, quindi dobbiamo gestire il risultato
        // prima di procedere, o concatenarli.
        // Per semplicità e leggibilità, aspettiamo sequenzialmente.

        return await buyFeesResult.fold(
          (failure) async => throw failure,
          (buyFees) async {
            final sellFeesResult = await calculateTotalFees(
              quantity: quantity,
              price: sellPrice,
              isMaker: false,
              symbol: symbol,
              useDiscount: true,
            );

            return sellFeesResult.fold(
              (failure) => throw failure,
              (sellFees) {
                final totalCost = (quantity * buyPrice) + buyFees;
                final totalRevenue = (quantity * sellPrice) - sellFees;
                final isProfitable = totalRevenue > totalCost;

                _log.d('Transaction profitability check for $symbol: '
                    'Cost=$totalCost, Revenue=$totalRevenue, Profitable=$isProfitable');

                return isProfitable;
              },
            );
          },
        );
      },
      operationName: 'isTransactionProfitable',
    );
  }

  /// Ottiene le fee correnti per un simbolo
  Future<Either<Failure, FeeInfo>> getCurrentFees(String symbol) async {
    return await _feeRepository.getSymbolFeesIfNeeded(symbol);
  }

  /// Aggiorna le fee per un simbolo
  Future<Either<Failure, FeeInfo>> refreshFees(String symbol) async {
    return await _feeRepository.refreshSymbolFees(symbol);
  }

  /// Pulisce la cache delle fee
  Future<void> clearFeeCache() async {
    await _feeRepository.clearCache();
    _log.i('Fee cache cleared via FeeCalculationService');
  }
}
