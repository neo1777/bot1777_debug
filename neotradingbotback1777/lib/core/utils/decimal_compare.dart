import 'package:decimal/decimal.dart';
import 'package:rational/rational.dart';
import 'package:neotradingbotback1777/core/utils/decimal_utils.dart';

/// Helper centralizzati per confronti robusti basati su Decimal.
///
/// Regola: convertiamo i doppi ai confini in Decimal tramite stringa
/// (vedi DecimalUtils.dFromDouble) e poi usiamo compareTo.
class DecimalCompare {
  /// Confronta due double come Decimal con la scala specificata.
  /// Ritorna: -1 se valueA < valueB, 0 se valueA==valueB, 1 se valueA>valueB
  static int cmpDoubles(double valueA, double valueB,
      {int scale = DecimalUtils.defaultScale}) {
    final dValueA = DecimalUtils.dFromDouble(valueA, scale: scale);
    final dValueB = DecimalUtils.dFromDouble(valueB, scale: scale);
    return dValueA.compareTo(dValueB);
  }

  static bool ltDoubles(double valueA, double valueB,
          {int scale = DecimalUtils.defaultScale}) =>
      cmpDoubles(valueA, valueB, scale: scale) < 0;

  static bool lteDoubles(double valueA, double valueB,
          {int scale = DecimalUtils.defaultScale}) =>
      cmpDoubles(valueA, valueB, scale: scale) <= 0;

  static bool gtDoubles(double valueA, double valueB,
          {int scale = DecimalUtils.defaultScale}) =>
      cmpDoubles(valueA, valueB, scale: scale) > 0;

  static bool gteDoubles(double valueA, double valueB,
          {int scale = DecimalUtils.defaultScale}) =>
      cmpDoubles(valueA, valueB, scale: scale) >= 0;

  /// Percentuale (valueA-valueB)/valueB*100 calcolata con Decimal, restituita come Decimal.
  static Decimal percentChange(double valueA, double valueB,
      {int scale = DecimalUtils.defaultScale}) {
    final dValueA = DecimalUtils.dFromDouble(valueA, scale: scale);
    final dValueB = DecimalUtils.dFromDouble(valueB, scale: scale);
    if (dValueB == Decimal.zero) return Decimal.zero;
    final dynamic rawRatio = (dValueA - dValueB) / dValueB;
    final Decimal ratioDecimal = rawRatio is Decimal
        ? rawRatio
        : (rawRatio as Rational).toDecimal(scaleOnInfinitePrecision: scale);
    return ratioDecimal * Decimal.fromInt(100);
  }

  /// Ritorna true se (ref - cur)/ref*100 >= thresholdPct (tutto in Decimal)
  static bool percentDecrementReached({
    required double current,
    required double reference,
    required double thresholdPct,
    int scale = DecimalUtils.defaultScale,
  }) {
    final dRef = DecimalUtils.dFromDouble(reference, scale: scale);
    final dCur = DecimalUtils.dFromDouble(current, scale: scale);
    final dTh = DecimalUtils.dFromDouble(thresholdPct, scale: scale);
    if (dRef <= Decimal.zero) return false;
    final dynamic ratio = (dRef - dCur) / dRef;
    final Decimal decRatioDec = ratio is Decimal
        ? ratio
        : (ratio as Rational).toDecimal(scaleOnInfinitePrecision: scale);
    final Decimal decPct = decRatioDec * Decimal.fromInt(100);
    return decPct.compareTo(dTh) >= 0 && dTh > Decimal.zero;
  }
}
