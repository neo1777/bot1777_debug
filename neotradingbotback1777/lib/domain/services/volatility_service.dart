import 'dart:math';
import 'package:neotradingbotback1777/core/config/trading_constants.dart';

/// Configurazione per il servizio di volatilità
class VolatilityConfig {
  final double threshold;
  final Duration freezeDuration;
  final Duration minFreezeDuration;
  final int minSamples;
  final double volatilityThreshold;
  final double unfreezeThreshold;
  final int windowSize;

  const VolatilityConfig({
    required this.threshold,
    required this.freezeDuration,
    required this.minFreezeDuration,
    required this.minSamples,
    required this.volatilityThreshold,
    required this.unfreezeThreshold,
    required this.windowSize,
  });

  factory VolatilityConfig.defaultConfig() => VolatilityConfig(
        threshold: TradingConstants.defaultVolatilityThreshold,
        freezeDuration: Duration(minutes: 1),
        minFreezeDuration: Duration(seconds: 30),
        minSamples: 5,
        volatilityThreshold: TradingConstants.defaultVolatilityThreshold,
        unfreezeThreshold: TradingConstants.defaultVolatilityThreshold * 0.5,
        windowSize: 20,
      );
}

/// Servizio per la gestione della volatilità di mercato
/// Implementa algoritmi per rilevare condizioni di alta volatilità
class VolatilityService {
  final VolatilityConfig _config;

  VolatilityService({VolatilityConfig? config})
      : _config = config ?? VolatilityConfig.defaultConfig();

  /// Determina se il mercato è in alta volatilità
  ///
  /// [volatilityLevel]: Livello di volatilità corrente (0.0 - 1.0)
  /// [isCurrentlyFrozen]: Se il prezzo è attualmente congelato
  /// [lastFreezeTime]: Timestamp dell'ultimo freeze
  ///
  /// Returns: true se il prezzo dovrebbe essere congelato
  bool shouldFreezePrice({
    required double volatilityLevel,
    required bool isCurrentlyFrozen,
    DateTime? lastFreezeTime,
  }) {
    // Se la volatilità supera la soglia, attiva il freeze
    if (volatilityLevel >= _config.volatilityThreshold) {
      return true;
    }

    // Se non è congelato, non fare nulla
    if (!isCurrentlyFrozen) {
      return false;
    }

    // Se è congelato, controlla se può essere sbloccato
    return !_canUnfreezePrice(
      volatilityLevel: volatilityLevel,
      lastFreezeTime: lastFreezeTime,
    );
  }

  /// Determina se il prezzo può essere sbloccato
  bool _canUnfreezePrice({
    required double volatilityLevel,
    required DateTime? lastFreezeTime,
  }) {
    // La volatilità deve essere sotto la soglia di sblocco
    if (volatilityLevel >= _config.unfreezeThreshold) {
      return false;
    }

    // Deve essere passato il tempo minimo di freeze
    if (lastFreezeTime != null) {
      final timeSinceFreeze = DateTime.now().difference(lastFreezeTime);
      if (timeSinceFreeze < _config.minFreezeDuration) {
        return false;
      }
    }

    return true;
  }

  /// Calcola la volatilità come deviazione standard normalizzata
  ///
  /// [prices]: Lista dei prezzi recenti
  ///
  /// Returns: Livello di volatilità normalizzato (0.0 - 1.0)
  double calculateVolatility(List<double> prices) {
    if (prices.length < 2) return 0.0;

    // Usa solo gli ultimi N prezzi basato sulla configurazione
    final startIndex = prices.length > _config.windowSize
        ? prices.length - _config.windowSize
        : 0;
    final recentPrices = prices.sublist(startIndex);

    final mean =
        recentPrices.reduce((a, b) => a + b) / recentPrices.length.toDouble();
    if (mean <= 0) return 0.0;

    final variance = recentPrices
            .map((p) => (p - mean) * (p - mean))
            .reduce((a, b) => a + b) /
        recentPrices.length;
    final stdDev = sqrt(variance);

    // Normalizza rispetto al prezzo medio
    return (stdDev / mean).clamp(0.0, 1.0);
  }
}
