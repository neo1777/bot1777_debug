import 'package:test/test.dart';
import 'package:neotradingbotback1777/domain/services/trade_validation_service.dart';
import 'package:neotradingbotback1777/domain/entities/symbol_info.dart';

void main() {
  late TradeValidationService service;

  setUp(() {
    service = TradeValidationService();
  });

  // -----------------------------------------------------------------------
  // Helper to create SymbolInfo with typical Binance constraints
  // -----------------------------------------------------------------------
  SymbolInfo _limits({
    double minQty = 0.00001,
    double maxQty = 9000.0,
    double stepSize = 0.00001,
    double minNotional = 10.0,
  }) =>
      SymbolInfo(
        symbol: 'BTCUSDC',
        minQty: minQty,
        maxQty: maxQty,
        stepSize: stepSize,
        minNotional: minNotional,
      );

  // =========================================================================
  group('TradeValidationService', () {
    // -----------------------------------------------------------------------
    group('roundUpToStep', () {
      test('[TVS-001] should round up to next step increment', () {
        // ARRANGE — stepSize 0.001, quantity 0.1234 → ceil to 0.124
        final limits = _limits(stepSize: 0.001);

        // ACT
        final result = service.roundUpToStep(limits, 0.1234);

        // ASSERT
        expect(result, closeTo(0.124, 1e-10));
      });

      test('[TVS-002] should not change quantity already on step', () {
        // ARRANGE
        final limits = _limits(stepSize: 0.001);

        // ACT
        final result = service.roundUpToStep(limits, 0.123);

        // ASSERT
        expect(result, closeTo(0.123, 1e-10));
      });

      test('[TVS-003] should handle stepSize of 1.0 (whole units)', () {
        // ARRANGE — some altcoins require integer quantities
        final limits = _limits(stepSize: 1.0);

        // ACT
        final result = service.roundUpToStep(limits, 2.3);

        // ASSERT
        expect(result, equals(3.0));
      });

      test('[TVS-004] should handle stepSize of 0 (no constraint)', () {
        // ARRANGE
        final limits = _limits(stepSize: 0.0);

        // ACT
        final result = service.roundUpToStep(limits, 1.23456);

        // ASSERT — returns unchanged
        expect(result, equals(1.23456));
      });

      test('[TVS-005] should handle very small stepSize (satoshi level)', () {
        // ARRANGE — BTC minimum step
        final limits = _limits(stepSize: 0.00000001);

        // ACT
        final result = service.roundUpToStep(limits, 0.123456789);

        // ASSERT — ceil at satoshi level
        expect(result, closeTo(0.12345679, 1e-10));
      });

      test('[TVS-006] should handle zero quantity', () {
        // ARRANGE
        final limits = _limits(stepSize: 0.001);

        // ACT
        final result = service.roundUpToStep(limits, 0.0);

        // ASSERT
        expect(result, equals(0.0));
      });
    });

    // -----------------------------------------------------------------------
    group('validateAndFormatQuantity', () {
      group('validation checks', () {
        test('[TVS-007] should reject quantity below minQty', () {
          // ARRANGE
          final limits = _limits(minQty: 0.001);

          // ACT
          final result = service.validateAndFormatQuantity(limits, 0.0001);

          // ASSERT
          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) =>
                expect(failure.message, contains('inferiore al minimo')),
            (_) => fail('Expected Left'),
          );
        });

        test('[TVS-008] should reject quantity above maxQty', () {
          // ARRANGE
          final limits = _limits(maxQty: 100.0);

          // ACT
          final result = service.validateAndFormatQuantity(limits, 200.0);

          // ASSERT
          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) =>
                expect(failure.message, contains('superiore al massimo')),
            (_) => fail('Expected Left'),
          );
        });

        test('[TVS-009] should accept quantity at exact minQty', () {
          // ARRANGE
          final limits = _limits(minQty: 0.001, stepSize: 0.001);

          // ACT
          final result = service.validateAndFormatQuantity(limits, 0.001);

          // ASSERT
          expect(result.isRight(), isTrue);
          result.fold(
            (_) => fail('Expected Right'),
            (qty) => expect(qty, closeTo(0.001, 1e-10)),
          );
        });

        test('[TVS-010] should accept quantity at exact maxQty', () {
          // ARRANGE
          final limits = _limits(maxQty: 100.0, stepSize: 1.0);

          // ACT
          final result = service.validateAndFormatQuantity(limits, 100.0);

          // ASSERT
          expect(result.isRight(), isTrue);
        });
      });

      group('stepSize formatting — floor mode (default)', () {
        test('[TVS-011] should floor quantity to step size', () {
          // ARRANGE — step 0.01
          final limits = _limits(stepSize: 0.01);

          // ACT
          final result = service.validateAndFormatQuantity(limits, 1.2345);

          // ASSERT — floor(1.2345 * 100) / 100 = 1.23
          result.fold(
            (_) => fail('Expected Right'),
            (qty) => expect(qty, closeTo(1.23, 1e-10)),
          );
        });

        test('[TVS-012] should not round down when already on step', () {
          // ARRANGE
          final limits = _limits(stepSize: 0.01);

          // ACT
          final result = service.validateAndFormatQuantity(limits, 1.23);

          // ASSERT
          result.fold(
            (_) => fail('Expected Right'),
            (qty) => expect(qty, closeTo(1.23, 1e-10)),
          );
        });

        test('[TVS-013] should floor to step with stepSize 0.001', () {
          // ARRANGE
          final limits = _limits(stepSize: 0.001);

          // ACT
          final result = service.validateAndFormatQuantity(limits, 0.12349);

          // ASSERT — floor → 0.123
          result.fold(
            (_) => fail('Expected Right'),
            (qty) => expect(qty, closeTo(0.123, 1e-10)),
          );
        });
      });

      group('stepSize formatting — round mode (isFixedQuantity)', () {
        test('[TVS-014] should round quantity to nearest step', () {
          // ARRANGE — step 0.01
          final limits = _limits(stepSize: 0.01);

          // ACT
          final result = service.validateAndFormatQuantity(limits, 1.235,
              isFixedQuantity: true);

          // ASSERT — round(1.235 * 100) / 100 = 1.24 (rounds up)
          result.fold(
            (_) => fail('Expected Right'),
            (qty) => expect(qty, closeTo(1.24, 1e-10)),
          );
        });

        test('[TVS-015] should round down when closer to lower step', () {
          // ARRANGE — step 0.01
          final limits = _limits(stepSize: 0.01);

          // ACT
          final result = service.validateAndFormatQuantity(limits, 1.234,
              isFixedQuantity: true);

          // ASSERT — round(1.234 * 100) / 100 = 1.23
          result.fold(
            (_) => fail('Expected Right'),
            (qty) => expect(qty, closeTo(1.23, 1e-10)),
          );
        });
      });

      group('stepSize zero (no constraint)', () {
        test('[TVS-016] should return quantity unchanged with step 0', () {
          // ARRANGE
          final limits = _limits(stepSize: 0.0);

          // ACT
          final result = service.validateAndFormatQuantity(limits, 1.23456789);

          // ASSERT
          result.fold(
            (_) => fail('Expected Right'),
            (qty) => expect(qty, equals(1.23456789)),
          );
        });
      });

      group('real Binance symbol scenarios', () {
        test('[TVS-017] BTCUSDC: stepSize 0.00001, typical buy', () {
          // ARRANGE — real Binance BTC limits
          final limits = SymbolInfo(
            symbol: 'BTCUSDC',
            minQty: 0.00001,
            maxQty: 9000.0,
            stepSize: 0.00001,
            minNotional: 10.0,
          );

          // ACT — buying 0.001234567 BTC
          final result = service.validateAndFormatQuantity(limits, 0.001234567);

          // ASSERT — floor to 5 decimals → 0.00123
          result.fold(
            (_) => fail('Expected Right'),
            (qty) => expect(qty, closeTo(0.00123, 1e-10)),
          );
        });

        test('[TVS-018] ADAUSDC: stepSize 1.0, typical buy', () {
          // ARRANGE — ADA requires integer quantities
          final limits = SymbolInfo(
            symbol: 'ADAUSDC',
            minQty: 1.0,
            maxQty: 9000000.0,
            stepSize: 1.0,
            minNotional: 10.0,
          );

          // ACT — budget calculation gives 234.56 ADA
          final result = service.validateAndFormatQuantity(limits, 234.56);

          // ASSERT — floor → 234
          result.fold(
            (_) => fail('Expected Right'),
            (qty) => expect(qty, equals(234.0)),
          );
        });

        test('[TVS-019] ETHUSDC: stepSize 0.0001, fixed quantity', () {
          // ARRANGE
          final limits = SymbolInfo(
            symbol: 'ETHUSDC',
            minQty: 0.0001,
            maxQty: 9000.0,
            stepSize: 0.0001,
            minNotional: 10.0,
          );

          // ACT — user wants exactly 1.23456 ETH
          final result = service.validateAndFormatQuantity(limits, 1.23456,
              isFixedQuantity: true);

          // ASSERT — round to 4 decimals → 1.2346
          result.fold(
            (_) => fail('Expected Right'),
            (qty) => expect(qty, closeTo(1.2346, 1e-10)),
          );
        });
      });

      group('edge cases & security', () {
        test('[TVS-020] should reject negative quantity', () {
          // ARRANGE
          final limits = _limits(minQty: 0.001);

          // ACT
          final result = service.validateAndFormatQuantity(limits, -1.0);

          // ASSERT — negative < minQty → rejected
          expect(result.isLeft(), isTrue);
        });

        test('[TVS-021] should handle very large quantity within limits', () {
          // ARRANGE
          final limits = _limits(maxQty: 999999.0, stepSize: 0.01);

          // ACT
          final result = service.validateAndFormatQuantity(limits, 999999.0);

          // ASSERT
          expect(result.isRight(), isTrue);
        });

        test('[TVS-022] should handle quantity just above maxQty', () {
          // ARRANGE
          final limits = _limits(maxQty: 100.0);

          // ACT
          final result = service.validateAndFormatQuantity(limits, 100.00001);

          // ASSERT
          expect(result.isLeft(), isTrue);
        });

        test('[TVS-023] should maintain decimal precision after formatting',
            () {
          // ARRANGE — stepSize 0.00001 (5 decimals)
          final limits = _limits(stepSize: 0.00001);

          // ACT
          final result = service.validateAndFormatQuantity(limits, 0.123456789);

          // ASSERT — should have exactly 5 decimal places
          result.fold(
            (_) => fail('Expected Right'),
            (qty) {
              // Verify no floating point artifacts
              expect(qty, closeTo(0.12345, 1e-10));
            },
          );
        });
      });
    });
  });
  // =========================================================================
}

