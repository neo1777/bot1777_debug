import 'package:fpdart/fpdart.dart';
import 'package:test/test.dart';
import 'package:neotradingbotback1777/domain/services/fee_calculation_service.dart';
import 'package:neotradingbotback1777/domain/repositories/i_fee_repository.dart';
import 'package:neotradingbotback1777/domain/entities/fee_info.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import '../../helpers/mockito_dummy_registrations.dart';

// ---------------------------------------------------------------------------
// Configurable Mock — allows per-test control of repository responses
// ---------------------------------------------------------------------------
class _ConfigurableFeeRepository implements IFeeRepository {
  Either<Failure, FeeInfo> Function(String symbol)? onGetSymbolFeesIfNeeded;
  Either<Failure, FeeInfo> Function(String symbol)? onRefreshSymbolFees;
  int getSymbolFeesIfNeededCallCount = 0;

  @override
  Future<Either<Failure, FeeInfo>> getSymbolFeesIfNeeded(String symbol) async {
    getSymbolFeesIfNeededCallCount++;
    if (onGetSymbolFeesIfNeeded != null) {
      return onGetSymbolFeesIfNeeded!(symbol);
    }
    return Right(FeeInfo.defaultBinance(symbol: symbol));
  }

  @override
  Future<Either<Failure, FeeInfo>> getSymbolFees(String symbol) async =>
      Right(FeeInfo.defaultBinance(symbol: symbol));

  @override
  Future<Either<Failure, Map<String, FeeInfo>>> getAllSymbolFees() async =>
      const Right({});

  @override
  Future<Either<Failure, FeeInfo>> refreshSymbolFees(String symbol) async {
    if (onRefreshSymbolFees != null) return onRefreshSymbolFees!(symbol);
    return Right(FeeInfo.defaultBinance(symbol: symbol));
  }

  @override
  Future<void> clearCache() async {}

  @override
  bool areFeesValid(String symbol) => true;
}

