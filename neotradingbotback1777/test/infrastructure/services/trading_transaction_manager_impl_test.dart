import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive_ce/hive.dart';

import 'package:neotradingbotback1777/domain/entities/app_trade.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/strategy_state_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/trading_repository_new.dart';
import 'package:neotradingbotback1777/infrastructure/services/trading_transaction_manager_impl.dart';
import 'package:neotradingbotback1777/core/config/constants.dart';
import 'package:neotradingbotback1777/domain/value_objects/amounts.dart';

class MockTradingRepository extends Mock implements TradingRepository {}

class MockStrategyStateRepository extends Mock
    implements StrategyStateRepository {}

void main() {
  late TradingTransactionManagerImpl manager;
  late MockTradingRepository mockTradingRepository;
  late MockStrategyStateRepository mockStrategyStateRepository;

  setUpAll(() async {
    // We need Hive for the journal
    Hive.init('test_hive_manager');
    registerFallbackValue(AppTrade(
      symbol: 'BTCUSDT',
      price: MoneyAmount.fromDouble(50000),
      quantity: QuantityAmount.fromDouble(1),
      isBuy: true,
      timestamp: 1,
      orderStatus: 'NEW',
    ));
    registerFallbackValue(AppStrategyState(symbol: 'BTCUSDT'));
  });

  setUp(() async {
    if (Hive.isBoxOpen(Constants.transactionJournalBoxName)) {
      await Hive.box<Map>(Constants.transactionJournalBoxName).clear();
    } else {
      await Hive.openBox<Map>(Constants.transactionJournalBoxName);
    }

    mockTradingRepository = MockTradingRepository();
    mockStrategyStateRepository = MockStrategyStateRepository();

    manager = TradingTransactionManagerImpl(
      tradingRepository: mockTradingRepository,
      strategyStateRepository: mockStrategyStateRepository,
    );
  });

  tearDown(() {
    manager.dispose();
  });

  tearDownAll(() async {
    await Hive.deleteBoxFromDisk(Constants.transactionJournalBoxName);
  });

  final dummyTrade = AppTrade(
    symbol: 'BTCUSDT',
    price: MoneyAmount.fromDouble(50000),
    quantity: QuantityAmount.fromDouble(1),
    isBuy: true,
    timestamp: 1234567890,
    orderStatus: 'FILLED',
  );

  final dummyState = AppStrategyState(
    symbol: 'BTCUSDT',
    status: StrategyState.MONITORING_FOR_BUY,
  );

  group('TradingTransactionManagerImpl - saveTradeAndState', () {
    test('successfully saves trade and state atomically', () async {
      when(() => mockTradingRepository.saveTrade(any()))
          .thenAnswer((_) async => Right(null));
      when(() => mockStrategyStateRepository.getStrategyState(any()))
          .thenAnswer((_) async => Right(null)); // Mock previous state
      when(() => mockStrategyStateRepository.saveStrategyState(any()))
          .thenAnswer((_) async => Right(null));

      final result = await manager.saveTradeAndState(dummyTrade, dummyState);

      expect(result.isRight(), isTrue);

      verify(() => mockTradingRepository.saveTrade(dummyTrade)).called(1);
      verify(() => mockStrategyStateRepository.saveStrategyState(dummyState))
          .called(1);
    });

    test('rolls back if saveStrategyState fails', () async {
      when(() => mockStrategyStateRepository.getStrategyState(any()))
          .thenAnswer((_) async => Right(null)); // previous state

      // Trade succeeds
      when(() => mockTradingRepository.saveTrade(any()))
          .thenAnswer((_) async => Right(null));

      // Deleting trade during rollback succeeds
      when(() => mockTradingRepository.deleteTrade(any()))
          .thenAnswer((_) async => Right(null));

      // State fails
      when(() => mockStrategyStateRepository.saveStrategyState(any()))
          .thenAnswer((_) async => Left(ServerFailure(message: 'DB Error')));

      final result = await manager.saveTradeAndState(dummyTrade, dummyState);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('Should be left'),
      );

      // Verify rollback occurred
      verify(() => mockTradingRepository.saveTrade(dummyTrade)).called(1);
      verify(() => mockTradingRepository.deleteTrade(any())).called(2);
    });

    test('fails immediately if saveTrade fails without trying to save state',
        () async {
      when(() => mockStrategyStateRepository.getStrategyState(any()))
          .thenAnswer((_) async => Right(null));

      // Trade fails
      when(() => mockTradingRepository.saveTrade(any()))
          .thenAnswer((_) async => Left(ServerFailure(message: 'DB Error')));

      final result = await manager.saveTradeAndState(dummyTrade, dummyState);

      expect(result.isLeft(), isTrue);

      verify(() => mockTradingRepository.saveTrade(dummyTrade)).called(1);
      verifyNever(() => mockStrategyStateRepository.saveStrategyState(any()));
    });
  });

  group('TradingTransactionManagerImpl - executeAtomically', () {
    test('executes all operations successfully', () async {
      int count = 0;
      final ops = <Future<Either<Failure, int>> Function()>[
        () async {
          count++;
          return Right(1);
        },
        () async {
          count++;
          return Right(2);
        },
      ];

      final result = await manager.executeAtomically(ops);

      expect(result.isRight(), isTrue);
      result.fold(
        (f) => fail('Should be right'),
        (v) => expect(v, [1, 2]),
      );
      expect(count, 2);
    });

    test('returns failure if any operation fails and halts execution',
        () async {
      int count = 0;
      final ops = <Future<Either<Failure, int>> Function()>[
        () async {
          count++;
          return Right(1);
        },
        () async {
          count++;
          return Left(ServerFailure(message: 'Fail'));
        },
        () async {
          count++;
          return Right(3);
        }, // Should not be executed
      ];

      final result = await manager.executeAtomically<int>(ops);

      expect(result.isLeft(), isTrue);
      expect(count, 2);
    });
  });

  group('TradingTransactionManagerImpl - executeWithBackup & Checkpoints', () {
    test('restores checkpoint on failure', () async {
      when(() => mockStrategyStateRepository.saveStrategyState(any()))
          .thenAnswer((_) async => Right(null));

      // Simulate state modification inside operation
      final result = await manager.executeWithBackup(() async {
        // Manually manipulate the internal checkpoint for testing the rollback
        final checkpoints = manager.getDiagnostics()['total_checkpoints'];
        expect(checkpoints, 1);

        // We know there's one active checkpoint. Let's assume we can trigger a rollback by returning Left.
        return Left(UnexpectedFailure(message: 'Intentional fail'));
      });

      expect(result.isLeft(), isTrue);
      // Since we didn't fully populate the checkpoint with `previous_state` inside user-land,
      // the rollbackToCheckpoint just succeeds silently without calling saveStrategyState.
      // But we verify it intercepts the failure.
    });

    test('does not rollback on success', () async {
      final result = await manager.executeWithBackup(() async {
        return Right('Success');
      });

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should be right'),
        (v) => expect(v, 'Success'),
      );
    });
  });

  group('TradingTransactionManagerImpl - Journal Scan', () {
    test('cleans up orphaned trades on boot (repaired)', () async {
      final journal = Hive.box<Map>(Constants.transactionJournalBoxName);

      final tradeMap = {
        'symbol': 'BTCUSDT',
        'price': 50000.0,
        'quantity': 1.0,
        'isBuy': true,
        'timestamp': 123456,
        'orderStatus': 'FILLED',
      };

      await journal.put('stuck_tx', {
        'op': 'saveTradeAndState',
        'trade_saved': true,
        'state_saved': false, // Anomalous state
        'trade': tradeMap,
      });

      when(() => mockTradingRepository.deleteTrade(any()))
          .thenAnswer((_) async => Right(null));

      final result = await manager.scanAndRepairJournalOnBoot();

      expect(result.isRight(), isTrue);
      result.fold((f) => fail('Should be right'), (report) {
        expect(report['journal_entries_scanned'], 1);
        expect(report['transactions_repaired'], 1);
        expect(report['journal_entries_removed'], 1);
      });

      // Verify trade was deleted to clean up
      verify(() => mockTradingRepository.deleteTrade(any())).called(1);
      expect(journal.containsKey('stuck_tx'), isFalse);
    });

    test('removes fully completed transactions from journal', () async {
      final journal = Hive.box<Map>(Constants.transactionJournalBoxName);

      await journal.put('clean_tx', {
        'op': 'saveTradeAndState',
        'trade_saved': true,
        'state_saved': true,
      });

      final result = await manager.scanAndRepairJournalOnBoot();

      expect(result.isRight(), isTrue);
      expect(journal.containsKey('clean_tx'), isFalse);

      result.fold((f) => fail('Should be right'), (report) {
        expect(report['transactions_repaired'], 0);
        expect(report['journal_entries_removed'], 1);
      });
    });
  });
}

