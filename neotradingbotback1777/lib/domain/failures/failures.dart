import 'package:equatable/equatable.dart';

/// La classe base per tutti i fallimenti (errori gestiti) nell'applicazione.
/// L'uso di una `sealed class` garantisce che ogni tipo di fallimento debba essere
/// gestito esplicitamente nei `when` o `switch`, migliorando la robustezza del codice.
sealed class Failure extends Equatable {
  final String message;
  // Codice opzionale per classificare il tipo di failure (es. DUST_UNSELLABLE)
  final String? code;
  // Metadati opzionali strutturati per diagnosi/azioni (key-value JSON-safe)
  final Map<String, Object?>? details;

  const Failure({required this.message, this.code, this.details});

  @override
  List<Object> get props => [message, code ?? '', details ?? const {}];
}

/// Rappresenta un fallimento durante la comunicazione con un server o API esterna.
/// Esempi: risposta HTTP 500, 401, 403, o errori specifici dell'API di Binance.
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure(
      {required super.message, this.statusCode, super.code, super.details});

  @override
  List<Object> get props => [message, statusCode ?? 0];
}

/// Rappresenta un fallimento durante l'interazione con la cache locale (Hive).
/// Esempi: errore di scrittura, lettura, o corruzione dei dati.
class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code, super.details});
}

/// Rappresenta un fallimento a livello di connettività di rete.
/// Esempi: assenza di connessione internet, problemi DNS.
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.code, super.details});
}

/// Rappresenta un fallimento dovuto a input non validi.
/// Esempio: un simbolo non valido fornito in una richiesta gRPC.
class ValidationFailure extends Failure {
  final dynamic originalError;

  const ValidationFailure({
    required super.message,
    super.code,
    super.details,
    this.originalError,
  });

  @override
  List<Object> get props =>
      [message, code ?? '', details ?? const {}, originalError ?? ''];
}

/// Un fallimento generico per errori inaspettati e non catturati
/// dalle altre categorie. Funge da "catch-all".
class UnexpectedFailure extends Failure {
  final dynamic originalError;
  final StackTrace? stackTrace;

  const UnexpectedFailure({
    required super.message,
    super.code,
    super.details,
    this.originalError,
    this.stackTrace,
  });

  @override
  List<Object> get props => [
        message,
        code ?? '',
        details ?? const {},
        originalError ?? '',
        stackTrace ?? ''
      ];
}

/// Rappresenta un fallimento nella logica di business dell'applicazione.
/// Esempio: saldo insufficiente per avviare una strategia.
class BusinessLogicFailure extends Failure {
  const BusinessLogicFailure(
      {required super.message, super.code, super.details});
}

/// Rappresenta un fallimento di timeout durante operazioni che richiedono tempo.
class TimeoutFailure extends Failure {
  final Duration? timeoutDuration;
  final dynamic originalError;

  const TimeoutFailure({
    required super.message,
    super.code,
    super.details,
    this.timeoutDuration,
    this.originalError,
  });

  @override
  List<Object> get props => [
        message,
        code ?? '',
        details ?? const {},
        timeoutDuration ?? Duration.zero,
        originalError ?? ''
      ];
}

/// Rappresenta un fallimento specifico per operazioni di trading.
class TradingFailure extends Failure {
  final String? symbol;
  final String? operation;
  final dynamic originalError;

  const TradingFailure({
    required super.message,
    super.code,
    super.details,
    this.symbol,
    this.operation,
    this.originalError,
  });

  @override
  List<Object> get props => [
        message,
        code ?? '',
        details ?? const {},
        symbol ?? '',
        operation ?? '',
        originalError ?? ''
      ];
}

/// Rappresenta un fallimento dovuto a saldo insufficiente.
class InsufficientBalanceFailure extends Failure {
  final String? asset;
  final double? requiredAmount;
  final double? availableAmount;
  final dynamic originalError;

  const InsufficientBalanceFailure({
    required super.message,
    super.code,
    super.details,
    this.asset,
    this.requiredAmount,
    this.availableAmount,
    this.originalError,
  });