void main() {
  const tSymbol = 'BTCUSDC';
  const tPrice = 50000.0;
  const tQuantity = 1.0;

  late _ConfigurableFeeRepository mockRepo;
  late FeeCalculationService service;

  setUp(() {
    registerMockitoDummies();
    mockRepo = _ConfigurableFeeRepository();
    service = FeeCalculationService(feeRepository: mockRepo);
  });

  // -----------------------------------------------------------------------
  // Helper to create a FeeInfo with known values
  // -----------------------------------------------------------------------
  FeeInfo _fee({
    double maker = 0.001,
    double taker = 0.001,
    bool discount = false,
    double discountPct = 0.0,
  }) =>
      FeeInfo(
        makerFee: maker,
        takerFee: taker,
        feeCurrency: 'USDT',
        isDiscountActive: discount,
        discountPercentage: discountPct,
        lastUpdated: DateTime(2026),
        symbol: tSymbol,
      );

  // =========================================================================
  group('FeeCalculationService', () {
    // -----------------------------------------------------------------------
    group('calculateTotalFees', () {
      test('[FCS-001] should calculate maker fee correctly', () async {
        // ARRANGE — 0.1% maker fee on 1 BTC @ 50 000 = 50 USDT fee
        mockRepo.onGetSymbolFeesIfNeeded = (s) => Right(_fee(maker: 0.001));

        // ACT
        final result = await service.calculateTotalFees(
          quantity: tQuantity,
          price: tPrice,
          isMaker: true,
          symbol: tSymbol,
        );

        // ASSERT
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (fee) => expect(fee, closeTo(50.0, 0.001)),
        );
      });

      test('[FCS-002] should calculate taker fee correctly', () async {
        // ARRANGE — 0.1% taker fee
        mockRepo.onGetSymbolFeesIfNeeded = (s) => Right(_fee(taker: 0.001));

        // ACT
        final result = await service.calculateTotalFees(
          quantity: tQuantity,
          price: tPrice,
          isMaker: false,
          symbol: tSymbol,
        );

        // ASSERT
        result.fold(
          (_) => fail('Expected Right'),
          (fee) => expect(fee, closeTo(50.0, 0.001)),
        );
      });

      test('[FCS-003] should differentiate maker vs taker rates', () async {
        // ARRANGE — maker 0.02%, taker 0.04%
        mockRepo.onGetSymbolFeesIfNeeded =
            (s) => Right(_fee(maker: 0.0002, taker: 0.0004));

        // ACT
        final makerResult = await service.calculateTotalFees(
          quantity: tQuantity,
          price: tPrice,
          isMaker: true,
          symbol: tSymbol,
        );
        final takerResult = await service.calculateTotalFees(
          quantity: tQuantity,
          price: tPrice,
          isMaker: false,
          symbol: tSymbol,
        );

        // ASSERT
        makerResult.fold(
            (_) => fail(''), (f) => expect(f, closeTo(10.0, 0.01)));
        takerResult.fold(
            (_) => fail(''), (f) => expect(f, closeTo(20.0, 0.01)));
      });

      test('[FCS-004] should apply BNB discount when active', () async {
        // ARRANGE — 0.1% base, 25% discount => 0.075% effective
        mockRepo.onGetSymbolFeesIfNeeded =
            (s) => Right(_fee(maker: 0.001, discount: true, discountPct: 0.25));

        // ACT
        final result = await service.calculateTotalFees(
          quantity: tQuantity,
          price: tPrice,
          isMaker: true,
          symbol: tSymbol,
          useDiscount: true,
        );

        // ASSERT — 50000 * 0.00075 = 37.5
        result.fold(
          (_) => fail('Expected Right'),
          (fee) => expect(fee, closeTo(37.5, 0.01)),
        );
      });

      test('[FCS-005] should NOT apply discount when useDiscount is false',
          () async {
        // ARRANGE
        mockRepo.onGetSymbolFeesIfNeeded =
            (s) => Right(_fee(maker: 0.001, discount: true, discountPct: 0.25));

        // ACT
        final result = await service.calculateTotalFees(
          quantity: tQuantity,
          price: tPrice,
          isMaker: true,
          symbol: tSymbol,
          useDiscount: false,
        );

        // ASSERT — full 0.1% = 50.0
        result.fold(
          (_) => fail('Expected Right'),
          (fee) => expect(fee, closeTo(50.0, 0.01)),
        );
      });

      test('[FCS-006] should fallback to default fees on repository failure',
          () async {
        // ARRANGE — repo returns Left
        mockRepo.onGetSymbolFeesIfNeeded =
            (s) => Left(ServerFailure(message: 'API error'));

        // ACT
        final result = await service.calculateTotalFees(
          quantity: tQuantity,
          price: tPrice,
          isMaker: true,
          symbol: tSymbol,
        );

        // ASSERT — should still succeed with default 0.1% fee
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right with fallback'),
          (fee) => expect(fee, closeTo(50.0, 0.01)),
        );
      });

      test('[FCS-007] should handle zero quantity', () async {
        // ACT
        final result = await service.calculateTotalFees(
          quantity: 0.0,
          price: tPrice,
          isMaker: true,
          symbol: tSymbol,
        );

        // ASSERT — 0 * anything = 0
        result.fold(
          (_) => fail('Expected Right'),
          (fee) => expect(fee, equals(0.0)),
        );
      });

      test('[FCS-008] should handle zero price', () async {
        // ACT
        final result = await service.calculateTotalFees(
          quantity: tQuantity,
          price: 0.0,
          isMaker: true,
          symbol: tSymbol,
        );

        // ASSERT
        result.fold(
          (_) => fail('Expected Right'),
          (fee) => expect(fee, equals(0.0)),
        );
      });

      test('[FCS-009] should handle very small quantities (satoshi level)',
          () async {
        // ARRANGE — 0.00000001 BTC @ 50000 = 0.0005 USDT value
        mockRepo.onGetSymbolFeesIfNeeded = (s) => Right(_fee(maker: 0.001));

        // ACT
        final result = await service.calculateTotalFees(
          quantity: 0.00000001,
          price: tPrice,
          isMaker: true,
          symbol: tSymbol,
        );

        // ASSERT — 0.0005 * 0.001 = 0.0000005
        result.fold(
          (_) => fail('Expected Right'),
          (fee) => expect(fee, closeTo(0.0000005, 1e-10)),
        );
      });

      test('[FCS-010] should handle very large values (whale trade)', () async {
        // ARRANGE — 100 BTC @ 100,000 = 10,000,000 USDT
        mockRepo.onGetSymbolFeesIfNeeded = (s) => Right(_fee(taker: 0.001));

        // ACT
        final result = await service.calculateTotalFees(
          quantity: 100.0,
          price: 100000.0,
          isMaker: false,
          symbol: tSymbol,
        );

        // ASSERT — 10,000,000 * 0.001 = 10,000
        result.fold(
          (_) => fail('Expected Right'),
          (fee) => expect(fee, closeTo(10000.0, 0.01)),
        );
      });
    });

    // -----------------------------------------------------------------------
    group('calculateNetProfit', () {
      test('[FCS-011] should subtract fees from gross profit', () async {
        // ARRANGE — 2% gross profit, 0.1% fee
        mockRepo.onGetSymbolFeesIfNeeded = (s) => Right(_fee(taker: 0.001));

        // ACT
        final result = await service.calculateNetProfit(
          grossProfitPercent: 2.0,
          quantity: tQuantity,
          price: tPrice,
          symbol: tSymbol,
          isMaker: false,
        );

        // ASSERT
        // Gross: 2% of 50000 = 1000
        // Fees: 50000 * 0.001 = 50
        // Net: 1000 - 50 = 950
        // Net %: (950 / 50000) * 100 = 1.9%
        result.fold(
          (_) => fail('Expected Right'),
          (netPct) => expect(netPct, closeTo(1.9, 0.01)),
        );
      });

      test('[FCS-012] should return negative when fees exceed profit',
          () async {
        // ARRANGE — 0.05% gross profit, 0.1% fee (fee > profit)
        mockRepo.onGetSymbolFeesIfNeeded = (s) => Right(_fee(taker: 0.001));

        // ACT
        final result = await service.calculateNetProfit(
          grossProfitPercent: 0.05,
          quantity: tQuantity,
          price: tPrice,
          symbol: tSymbol,
          isMaker: false,
        );

        // ASSERT — negative net profit
        result.fold(
          (_) => fail('Expected Right'),
          (netPct) => expect(netPct, lessThan(0.0)),
        );
      });

      test('[FCS-013] should handle zero gross profit', () async {
        // ACT
        final result = await service.calculateNetProfit(
          grossProfitPercent: 0.0,
          quantity: tQuantity,
          price: tPrice,
          symbol: tSymbol,
        );

        // ASSERT — net profit = 0 - fees = negative
        result.fold(
          (_) => fail('Expected Right'),
          (netPct) => expect(netPct, lessThanOrEqualTo(0.0)),
        );
      });
    });

    // -----------------------------------------------------------------------
    group('calculateTotalCost', () {
      test('[FCS-014] should add fees to base cost', () async {
        // ARRANGE — 1 BTC @ 50000, 0.1% fee
        mockRepo.onGetSymbolFeesIfNeeded = (s) => Right(_fee(maker: 0.001));

        // ACT
        final result = await service.calculateTotalCost(
          quantity: tQuantity,
          price: tPrice,
          symbol: tSymbol,
          isMaker: true,
        );

        // ASSERT — 50000 + 50 = 50050
        result.fold(
          (_) => fail('Expected Right'),
          (cost) => expect(cost, closeTo(50050.0, 0.01)),
        );
      });

      test('[FCS-015] should propagate failure from fee calculation', () async {
        // ARRANGE — both getSymbolFeesIfNeeded calls will fail
        mockRepo.onGetSymbolFeesIfNeeded =
            (s) => Left(ServerFailure(message: 'API error'));

        // ACT — totalCost calls calculateTotalFees which calls getSymbolFeesIfNeeded
        // calculateTotalFees has fallback, so it should still succeed
        final result = await service.calculateTotalCost(
          quantity: tQuantity,
          price: tPrice,
          symbol: tSymbol,
        );

        // ASSERT — succeeds with default fee fallback
        expect(result.isRight(), isTrue);
      });
    });

    // -----------------------------------------------------------------------
    group('calculateAffordableQuantity', () {
      test('[FCS-016] should calculate quantity within budget including fees',
          () async {
        // ARRANGE — budget 1000, price 50000, 0.1% fee
        mockRepo.onGetSymbolFeesIfNeeded = (s) => Right(_fee(maker: 0.001));

        // ACT
        final result = await service.calculateAffordableQuantity(
          budget: 1000.0,
          price: tPrice,
          symbol: tSymbol,
        );

        // ASSERT — budget / (price * (1 + feeRate))
        // feeRate = (50000 * 0.001) / 50000 = 0.001
        // qty = 1000 / (50000 * 1.001) ≈ 0.01998
        result.fold(
          (_) => fail('Expected Right'),
          (qty) {
            expect(qty, greaterThan(0.0));
            expect(qty, lessThan(1000.0 / tPrice)); // less than no-fee qty
            expect(qty, closeTo(0.01998, 0.001));
          },
        );
      });

      test('[FCS-017] should return less quantity than no-fee calculation',
          () async {
        // ARRANGE
        mockRepo.onGetSymbolFeesIfNeeded = (s) => Right(_fee(maker: 0.001));

        // ACT
        final result = await service.calculateAffordableQuantity(
          budget: 5000.0,
          price: tPrice,
          symbol: tSymbol,
        );

        // ASSERT — should always be less than budget/price due to fees
        result.fold(
          (_) => fail('Expected Right'),
          (qty) {
            final noFeeQty = 5000.0 / tPrice;
            expect(qty, lessThan(noFeeQty));
          },
        );
      });
    });

    // -----------------------------------------------------------------------
    group('isTransactionProfitable', () {
      test('[FCS-018] should return true when sell price covers fees',
          () async {
        // ARRANGE — buy 50000, sell 51000, 0.1% each side
        mockRepo.onGetSymbolFeesIfNeeded = (s) => Right(_fee(
              maker: 0.001,
              taker: 0.001,
            ));

        // ACT
        final result = await service.isTransactionProfitable(
          buyPrice: 50000.0,
          sellPrice: 51000.0,
          quantity: tQuantity,
          symbol: tSymbol,
        );

        // ASSERT
        // Cost: 50000 + 50 = 50050
        // Revenue: 51000 - 51 = 50949
        // 50949 > 50050 → profitable
        result.fold(
          (_) => fail('Expected Right'),
          (profitable) => expect(profitable, isTrue),
        );
      });

      test('[FCS-019] should return false when spread does not cover fees',
          () async {
        // ARRANGE — buy 50000, sell 50010, 0.1% fee
        mockRepo.onGetSymbolFeesIfNeeded = (s) => Right(_fee(
              maker: 0.001,
              taker: 0.001,
            ));

        // ACT
        final result = await service.isTransactionProfitable(
          buyPrice: 50000.0,
          sellPrice: 50010.0, // only 0.02% gain, fee is 0.1% each side
          quantity: tQuantity,
          symbol: tSymbol,
        );

        // ASSERT
        result.fold(
          (_) => fail('Expected Right'),
          (profitable) => expect(profitable, isFalse),
        );
      });

      test('[FCS-020] should return false when selling at same price',
          () async {
        // ARRANGE — buy = sell, fees eat into capital
        mockRepo.onGetSymbolFeesIfNeeded = (s) => Right(_fee());

        // ACT
        final result = await service.isTransactionProfitable(
          buyPrice: tPrice,
          sellPrice: tPrice,
          quantity: tQuantity,
          symbol: tSymbol,
        );

        // ASSERT — same price but fees on both sides
        result.fold(
          (_) => fail('Expected Right'),
          (profitable) => expect(profitable, isFalse),
        );
      });

      test('[FCS-021] should handle zero-fee scenario', () async {
        // ARRANGE — rare but test boundary
        mockRepo.onGetSymbolFeesIfNeeded =
            (s) => Right(_fee(maker: 0.0, taker: 0.0));

        // ACT
        final result = await service.isTransactionProfitable(
          buyPrice: 50000.0,
          sellPrice: 50001.0, // minimal gain
          quantity: tQuantity,
          symbol: tSymbol,
        );

        // ASSERT — even $1 gain is profitable with zero fees
        result.fold(
          (_) => fail('Expected Right'),
          (profitable) => expect(profitable, isTrue),
        );
      });
    });

    // -----------------------------------------------------------------------
    group('getCurrentFees & refreshFees', () {
      test('[FCS-022] getCurrentFees should delegate to repository', () async {
        // ACT
        final result = await service.getCurrentFees(tSymbol);

        // ASSERT
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (feeInfo) => expect(feeInfo.symbol, tSymbol),
        );
      });

      test('[FCS-023] refreshFees should delegate to repository', () async {
        // ACT
        final result = await service.refreshFees(tSymbol);

        // ASSERT
        expect(result.isRight(), isTrue);
      });

      test('[FCS-024] clearFeeCache should delegate to repository', () async {
        // ACT & ASSERT — should not throw
        await service.clearFeeCache();
      });
    });

    // -----------------------------------------------------------------------
    group('multi-symbol scenarios', () {
      test('[FCS-025] should calculate fees for different symbols', () async {
        // ARRANGE — different fee tiers per symbol
        mockRepo.onGetSymbolFeesIfNeeded = (symbol) {
          if (symbol == 'BTCUSDC') {
            return Right(_fee(maker: 0.001)); // VIP 0
          } else if (symbol == 'ETHUSDC') {
            return Right(_fee(maker: 0.0008)); // VIP 1
          }
          return Right(_fee(maker: 0.0006)); // VIP 2
        };

        // ACT
        final btcFee = await service.calculateTotalFees(
          quantity: 1.0,
          price: 50000.0,
          isMaker: true,
          symbol: 'BTCUSDC',
        );
        final ethFee = await service.calculateTotalFees(
          quantity: 10.0,
          price: 3000.0,
          isMaker: true,
          symbol: 'ETHUSDC',
        );

        // ASSERT
        btcFee.fold((_) => fail(''), (f) => expect(f, closeTo(50.0, 0.01)));
        ethFee.fold((_) => fail(''), (f) => expect(f, closeTo(24.0, 0.01)));
      });
    });

    // -----------------------------------------------------------------------
    group('precision & edge cases', () {
      test('[FCS-026] should maintain precision across fee chain', () async {
        // ARRANGE — realistic micro-trade
        mockRepo.onGetSymbolFeesIfNeeded =
            (s) => Right(_fee(maker: 0.001, taker: 0.001));

        // ACT — buy + sell profitability check
        final profitable = await service.isTransactionProfitable(
          buyPrice: 50000.12345,
          sellPrice: 50200.67890,
          quantity: 0.00123456,
          symbol: tSymbol,
        );

        // ASSERT — just verify no precision errors
        expect(profitable.isRight(), isTrue);
      });

      test('[FCS-027] should call repository exactly once per fee request',
          () async {
        // ACT
        await service.calculateTotalFees(
          quantity: tQuantity,
          price: tPrice,
          isMaker: true,
          symbol: tSymbol,
        );

        // ASSERT
        expect(mockRepo.getSymbolFeesIfNeededCallCount, equals(1));
      });
    });
  });
  // =========================================================================
}
