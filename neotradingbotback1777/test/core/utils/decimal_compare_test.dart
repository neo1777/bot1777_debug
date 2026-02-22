import 'package:test/test.dart';
import 'package:decimal/decimal.dart';
import 'package:neotradingbotback1777/core/utils/decimal_compare.dart';

void main() {
  group('DecimalCompare - Unit Tests', () {
    group('cmpDoubles', () {
      test('should compare two doubles correctly', () {
        // ARRANGE
        const a = 100.0;
        const b = 50.0;

        // ACT & ASSERT
        expect(DecimalCompare.cmpDoubles(a, b) > 0, isTrue); // a > b
        expect(DecimalCompare.cmpDoubles(b, a) < 0, isTrue); // b < a
        expect(DecimalCompare.cmpDoubles(a, a) == 0, isTrue); // a == a
      });

      test('should handle equal values', () {
        // ARRANGE
        const a = 42.0;
        const b = 42.0;

        // ACT & ASSERT
        expect(DecimalCompare.cmpDoubles(a, b), 0);
      });

      test('should handle negative values', () {
        // ARRANGE
        const a = -10.0;
        const b = 10.0;

        // ACT & ASSERT
        expect(DecimalCompare.cmpDoubles(a, b), lessThan(0));
        expect(DecimalCompare.cmpDoubles(b, a), greaterThan(0));
      });

      test('should handle zero correctly', () {
        // ARRANGE
        const a = 0.0;
        const b = 100.0;

        // ACT & ASSERT
        expect(DecimalCompare.cmpDoubles(a, b), lessThan(0));
        expect(DecimalCompare.cmpDoubles(b, a), greaterThan(0));
        expect(DecimalCompare.cmpDoubles(a, a), 0);
      });
    });

    group('Comparison Operators', () {
      test('should provide correct less than comparison', () {
        // ARRANGE
        const a = 50.0;
        const b = 100.0;

        // ACT & ASSERT
        expect(DecimalCompare.ltDoubles(a, b), isTrue);
        expect(DecimalCompare.ltDoubles(b, a), isFalse);
        expect(DecimalCompare.ltDoubles(a, a), isFalse);
      });

      test('should provide correct less than or equal comparison', () {
        // ARRANGE
        const a = 50.0;
        const b = 100.0;

        // ACT & ASSERT
        expect(DecimalCompare.lteDoubles(a, b), isTrue);
        expect(DecimalCompare.lteDoubles(b, a), isFalse);
        expect(DecimalCompare.lteDoubles(a, a), isTrue);
      });

      test('should provide correct greater than comparison', () {
        // ARRANGE
        const a = 100.0;
        const b = 50.0;

        // ACT & ASSERT
        expect(DecimalCompare.gtDoubles(a, b), isTrue);
        expect(DecimalCompare.gtDoubles(b, a), isFalse);
        expect(DecimalCompare.gtDoubles(a, a), isFalse);
      });

      test('should provide correct greater than or equal comparison', () {
        // ARRANGE
        const a = 100.0;
        const b = 50.0;

        // ACT & ASSERT
        expect(DecimalCompare.gteDoubles(a, b), isTrue);
        expect(DecimalCompare.gteDoubles(b, a), isFalse);
        expect(DecimalCompare.gteDoubles(a, a), isTrue);
      });
    });

    group('percentChange', () {
      test('[TEST-005] should calculate percentage change correctly', () {
        // ARRANGE
        const newValue = 110.0;
        const oldValue = 100.0;
// +10%

        // ACT
        final result = DecimalCompare.percentChange(newValue, oldValue);

        // ASSERT
        expect(result.toString(), contains('10'));
        expect(result > Decimal.zero, isTrue);
      });

      test('should calculate negative percentage change correctly', () {
        // ARRANGE
        const newValue = 90.0;
        const oldValue = 100.0;
// -10%

        // ACT
        final result = DecimalCompare.percentChange(newValue, oldValue);

        // ASSERT
        expect(result.toString(), contains('-10'));
        expect(result < Decimal.zero, isTrue);
      });

      test('should handle zero old value safely', () {
        // ARRANGE
        const newValue = 110.0;
        const oldValue = 0.0;

        // ACT
        final result = DecimalCompare.percentChange(newValue, oldValue);

        // ASSERT
        expect(result, Decimal.zero);
      });

      test('should handle equal values correctly', () {
        // ARRANGE
        const newValue = 100.0;
        const oldValue = 100.0;

        // ACT
        final result = DecimalCompare.percentChange(newValue, oldValue);

        // ASSERT
        expect(result, Decimal.zero);
      });

      test('should handle very small changes accurately', () {
        // ARRANGE
        const newValue = 100.001;
        const oldValue = 100.0;
// +0.001%

        // ACT
        final result = DecimalCompare.percentChange(newValue, oldValue);

        // ASSERT
        expect(result.toString(), contains('0.001'));
        expect(result > Decimal.zero, isTrue);
      });

      test('should handle very large changes accurately', () {
        // ARRANGE
        const newValue = 200.0;
        const oldValue = 100.0;
// +100%

        // ACT
        final result = DecimalCompare.percentChange(newValue, oldValue);

        // ASSERT
        expect(result.toString(), contains('100'));
        expect(result > Decimal.zero, isTrue);
      });
    });

    group('percentDecrementReached', () {
      test('[TEST-005] should return true when percentage decrement is reached',
          () {
        // ARRANGE
        const current = 95.0;
        const reference = 100.0;
        const thresholdPct = 5.0;

        // ACT
        final result = DecimalCompare.percentDecrementReached(
          current: current,
          reference: reference,
          thresholdPct: thresholdPct,
        );

        // ASSERT
        expect(result, isTrue);
        // Verifica: (100-95)/100*100 = 5.0% >= 5.0%
      });

      test('should return true when decrement is exactly at threshold', () {
        // ARRANGE
        const current = 90.0;
        const reference = 100.0;
        const thresholdPct = 10.0;

        // ACT
        final result = DecimalCompare.percentDecrementReached(
          current: current,
          reference: reference,
          thresholdPct: thresholdPct,
        );

        // ASSERT
        expect(result, isTrue);
        // Verifica: (100-90)/100*100 = 10.0% >= 10.0%
      });

      test('should return false when decrement is below threshold', () {
        // ARRANGE
        const current = 91.0;
        const reference = 100.0;
        const thresholdPct = 10.0;

        // ACT
        final result = DecimalCompare.percentDecrementReached(
          current: current,
          reference: reference,
          thresholdPct: thresholdPct,
        );

        // ASSERT
        expect(result, isFalse);
        // Verifica: (100-91)/100*100 = 9.0% < 10.0%
      });

      test('should handle zero reference price safely', () {
        // ARRANGE
        const current = 50.0;
        const reference = 0.0;
        const thresholdPct = 10.0;

        // ACT
        final result = DecimalCompare.percentDecrementReached(
          current: current,
          reference: reference,
          thresholdPct: thresholdPct,
        );

        // ASSERT
        expect(result, isFalse);
      });

      test('should handle negative threshold correctly', () {
        // ARRANGE
        const current = 98.0;
        const reference = 100.0;
        const thresholdPct = -1.0; // Negativo

        // ACT
        final result = DecimalCompare.percentDecrementReached(
          current: current,
          reference: reference,
          thresholdPct: thresholdPct,
        );

        // ASSERT
        expect(result, isFalse);
      });

      test('should handle zero threshold correctly', () {
        // ARRANGE
        const current = 99.0;
        const reference = 100.0;
        const thresholdPct = 0.0;

        // ACT
        final result = DecimalCompare.percentDecrementReached(
          current: current,
          reference: reference,
          thresholdPct: thresholdPct,
        );

        // ASSERT
        expect(result, isFalse);
      });

      test('should handle very small decrements accurately', () {
        // ARRANGE
        const current = 99.95;
        const reference = 100.0;
        const thresholdPct = 0.05; // 0.05%

        // ACT
        final result = DecimalCompare.percentDecrementReached(
          current: current,
          reference: reference,
          thresholdPct: thresholdPct,
        );

        // ASSERT
        expect(result, isTrue);
        // Verifica: (100-99.95)/100*100 = 0.05% >= 0.05%
      });

      test('should handle very large decrements accurately', () {
        // ARRANGE
        const current = 50.0;
        const reference = 100.0;
        const thresholdPct = 50.0; // 50%

        // ACT
        final result = DecimalCompare.percentDecrementReached(
          current: current,
          reference: reference,
          thresholdPct: thresholdPct,
        );

        // ASSERT
        expect(result, isTrue);
        // Verifica: (100-50)/100*100 = 50% >= 50%
      });

      test('should handle current price higher than reference', () {
        // ARRANGE
        const current = 110.0;
        const reference = 100.0;
        const thresholdPct = 5.0;

        // ACT
        final result = DecimalCompare.percentDecrementReached(
          current: current,
          reference: reference,
          thresholdPct: thresholdPct,
        );

        // ASSERT
        expect(result, isFalse);
        // Verifica: (100-110)/100*100 = -10% < 5.0%
      });
    });

    group('Edge Cases and Precision', () {
      test('should maintain precision with custom scale', () {
        // ARRANGE
        const customScale = 8;
        const current = 99.99999999;
        const reference = 100.0;
        const thresholdPct = 0.00000001;

        // ACT
        final result = DecimalCompare.percentDecrementReached(
          current: current,
          reference: reference,
          thresholdPct: thresholdPct,
          scale: customScale,
        );

        // ASSERT
        expect(result, isTrue);
      });

      test('should handle extreme values correctly', () {
        // ARRANGE
        const current = 0.000000000001;
        const reference = 1000000000000.0;
        const thresholdPct = 99.999999999999;

        // ACT
        final result = DecimalCompare.percentDecrementReached(
          current: current,
          reference: reference,
          thresholdPct: thresholdPct,
        );

        // ASSERT
        expect(result, isTrue);
      });

      test('should provide consistent results across multiple calls', () {
        // ARRANGE
        const current = 95.0;
        const reference = 100.0;
        const thresholdPct = 5.0;

        // ACT
        final result1 = DecimalCompare.percentDecrementReached(
          current: current,
          reference: reference,
          thresholdPct: thresholdPct,
        );
        final result2 = DecimalCompare.percentDecrementReached(
          current: current,
          reference: reference,
          thresholdPct: thresholdPct,
        );
        final result3 = DecimalCompare.percentDecrementReached(
          current: current,
          reference: reference,
          thresholdPct: thresholdPct,
        );

        // ASSERT
        expect(result1, equals(result2));
        expect(result2, equals(result3));
        expect(result1, isTrue);
      });
    });
  });
}

