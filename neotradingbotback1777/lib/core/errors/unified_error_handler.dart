import 'dart:async';
import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';
// ignore: deprecated_member_use
import 'package:neotradingbotback1777/core/errors/error_handler.dart';
import 'package:logger/logger.dart';

/// Gestore unificato degli errori che standardizza l'uso di `Either<Failure, Success>`
/// attraverso tutti i layer dell'applicazione
class UnifiedErrorHandler {
  // ignore: deprecated_member_use_from_same_package
  final ErrorHandler _errorHandler;
  final Logger _log;

  // Logger statico per la gestione centralizzata delle eccezioni non gestite.
  static final Logger _staticLog = LogManager.getLogger();

  UnifiedErrorHandler({
    // ignore: deprecated_member_use_from_same_package
    ErrorHandler? errorHandler,
    Logger? logger,
    // ignore: deprecated_member_use_from_same_package
  })  : _errorHandler = errorHandler ?? ErrorHandler(),
        _log = logger ?? LogManager.getLogger();

  /// Gestisce e logga un'eccezione non gestita (metodo statico di convenienza).
  ///
  /// [context]: Dove si è verificato l'errore (es. nome classe/funzione).
  /// [error]: L'oggetto Exception o Error catturato.
  /// [stackTrace]: Lo stack trace associato.
  static void handleError(
    String context,
    dynamic error, [
    StackTrace? stackTrace,
  ]) {
    _staticLog.e(
      'Eccezione non gestita in "$context"',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Gestisce un'operazione asincrona con `Either<Failure, Success>`
  Future<Either<Failure, T>> handleAsyncOperation<T>(
    Future<T> Function() operation, {
    T? fallbackValue,
    bool logError = true,
    String? operationName,
  }) async {
    try {
      final result = await operation();
      return Right(result);
    } catch (e, stackTrace) {
      if (logError) {
        final context = operationName != null ? ' [$operationName]' : '';
        _log.e('Async operation failed$context: $e', stackTrace: stackTrace);
      }

      if (fallbackValue != null) {
        return Right(fallbackValue);
      }

      return Left(_mapExceptionToFailure(e, operationName));
    }
  }

  /// Gestisce un'operazione sincrona con `Either<Failure, Success>`
  Either<Failure, T> handleSyncOperation<T>(
    T Function() operation, {
    T? fallbackValue,
    bool logError = true,
    String? operationName,
  }) {
    try {
      final result = operation();
      return Right(result);
    } catch (e, stackTrace) {
      if (logError) {
        final context = operationName != null ? ' [$operationName]' : '';
        _log.e('Sync operation failed$context: $e', stackTrace: stackTrace);
      }

      if (fallbackValue != null) {
        return Right(fallbackValue);
      }

      return Left(_mapExceptionToFailure(e, operationName));
    }
  }

  /// Gestisce un'operazione di rete con retry e circuit breaker
  Future<Either<Failure, T>> handleNetworkOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
    String? operationName,
  }) async {
    return await _errorHandler.handleNetworkOperation(
      operation,
      maxRetries: maxRetries,
      retryDelay: retryDelay,
    );
  }

  /// Gestisce un'operazione di validazione
  Either<Failure, T> handleValidation<T>(
    T Function() operation,
    String fieldName, {
    String? operationName,
  }) {
    return _errorHandler.handleValidation(operation, fieldName);
  }

  /// Gestisce un'operazione di business logic
  Either<Failure, T> handleBusinessLogic<T>(
    T Function() operation,
    String operationName,
  ) {
    return _errorHandler.handleBusinessLogic(operation, operationName);
  }

  /// Gestisce un'operazione di persistenza
  Future<Either<Failure, T>> handlePersistenceOperation<T>(
    Future<T> Function() operation,
    String entityName, {
    String? operationName,
  }) async {
    return await _errorHandler.handlePersistenceOperation(
        operation, entityName);
  }

  /// Gestisce un'operazione di trading critica
  Future<Either<Failure, T>> handleTradingOperation<T>(
    Future<T> Function() operation, {
    String? operationName,
    bool allowRetry = true,
    int maxRetries = 2,
  }) async {
    if (allowRetry && maxRetries > 0) {
      return await _handleWithRetry(
        operation,
        maxRetries: maxRetries,
        operationName: operationName,
      );
    }

    return await handleAsyncOperation(
      operation,
      operationName: operationName,
    );
  }

