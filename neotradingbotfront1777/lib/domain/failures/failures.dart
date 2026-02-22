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

  const ServerFailure({
    required super.message,
    this.statusCode,
    super.code,
    super.details,
  });

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
  const ValidationFailure({required super.message, super.code, super.details});
}

/// Un fallimento generico per errori inaspettati e non catturati
/// dalle altre categorie. Funge da "catch-all".
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({required super.message, super.code, super.details});
}

/// Rappresenta un fallimento nella logica di business dell'applicazione.
/// Esempio: saldo insufficiente per avviare una strategia.
class BusinessLogicFailure extends Failure {
  const BusinessLogicFailure({
    required super.message,
    super.code,
    super.details,
  });
}

/// Rappresenta un fallimento quando una risorsa richiesta non è stata trovata.
/// Esempio: strategia o simbolo non presente nel backend.
class NotFoundFailure extends Failure {
  const NotFoundFailure({required super.message, super.code, super.details});
}
