import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:neotradingbotback1777/core/utils/decimal_utils.dart';
import 'package:rational/rational.dart';

class MoneyAmount extends Equatable implements Comparable<MoneyAmount> {
  final Decimal value;
  const MoneyAmount._(this.value);

  factory MoneyAmount.fromDecimal(Decimal d) => MoneyAmount._(d);
  factory MoneyAmount.fromDouble(double v,
          {int scale = DecimalUtils.defaultScale}) =>
      MoneyAmount._(DecimalUtils.dFromDouble(v, scale: scale));

  double toDouble() => DecimalUtils.toDouble(value);
  MoneyAmount operator +(MoneyAmount other) =>
      MoneyAmount._(value + other.value);
  MoneyAmount operator -(MoneyAmount other) =>
      MoneyAmount._(value - other.value);
  MoneyAmount operator *(Decimal factor) => MoneyAmount._(value * factor);
  @override
  int compareTo(MoneyAmount other) => value.compareTo(other.value);
  @override
  List<Object?> get props => [value];
  @override
  String toString() => value.toString();
}

class QuantityAmount extends Equatable implements Comparable<QuantityAmount> {
  final Decimal value;
  const QuantityAmount._(this.value);

  factory QuantityAmount.fromDecimal(Decimal d) => QuantityAmount._(d);
  factory QuantityAmount.fromDouble(double v,
          {int scale = DecimalUtils.defaultScale}) =>
      QuantityAmount._(DecimalUtils.dFromDouble(v, scale: scale));

  double toDouble() => DecimalUtils.toDouble(value);
  QuantityAmount operator +(QuantityAmount other) =>
      QuantityAmount._(value + other.value);
  QuantityAmount operator -(QuantityAmount other) =>
      QuantityAmount._(value - other.value);
  @override
  int compareTo(QuantityAmount other) => value.compareTo(other.value);
  @override
  List<Object?> get props => [value];
  @override
  String toString() => value.toString();
}

class PercentRate extends Equatable implements Comparable<PercentRate> {
  final Decimal value; // espressa in percento, es. 1.5 = 1.5%
  const PercentRate._(this.value);

  factory PercentRate.fromDecimal(Decimal d) => PercentRate._(d);
  factory PercentRate.fromDouble(double v,
          {int scale = DecimalUtils.defaultScale}) =>
      PercentRate._(DecimalUtils.dFromDouble(v, scale: scale));

  double toDouble() => DecimalUtils.toDouble(value);
  Decimal asUnitFraction() {
    final dynamic ratio = value / Decimal.fromInt(100);
    if (ratio is Decimal) return ratio;
    return (ratio as Rational)
        .toDecimal(scaleOnInfinitePrecision: DecimalUtils.defaultScale);
  }

  @override
  int compareTo(PercentRate other) => value.compareTo(other.value);
  @override
  List<Object?> get props => [value];
  @override
  String toString() => value.toString();
}
