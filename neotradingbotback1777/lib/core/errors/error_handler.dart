import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:logger/logger.dart';

/// Gestore centralizzato degli errori per standardizzare la gestione
///
/// Implementa il pattern Either<Failure, Success> in modo consistente
/// attraverso tutti i layer dell'applicazione
///
/// **DEPRECATO**: Preferire [UnifiedErrorHandler] per nuove implementazioni.
/// Questa classe è mantenuta per retrocompatibilità.
@Deprecated('Use UnifiedErrorHandler instead for new code')
class ErrorHandler {
  final Logger _log;

  ErrorHandler({Logger? logger}) : _log = logger ?? LogManager.getLogger();

  // Logger statico per la gestione centralizzata delle eccezioni non gestite.
  // Compatibilità con il vecchio core/error/ErrorHandler — usato dai layer
  // infrastruttura per loggare errori imprevisti senza convertirli in Failure.
  static final Logger _staticLog = LogManager.getLogger();

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

  /// Gestisce un'operazione che può fallire
  ///
  /// [operation]: Operazione da eseguire
  /// [fallbackValue]: Valore di fallback in caso di errore
  /// [logError]: Se loggare l'errore
  Future<Either<Failure, T>> handleOperation<T>(
    Future<T> Function() operation, {
    T? fallbackValue,
    bool logError = true,
  }) async {
    try {
      final result = await operation();
      return Right(result);
    } catch (e, stackTrace) {
      if (logError) {
        _log.e('Operation failed: $e', stackTrace: stackTrace);
      }

      if (fallbackValue != null) {
        return Right(fallbackValue);
      }

      return Left(_mapExceptionToFailure(e));
    }
  }

  /// Gestisce un'operazione sincrona che può fallire
  Either<Failure, T> handleSyncOperation<T>(
    T Function() operation, {
    T? fallbackValue,
    bool logError = true,
  }) {
    try {
      final result = operation();
      return Right(result);
    } catch (e, stackTrace) {
      if (logError) {
        _log.e('Sync operation failed: $e', stackTrace: stackTrace);
      }

      if (fallbackValue != null) {
        return Right(fallbackValue);
      }

      return Left(_mapExceptionToFailure(e));
    }
  }

