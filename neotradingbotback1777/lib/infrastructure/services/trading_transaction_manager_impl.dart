import 'dart:async';
import 'package:fpdart/fpdart.dart';
import 'package:mutex/mutex.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:neotradingbotback1777/domain/entities/app_trade.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/strategy_state_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/trading_repository_new.dart';
import 'package:neotradingbotback1777/domain/services/trading_transaction_manager.dart';
import 'package:hive_ce/hive.dart';
import 'package:neotradingbotback1777/core/config/constants.dart';
import 'package:neotradingbotback1777/domain/value_objects/amounts.dart';

/// Implementation of [TradingTransactionManager] for coordinating atomic transactions.
///
/// This service manages complex operations that require coordination between
/// different repositories while maintaining data consistency and providing
/// rollback capabilities.
class TradingTransactionManagerImpl implements TradingTransactionManager {
  final TradingRepository _tradingRepository;
  final StrategyStateRepository _strategyStateRepository;
  final _log = LogManager.getLogger();
  final Mutex _transactionMutex = Mutex();

  // Transaction state tracking
  final Map<String, DateTime> _activeTransactions = {};
  final Map<String, Map<String, dynamic>> _checkpoints = {};
  int _transactionCounter = 0;

  TradingTransactionManagerImpl({
    required TradingRepository tradingRepository,
    required StrategyStateRepository strategyStateRepository,
  })  : _tradingRepository = tradingRepository,
        _strategyStateRepository = strategyStateRepository;

  Box<Map>? _journalBox;
  Future<Box<Map>> _getJournalBox() async {
    _journalBox ??= Hive.isBoxOpen(Constants.transactionJournalBoxName)
        ? Hive.box<Map>(Constants.transactionJournalBoxName)
        : await Hive.openBox<Map>(Constants.transactionJournalBoxName);
    return _journalBox!;
  }

  Map<String, dynamic> _toPlainTrade(AppTrade trade) => {
        'symbol': trade.symbol,
        'price': trade.price.toDouble(),
        'quantity': trade.quantity.toDouble(),
        'isBuy': trade.isBuy,
        'timestamp': trade.timestamp,
        'orderStatus': trade.orderStatus,
        'profit': trade.profit?.toDouble(),
      };

  AppTrade _fromPlainTrade(Map<String, dynamic> m) => AppTrade(
        symbol: m['symbol'] as String,
        price: MoneyAmount.fromDouble((m['price'] as num).toDouble()),
        quantity: QuantityAmount.fromDouble((m['quantity'] as num).toDouble()),
        isBuy: m['isBuy'] as bool,
        timestamp: (m['timestamp'] as num).toInt(),
        orderStatus: m['orderStatus'] as String,
        profit: (m['profit'] is num)
            ? MoneyAmount.fromDouble((m['profit'] as num).toDouble())
            : null,
      );

