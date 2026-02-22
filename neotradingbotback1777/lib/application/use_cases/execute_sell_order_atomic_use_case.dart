import 'package:decimal/decimal.dart';
import 'package:neotradingbotback1777/core/utils/decimal_utils.dart';
import 'package:neotradingbotback1777/core/utils/decimal_compare.dart';
import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:neotradingbotback1777/core/errors/unified_error_handler.dart';
import 'package:neotradingbotback1777/domain/entities/app_trade.dart';

import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/i_symbol_info_repository.dart';
import 'package:neotradingbotback1777/domain/services/i_trading_api_service.dart';
import 'package:neotradingbotback1777/domain/value_objects/amounts.dart';
import 'package:neotradingbotback1777/domain/services/trade_validation_service.dart';
import 'package:neotradingbotback1777/core/utils/unique_id_generator.dart';

class ExecuteSellOrderAtomic {
  final ITradingApiService apiService;
  final ISymbolInfoRepository symbolInfoRepository;
  final TradeValidationService tradeValidationService;
  final String symbol;
  final double quantityToSell;
  final double price; // Prezzo corrente passato dall'esterno
  final bool isTestMode;
  final UnifiedErrorHandler _errorHandler;

  ExecuteSellOrderAtomic({
    required this.apiService,
    required this.symbolInfoRepository,
    required this.symbol,
    required this.quantityToSell,
    required this.price,
    required this.isTestMode,
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

        // 1) Validazione e rounding della quantità richiesta
        final formattedQuantityEither = tradeValidationService
            .validateAndFormatQuantity(symbolInfo, quantityToSell);
        var formattedQuantity =
            formattedQuantityEither.getOrElse((f) => throw f);

        // 2) Gestione dust
        final notionalValue = DecimalUtils.toDouble(
            DecimalUtils.mulDoubles(formattedQuantity, price));
        if (DecimalCompare.ltDoubles(notionalValue, symbolInfo.minNotional)) {
          final minQtyByNotional = tradeValidationService.roundUpToStep(
              symbolInfo, symbolInfo.minNotional / price);
          final maxSellable = quantityToSell;
          if (DecimalCompare.lteDoubles(minQtyByNotional, maxSellable)) {
            formattedQuantity = minQtyByNotional;
          } else {
            final maxSellFloor =
                tradeValidationService.roundUpToStep(symbolInfo, maxSellable);
            final maxSellNotional = DecimalUtils.toDouble(
                DecimalUtils.mulDoubles(maxSellFloor, price));
            if (DecimalCompare.gteDoubles(
                maxSellNotional, symbolInfo.minNotional)) {
              formattedQuantity = maxSellFloor;
            } else {
              final requiredNotional = symbolInfo.minNotional;
              final deficit = requiredNotional - notionalValue;
              final message =
                  'DUST_UNSELLABLE;symbol=$symbol;qty=${formattedQuantity.toStringAsFixed(8)};notional=${notionalValue.toStringAsFixed(8)};min=$requiredNotional;deficit=${deficit.toStringAsFixed(8)}';

              LogManager.getLogger().w(message);
              throw BusinessLogicFailure(
                message: message,
                code: 'DUST_UNSELLABLE',
              );
            }
          }
        }

        if (isTestMode) {
          final trade = AppTrade(
            symbol: symbol,
            price: MoneyAmount.fromDouble(price),
            quantity: QuantityAmount.fromDouble(formattedQuantity),
            isBuy: false,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            orderStatus: 'FILLED',
          );
          LogManager.getLogger().i(
              'Ordine SELL simulato per $symbol (Test Mode) eseguito con successo via UseCase.');
          return trade;
        }

        final clientOrderId =
            UniqueIdGenerator.generateStringId('SELL_$symbol');
        final orderResult = await apiService.createOrder(
          symbol: symbol,
          side: "SELL",
          quantity: formattedQuantity,
          clientOrderId: clientOrderId,
        );

        final orderResponse = orderResult.getOrElse((f) => throw f);

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

        if (totalQuantity == Decimal.zero) {
          throw ServerFailure(
              message:
                  'Ordine SELL $symbol senza eseguito: ${orderResponse.status}');
        }

        final averagePrice = (totalQuantity > Decimal.zero)
            ? DecimalUtils.toDoubleAny(totalValue / totalQuantity)
            : 0.0;

        final trade = AppTrade(
          symbol: symbol,
          price: MoneyAmount.fromDouble(averagePrice),
          quantity:
              QuantityAmount.fromDouble(DecimalUtils.toDouble(totalQuantity)),
          isBuy: false,
          timestamp: orderResponse.timestamp,
          orderStatus: orderResponse.status,
        );

        LogManager.getLogger()
            .i('Ordine SELL per $symbol eseguito con successo.');
        return trade;
      },
      operationName: 'ExecuteSellOrderAtomic',
    );
  }
}
