import 'package:neotradingbotfront1777/domain/entities/fee_info.dart';

/// Servizio per calcoli di trading consapevoli delle fee
///
/// Fornisce metodi per calcolare target, profitti e distanze
/// considerando le commissioni reali di Binance
class FeeAwareCalculationService {
  /// Calcola il target di take profit considerando le fee
  ///
  /// [averagePrice] - Prezzo medio di acquisto
  /// [profitTargetPercentage] - Percentuale target di profitto
  /// [fees] - Informazioni sulle fee (se null, usa calcolo tradizionale)
  /// [isMaker] - Se true, usa fee maker (tipicamente più basse)
  static double calculateTakeProfitTarget({
    required double averagePrice,
    required double profitTargetPercentage,
    FeeInfo? fees,
    bool isMaker = false,
  }) {
    if (fees == null) {
      // Calcolo tradizionale senza fee
      return averagePrice * (1 + profitTargetPercentage / 100);
    }

    // Calcolo con fee considerate
    // Per ottenere un profitto NETTO del X%, dobbiamo vendere a un prezzo
    // che compensi le fee e ci dia il profitto desiderato

    final effectiveFee = fees.getEffectiveFeePercentage(isMaker: isMaker);

    // Formula: target = prezzo_medio * (1 + profitto_target + fee) / (1 - fee)
    // Questo garantisce che dopo aver pagato le fee, il profitto sia esattamente quello target
    final target =
        averagePrice *
        (1 + profitTargetPercentage / 100 + effectiveFee) /
        (1 - effectiveFee);

    return target;
  }

  /// Calcola il target di stop loss considerando le fee
  ///
  /// [averagePrice] - Prezzo medio di acquisto
  /// [stopLossPercentage] - Percentuale di stop loss
  /// [fees] - Informazioni sulle fee (se null, usa calcolo tradizionale)
  /// [isMaker] - Se true, usa fee maker
  static double calculateStopLossTarget({
    required double averagePrice,
    required double stopLossPercentage,
    FeeInfo? fees,
    bool isMaker = false,
  }) {
    if (fees == null) {
      // Calcolo tradizionale senza fee
      return averagePrice * (1 - stopLossPercentage / 100);
    }

    // Calcolo con fee considerate
    // Per uno stop loss NETTO del X%, dobbiamo vendere a un prezzo
    // che dopo le fee ci dia esattamente quella perdita

    final effectiveFee = fees.getEffectiveFeePercentage(isMaker: isMaker);

    // Formula: target = prezzo_medio * (1 - stop_loss - fee) / (1 - fee)
    final target =
        averagePrice *
        (1 - stopLossPercentage / 100 - effectiveFee) /
        (1 - effectiveFee);

    return target;
  }

  /// Calcola il profitto netto atteso a un prezzo target
  ///
  /// [targetPrice] - Prezzo target di vendita
  /// [averagePrice] - Prezzo medio di acquisto
  /// [quantity] - Quantità da vendere
  /// [fees] - Informazioni sulle fee
  /// [isMaker] - Se true, usa fee maker
  static double calculateNetProfitAtTarget({
    required double targetPrice,
    required double averagePrice,
    required double quantity,
    required FeeInfo fees,
    bool isMaker = false,
  }) {
    // Profitto lordo
    final grossProfit = (targetPrice - averagePrice) * quantity;

    // Fee totali per la vendita
    final totalFees = fees.calculateTotalFees(
      quantity: quantity,
      price: targetPrice,
      isMaker: isMaker,
      useDiscount: true,
    );

    // Profitto netto
    final netProfit = grossProfit - totalFees;

    return netProfit;
  }

  /// Calcola la percentuale di profitto netto a un prezzo target
  ///
  /// [targetPrice] - Prezzo target di vendita
  /// [averagePrice] - Prezzo medio di acquisto
  /// [fees] - Informazioni sulle fee
  /// [isMaker] - Se true, usa fee maker
  static double calculateNetProfitPercentageAtTarget({
    required double targetPrice,
    required double averagePrice,
    required FeeInfo fees,
    bool isMaker = false,
  }) {
    // Profitto lordo percentuale
    final grossProfitPercent =
        ((targetPrice - averagePrice) / averagePrice) * 100;

    // Fee percentuale
    final effectiveFee = fees.getEffectiveFeePercentage(isMaker: isMaker);

    // Profitto netto percentuale
    final netProfitPercent = grossProfitPercent - (effectiveFee * 100);

    return netProfitPercent;
  }

  /// Calcola la distanza percentuale a un target considerando le fee
  ///
  /// [currentPrice] - Prezzo corrente
  /// [targetPrice] - Prezzo target
  /// [fees] - Informazioni sulle fee (per calcoli aggiuntivi)
  static double calculateDistanceToTarget({
    required double currentPrice,
    required double targetPrice,
    FeeInfo? fees,
  }) {
    if (currentPrice <= 0) return 0.0;

    // Distanza percentuale semplice
    final distance = ((targetPrice - currentPrice) / currentPrice) * 100;

    // Se le fee sono disponibili, possiamo fornire informazioni aggiuntive
    // ma per ora restituiamo la distanza base
    return distance;
  }

  /// Determina se un prezzo target è raggiungibile considerando le fee
  ///
  /// [targetPrice] - Prezzo target
  /// [currentPrice] - Prezzo corrente
  /// [fees] - Informazioni sulle fee
  /// [threshold] - Soglia minima per considerare raggiungibile (default 0.1%)
  static bool isTargetReachable({
    required double targetPrice,
    required double currentPrice,
    required FeeInfo fees,
    double threshold = 0.1,
  }) {
    if (currentPrice <= 0) return false;

    final distance = calculateDistanceToTarget(
      currentPrice: currentPrice,
      targetPrice: targetPrice,
      fees: fees,
    );

    // Target raggiungibile se la distanza è positiva e significativa
    return distance > threshold;
  }
}
