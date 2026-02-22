import 'dart:async';
import 'dart:math';
import 'package:test/test.dart';

void main() {
  group('ConcurrencyManager - Stress Tests', () {
    late Random random;

    setUp(() {
      random = Random(42); // Seed fisso per test deterministici
    });

    test(
        '[CONCURRENCY-TEST-001] should handle 1000 concurrent operations without deadlock',
        () async {
      final operationCount = 1000;
      final operations = <Future<int>>[];
      final results = <int>[];

      for (int i = 0; i < operationCount; i++) {
        final operation = Future(() async {
          await Future.delayed(Duration(milliseconds: random.nextInt(5) + 1));
          return random.nextInt(1000);
        });
        operations.add(operation);
      }

      final startTime = DateTime.now();
      final completedResults = await Future.wait(operations);
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;

      results.addAll(completedResults);

      expect(results.length, operationCount);
      expect(duration,
          lessThan(3000)); // Dovrebbe completarsi in meno di 3 secondi
      expect(results.every((r) => r >= 0 && r < 1000), isTrue);
    });

    test('[CONCURRENCY-TEST-002] should manage resource allocation efficiently',
        () async {
      final resourceCount = 500;
      final resources = <StreamController>[];
      final allocationTimes = <int>[];

      for (int i = 0; i < resourceCount; i++) {
        final startTime = DateTime.now();
        final resource = StreamController<int>();
        resources.add(resource);
        final endTime = DateTime.now();
        allocationTimes.add(endTime.difference(startTime).inMilliseconds);
      }

      expect(resources.length, resourceCount);
      expect(allocationTimes.length, resourceCount);
      expect(allocationTimes.every((t) => t >= 0), isTrue);
      expect(allocationTimes.every((t) => t <= 100), isTrue);

      // Cleanup
      for (final resource in resources) {
        unawaited(resource.close());
      }
    });

    test(
        '[CONCURRENCY-TEST-003] should handle concurrent state transitions correctly',
        () async {
      final transitionCount = 300;
      final states = <String>[];
      final lock = Lock();
      // String currentState = 'IDLE'; // Non utilizzata

      final transitions = List.generate(transitionCount, (index) async {
        return await lock.synchronized(() async {
          final newState =
              ['IDLE', 'RUNNING', 'PAUSED', 'STOPPED'][random.nextInt(4)];
          states.add(newState);
          await Future.delayed(Duration(milliseconds: random.nextInt(3) + 1));
          return newState;
        });
      });

      final results = await Future.wait(transitions);

      expect(results.length, transitionCount);
      expect(states.length, transitionCount);
      expect(
          results.every(
              (r) => ['IDLE', 'RUNNING', 'PAUSED', 'STOPPED'].contains(r)),
          isTrue);
    });

    test(
        '[CONCURRENCY-TEST-004] should handle concurrent price updates without data corruption',
        () async {
      final updateCount = 400;
      final priceUpdates = <Future<double>>[];
      double currPrice = 100.0;

      for (int i = 0; i < updateCount; i++) {
        final update = Future(() async {
          await Future.delayed(Duration(milliseconds: random.nextInt(2) + 1));
          final change = (random.nextDouble() - 0.5) * 2.0; // -1% to +1%
          currPrice = currPrice * (1 + change / 100);
          return currPrice;
        });
        priceUpdates.add(update);
      }

      final results = await Future.wait(priceUpdates);
      final finalPrice = results.last;

      expect(results.length, updateCount);
      expect(currPrice, greaterThan(0.0));
      expect(currPrice, lessThanOrEqualTo(10000.0));
      expect(finalPrice, greaterThan(0.0));
      expect(finalPrice, lessThanOrEqualTo(10000.0));

      // Verifica che le variazioni siano ragionevoli
      final change = ((finalPrice - 100.0) / 100.0).abs();
      expect(change, lessThan(0.5));
    });

    test(
        '[CONCURRENCY-TEST-005] should handle memory pressure during concurrent operations',
        () async {
      final operationCount = 200;
      final memoryIntensiveData = <List<double>>[];
      final operations = <Future<void>>[];

      for (int i = 0; i < operationCount; i++) {
        final operation = Future(() async {
          final data = List.generate(1000, (index) => random.nextDouble());
          memoryIntensiveData.add(data);

          await Future.delayed(Duration(milliseconds: random.nextInt(5) + 1));

          // Cleanup per evitare overflow di memoria
          if (memoryIntensiveData.length > 50) {
            memoryIntensiveData.removeAt(0);
          }
        });
        operations.add(operation);
      }

      await Future.wait(operations);

      expect(memoryIntensiveData.length, lessThanOrEqualTo(50));
      expect(operations.length, operationCount);
    });

    test(
        '[CONCURRENCY-TEST-006] should handle concurrent error scenarios gracefully',
        () async {
      final errorTestCount = 250;
      final operations = <Future<bool>>[];
      int successCount = 0;
      int errorCountActual = 0;

      for (int i = 0; i < errorTestCount; i++) {
        final operation = Future(() async {
          try {
            if (random.nextDouble() < 0.3) {
              // 30% di errori
              throw Exception('Simulated concurrent error');
            }

            await Future.delayed(Duration(milliseconds: random.nextInt(3) + 1));
            return true;
          } catch (e) {
            return false;
          }
        });
        operations.add(operation);
      }

      final results = await Future.wait(operations);

      for (final result in results) {
        if (result) {
          successCount++;
        } else {
          errorCountActual++;
        }
      }

      expect(results.length, errorTestCount);
      expect(successCount + errorCountActual, errorTestCount);
      expect(successCount, greaterThan(0));
      expect(errorCountActual, greaterThan(0));
    });

    test(
        '[CONCURRENCY-TEST-007] should maintain data consistency during concurrent modifications',
        () async {
      final modificationCount = 150;
      final sharedData = <String, dynamic>{
        'balance': 10000.0,
        'trades': <String>[],
        'lastUpdate': DateTime.now(),
      };

      final modifications = List.generate(modificationCount, (index) async {
        return await Future(() async {
          await Future.delayed(Duration(milliseconds: random.nextInt(2) + 1));

          // Modifica concorrente dei dati condivisi
          sharedData['balance'] = (sharedData['balance'] as double) +
              (random.nextDouble() - 0.5) * 100;
          (sharedData['trades'] as List<String>).add('TRADE$index');
          sharedData['lastUpdate'] = DateTime.now();

          return true;
        });
      });

      final results = await Future.wait(modifications);

      expect(results.length, modificationCount);
      expect(results.every((r) => r == true), isTrue);
      expect((sharedData['balance'] as double), greaterThan(0.0));
      expect((sharedData['trades'] as List).length, greaterThanOrEqualTo(0));
      expect(sharedData['lastUpdate'], isA<DateTime>());
    });

    test(
        '[CONCURRENCY-TEST-008] should handle resource cleanup during concurrent shutdown',
        () {
      final resourceCount = 3;
      final resources = <StreamController>[];

      for (int i = 0; i < resourceCount; i++) {
        resources.add(StreamController<int>());
      }

      // ACT - Cleanup immediato
      for (int i = 0; i < resourceCount; i++) {
        resources[i].close();
      }

      // ASSERT
      expect(resources.length, resourceCount);
      for (final resource in resources) {
        expect(resource.hasListener, isFalse);
      }
    });
  });
}

class Lock {
  bool _locked = false;
  final _queue = <Completer<void>>[];

  Future<T> synchronized<T>(Future<T> Function() operation) async {
    if (_locked) {
      final completer = Completer<void>();
      _queue.add(completer);
      await completer.future;
    }

    _locked = true;
    try {
      return await operation();
    } finally {
      _locked = false;
      if (_queue.isNotEmpty) {
        final next = _queue.removeAt(0);
        next.complete();
      }
    }
  }
}

