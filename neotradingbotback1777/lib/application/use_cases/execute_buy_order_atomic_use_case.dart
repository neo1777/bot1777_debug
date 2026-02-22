import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:neotradingbotback1777/core/errors/unified_error_handler.dart';
import 'package:neotradingbotback1777/domain/entities/app_trade.dart';
import 'package:neotradingbotback1777/domain/entities/symbol_info.dart';

import 'package:neotradingbotback1777/domain/entities/account_info.dart';
import 'package:neotradingbotback1777/domain/repositories/account_repository.dart';
import 'package:neotradingbotback1777/domain/entities/balance.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/i_symbol_info_repository.dart';
import 'package:neotradingbotback1777/domain/services/i_trading_api_service.dart';
import 'package:decimal/decimal.dart';
import 'package:neotradingbotback1777/core/utils/decimal_utils.dart';
import 'package:neotradingbotback1777/core/utils/decimal_compare.dart';

import 'package:neotradingbotback1777/domain/value_objects/amounts.dart';
import 'package:neotradingbotback1777/domain/services/trade_validation_service.dart';
import 'package:neotradingbotback1777/core/utils/unique_id_generator.dart';

class ExecuteBuyOrderAtomic {
  final ITradingApiService apiService;
  final ISymbolInfoRepository symbolInfoRepository;
  final AccountRepository accountRepository;
  final TradeValidationService tradeValidationService;
  final String symbol;
  final double price;
  final double tradeAmount;
  final double? fixedQuantity;
  final bool isTestMode;
  final double maxBuyOveragePct;
  final bool strictBudget;
  final UnifiedErrorHandler _errorHandler;

  ExecuteBuyOrderAtomic({
    required this.apiService,
    required this.symbolInfoRepository,
    required this.accountRepository,
    required this.symbol,
    required this.price,
    required this.tradeAmount,
    required this.isTestMode,
    required this.maxBuyOveragePct,
    required this.strictBudget,
    this.fixedQuantity,
    TradeValidationService? tradeValidationService,
    UnifiedErrorHandler? errorHandler,
  })  : tradeValidationService =
            tradeValidationService ?? TradeValidationService(),
        _errorHandler = errorHandler ?? GlobalUnifiedErrorHandler.instance;

  Future<Either<Failure, AppTrade>> call() async {
    return _errorHandler.handleAsyncOperation(
      () async {
        final limitsResult = await symbolInfoRepository.getSymbolInfo(symbol);
        final symbolInfo = limitsResult.getOrElse((f) => throw f);

        // Calcolo quantità
        final qtyResult = _computeBuyQuantityEnsuringNotional(
            symbolInfo, price, tradeAmount, fixedQuantity);
        final formattedQuantity = qtyResult.getOrElse((f) => throw f);

        // Verifica saldo
        final requiredQuote = formattedQuantity * price;
        final accountResult = await accountRepository.getAccountInfo();
        final accountInfo =
            accountResult.getOrElse((f) => throw f) as AccountInfo;

        final inferredQuoteAsset =
            _inferQuoteAssetFromBalances(symbol, accountInfo);
        if (inferredQuoteAsset == null) {
          throw ValidationFailure(
              message: 'Impossibile inferire valuta quotazione per $symbol');
        }

        final balance = accountInfo.balances.firstWhere(
          (b) => b.asset == inferredQuoteAsset,
          orElse: () =>
              Balance(asset: inferredQuoteAsset, free: 0.0, locked: 0.0),
        );

        if (DecimalCompare.ltDoubles(balance.free, requiredQuote)) {
          throw BusinessLogicFailure(
            message: 'Saldo $inferredQuoteAsset insufficiente per BUY.',
          );
        }

        if (isTestMode) {
          final trade = AppTrade(
            symbol: symbol,
            price: MoneyAmount.fromDouble(price),
            quantity: QuantityAmount.fromDouble(formattedQuantity),
            isBuy: true,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            orderStatus: 'FILLED',
          );
          LogManager.getLogger().i(
              'Ordine BUY simulato per $symbol (Test Mode) eseguito con successo via UseCase.');
          return trade;
        }

        final clientOrderId = UniqueIdGenerator.generateStringId('BUY_$symbol');
        final orderResult = await apiService.createOrder(
          symbol: symbol,
          side: "BUY",
          quantity: formattedQuantity,
          clientOrderId: clientOrderId,
        );

        final orderResponse = orderResult.getOrElse((f) => throw f);

        if (orderResponse.status != 'FILLED') {
          throw ServerFailure(
              message:
                  'Ordine BUY $symbol non FILLED: ${orderResponse.status}');
        }

        Decimal totalValue = Decimal.zero;
        Decimal totalQuantity = Decimal.zero;

        if (orderResponse.fills != null && orderResponse.fills!.isNotEmpty) {
          for (var fill in orderResponse.fills!) {
            final fillPrice = double.tryParse(fill['price']) ?? 0.0;
            final fillQuantity = double.tryParse(fill['qty']) ?? 0.0;
            totalValue += DecimalUtils.mulDoubles(fillQuantity, fillPrice);
            totalQuantity += DecimalUtils.dFromDouble(fillQuantity);
          }
        } else {
          totalValue =
              DecimalUtils.dFromDouble(orderResponse.cumulativeQuoteQty ?? 0.0);
          totalQuantity = DecimalUtils.dFromDouble(orderResponse.executedQty);
        }

        final averagePrice = (totalQuantity > Decimal.zero)
            ? DecimalUtils.toDoubleAny(totalValue / totalQuantity)
            : price;

        final trade = AppTrade(
          symbol: symbol,
          price: MoneyAmount.fromDouble(averagePrice),
          quantity:
              QuantityAmount.fromDouble(DecimalUtils.toDouble(totalQuantity)),
          isBuy: true,
          timestamp: orderResponse.timestamp,
          orderStatus: orderResponse.status,
        );

        LogManager.getLogger()
            .i('Ordine BUY per $symbol eseguito con successo.');
        return trade;
      },
      operationName: 'ExecuteBuyOrderAtomic',
    );
  }