  /// Gestisce un'operazione con retry per operazioni critiche
  Future<Either<Failure, T>> _handleWithRetry<T>(
    Future<T> Function() operation, {
    required int maxRetries,
    String? operationName,
  }) async {
    int attempts = 0;
    Exception? lastException;

    while (attempts < maxRetries) {
      attempts++;

      try {
        final result = await operation();
        if (attempts > 1) {
          _log.i(
              'Operation succeeded on attempt $attempts${operationName != null ? ' [$operationName]' : ''}');
        }
        return Right(result);
      } catch (e, stackTrace) {
        lastException = e is Exception ? e : Exception(e.toString());

        if (attempts < maxRetries) {
          final delay = Duration(milliseconds: 500 * attempts);
          _log.w(
              'Operation failed on attempt $attempts${operationName != null ? ' [$operationName]' : ''}, retrying in ${delay.inMilliseconds}ms: $e');
          await Future.delayed(delay);
        } else {
          _log.e(
              'Operation failed after $maxRetries attempts${operationName != null ? ' [$operationName]' : ''}: $e',
              stackTrace: stackTrace);
        }
      }
    }

    return Left(_mapExceptionToFailure(lastException, operationName));
  }

  /// Mappa un'eccezione a un Failure specifico
  Failure _mapExceptionToFailure(dynamic exception, String? operationName) {
    if (exception is Failure) {
      return exception;
    }

    final context = operationName != null ? ' in $operationName' : '';

    if (exception is FormatException) {
      return ValidationFailure(
        message: 'Invalid format$context: ${exception.message}',
        code: 'FORMAT_ERROR',
        details: {'operation': operationName, 'error': exception.toString()},
      );
    }

    if (exception is ArgumentError) {
      return ValidationFailure(
        message: 'Invalid argument$context: ${exception.message}',
        code: 'ARGUMENT_ERROR',
        details: {'operation': operationName, 'error': exception.toString()},
      );
    }

    if (exception is StateError) {
      return BusinessLogicFailure(
        message: 'Invalid state$context: ${exception.message}',
        code: 'STATE_ERROR',
        details: {'operation': operationName, 'error': exception.toString()},
      );
    }

    if (exception is TimeoutException) {
      return NetworkFailure(
        message: 'Operation timeout$context',
        code: 'TIMEOUT_ERROR',
        details: {'operation': operationName, 'error': exception.toString()},
      );
    }

    if (exception is SocketException) {
      return NetworkFailure(
        message: 'Network connection error$context: ${exception.message}',
        code: 'CONNECTION_ERROR',
        details: {'operation': operationName, 'error': exception.toString()},
      );
    }

    return UnexpectedFailure(
      message: 'Unexpected error$context: ${exception.toString()}',
      code: 'UNEXPECTED_ERROR',
      details: {'operation': operationName, 'error': exception.toString()},
    );
  }

  /// Combina più risultati Either
  Either<Failure, List<T>> combineResults<T>(
    List<Either<Failure, T>> results, {
    String? operationName,
  }) {
    return _errorHandler.combineResults(results);
  }

  /// Esegue un'operazione con fallback
  Future<Either<Failure, T>> executeWithFallback<T>(
    Future<Either<Failure, T>> Function() primaryOperation,
    Future<Either<Failure, T>> Function() fallbackOperation, {
    String? operationName,
  }) async {
    return await _errorHandler.executeWithFallback(
      primaryOperation,
      fallbackOperation,
    );
  }

  /// Valida un risultato Either
  bool isValidResult<T>(Either<Failure, T> result) {
    return _errorHandler.isValidResult(result);
  }

  /// Estrae il valore da un risultato Either o lancia un'eccezione
  T extractValue<T>(Either<Failure, T> result) {
    return _errorHandler.extractValue(result);
  }

  /// Estrae il valore da un risultato Either con valore di default
  T extractValueOrDefault<T>(Either<Failure, T> result, T defaultValue) {
    return _errorHandler.extractValueOrDefault(result, defaultValue);
  }
}

/// Singleton per l'error handler unificato globale
class GlobalUnifiedErrorHandler {
  static final UnifiedErrorHandler _instance = UnifiedErrorHandler();

  static UnifiedErrorHandler get instance => _instance;

  /// Gestisce un'operazione asincrona globale
  static Future<Either<Failure, T>> handleAsyncOperation<T>(
    Future<T> Function() operation, {
    T? fallbackValue,
    bool logError = true,
    String? operationName,
  }) {
    return _instance.handleAsyncOperation(
      operation,
      fallbackValue: fallbackValue,
      logError: logError,
      operationName: operationName,
    );
  }

  /// Gestisce un'operazione di trading critica globale
  static Future<Either<Failure, T>> handleTradingOperation<T>(
    Future<T> Function() operation, {
    String? operationName,
    bool allowRetry = true,
    int maxRetries = 2,
  }) {
    return _instance.handleTradingOperation(
      operation,
      operationName: operationName,
      allowRetry: allowRetry,
      maxRetries: maxRetries,
    );
  }

  /// Gestisce un'operazione di rete globale
  static Future<Either<Failure, T>> handleNetworkOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
    String? operationName,
  }) {
    return _instance.handleNetworkOperation(
      operation,
      maxRetries: maxRetries,
      retryDelay: retryDelay,
      operationName: operationName,
    );
  }
}
