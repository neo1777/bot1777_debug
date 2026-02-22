import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neotradingbotfront1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotfront1777/presentation/features/dashboard/widgets/strategy_state_card_content.dart';

void main() {
  group('StrategyStateCardContent Widget Tests', () {
    Widget createTestWidget({required StrategyState strategyState}) {
      return MaterialApp(
        home: Scaffold(body: StrategyStateCardContent(state: strategyState)),
      );
    }

    testWidgets(
      '[WIDGET-TEST-001] should display strategy state information correctly',
      (WidgetTester tester) async {
        // ARRANGE
        final strategyState = StrategyState.initial(symbol: 'BTCUSDC');

        // ACT
        await tester.pumpWidget(createTestWidget(strategyState: strategyState));

        // ASSERT
        expect(find.text('BTCUSDC'), findsOneWidget);
        expect(find.text('INATTIVA'), findsOneWidget);
        expect(
          find.text('—'),
          findsNWidgets(3),
        ); // openTradesCount, averagePrice, cumulativeProfit
      },
    );

    testWidgets(
      '[WIDGET-TEST-002] should display running strategy state correctly',
      (WidgetTester tester) async {
        // ARRANGE
        final strategyState = StrategyState(
          symbol: 'ETHUSDC',
          status: StrategyStatus.running,
          openTradesCount: 5,
          averagePrice: 2500.0,
          totalQuantity: 2.5,
          lastBuyPrice: 2450.0,
          currentRoundId: 3,
          cumulativeProfit: 150.0,
          successfulRounds: 2,
          failedRounds: 0,
        );

        // ACT
        await tester.pumpWidget(createTestWidget(strategyState: strategyState));

        // ASSERT
        expect(find.text('ETHUSDC'), findsOneWidget);
        expect(find.text('ATTIVA'), findsOneWidget);
        expect(find.text('5'), findsOneWidget); // openTradesCount
        expect(
          find.text('2500.000000'),
          findsOneWidget,
        ); // averagePrice (toStringAsFixed(6))
        expect(
          find.text('150.00 \$'),
          findsOneWidget,
        ); // cumulativeProfit (toStringAsFixed(2)) + $
      },
    );

    testWidgets(
      '[WIDGET-TEST-003] should display paused strategy state correctly',
      (WidgetTester tester) async {
        // ARRANGE
        final strategyState = StrategyState(
          symbol: 'ADAUSDC',
          status: StrategyStatus.paused,
          openTradesCount: 2,
          averagePrice: 0.45,
          totalQuantity: 1000.0,
          lastBuyPrice: 0.44,
          currentRoundId: 1,
          cumulativeProfit: -25.0,
          successfulRounds: 0,
          failedRounds: 1,
        );

        // ACT
        await tester.pumpWidget(createTestWidget(strategyState: strategyState));

        // ASSERT
        expect(find.text('ADAUSDC'), findsOneWidget);
        expect(find.text('IN PAUSA'), findsOneWidget);
        expect(find.text('2'), findsOneWidget); // openTradesCount
        expect(
          find.text('0.450000'),
          findsOneWidget,
        ); // averagePrice (toStringAsFixed(6))
        expect(
          find.text('-25.00 \$'),
          findsOneWidget,
        ); // cumulativeProfit (toStringAsFixed(2)) + $
      },
    );

    testWidgets(
      '[WIDGET-TEST-004] should display error strategy state correctly',
      (WidgetTester tester) async {
        // ARRANGE
        final strategyState = StrategyState(
          symbol: 'DOTUSDC',
          status: StrategyStatus.error,
          openTradesCount: 0,
          averagePrice: 0.0,
          totalQuantity: 0.0,
          lastBuyPrice: 0.0,
          currentRoundId: 0,
          cumulativeProfit: 0.0,
          successfulRounds: 0,
          failedRounds: 0,
        );

        // ACT
        await tester.pumpWidget(createTestWidget(strategyState: strategyState));

        // ASSERT
        expect(find.text('DOTUSDC'), findsOneWidget);
        expect(find.text('ERRORE'), findsOneWidget);
        expect(find.text('0'), findsOneWidget); // openTradesCount
        expect(
          find.text('0.000000'),
          findsOneWidget,
        ); // averagePrice (toStringAsFixed(6))
        expect(
          find.text('0.00 \$'),
          findsOneWidget,
        ); // cumulativeProfit (toStringAsFixed(2)) + $
      },
    );

    testWidgets(
      '[WIDGET-TEST-005] should display recovering strategy state correctly',
      (WidgetTester tester) async {
        // ARRANGE
        final strategyState = StrategyState(
          symbol: 'LINKUSDC',
          status: StrategyStatus.recovering,
          openTradesCount: 1,
          averagePrice: 15.75,
          totalQuantity: 50.0,
          lastBuyPrice: 15.50,
          currentRoundId: 2,
          cumulativeProfit: 75.0,
          successfulRounds: 1,
          failedRounds: 0,
        );

        // ACT
        await tester.pumpWidget(createTestWidget(strategyState: strategyState));

        // ASSERT
        expect(find.text('LINKUSDC'), findsOneWidget);
        expect(find.text('RIPRISTINO'), findsOneWidget);
        expect(find.text('1'), findsOneWidget); // openTradesCount
        expect(
          find.text('15.750000'),
          findsOneWidget,
        ); // averagePrice (toStringAsFixed(6))
        expect(
          find.text('75.00 \$'),
          findsOneWidget,
        ); // cumulativeProfit (toStringAsFixed(2)) + $
      },
    );

    testWidgets(
      '[WIDGET-TEST-006] should display unspecified strategy state correctly',
      (WidgetTester tester) async {
        // ARRANGE
        final strategyState = StrategyState(
          symbol: 'UNIUSDC',
          status: StrategyStatus.unspecified,
          openTradesCount: 0,
          averagePrice: 0.0,
          totalQuantity: 0.0,
          lastBuyPrice: 0.0,
          currentRoundId: 0,
          cumulativeProfit: 0.0,
          successfulRounds: 0,
          failedRounds: 0,
        );

        // ACT
        await tester.pumpWidget(createTestWidget(strategyState: strategyState));

        // ASSERT
        expect(find.text('UNIUSDC'), findsOneWidget);
        expect(find.text('NON SPECIFICATO'), findsOneWidget);
        expect(find.text('0'), findsOneWidget); // openTradesCount
        expect(
          find.text('0.000000'),
          findsOneWidget,
        ); // averagePrice (toStringAsFixed(6))
        expect(
          find.text('0.00 \$'),
          findsOneWidget,
        ); // cumulativeProfit (toStringAsFixed(2)) + $
      },
    );

    testWidgets(
      '[WIDGET-TEST-007] should display strategy with high values correctly',
      (WidgetTester tester) async {
        // ARRANGE
        final strategyState = StrategyState(
          symbol: 'XRPUSDC',
          status: StrategyStatus.running,
          openTradesCount: 999,
          averagePrice: 999999.99,
          totalQuantity: 999999.99,
          lastBuyPrice: 999999.99,
          currentRoundId: 999999,
          cumulativeProfit: 999999.99,
          successfulRounds: 999999,
          failedRounds: 999999,
        );

        // ACT
        await tester.pumpWidget(createTestWidget(strategyState: strategyState));

        // ASSERT
        expect(find.text('XRPUSDC'), findsOneWidget);
        expect(find.text('ATTIVA'), findsOneWidget);
        expect(find.text('999'), findsOneWidget); // openTradesCount
        expect(
          find.text('999999.990000'),
          findsOneWidget,
        ); // averagePrice (toStringAsFixed(6))
        expect(
          find.text('999999.99 \$'),
          findsOneWidget,
        ); // cumulativeProfit (toStringAsFixed(2)) + $
      },
    );

    testWidgets(
      '[WIDGET-TEST-008] should display strategy with zero values correctly',
      (WidgetTester tester) async {
        // ARRANGE
        final strategyState = StrategyState(
          symbol: 'BCHUSDC',
          status: StrategyStatus.idle,
          openTradesCount: 0,
          averagePrice: 0.0,
          totalQuantity: 0.0,
          lastBuyPrice: 0.0,
          currentRoundId: 0,
          cumulativeProfit: 0.0,
          successfulRounds: 0,
          failedRounds: 0,
        );

        // ACT
        await tester.pumpWidget(createTestWidget(strategyState: strategyState));

        // ASSERT
        expect(find.text('BCHUSDC'), findsOneWidget);
        expect(find.text('INATTIVA'), findsOneWidget);
        expect(
          find.text('—'),
          findsNWidgets(3),
        ); // openTradesCount, averagePrice, cumulativeProfit
      },
    );
    testWidgets(
      '[WIDGET-TEST-009] should filter raw warning containing AUTO_STOP_IN_CYCLES',
      (WidgetTester tester) async {
        // ARRANGE
        final strategyState = StrategyState(
          symbol: 'BTCUSDC',
          status: StrategyStatus.running,
          openTradesCount: 1,
          averagePrice: 50000.0,
          totalQuantity: 0.1,
          lastBuyPrice: 50000.0,
          currentRoundId: 1,
          cumulativeProfit: 10.0,
          // Contains AUTO_STOP_IN_CYCLES, should be filtered by _shouldShowRawWarning
          warningMessage: 'AUTO_STOP_IN_CYCLES;remaining=5',
          successfulRounds: 0,
          failedRounds: 0,
        );

        // ACT
        await tester.pumpWidget(createTestWidget(strategyState: strategyState));

        // ASSERT
        // The raw message text should NOT be found (it's filtered).
        // Note: The pill displays "Cicli rimanenti: 5", check for that?
        // _buildAutoStopPill logic displays "Cicli rimanenti: $remaining"
        expect(find.text('AUTO_STOP_IN_CYCLES;remaining=5'), findsNothing);
        expect(find.text('Cicli rimanenti: 5'), findsOneWidget);
      },
    );
    testWidgets('[WIDGET-TEST-010] should display other raw warnings', (
      WidgetTester tester,
    ) async {
      // ARRANGE
      final strategyState = StrategyState(
        symbol: 'BTCUSDC',
        status: StrategyStatus.running,
        openTradesCount: 1,
        averagePrice: 50000.0,
        totalQuantity: 0.1,
        lastBuyPrice: 50000.0,
        currentRoundId: 1,
        cumulativeProfit: 10.0,
        warningMessage: 'Low Balance Warning',
        successfulRounds: 0,
        failedRounds: 0,
      );

      // ACT
      await tester.pumpWidget(createTestWidget(strategyState: strategyState));

      // ASSERT
      expect(find.text('Low Balance Warning'), findsOneWidget);
    });
  });
}