  @override
  Future<Either<Failure, void>> saveTradeAndState(
    AppTrade trade,
    AppStrategyState state,
  ) async {
    final transactionId =
        'trade_state_${++_transactionCounter}_${DateTime.now().millisecondsSinceEpoch}';

    try {
      _log.d('Starting atomic transaction: $transactionId');
      _activeTransactions[transactionId] = DateTime.now();

      final checkpointResult = await createCheckpoint();
      final checkpointId = checkpointResult.fold((_) => null, (id) => id);
      if (checkpointId != null) {
        try {
          final prevStateEither =
              await _strategyStateRepository.getStrategyState(state.symbol);
          final prevState = prevStateEither.fold((_) => null, (s) => s);
          final checkpoint = _checkpoints[checkpointId]!;
          checkpoint['symbol'] = state.symbol;
          checkpoint['previous_state'] = prevState;
          checkpoint['saved_trade'] = null;
        } catch (e, s) {
          _log.w('Failed to populate checkpoint details for $checkpointId: $e',
              stackTrace: s);
        }
      }

      if (checkpointId != null) {
        final journal = await _getJournalBox();
        await journal.put(transactionId, {
          'checkpoint_id': checkpointId,
          'symbol': state.symbol,
          'op': 'saveTradeAndState',
          'trade': _toPlainTrade(trade),
          'trade_saved': false,
          'state_saved': false,
        });
      }

      final saveTradeResult = await _tradingRepository.saveTrade(trade);
      if (saveTradeResult.isLeft()) {
        return Left(saveTradeResult.fold(
            (f) => f, (_) => const UnexpectedFailure(message: 'Unknown')));
      }

      if (checkpointId != null) {
        final checkpoint = _checkpoints[checkpointId];
        if (checkpoint != null) {
          checkpoint['saved_trade'] = _toPlainTrade(trade);
        }
        try {
          final journal = await _getJournalBox();
          final entry =
              Map<String, dynamic>.from(journal.get(transactionId) ?? {});
          entry['trade_saved'] = true;
          await journal.put(transactionId, entry);
        } catch (e, s) {
          _log.w(
              'Failed to update journal for trade_saved ($transactionId): $e',
              stackTrace: s);
        }
      }

      final saveStateResult =
          await _strategyStateRepository.saveStrategyState(state);
      if (saveStateResult.isLeft()) {
        await _tradingRepository.deleteTrade(trade);
        if (checkpointId != null) {
          await rollbackToCheckpoint(checkpointId);
        }
        return Left(saveStateResult.fold(
            (f) => f, (_) => const UnexpectedFailure(message: 'Unknown')));
      }

      if (checkpointId != null) {
        try {
          final journal = await _getJournalBox();
          final entry =
              Map<String, dynamic>.from(journal.get(transactionId) ?? {});
          entry['state_saved'] = true;
          await journal.put(transactionId, entry);
          await journal.delete(transactionId);
        } catch (e, s) {
          _log.w(
              'Failed to update/delete journal for state_saved ($transactionId): $e',
              stackTrace: s);
        }
      }

      _activeTransactions.remove(transactionId);
      return const Right(null);
    } catch (e, s) {
      _activeTransactions.remove(transactionId);
      _log.e('[$transactionId] Unexpected error in atomic transaction: $e',
          stackTrace: s);
      return Left(UnexpectedFailure(message: 'Transaction failed: $e'));
    }
  }

  @override
  Future<Either<Failure, List<T>>> executeAtomically<T>(
    List<Future<Either<Failure, T>> Function()> operations,
  ) async {
    return await _transactionMutex.protect(() async {
      try {
        final results = <T>[];
        for (final op in operations) {
          final res = await op();
          final r = res.fold((f) => null, (v) => v);
          if (r == null) {
            return Left(res.fold(
                (f) => f, (_) => const UnexpectedFailure(message: 'Unknown')));
          }
          results.add(r);
        }
        return Right(results);
      } catch (e, s) {
        _log.e('Unexpected error in atomic operations: $e', stackTrace: s);
        return Left(UnexpectedFailure(message: 'Atomic ops failed: $e'));
      }
    });
  }

  @override
  Future<Either<Failure, T>> executeWithBackup<T>(
    Future<Either<Failure, T>> Function() operation,
  ) async {
    // Semplice wrapper: crea checkpoint, esegue op, rollback su failure
    final checkpoint = await createCheckpoint();
    final checkpointId = checkpoint.fold((_) => null, (id) => id);
    final res = await operation();
    return await res.fold((f) async {
      if (checkpointId != null) {
        await rollbackToCheckpoint(checkpointId);
      }
      return Left(f);
    }, (v) async {
      return Right(v);
    });
  }

