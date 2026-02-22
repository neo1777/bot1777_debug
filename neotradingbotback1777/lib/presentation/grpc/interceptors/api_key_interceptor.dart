import 'dart:async';

// [AUDIT-PHASE-11] - Final Convergence & Security Audit Marker
import 'package:grpc/grpc.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:neotradingbotback1777/core/utils/token_bucket.dart';
import 'package:neotradingbotback1777/core/config/env_config.dart';

/// Header che il client deve inviare con la API key.
const String _apiKeyHeader = 'x-api-key';

/// La API key attesa, letta una sola volta da `GRPC_API_KEY`.
/// Se non configurata, `_expectedKey` è `null` e l'interceptor è disabilitato.
final String? _expectedKey = EnvConfig().get('GRPC_API_KEY');

/// `true` se `GRPC_API_KEY` è configurata e non vuota.
final bool _authEnabled = _expectedKey != null && _expectedKey!.isNotEmpty;

/// Global Rate Limiter: 50 req burst, 10 req/s refill.
/// Sufficiente per uso normale, protegge da loop accidentali o scan aggressivi.
final _rateLimiter = TokenBucket(capacity: 50, refillRate: 10.0);

/// Interceptor gRPC che valida il header `x-api-key`.
///
/// - Se `GRPC_API_KEY` non è settata → interceptor disabilitato, tutte le richieste passano.
/// - Se `GRPC_API_KEY` è settata → ogni richiesta deve avere `x-api-key: <valore>` nel metadata.
///
/// Per abilitare:
/// ```bash
/// GRPC_API_KEY=my-secret-key dart run
/// ```
FutureOr<GrpcError?> apiKeyInterceptor(ServiceCall call, ServiceMethod method) {
  // Rate Limiting Check (Global)
  if (!_rateLimiter.tryConsume()) {
    final log = LogManager.getLogger();
    log.w('[RATE-LIMIT] Troppe richieste gRPC rilevate. Richiesta rifiutata.');
    throw GrpcError.resourceExhausted(
        'Rate limit exceeded. Riprova più tardi.');
  }

  if (!_authEnabled) return null;

  final clientKey = call.clientMetadata?[_apiKeyHeader];

  if (clientKey == null || clientKey != _expectedKey) {
    final log = LogManager.getLogger();
    log.w(
      '[AUTH] Richiesta rifiutata per ${method.name}: '
      'API key ${clientKey == null ? "mancante" : "non valida"}.',
    );
    throw GrpcError.unauthenticated(
      'API key mancante o non valida. '
      'Fornire header "$_apiKeyHeader" con chiave corretta.',
    );
  }

  return null;
}

/// Log iniziale sullo stato dell'auth. Da chiamare all'avvio del server.
void logApiKeyAuthStatus() {
  final log = LogManager.getLogger();
  if (_authEnabled) {
    log.i('[AUTH] API Key auth ATTIVA. '
        'Le richieste devono includere header "$_apiKeyHeader".');
  } else {
    log.w(
      '[AUTH] ⚠️  GRPC_API_KEY non configurata — '
      'autenticazione API disabilitata. '
      'Chiunque raggiunga la porta gRPC può controllare il bot. '
      'Impostare GRPC_API_KEY per proteggere il server.',
    );
  }
}
