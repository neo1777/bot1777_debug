import 'package:neotradingbotback1777/domain/entities/app_trade.dart';
import 'package:decimal/decimal.dart';
import 'package:neotradingbotback1777/core/utils/decimal_utils.dart';
import 'package:neotradingbotback1777/domain/value_objects/amounts.dart';

class ProfitCalculationService {
  /// Calcola i profitti per una lista di transazioni usando una strategia FIFO.
  /// Restituisce una nuova lista di [AppTrade] dove le transazioni di vendita
  /// sono arricchite con il profitto calcolato.
  List<AppTrade> calculateFifoProfit(List<AppTrade> allTrades) {
    final tradesBySymbol = <String, List<AppTrade>>{};

    // Raggruppa i trade per simbolo
    for (final trade in allTrades) {
      (tradesBySymbol[trade.symbol] ??= []).add(trade);
    }

    final tradesWithProfit = <AppTrade>[];

    tradesBySymbol.forEach((symbol, trades) {
      // Ordina i trade per data, dal più vecchio al più recente
      trades.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      final buyQueue = <AppTrade>[];

      for (final trade in trades) {
        if (trade.isBuy) {
          buyQueue.add(trade);
          tradesWithProfit.add(trade); // Aggiungi l'acquisto alla lista finale
        } else {
          // È una vendita, calcoliamo il profitto
          Decimal totalCost = Decimal.zero;
          double quantityToMatch = trade.quantity.toDouble();
          Decimal profit = Decimal.zero;

          final tempBuyQueue = <AppTrade>[];

          while (quantityToMatch > 0 && buyQueue.isNotEmpty) {
            final buy = buyQueue.first;

            if (buy.quantity.toDouble() <= quantityToMatch) {
              // Questo acquisto è completamente consumato dalla vendita
              totalCost += DecimalUtils.mulDoubles(
                  buy.quantity.toDouble(), buy.price.toDouble());
              quantityToMatch -= buy.quantity.toDouble();
              buyQueue.removeAt(0);
            } else {
              // Questo acquisto è parzialmente consumato dalla vendita
              totalCost += DecimalUtils.mulDoubles(
                  quantityToMatch, buy.price.toDouble());

              // Aggiorna la quantità rimanente dell'acquisto
              final remainingBuy = buy.copyWith(
                  quantity: QuantityAmount.fromDouble(
                      buy.quantity.toDouble() - quantityToMatch));
              tempBuyQueue.add(remainingBuy);
              buyQueue.removeAt(0);

              quantityToMatch = 0;
            }
          }

          buyQueue.insertAll(0, tempBuyQueue);

          if (totalCost > Decimal.zero) {
            final sellValue = DecimalUtils.mulDoubles(
                trade.quantity.toDouble(), trade.price.toDouble());
            profit = sellValue - totalCost;
          }

          tradesWithProfit.add(trade.copyWith(
              profit: MoneyAmount.fromDouble(DecimalUtils.toDouble(profit))));
        }
      }
    });

    // Riordina la lista finale per data, dalla più recente alla più vecchia, come l'originale
    tradesWithProfit.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return tradesWithProfit;
  }
}