  @override
  Future<Either<Failure, void>> rollbackToCheckpoint(
      String checkpointId) async {
    try {
      final checkpoint = _checkpoints[checkpointId];
      if (checkpoint == null) {
        return Left(
            ValidationFailure(message: 'Checkpoint $checkpointId not found'));
      }

      final symbol = checkpoint['symbol'] as String?;
      final previousState = checkpoint['previous_state'] as AppStrategyState?;
      final savedTradePlain =
          checkpoint['saved_trade'] as Map<String, dynamic>?;

      if (savedTradePlain != null) {
        final savedTrade = _fromPlainTrade(savedTradePlain);
        await _tradingRepository.deleteTrade(savedTrade);
      }

      if (symbol != null && previousState != null) {
        await _strategyStateRepository.saveStrategyState(previousState);
      }

      _checkpoints.remove(checkpointId);
      return const Right(null);
    } catch (e, s) {
      _log.e('Error rolling back to checkpoint $checkpointId: $e',
          stackTrace: s);
      return Left(UnexpectedFailure(message: 'Rollback failed: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> createCheckpoint() async {
    try {
      final checkpointId =
          'checkpoint_${DateTime.now().millisecondsSinceEpoch}';
      _checkpoints[checkpointId] = {
        'timestamp': DateTime.now().toIso8601String(),
        'active_transactions': _activeTransactions.length,
        'checkpoint_id': checkpointId,
        'symbol': null,
        'previous_state': null,
        'saved_trade': null,
      };
      return Right(checkpointId);
    } catch (e, s) {
      _log.e('Error creating checkpoint: $e', stackTrace: s);
      return Left(
          UnexpectedFailure(message: 'Failed to create checkpoint: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>>
      validateDataConsistency() async {
    try {
      final stats = <String, dynamic>{
        'active_transactions': _activeTransactions.length,
        'active_checkpoints': _checkpoints.length,
      };
      return Right(stats);
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Validation failed: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>>
      repairDataInconsistencies() async {
    try {
      // Best-effort: al momento nessuna riparazione automatica extra oltre al journal scan (invocabile separatamente)
      return Right({'status': 'noop'});
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Repair failed: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>>
      getTransactionStatistics() async {
    try {
      final stats = <String, dynamic>{
        'total_active_transactions': _activeTransactions.length,
        'total_checkpoints': _checkpoints.length,
        'transaction_counter': _transactionCounter,
        'active_transactions': _activeTransactions.map(
          (id, timestamp) => MapEntry(id, timestamp.toIso8601String()),
        ),
      };
      return Right(stats);
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Stats failed: $e'));
    }
  }

  Map<String, dynamic> getDiagnostics() {
    try {
      final stats = <String, dynamic>{
        'total_active_transactions': _activeTransactions.length,
        'total_checkpoints': _checkpoints.length,
        'transaction_counter': _transactionCounter,
        'active_transactions': _activeTransactions.map(
          (id, timestamp) => MapEntry(id, timestamp.toIso8601String()),
        ),
      };
      return stats;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Scans the transactional journal on boot and attempts best-effort repairs.
  ///
  /// Current strategy:
  /// - For entries with op == 'saveTradeAndState':
  ///   - if trade_saved == true and state_saved == false, delete the saved trade
  ///     and remove the journal entry (rollback to pre-transaction state)
  ///   - all other combinations are either no-op or already consistent; the
  ///     entry is removed to keep the journal clean
  ///
  /// Returns a report with counts of scanned, repaired and anomalies found.
  Future<Either<Failure, Map<String, dynamic>>>
      scanAndRepairJournalOnBoot() async {
    try {
      final journal = await _getJournalBox();
      final keys = journal.keys.toList(growable: false);
      int scanned = 0;
      int repaired = 0;
      int removed = 0;
      int anomalies = 0;

      for (final key in keys) {
        scanned++;
        final dynamic raw = journal.get(key);
        if (raw is! Map) {
          anomalies++;
          await journal.delete(key);
          removed++;
          continue;
        }

        final entry = Map<String, dynamic>.from(raw);
        final String? op = entry['op'] as String?;
        final bool tradeSaved = (entry['trade_saved'] as bool?) ?? false;
        final bool stateSaved = (entry['state_saved'] as bool?) ?? false;

        if (op == 'saveTradeAndState') {
          if (tradeSaved && !stateSaved) {
            try {
              final tradePlain = entry['trade'] as Map<dynamic, dynamic>?;
              if (tradePlain != null) {
                final trade = _fromPlainTrade(Map<String, dynamic>.from(
                    tradePlain.map((k, v) => MapEntry(k.toString(), v))));
                await _tradingRepository.deleteTrade(trade);
                repaired++;
              } else {
                anomalies++;
              }
            } catch (e, s) {
              _log.w('Journal repair: failed to delete trade for $key: $e',
                  stackTrace: s);
              anomalies++;
            } finally {
              await journal.delete(key);
              removed++;
            }
            continue;
          }

          // Other combinations: either nothing was persisted or both were.
          // In both cases, just clean the entry.
          await journal.delete(key);
          removed++;
          continue;
        }

        // Unknown operation: remove to keep journal clean, count anomaly.
        anomalies++;
        await journal.delete(key);
        removed++;
      }

      final report = <String, dynamic>{
        'journal_entries_scanned': scanned,
        'journal_entries_removed': removed,
        'transactions_repaired': repaired,
        'anomalies_detected': anomalies,
      };
      _log.i('[BOOT] Journal scan completed: $report');
      return Right(report);
    } catch (e, s) {
      _log.e('Journal scan/repair failed: $e', stackTrace: s);
      return Left(UnexpectedFailure(message: 'Journal scan failed: $e'));
    }
  }

  void dispose() {
    _activeTransactions.clear();
    _checkpoints.clear();
  }
}