  /// Gestisce un'operazione di rete
  Future<Either<Failure, T>> handleNetworkOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        final result = await operation();
        return Right(result);
      } catch (e, stackTrace) {
        attempts++;

        if (attempts >= maxRetries) {
          _log.e('Network operation failed after $maxRetries attempts: $e',
              stackTrace: stackTrace);
          return Left(_mapNetworkExceptionToFailure(e));
        }

        _log.w('Network operation attempt $attempts failed: $e, retrying...');
        await Future.delayed(retryDelay * attempts);
      }
    }

    return Left(NetworkFailure(message: 'Max retries exceeded'));
  }

  /// Gestisce un'operazione di validazione
  Either<Failure, T> handleValidation<T>(
    T Function() operation,
    String fieldName,
  ) {
    try {
      final result = operation();
      return Right(result);
    } catch (e) {
      _log.w('Validation failed for $fieldName: $e');
      return Left(ValidationFailure(
        message: 'Validation failed for $fieldName: $e',
        code: 'VALIDATION_ERROR',
        details: {'field': fieldName, 'error': e.toString()},
      ));
    }
  }

  /// Gestisce un'operazione di business logic
  Either<Failure, T> handleBusinessLogic<T>(
    T Function() operation,
    String operationName,
  ) {
    try {
      final result = operation();
      return Right(result);
    } catch (e, stackTrace) {
      _log.e('Business logic error in $operationName: $e',
          stackTrace: stackTrace);
      return Left(BusinessLogicFailure(
        message: 'Business logic error in $operationName: $e',
        code: 'BUSINESS_LOGIC_ERROR',
        details: {'operation': operationName, 'error': e.toString()},
      ));
    }
  }

  /// Gestisce un'operazione di persistenza
  Future<Either<Failure, T>> handlePersistenceOperation<T>(
    Future<T> Function() operation,
    String entityName,
  ) async {
    try {
      final result = await operation();
      return Right(result);
    } catch (e, stackTrace) {
      _log.e('Persistence error for $entityName: $e', stackTrace: stackTrace);
      return Left(CacheFailure(
        message: 'Persistence error for $entityName: $e',
        code: 'PERSISTENCE_ERROR',
        details: {'entity': entityName, 'error': e.toString()},
      ));
    }
  }

  /// Mappa un'eccezione generica a un Failure specifico
  Failure _mapExceptionToFailure(dynamic exception) {
    if (exception is FormatException) {
      return ValidationFailure(
        message: 'Invalid format: ${exception.message}',
        code: 'FORMAT_ERROR',
        details: {'error': exception.toString()},
      );
    }

    if (exception is ArgumentError) {
      return ValidationFailure(
        message: 'Invalid argument: ${exception.message}',
        code: 'ARGUMENT_ERROR',
        details: {'error': exception.toString()},
      );
    }

    if (exception is StateError) {
      return BusinessLogicFailure(
        message: 'Invalid state: ${exception.message}',
        code: 'STATE_ERROR',
        details: {'error': exception.toString()},
      );
    }

    return UnexpectedFailure(message: exception.toString());
  }

  /// Mappa un'eccezione di rete a un Failure specifico
  Failure _mapNetworkExceptionToFailure(dynamic exception) {
    final message = exception.toString().toLowerCase();

    if (message.contains('timeout')) {
      return NetworkFailure(message: 'Request timeout');
    }

    if (message.contains('connection')) {
      return NetworkFailure(message: 'Connection error');
    }

    if (message.contains('ssl') || message.contains('certificate')) {
      return NetworkFailure(message: 'SSL/TLS error');
    }

    if (message.contains('unauthorized') || message.contains('401')) {
      return ServerFailure(
        message: 'Authentication failed',
        statusCode: 401,
        code: 'AUTHENTICATION_ERROR',
      );
    }

    if (message.contains('forbidden') || message.contains('403')) {
      return ServerFailure(
        message: 'Access forbidden',
        statusCode: 403,
        code: 'AUTHORIZATION_ERROR',
      );
    }

    if (message.contains('not found') || message.contains('404')) {
      return ServerFailure(
        message: 'Resource not found',
        statusCode: 404,
        code: 'NOT_FOUND_ERROR',
      );
    }

    if (message.contains('rate limit') || message.contains('429')) {
      return ServerFailure(
        message: 'Rate limit exceeded',
        statusCode: 429,
        code: 'RATE_LIMIT_ERROR',
      );
    }

    if (message.contains('server error') || message.contains('5')) {
      return ServerFailure(message: 'Server error');
    }

    return NetworkFailure(message: exception.toString());
  }

  /// Combina più risultati Either
  Either<Failure, List<T>> combineResults<T>(
    List<Either<Failure, T>> results,
  ) {
    final failures = <Failure>[];
    final successes = <T>[];

    for (final result in results) {
      result.fold(
        (failure) => failures.add(failure),
        (success) => successes.add(success),
      );
    }

    if (failures.isNotEmpty) {
      return Left(failures.first);
    }

    return Right(successes);
  }

  /// Esegue un'operazione con fallback
  Future<Either<Failure, T>> executeWithFallback<T>(
    Future<Either<Failure, T>> Function() primaryOperation,
    Future<Either<Failure, T>> Function() fallbackOperation,
  ) async {
    final primaryResult = await primaryOperation();

    return primaryResult.fold(
      (failure) async {
        _log.w('Primary operation failed: ${failure.message}, trying fallback');
        return await fallbackOperation();
      },
      (success) => Right(success),
    );
  }

  /// Valida un risultato Either
  bool isValidResult<T>(Either<Failure, T> result) {
    return result.isRight();
  }

  /// Estrae il valore da un risultato Either o lancia un'eccezione
  T extractValue<T>(Either<Failure, T> result) {
    return result.fold(
      (failure) => throw Exception(
          'Cannot extract value from failure: ${failure.message}'),
      (value) => value,
    );
  }

  /// Estrae il valore da un risultato Either con valore di default
  T extractValueOrDefault<T>(Either<Failure, T> result, T defaultValue) {
    return result.fold(
      (failure) => defaultValue,
      (value) => value,
    );
  }
}

/// Singleton per l'error handler globale
///
/// **DEPRECATO**: Preferire [GlobalUnifiedErrorHandler] per nuove implementazioni.
@Deprecated('Use GlobalUnifiedErrorHandler instead for new code')
class GlobalErrorHandler {
  static final ErrorHandler _instance = ErrorHandler();

  static ErrorHandler get instance => _instance;

  /// Gestisce un'operazione globale
  static Future<Either<Failure, T>> handleOperation<T>(
    Future<T> Function() operation, {
    T? fallbackValue,
    bool logError = true,
  }) {
    return _instance.handleOperation(
      operation,
      fallbackValue: fallbackValue,
      logError: logError,
    );
  }

  /// Gestisce un'operazione di rete globale
  static Future<Either<Failure, T>> handleNetworkOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
  }) {
    return _instance.handleNetworkOperation(
      operation,
      maxRetries: maxRetries,
      retryDelay: retryDelay,
    );
  }
}