  @override
  List<Object> get props => [
        message,
        code ?? '',
        details ?? const {},
        asset ?? '',
        requiredAmount ?? 0.0,
        availableAmount ?? 0.0,
        originalError ?? ''
      ];
}

/// Rappresenta un fallimento dovuto al superamento del rate limit.
class RateLimitFailure extends Failure {
  final int? retryAfterSeconds;
  final String? endpoint;
  final dynamic originalError;

  const RateLimitFailure({
    required super.message,
    super.code,
    super.details,
    this.retryAfterSeconds,
    this.endpoint,
    this.originalError,
  });

  @override
  List<Object> get props => [
        message,
        code ?? '',
        details ?? const {},
        retryAfterSeconds ?? 0,
        endpoint ?? '',
        originalError ?? ''
      ];
}

/// Rappresenta un fallimento di rete specifico con dettagli aggiuntivi.
class NetworkFailureDetailed extends Failure {
  final String? endpoint;
  final int? statusCode;
  final dynamic originalError;

  const NetworkFailureDetailed({
    required super.message,
    super.code,
    super.details,
    this.endpoint,
    this.statusCode,
    this.originalError,
  });

  @override
  List<Object> get props => [
        message,
        code ?? '',
        details ?? const {},
        endpoint ?? '',
        statusCode ?? 0,
        originalError ?? ''
      ];
}

/// Factory methods for creating common failure types
extension FailureFactory on Failure {
  /// Create an unexpected failure
  static Failure unexpected({
    required String message,
    String? code,
    Map<String, Object?>? details,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return UnexpectedFailure(
      message: message,
      code: code,
      details: details,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  /// Create a validation failure
  static Failure validation({
    required String message,
    String? code,
    Map<String, Object?>? details,
    dynamic originalError,
  }) {
    return ValidationFailure(
      message: message,
      code: code,
      details: details,
      originalError: originalError,
    );
  }

  /// Create a timeout failure
  static Failure timeout({
    required String message,
    String? code,
    Map<String, Object?>? details,
    Duration? timeoutDuration,
    dynamic originalError,
  }) {
    return TimeoutFailure(
      message: message,
      code: code,
      details: details,
      timeoutDuration: timeoutDuration,
      originalError: originalError,
    );
  }

  /// Create a trading failure
  static Failure tradingError({
    required String message,
    String? code,
    Map<String, Object?>? details,
    String? symbol,
    String? operation,
    dynamic originalError,
  }) {
    return TradingFailure(
      message: message,
      code: code,
      details: details,
      symbol: symbol,
      operation: operation,
      originalError: originalError,
    );
  }

  /// Create an insufficient balance failure
  static Failure insufficientBalance({
    required String message,
    String? code,
    Map<String, Object?>? details,
    String? asset,
    double? requiredAmount,
    double? availableAmount,
    dynamic originalError,
  }) {
    return InsufficientBalanceFailure(
      message: message,
      code: code,
      details: details,
      asset: asset,
      requiredAmount: requiredAmount,
      availableAmount: availableAmount,
      originalError: originalError,
    );
  }

  /// Create a rate limit failure
  static Failure rateLimitExceeded({
    required String message,
    String? code,
    Map<String, Object?>? details,
    int? retryAfterSeconds,
    String? endpoint,
    dynamic originalError,
  }) {
    return RateLimitFailure(
      message: message,
      code: code,
      details: details,
      retryAfterSeconds: retryAfterSeconds,
      endpoint: endpoint,
      originalError: originalError,
    );
  }

  /// Create a network failure
  static Failure networkError({
    required String message,
    String? code,
    Map<String, Object?>? details,
    String? endpoint,
    int? statusCode,
    dynamic originalError,
  }) {
    return NetworkFailureDetailed(
      message: message,
      code: code,
      details: details,
      endpoint: endpoint,
      statusCode: statusCode,
      originalError: originalError,
    );
  }
}
