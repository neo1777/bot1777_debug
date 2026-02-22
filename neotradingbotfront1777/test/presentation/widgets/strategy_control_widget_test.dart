import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neotradingbotfront1777/presentation/blocs/strategy_control/strategy_control_bloc.dart';

// Mock the Bloc itself using MockBloc from bloc_test
class MockStrategyControlBloc
    extends MockBloc<StrategyControlEvent, StrategyControlState>
    implements StrategyControlBloc {}

void main() {
  late MockStrategyControlBloc mockBloc;

  const tSymbol = 'BTCUSDC';

  // Helper function per ottenere il colore dello status
  Color getStatusColor(OperationStatus status) {
    switch (status) {
      case OperationStatus.none:
        return Colors.grey;
      case OperationStatus.inProgress:
        return Colors.blue;
      case OperationStatus.success:
        return Colors.green;
      case OperationStatus.failure:
        return Colors.red;
    }
  }

  // Widget di test semplificato per il controllo della strategia
  Widget createTestWidget(MockStrategyControlBloc bloc) {
    return MaterialApp(
      home: BlocProvider<StrategyControlBloc>.value(
        value: bloc,
        child: Scaffold(
          body: Column(
            children: [
              BlocBuilder<StrategyControlBloc, StrategyControlState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      // Status indicator
                      Container(
                        key: const Key('status_container'),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: getStatusColor(state.status),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Status: ${state.status.name}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Error message display
                      if (state.status == OperationStatus.failure)
                        Container(
                          key: const Key('error_container'),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            border: Border.all(color: Colors.red),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            state.errorMessage ?? 'Unknown error',
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                        ),
                      const SizedBox(height: 16),
                      // Control buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed:
                                state.status == OperationStatus.inProgress
                                    ? null
                                    : () =>
                                        context.read<StrategyControlBloc>().add(
                                          const StartStrategyRequested(tSymbol),
                                        ),
                            child: const Text('START'),
                          ),
                          ElevatedButton(
                            onPressed:
                                state.status == OperationStatus.inProgress
                                    ? null
                                    : () =>
                                        context.read<StrategyControlBloc>().add(
                                          const StopStrategyRequested(tSymbol),
                                        ),
                            child: const Text('STOP'),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to check if a button is enabled
  bool isButtonEnabled(WidgetTester tester, String text) {
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, text),
    );
    return button.onPressed != null;
  }

  setUp(() {
    mockBloc = MockStrategyControlBloc();
  });

  group('[FRONTEND-TEST-002] Test Widget per Stati di Errore', () {
    testWidgets('should display initial state correctly', (
      WidgetTester tester,
    ) async {
      // ARRANGE - Set initial state
      when(() => mockBloc.state).thenReturn(const StrategyControlState());

      await tester.pumpWidget(createTestWidget(mockBloc));

      // ASSERT
      expect(find.text('Status: none'), findsOneWidget);
      expect(find.text('START'), findsOneWidget);
      expect(find.text('STOP'), findsOneWidget);
      expect(isButtonEnabled(tester, 'START'), isTrue);
      expect(isButtonEnabled(tester, 'STOP'), isTrue);
    });

    testWidgets('should display in-progress state correctly', (
      WidgetTester tester,
    ) async {
      // ARRANGE - Use whenListen to emit inProgress state
      whenListen(
        mockBloc,
        Stream.value(
          const StrategyControlState(status: OperationStatus.inProgress),
        ),
        initialState: const StrategyControlState(),
      );

      await tester.pumpWidget(createTestWidget(mockBloc));
      await tester.pump(); // Process the stream emission

      // ASSERT
      expect(find.text('Status: inProgress'), findsOneWidget);
      expect(isButtonEnabled(tester, 'START'), isFalse);
      expect(isButtonEnabled(tester, 'STOP'), isFalse);
    });

    testWidgets('should display success state correctly', (
      WidgetTester tester,
    ) async {
      // ARRANGE - Emit inProgress then success
      whenListen(
        mockBloc,
        Stream.fromIterable([
          const StrategyControlState(status: OperationStatus.inProgress),
          const StrategyControlState(status: OperationStatus.success),
        ]),
        initialState: const StrategyControlState(),
      );

      await tester.pumpWidget(createTestWidget(mockBloc));
      await tester.pump(); // Process stream emissions

      // ASSERT
      expect(find.text('Status: success'), findsOneWidget);
      expect(isButtonEnabled(tester, 'START'), isTrue);
      expect(isButtonEnabled(tester, 'STOP'), isTrue);
    });

    testWidgets('should display error state correctly', (
      WidgetTester tester,
    ) async {
      // ARRANGE - Emit inProgress then failure
      whenListen(
        mockBloc,
        Stream.fromIterable([
          const StrategyControlState(status: OperationStatus.inProgress),
          const StrategyControlState(
            status: OperationStatus.failure,
            errorMessage: 'Network error',
          ),
        ]),
        initialState: const StrategyControlState(),
      );

      await tester.pumpWidget(createTestWidget(mockBloc));
      await tester.pump();

      // ASSERT
      expect(find.text('Status: failure'), findsOneWidget);
      expect(find.text('Network error'), findsOneWidget);
      expect(isButtonEnabled(tester, 'START'), isTrue);
      expect(isButtonEnabled(tester, 'STOP'), isTrue);
    });

    testWidgets('should handle multiple error states correctly', (
      WidgetTester tester,
    ) async {
      final controller = StreamController<StrategyControlState>();

      // ARRANGE
      whenListen(
        mockBloc,
        controller.stream,
        initialState: const StrategyControlState(),
      );

      await tester.pumpWidget(createTestWidget(mockBloc));

      // Primo errore
      controller.add(
        const StrategyControlState(status: OperationStatus.inProgress),
      );
      await tester.pump();
      controller.add(
        const StrategyControlState(
          status: OperationStatus.failure,
          errorMessage: 'First error',
        ),
      );
      await tester.pump();

      expect(find.text('Status: failure'), findsOneWidget);
      expect(find.text('First error'), findsOneWidget);

      // Secondo errore
      controller.add(
        const StrategyControlState(status: OperationStatus.inProgress),
      );
      await tester.pump();
      controller.add(
        const StrategyControlState(
          status: OperationStatus.failure,
          errorMessage: 'Second error',
        ),
      );
      await tester.pump();

      expect(find.text('Status: failure'), findsOneWidget);
      expect(find.text('Second error'), findsOneWidget);

      // Successo
      controller.add(
        const StrategyControlState(status: OperationStatus.inProgress),
      );
      await tester.pump();
      controller.add(
        const StrategyControlState(status: OperationStatus.success),
      );
      await tester.pump();

      expect(find.text('Status: success'), findsOneWidget);
      expect(find.text('First error'), findsNothing);
      expect(find.text('Second error'), findsNothing);

      await controller.close();
    });

    testWidgets('should handle empty error messages gracefully', (
      WidgetTester tester,
    ) async {
      // ARRANGE
      whenListen(
        mockBloc,
        Stream.value(
          const StrategyControlState(
            status: OperationStatus.failure,
            errorMessage: '',
          ),
        ),
        initialState: const StrategyControlState(),
      );

      await tester.pumpWidget(createTestWidget(mockBloc));
      await tester.pump();

      // ASSERT
      expect(find.text('Status: failure'), findsOneWidget);
      // errorMessage is '' (empty string, not null), so 'Unknown error' fallback
      // is not triggered. The error container should still appear.
      expect(find.byKey(const Key('error_container')), findsOneWidget);
    });

    testWidgets('should handle very long error messages', (
      WidgetTester tester,
    ) async {
      final longMessage = 'A' * 500;

      // ARRANGE
      whenListen(
        mockBloc,
        Stream.value(
          StrategyControlState(
            status: OperationStatus.failure,
            errorMessage: longMessage,
          ),
        ),
        initialState: const StrategyControlState(),
      );

      await tester.pumpWidget(createTestWidget(mockBloc));
      await tester.pump();

      // ASSERT
      expect(find.text('Status: failure'), findsOneWidget);
      expect(find.text(longMessage), findsOneWidget);
      expect(find.byKey(const Key('error_container')), findsOneWidget);
    });

    testWidgets(
      'should maintain button state consistency during rapid operations',
      (WidgetTester tester) async {
        final controller = StreamController<StrategyControlState>();

        // ARRANGE
        whenListen(
          mockBloc,
          controller.stream,
          initialState: const StrategyControlState(),
        );

        await tester.pumpWidget(createTestWidget(mockBloc));

        // inProgress: buttons disabled
        controller.add(
          const StrategyControlState(status: OperationStatus.inProgress),
        );
        await tester.pump();

        expect(isButtonEnabled(tester, 'START'), isFalse);
        expect(isButtonEnabled(tester, 'STOP'), isFalse);

        // success: buttons enabled again
        controller.add(
          const StrategyControlState(status: OperationStatus.success),
        );
        await tester.pump();

        expect(isButtonEnabled(tester, 'START'), isTrue);
        expect(isButtonEnabled(tester, 'STOP'), isTrue);

        // Another inProgress: buttons disabled
        controller.add(
          const StrategyControlState(status: OperationStatus.inProgress),
        );
        await tester.pump();

        expect(isButtonEnabled(tester, 'START'), isFalse);
        expect(isButtonEnabled(tester, 'STOP'), isFalse);

        await controller.close();
      },
    );

    testWidgets('should handle concurrent button presses gracefully', (
      WidgetTester tester,
    ) async {
      // ARRANGE - Bloc is in inProgress state
      whenListen(
        mockBloc,
        Stream.value(
          const StrategyControlState(status: OperationStatus.inProgress),
        ),
        initialState: const StrategyControlState(),
      );

      await tester.pumpWidget(createTestWidget(mockBloc));
      await tester.pump();

      // ASSERT - Buttons should be disabled during inProgress
      expect(find.text('Status: inProgress'), findsOneWidget);
      expect(isButtonEnabled(tester, 'START'), isFalse);
      expect(isButtonEnabled(tester, 'STOP'), isFalse);
    });

    testWidgets('should display appropriate colors for different statuses', (
      WidgetTester tester,
    ) async {
      final controller = StreamController<StrategyControlState>();

      // ARRANGE
      whenListen(
        mockBloc,
        controller.stream,
        initialState: const StrategyControlState(),
      );

      await tester.pumpWidget(createTestWidget(mockBloc));

      // Stato iniziale (grigio)
      var statusContainer = tester.widget<Container>(
        find.byKey(const Key('status_container')),
      );
      var decoration = statusContainer.decoration as BoxDecoration;
      expect(decoration.color, Colors.grey);

      // Successo (verde)
      controller.add(
        const StrategyControlState(status: OperationStatus.success),
      );
      await tester.pump();
      await tester.pump();

      statusContainer = tester.widget<Container>(
        find.byKey(const Key('status_container')),
      );
      decoration = statusContainer.decoration as BoxDecoration;
      expect(decoration.color, Colors.green);

      // Errore (rosso)
      controller.add(
        const StrategyControlState(
          status: OperationStatus.failure,
          errorMessage: 'Error',
        ),
      );
      await tester.pump();
      await tester.pump();

      statusContainer = tester.widget<Container>(
        find.byKey(const Key('status_container')),
      );
      decoration = statusContainer.decoration as BoxDecoration;
      expect(decoration.color, Colors.red);

      await controller.close();
    });
  });
}

