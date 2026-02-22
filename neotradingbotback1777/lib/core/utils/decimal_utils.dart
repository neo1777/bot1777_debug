import 'package:decimal/decimal.dart';
import 'package:rational/rational.dart';

/// Utility per usare Decimal nei calcoli finanziari mantenendo double ai confini.
/// Riduce gli errori di arrotondamento cumulativi quando si sommano/moltiplicano
/// prezzi e quantità.
class DecimalUtils {
  // Scala predefinita per la conversione da double → Decimal
  // 12 decimali sono generalmente sufficienti per crypto spot (qty fino a 8-10 decimali,
  // prezzi fino a 2-6 decimali). Aumentare se necessario.
  static const int defaultScale = 12;

  // === POOL DI DECIMAL PRE-CALCOLATI ===
  // Cache per valori comuni per evitare conversioni ripetute
  static final Map<String, Decimal> _decimalPool = {};
  static final Map<double, Decimal> _doubleToDecimalCache = {};

  /// Converte un double in Decimal con ottimizzazione del pool
  static Decimal dFromDouble(double value, {int scale = defaultScale}) {
    // Controlla la cache per double
    if (_doubleToDecimalCache.containsKey(value)) {
      return _doubleToDecimalCache[value]!;
    }

    // Converte via stringa con scala controllata per stabilizzare i bit binari del double
    final formattedValue = value.toStringAsFixed(scale);

    // Controlla se il valore convertito è nel pool
    if (_decimalPool.containsKey(formattedValue)) {
      final result = _decimalPool[formattedValue]!;
      // Cache il risultato per il double originale
      if (_doubleToDecimalCache.length < 200) {
        // Limite per evitare crescita eccessiva
        _doubleToDecimalCache[value] = result;
      }
      return result;
    }

    // Se non nel pool, crea e cache
    final result = Decimal.parse(formattedValue);
    if (_doubleToDecimalCache.length < 200) {
      _doubleToDecimalCache[value] = result;
    }

    return result;
  }

  /// Converte un Decimal in double in modo resiliente
  static double toDouble(Decimal decimalValue) =>
      double.tryParse(decimalValue.toString()) ?? 0.0;

  /// Converte un valore Decimal/Rational/double/int in double in modo resiliente
  static double toDoubleAny(dynamic rawValue, {int scale = defaultScale}) {
    if (rawValue is Decimal) return toDouble(rawValue);
    if (rawValue is Rational) {
      return toDouble(rawValue.toDecimal(scaleOnInfinitePrecision: scale));
    }
    if (rawValue is num) return rawValue.toDouble();
    return double.tryParse(rawValue.toString()) ?? 0.0;
  }

  /// Somma una lista di double convertendoli in Decimal per precisione
  /// Ottimizzato per evitare conversioni multiple
  static Decimal addDoubles(Iterable<double> values,
      {int scale = defaultScale}) {
    if (values.isEmpty) return Decimal.zero;

    // Se c'è un solo valore, evita la conversione in lista
    if (values.length == 1) {
      return dFromDouble(values.first, scale: scale);
    }

    // Ottimizzazione: converti tutti i valori in una volta
    final decimals = values.map((v) => dFromDouble(v, scale: scale)).toList();

    Decimal sum = decimals.first;
    for (int i = 1; i < decimals.length; i++) {
      sum += decimals[i];
    }
    return sum;
  }

  /// Moltiplica due double convertendoli in Decimal per precisione
  static Decimal mulDoubles(double valueA, double valueB,
      {int scale = defaultScale}) {
    // Controlla se il risultato è nel pool
    final result = valueA * valueB;
    final resultStr = result.toStringAsFixed(scale);

    if (_decimalPool.containsKey(resultStr)) {
      return _decimalPool[resultStr]!;
    }

    final product =
        dFromDouble(valueA, scale: scale) * dFromDouble(valueB, scale: scale);
    // La moltiplicazione restituisce sempre Decimal
    return product;
  }

  /// Sottrae due double convertendoli in Decimal per precisione
  static Decimal subDoubles(double valueA, double valueB,
      {int scale = defaultScale}) {
    final result =
        dFromDouble(valueA, scale: scale) - dFromDouble(valueB, scale: scale);
    // La sottrazione restituisce sempre Decimal
    return result;
  }

  /// Divide due double convertendoli in Decimal per precisione
  static Decimal divDoubles(double valueA, double valueB,
      {int scale = defaultScale}) {
    if (valueB == 0) return Decimal.zero;

    // Controlla se il risultato è nel pool
    final result = valueA / valueB;
    final resultStr = result.toStringAsFixed(scale);

    if (_decimalPool.containsKey(resultStr)) {
      return _decimalPool[resultStr]!;
    }

    final rationalResult =
        dFromDouble(valueA, scale: scale) / dFromDouble(valueB, scale: scale);
    // La divisione restituisce sempre Rational, convertiamo in Decimal
    return (rationalResult).toDecimal(scaleOnInfinitePrecision: scale);
  }

  /// Calcola la media ponderata di una lista di coppie (valore, peso)
  /// Ottimizzato per evitare conversioni multiple
  static double weightedAverage(
    Iterable<MapEntry<double, double>> values, {
    int scale = defaultScale,
  }) {
    if (values.isEmpty) return 0.0;

    Decimal totalWeight = Decimal.zero;
    Decimal weightedSum = Decimal.zero;

    for (final entry in values) {
      final value = dFromDouble(entry.key, scale: scale);
      final weight = dFromDouble(entry.value, scale: scale);

      totalWeight += weight;
      final product = value * weight;
      // La moltiplicazione restituisce sempre Decimal
      weightedSum += product;
    }

    if (totalWeight == Decimal.zero) return 0.0;

    final result = weightedSum / totalWeight;
    // La divisione restituisce sempre Rational, convertiamo in Decimal
    return toDouble((result).toDecimal(scaleOnInfinitePrecision: scale));
  }

  /// Calcola la media semplice di una lista di double
  /// Ottimizzato per evitare conversioni multiple
  static double average(Iterable<double> values, {int scale = defaultScale}) {
    if (values.isEmpty) return 0.0;

    final sum = addDoubles(values, scale: scale);
    final count = Decimal.fromInt(values.length);

    final result = sum / count;
    // La divisione restituisce sempre Rational, convertiamo in Decimal
    return toDouble((result).toDecimal(scaleOnInfinitePrecision: scale));
  }

  /// Pulisce il pool di cache per liberare memoria
  static void clearCache() {
    _decimalPool.clear();
    _doubleToDecimalCache.clear();
  }

  /// Restituisce statistiche sulla cache per monitoring
  static Map<String, int> getCacheStats() {
    return {
      'decimalPoolSize': _decimalPool.length,
      'doubleToDecimalCacheSize': _doubleToDecimalCache.length,
    };
  }
}