  /// Calcola la quantità di acquisto garantendo che il notional (qty * price) sia >= minNotional
  /// dopo il rounding a stepSize. Auto-adjust disabilitato per evitare dust.
  Either<Failure, double> _computeBuyQuantityEnsuringNotional(SymbolInfo limits,
      double price, double tradeAmount, double? fixedQuantity) {
    // Se è specificata una quantità fissa, usala direttamente
    if (fixedQuantity != null && fixedQuantity > 0) {
      final baseQtyEither = tradeValidationService.validateAndFormatQuantity(
          limits, fixedQuantity,
          isFixedQuantity: true);
      if (baseQtyEither.isLeft()) {
        return baseQtyEither;
      }
      final qty = baseQtyEither.getOrElse((_) => 0.0);

      // Verifica che il notional superi il minimo richiesto
      final notional = qty * price;
      if (DecimalCompare.ltDoubles(notional, limits.minNotional)) {
        return Left(ValidationFailure(
          message: 'Quantità fissa insufficiente per soddisfare minNotional. '
              'Aumenta la quantità fissa. '
              '(richiesti≈${(limits.minNotional / price).toStringAsFixed(8)}, disponibili≈${qty.toStringAsFixed(8)})',
          code: 'FIXED_QUANTITY_INSUFFICIENT',
          details: {
            'price': price,
            'fixedQuantity': fixedQuantity,
            'calculatedQuantity': qty,
            'notional': notional,
            'minNotional': limits.minNotional,
          },
        ));
      }

      return Right(qty);
    }

    // Quantità grezza desiderata in base al budget assegnato
    final desiredQty = tradeAmount / price;

    // Arrotonda per step e valida min/max quantità
    final baseQtyEither =
        tradeValidationService.validateAndFormatQuantity(limits, desiredQty);
    if (baseQtyEither.isLeft()) {
      // Auto-adjust disabilitato: restituisci errore se la quantità non è valida
      return baseQtyEither;
    }

    final qty = baseQtyEither.getOrElse((_) => 0.0);

    // Verifica che il notional superi il minimo richiesto
    final notional = qty * price;
    if (DecimalCompare.ltDoubles(notional, limits.minNotional)) {
      // Se strictBudget è attivo, non permettiamo overage
      // Altrimenti, verifichiamo se possiamo aumentare la quantità entro il limite di maxBuyOveragePct
      final canUseOverage = !strictBudget && maxBuyOveragePct > 0;
      final maxAllowedAmount = tradeAmount * (1 + maxBuyOveragePct);

      if (canUseOverage && limits.minNotional <= maxAllowedAmount) {
        // Calcoliamo la quantità minima necessaria per soddisfare il notional
        final minRequiredQty = limits.minNotional / price;
        final adjustedQtyResult = tradeValidationService
            .validateAndFormatQuantity(limits, minRequiredQty);
        return adjustedQtyResult.fold(
          (failure) => Left(failure),
          (adjustedQty) {
            final adjustedNotional = adjustedQty * price;
            // Se dopo il rounding siamo ancora sotto (raro ma possibile con floor), incrementiamo di un stepSize
            if (DecimalCompare.ltDoubles(
                adjustedNotional, limits.minNotional)) {
              final finalQty = adjustedQty + limits.stepSize;
              // Verifica finale che non superiamo comunque il maxAllowedAmount
              if ((finalQty * price) > maxAllowedAmount) {
                return Left(ValidationFailure(
                    message:
                        'Impossibile soddisfare minNotional neanche con overage.'));
              }
              return Right(finalQty);
            }
            return Right(adjustedQty);
          },
        );
      }

      return Left(ValidationFailure(
        message:
            'Importo trade insufficiente per soddisfare minNotional dopo rounding. '
            'Aumenta tradeAmount${!strictBudget ? ' o maxBuyOveragePct' : ''}. '
            '(richiesti≈${(limits.minNotional / price).toStringAsFixed(8)}, disponibili≈${qty.toStringAsFixed(8)})',
        code: 'BUY_BUDGET_INSUFFICIENT',
        details: {
          'price': price,
          'tradeAmount': tradeAmount,
          'maxAllowedAmount': maxAllowedAmount,
          'calculatedQuantity': qty,
          'notional': notional,
          'minNotional': limits.minNotional,
        },
      ));
    }

    return Right(qty);
  }

  String? _inferQuoteAssetFromBalances(String symbol, AccountInfo accountInfo) {
    String? best;
    for (final b in accountInfo.balances) {
      final asset = b.asset;
      if (asset.isEmpty) continue;
      if (symbol.endsWith(asset)) {
        if (best == null || asset.length > best.length) {
          best = asset;
        }
      }
    }
    return best;
  }
}
