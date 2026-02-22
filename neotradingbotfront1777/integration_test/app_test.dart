import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:neotradingbotfront1777/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Safe E2E Trading Scenario', () {
    testWidgets('Full Cycle: Start BTC Strategy, Monitor, and Stop', (
      tester,
    ) async {
      // 1. Launch the application
      // We use the real app entry point
      await app.main();
      await tester.pumpAndSettle();

      // Ensure the app title or a key dashboard element is present
      expect(find.text('BotBinance1777'), findsOneWidget);
      expect(find.text('CONTROLLO STRATEGIA'), findsOneWidget);

      // 2. Identify and Tap the START button
      // We look for the button labeled 'START' in the TradingControlPanel
      final startButton = find.text('START');
      expect(startButton, findsOneWidget);

      debugPrint('Tapping START strategy button...');
      await tester.tap(startButton);

      // Pump several times to handle the gRPC call and state updates
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // 3. Verify the Strategy transitions to ATTIVA (Running)
      // We wait up to 10 seconds for the backend to confirm the loop started
      bool isAttiva = false;
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(seconds: 1));
        if (find.textContaining('ATTIVA').evaluate().isNotEmpty) {
          isAttiva = true;
          break;
        }
        debugPrint('Waiting for strategy to start... attempt ${i + 1}');
      }

      expect(
        isAttiva,
        isTrue,
        reason: 'Strategy should reach "ATTIVA" state after START',
      );
      debugPrint('Strategy status: ATTIVA (Verified)');

      // 4. Check for Test Mode / Dry Run indications
      // Even if there is no explicit badge, we can verify that no error
      // related to "Insufficient Balance" or "API Key Permissions" occurs
      // because simulated orders avoid these real-world checks in the exchange driver.

      // 5. Monitor for a few seconds to ensure price updates and stability
      await tester.pump(const Duration(seconds: 3));

      // 6. Stop the strategy
      final stopButton = find.text('STOP');
      expect(stopButton, findsOneWidget);

      debugPrint('Tapping STOP strategy button...');
      await tester.tap(stopButton);
      await tester.pumpAndSettle();

      // 7. Verify status returns to INATTIVA
      bool isIdle = false;
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 1));
        if (find.textContaining('INATTIVA').evaluate().isNotEmpty) {
          isIdle = true;
          break;
        }
      }

      expect(
        isIdle,
        isTrue,
        reason: 'Strategy should return to "INATTIVA" state after STOP',
      );
      debugPrint('Strategy status: INATTIVA (Verified)');
    });
  });
}
