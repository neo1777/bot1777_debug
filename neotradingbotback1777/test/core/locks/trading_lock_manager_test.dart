import 'dart:async';
import 'package:test/test.dart';
import 'package:neotradingbotback1777/core/locks/trading_lock_manager.dart';

void main() {
  late TradingLockManager lockManager;

  setUp(() {
    lockManager = TradingLockManager(
      operationCooldown: const Duration(milliseconds: 100),
    );
  });

  tearDown(() {
    lockManager.cleanupOldOperationTimes();
  });

  group('TradingLockManager', () {
    test('should execute operation successfully', () async {
      final result = await lockManager.executeTradingOperation(
        'BTCUSDC',
        () async => 'success',
      );
      expect(result, 'success');
    });

    test('should prevent concurrent operations on same symbol', () async {
      final executionOrder = <String>[];
      final completer1 = Completer<void>();
      final completer2 = Completer<void>();

      // Start op 1
      final future1 = lockManager.executeTradingOperation('BTCUSDC', () async {
        executionOrder.add('start1');
        await completer1.future;
        executionOrder.add('end1');
      });

      // Start op 2 (should wait for op 1)
      final future2 = lockManager.executeTradingOperation('BTCUSDC', () async {
        executionOrder.add('start2');
        await completer2.future;
        executionOrder.add('end2');
      });

      // Allow op 1 to proceed
      await Future.delayed(const Duration(milliseconds: 10));
      expect(executionOrder, ['start1']); // op 2 shouldn't run yet

      completer1.complete();
      await future1;

      // Allow op 2 to proceed
      completer2.complete();
      await future2;

      expect(executionOrder, ['start1', 'end1', 'start2', 'end2']);
    });

    test('should allow concurrent operations on different symbols', () async {
      final executionOrder = <String>[];
      final completer1 = Completer<void>();
      final completer2 = Completer<void>();

      // Start op 1 on BTC
      final future1 = lockManager.executeTradingOperation('BTCUSDC', () async {
        executionOrder.add('start1');
        await completer1.future;
        executionOrder.add('end1');
      });

      // Start op 2 on ETH (should NOT wait)
      final future2 = lockManager.executeTradingOperation('ETHUSDC', () async {
        executionOrder.add('start2');
        await completer2.future;
        executionOrder.add('end2');
      });

      // Both should start
      await Future.delayed(const Duration(milliseconds: 10));
      expect(executionOrder, contains('start1'));
      expect(executionOrder, contains('start2'));

      completer1.complete();
      completer2.complete();
      await Future.wait([future1, future2]);
    });

    test('should enforce cooldown period', () async {
      // Op 1
      await lockManager.executeTradingOperation(
        'BTCUSDC',
        () async => 'success',
      );

      // Op 2 immediately - should fail due to cooldown
      expect(
        () => lockManager.executeTradingOperation(
          'BTCUSDC',
          () async => 'fail',
        ),
        throwsA(isA<TradingLockException>()),
      );

      // Wait for cooldown
      await Future.delayed(const Duration(milliseconds: 110));

      // Op 3 - should succeed
      await lockManager.executeTradingOperation(
        'BTCUSDC',
        () async => 'success',
      );
    });

    test('should respect checkCooldown flag', () async {
      // Op 1
      await lockManager.executeTradingOperation(
        'BTCUSDC',
        () async => 'success',
      );

      // Op 2 with checkCooldown: false - should succeed
      await lockManager.executeTradingOperation(
        'BTCUSDC',
        () async => 'success',
        checkCooldown: false,
      );
    });

    test(
        'executeTradingOperationSync should execute synchronously returning operations',
        () async {
      final result = await lockManager.executeTradingOperationSync(
        'BTCUSDC',
        () => 'sync_success',
      );
      expect(result, 'sync_success');
    });

    test('getStats should return correct stats', () async {
      await lockManager.executeTradingOperation('BTCUSDC', () async => 1);
      final stats = lockManager.getStats();
      expect(stats.trackedSymbolsCount, 1);
      // Lock might be cleaned up or not depending on implementation of _cleanupUnusedLocks
      // In current impl, it cleans up in cleanupOldOperationTimes which is not called here
      // But _cleanupUnusedLocks is called in cleanupOldOperationTimes

      // Since clean up logic is manual in current impl, locks map grows
      expect(stats.activeLocksCount, 1);
    });
  });
}

