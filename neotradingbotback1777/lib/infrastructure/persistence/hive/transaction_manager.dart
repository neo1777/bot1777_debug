import 'dart:async';
import 'package:fpdart/fpdart.dart';
import 'package:hive_ce/hive.dart';
import 'package:mutex/mutex.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';

/// Gestisce transazioni atomiche per operazioni critiche su Hive
class HiveTransactionManager {
  final _log = LogManager.getLogger();
  final _transactionMutex = Mutex();
  final Map<String, dynamic> _backupData = {};

  /// Esegue una transazione atomica con rollback automatico in caso di errore
  Future<Either<Failure, T>> executeTransaction<T>(
    String transactionId,
    Future<T> Function() operation,
    List<TransactionOperation> operations,
  ) async {
    return await _transactionMutex.protect(() async {
      _log.d('Starting transaction: $transactionId');

      try {
        // 1. Backup dei dati esistenti
        await _backupCurrentState(transactionId, operations);

        // 2. Esegui l'operazione
        final result = await operation();

        // 3. Verifica l'integrità del risultato
        final verificationResult =
            await _verifyTransactionResult(transactionId, operations);
        if (verificationResult != null) {
          // Rollback se la verifica fallisce
          await _rollbackTransaction(transactionId, operations);
          return Left(verificationResult);
        }

        // 4. Cleanup del backup se tutto è andato bene
        _cleanupBackup(transactionId);

        _log.d('Transaction completed successfully: $transactionId');
        return Right(result);
      } catch (e, stackTrace) {
        _log.e('Transaction failed: $transactionId - $e',
            error: e, stackTrace: stackTrace);

        // Rollback in caso di errore
        await _rollbackTransaction(transactionId, operations);

        return Left(CacheFailure(
            message: 'Transaction failed: $transactionId - ${e.toString()}'));
      }
    });
  }

  /// Crea un backup dello stato corrente
  Future<void> _backupCurrentState(
      String transactionId, List<TransactionOperation> operations) async {
    final backupKey = 'backup_$transactionId';
    final backup = <String, dynamic>{};

    for (final operation in operations) {
      try {
        final currentValue = operation.box.get(operation.key);
        if (currentValue != null) {
          backup[operation.key] = currentValue;
        }
      } catch (e) {
        _log.w('Failed to backup key ${operation.key}: $e');
      }
    }

    _backupData[backupKey] = backup;
    _log.d('Backup created for transaction: $transactionId');
  }

  /// Verifica l'integrità del risultato della transazione
  Future<Failure?> _verifyTransactionResult(
      String transactionId, List<TransactionOperation> operations) async {
    for (final operation in operations) {
      try {
        final currentValue = operation.box.get(operation.key);

        // Verifica che il valore esista se dovrebbe esistere
        if (operation.shouldExist && currentValue == null) {
          return CacheFailure(
              message:
                  'Verification failed: Expected value for key ${operation.key} not found');
        }

        // Verifica integrità del dato usando il validator se presente
        if (currentValue != null && operation.validator != null) {
          final isValid = operation.validator!(currentValue);
          if (!isValid) {
            return CacheFailure(
                message:
                    'Verification failed: Data integrity check failed for key ${operation.key}');
          }
        }
      } catch (e) {
        return CacheFailure(
            message:
                'Verification failed: Error checking key ${operation.key} - ${e.toString()}');
      }
    }

    return null; // Tutto OK
  }

  /// Esegue il rollback della transazione
  Future<void> _rollbackTransaction(
      String transactionId, List<TransactionOperation> operations) async {
    final backupKey = 'backup_$transactionId';
    final backup = _backupData[backupKey] as Map<String, dynamic>?;

    if (backup == null) {
      _log.w('No backup found for transaction: $transactionId');
      return;
    }

    _log.w('Rolling back transaction: $transactionId');

    for (final operation in operations.reversed) {
      try {
        if (backup.containsKey(operation.key)) {
          // Ripristina il valore originale
          await operation.box.put(operation.key, backup[operation.key]);
          _log.d('Restored key: ${operation.key}');
        } else {
          // Rimuovi la chiave se non esisteva prima
          await operation.box.delete(operation.key);
          _log.d('Removed key: ${operation.key}');
        }
      } catch (e) {
        _log.e('Failed to rollback key ${operation.key}: $e');
      }
    }

    _cleanupBackup(transactionId);
    _log.i('Transaction rolled back: $transactionId');
  }

  /// Pulisce i dati di backup
  void _cleanupBackup(String transactionId) {
    final backupKey = 'backup_$transactionId';
    _backupData.remove(backupKey);
  }

  /// Esegue operazioni multiple in modo atomico
  Future<Either<Failure, void>> executeMultipleOperations(
    String transactionId,
    List<Future<void> Function()> operations,
    List<TransactionOperation> monitoredOperations,
  ) async {
    return await executeTransaction<void>(
      transactionId,
      () async {
        for (final operation in operations) {
          await operation();
        }
      },
      monitoredOperations,
    );
  }
}

/// Rappresenta un'operazione da monitorare in una transazione
class TransactionOperation {
  final Box box;
  final String key;
  final bool shouldExist;
  final bool Function(dynamic value)? validator;

  TransactionOperation({
    required this.box,
    required this.key,
    this.shouldExist = true,
    this.validator,
  });
}

/// Validator predefiniti per diversi tipi di dati
class TransactionValidators {
  static bool Function(dynamic) notNull = (value) => value != null;

  static bool Function(dynamic) isValidSymbol = (value) {
    if (value is! String) return false;
    return value.length >= 3 &&
        value.length <= 20 &&
        value.toUpperCase() == value;
  };

  static bool Function(dynamic) isPositiveNumber = (value) {
    if (value is num) return value > 0;
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed != null && parsed > 0;
    }
    return false;
  };

  static bool Function(dynamic) isValidTimestamp = (value) {
    if (value is! int) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    final oneYearAgo = now - (365 * 24 * 60 * 60 * 1000);
    final oneYearFromNow = now + (365 * 24 * 60 * 60 * 1000);
    return value >= oneYearAgo && value <= oneYearFromNow;
  };
}
