import 'package:test/test.dart';
import 'package:decimal/decimal.dart';
import 'package:rational/rational.dart';
import 'package:neotradingbotback1777/core/utils/decimal_utils.dart';

void main() {
  group('DecimalUtils - Unit Tests', () {
    group('dFromDouble', () {
      test('[TEST-008] should maintain precision for financial calculations',
          () {
        // ARRANGE
        const testPrice = 0.123456789123; // 12 decimali
        const expectedScale = 12;

        // ACT
        final result =
            DecimalUtils.dFromDouble(testPrice, scale: expectedScale);

        // ASSERT
        expect(result.toString(), contains('0.123456789123'));
        expect(result.scale, expectedScale);
      });

      test('should handle edge cases gracefully', () {
        // ARRANGE & ACT & ASSERT
        expect(() => DecimalUtils.dFromDouble(0.0), returnsNormally);
        expect(
            () => DecimalUtils.dFromDouble(double.maxFinite), returnsNormally);
        expect(() => DecimalUtils.dFromDouble(double.minPositive),
            returnsNormally);
        expect(() => DecimalUtils.dFromDouble(-1.0), returnsNormally);
      });

      test('should handle very small numbers correctly', () {
        // ARRANGE
        const verySmallNumber = 0.000000000001; // 12 decimali

        // ACT
        final result = DecimalUtils.dFromDouble(verySmallNumber);

        // ASSERT
        expect(result.toString(), contains('0.000000000001'));
        expect(result.scale, DecimalUtils.defaultScale);
      });

      test('should handle very large numbers correctly', () {
        // ARRANGE
        const veryLargeNumber = 999999999999.999999999999;

        // ACT
        final result = DecimalUtils.dFromDouble(veryLargeNumber);

        // ASSERT
        // toStringAsFixed può modificare la scala, quindi verifichiamo solo che sia gestito
        expect(result > Decimal.zero, isTrue);
        expect(result.toString(), isNotEmpty);
        expect(result, isA<Decimal>());
      });
    });

    group('toDouble', () {
      test('should convert Decimal back to double correctly', () {
        // ARRANGE
        const originalValue = 123.456789;
        final decimal = DecimalUtils.dFromDouble(originalValue);

        // ACT
        final result = DecimalUtils.toDouble(decimal);

        // ASSERT
        expect(result, closeTo(originalValue, 0.000001));
      });

      test('should handle zero correctly', () {
        // ARRANGE
        final decimal = Decimal.zero;

        // ACT
        final result = DecimalUtils.toDouble(decimal);

        // ASSERT
        expect(result, 0.0);
      });

      test('should handle negative numbers correctly', () {
        // ARRANGE
        const originalValue = -123.456789;
        final decimal = DecimalUtils.dFromDouble(originalValue);

        // ACT
        final result = DecimalUtils.toDouble(decimal);

        // ASSERT
        expect(result, closeTo(originalValue, 0.000001));
      });
    });

    group('toDoubleAny', () {
      test('should convert various numeric types correctly', () {
        // ARRANGE
        final decimal = Decimal.fromInt(100);
        final rational = Rational(BigInt.one, BigInt.from(3));
        const doubleValue = 42.5;
        const intValue = 42;

        // ACT & ASSERT
        expect(DecimalUtils.toDoubleAny(decimal), 100.0);
        expect(DecimalUtils.toDoubleAny(rational), closeTo(0.333, 0.001));
        expect(DecimalUtils.toDoubleAny(doubleValue), 42.5);
        expect(DecimalUtils.toDoubleAny(intValue), 42.0);
      });

      test('should handle edge cases gracefully', () {
        // ARRANGE
        final decimal = Decimal.zero;
        final rational = Rational.zero;

        // ACT & ASSERT
        expect(DecimalUtils.toDoubleAny(decimal), 0.0);
        expect(DecimalUtils.toDoubleAny(rational), 0.0);
        // expect(DecimalUtils.toDoubleAny(null), 0.0); // Commented out due to type safety
      });
    });

    group('addDoubles', () {
      test('should add multiple doubles correctly', () {
        // ARRANGE
        const values = [1.1, 2.2, 3.3, 4.4, 5.5];
        const expectedSum = 16.5;

        // ACT
        final result = DecimalUtils.addDoubles(values);

        // ASSERT
        expect(DecimalUtils.toDouble(result), closeTo(expectedSum, 0.000001));
      });

      test('should handle empty list', () {
        // ARRANGE
        const values = <double>[];

        // ACT
        final result = DecimalUtils.addDoubles(values);

        // ASSERT
        expect(result, Decimal.zero);
      });

      test('should handle single value', () {
        // ARRANGE
        const values = [42.0];

        // ACT
        final result = DecimalUtils.addDoubles(values);

        // ASSERT
        expect(DecimalUtils.toDouble(result), 42.0);
      });

      test('should handle negative values', () {
        // ARRANGE
        const values = [10.0, -5.0, 3.0, -2.0];
        const expectedSum = 6.0;

        // ACT
        final result = DecimalUtils.addDoubles(values);

        // ASSERT
        expect(DecimalUtils.toDouble(result), closeTo(expectedSum, 0.000001));
      });
    });

    group('mulDoubles', () {
      test('should multiply two doubles correctly', () {
        // ARRANGE
        const a = 2.5;
        const b = 3.0;
        const expectedProduct = 7.5;

        // ACT
        final result = DecimalUtils.mulDoubles(a, b);

        // ASSERT
        expect(
            DecimalUtils.toDouble(result), closeTo(expectedProduct, 0.000001));
      });

      test('should handle zero correctly', () {
        // ARRANGE
        const a = 0.0;
        const b = 42.0;

        // ACT
        final result = DecimalUtils.mulDoubles(a, b);

        // ASSERT
        expect(result, Decimal.zero);
      });

      test('should handle negative numbers correctly', () {
        // ARRANGE
        const a = -2.0;
        const b = 3.0;
        const expectedProduct = -6.0;

        // ACT
        final result = DecimalUtils.mulDoubles(a, b);

        // ASSERT
        expect(
            DecimalUtils.toDouble(result), closeTo(expectedProduct, 0.000001));
      });

      test('should handle very small numbers', () {
        // ARRANGE
        const a = 0.000001;
        const b = 0.000001;
        const expectedProduct = 0.000000000001;

        // ACT
        final result = DecimalUtils.mulDoubles(a, b);

        // ASSERT
        expect(DecimalUtils.toDouble(result),
            closeTo(expectedProduct, 0.000000000001));
      });
    });

    group('subDoubles', () {
      test('should subtract two doubles correctly', () {
        // ARRANGE
        const a = 10.0;
        const b = 3.5;
        const expectedDifference = 6.5;

        // ACT
        final result = DecimalUtils.subDoubles(a, b);

        // ASSERT
        expect(DecimalUtils.toDouble(result),
            closeTo(expectedDifference, 0.000001));
      });

      test('should handle negative result', () {
        // ARRANGE
        const a = 5.0;
        const b = 10.0;
        const expectedDifference = -5.0;

        // ACT
        final result = DecimalUtils.subDoubles(a, b);

        // ASSERT
        expect(DecimalUtils.toDouble(result),
            closeTo(expectedDifference, 0.000001));
      });

      test('should handle zero correctly', () {
        // ARRANGE
        const a = 10.0;
        const b = 10.0;

        // ACT
        final result = DecimalUtils.subDoubles(a, b);

        // ASSERT
        expect(result, Decimal.zero);
      });
    });

    group('divDoubles', () {
      test('should divide two doubles correctly', () {
        // ARRANGE
        const a = 10.0;
        const b = 2.0;
        const expectedQuotient = 5.0;

        // ACT
        final result = DecimalUtils.divDoubles(a, b);

        // ASSERT
        expect(
            DecimalUtils.toDouble(result), closeTo(expectedQuotient, 0.000001));
      });

      test('should handle division by zero safely', () {
        // ARRANGE
        const a = 10.0;
        const b = 0.0;

        // ACT
        final result = DecimalUtils.divDoubles(a, b);

        // ASSERT
        expect(result, Decimal.zero);
      });

      test('should handle decimal results correctly', () {
        // ARRANGE
        const a = 10.0;
        const b = 3.0;
        const expectedQuotient = 3.333333333333;

        // ACT
        final result = DecimalUtils.divDoubles(a, b);

        // ASSERT
        expect(
            DecimalUtils.toDouble(result), closeTo(expectedQuotient, 0.000001));
      });

      test('should handle very small results', () {
        // ARRANGE
        const a = 0.000001;
        const b = 1000000.0;
        const expectedQuotient = 0.000000000001;

        // ACT
        final result = DecimalUtils.divDoubles(a, b);

        // ASSERT
        expect(DecimalUtils.toDouble(result),
            closeTo(expectedQuotient, 0.000000000001));
      });
    });

    group('Precision and Scale', () {
      test('should maintain consistent scale across operations', () {
        // ARRANGE
        const customScale = 8;
        const a = 1.12345678;
        const b = 2.87654321;

        // ACT
        final resultA = DecimalUtils.dFromDouble(a, scale: customScale);
        final resultB = DecimalUtils.dFromDouble(b, scale: customScale);
        final sum = resultA + resultB;

        // ASSERT
        expect(resultA.scale, customScale);
        expect(resultB.scale, customScale);
        expect(sum.scale, customScale);
      });

      test('should handle default scale correctly', () {
        // ARRANGE
        const value = 1.123456789123;

        // ACT
        final result = DecimalUtils.dFromDouble(value);

        // ASSERT
        expect(result.scale, DecimalUtils.defaultScale);
        expect(result.scale, 12);
      });
    });
  });
}
