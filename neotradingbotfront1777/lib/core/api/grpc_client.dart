import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:grpc/service_api.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pbgrpc.dart';
import 'package:neotradingbotfront1777/core/api/grpc_channel_factory.dart';
import 'package:neotradingbotfront1777/generated/proto/grpc/health/v1/health.pbgrpc.dart'
    as health;

/// Stato di connessione gRPC esposto al resto dell'app.
enum GrpcConnectionStatus {
  initializing,
  connected,
  unhealthy, // server raggiungibile ma health-check fallisce ripetutamente
  disconnected,
  pinningError,
  error,
}

/// Gestisce il ciclo di vita del client gRPC e del suo canale di comunicazione.
///
/// Questa classe implementa il pattern Singleton per garantire che esista una sola
/// istanza del canale e del client gRPC per tutta la durata dell'applicazione,
/// prevenendo la creazione inefficiente di connessioni multiple.
///
/// Fornisce un punto di accesso centralizzato al `TradingServiceClient` e
/// un metodo `shutdown` per chiudere correttamente la connessione.
class GrpcClientManager {
  // --- Singleton Pattern Implementation ---
  // L'istanza privata e statica.
  static final GrpcClientManager _instance = GrpcClientManager._internal();

  /// Factory constructor che restituisce sempre la stessa istanza.
  factory GrpcClientManager() {
    return _instance;
  }

  /// Costruttore privato utilizzato solo all'interno della classe.
  GrpcClientManager._internal();
  // --- Fine dell'implementazione del Singleton ---

  ClientChannel? _channel;
  TradingServiceClient? _client;
  Completer<void>? _initCompleter;
  final _statusController = StreamController<GrpcConnectionStatus>.broadcast();
  GrpcConnectionStatus _currentStatus = GrpcConnectionStatus.disconnected;

  Stream<GrpcConnectionStatus> get statusStream => _statusController.stream;
  GrpcConnectionStatus get currentStatus => _currentStatus;
  void _emit(GrpcConnectionStatus s) {
    _currentStatus = s;
    try {
      _statusController.add(s);
    } catch (e) {
      debugPrint('[GrpcClient] Failed to emit status $s: $e');
    }
  }

  /// Espone il canale per client ausiliari (es. HealthClient)
  ClientChannel get channel {
    if (_channel == null) {
      throw StateError(
        'Il canale gRPC non è stato inizializzato. Chiamare initialize() prima di accedere al canale.',
      );
    }
    return _channel!;
  }

  /// L'istanza del client gRPC.
  ///
  /// Lancia un'eccezione `StateError` se il client non è stato prima inizializzato
  /// tramite la chiamata al metodo `initialize()`.
  TradingServiceClient get client {
    if (_client == null || _channel == null) {
      throw StateError(
        'Il client gRPC non è stato inizializzato. Chiamare il metodo `initialize()` prima di accedere al client.',
      );
    }
    return _client!;
  }

  /// Inizializza il canale e il client gRPC.
  ///
  /// Questo metodo deve essere chiamato una sola volta all'avvio dell'applicazione
  /// (es. nel suo file `main.dart`).
  ///
  /// [host]: L'indirizzo del server gRPC (dovrebbe provenire da un file di configurazione).
  /// [port]: La porta del server gRPC (dovrebbe provenire da un file di configurazione).
  /// [secure]: Se `true`, utilizza una connessione sicura (TLS/SSL).
  ///          Per massimizzare la sicurezza, il default è `true` per le build di
  ///          rilascio (`kReleaseMode`) e `false` per quelle di debug.
  Future<void> initialize({
    required String host,
    required int port,
    bool? secure,
    String? certAssetPath,
    List<ClientInterceptor>? interceptors,
  }) async {
    // Previene reinizializzazioni multiple con Completer-based lock.
    // Se un'inizializzazione è già in corso, attende il completamento.
    if (_initCompleter != null) {
      debugPrint(
        'Avviso: il GrpcClientManager è già in fase di inizializzazione o inizializzato.',
      );
      await _initCompleter!.future;
      return;
    }
    _initCompleter = Completer<void>();
    _emit(GrpcConnectionStatus.initializing);

    // Principio "Security by Design": connessione sicura OBBLIGATORIA in release.
    // In debug è possibile consentire INSECURE solo con flag esplicito.
    const allowInsecure = bool.fromEnvironment(
      'GRPC_ALLOW_INSECURE',
      defaultValue: false,
    );
    bool useSecureConnection;
    if (kReleaseMode) {
      useSecureConnection = true; // hard-enforce TLS in release
    } else {
      useSecureConnection = secure ?? (!allowInsecure);
    }

    debugPrint('gRPC init: $host:$port, secure=$useSecureConnection');

    try {
      List<int>? certBytes;
      if (useSecureConnection) {
        final effectiveCertAssetPath =
            certAssetPath ??
            const String.fromEnvironment(
              'GRPC_TLS_CERT_ASSET',
              defaultValue: '',
            );
        const certBase64 = String.fromEnvironment(
          'GRPC_TLS_CERT_B64',
          defaultValue: '',
        );

        if (effectiveCertAssetPath.isNotEmpty) {
          try {
            final data = await rootBundle.load(effectiveCertAssetPath);
            certBytes = data.buffer.asUint8List();
          } catch (e) {
            debugPrint('Impossibile caricare certificato da asset: $e');
          }
        } else if (certBase64.isNotEmpty) {
          try {
            certBytes = const Base64Decoder().convert(certBase64);
          } catch (e) {
            debugPrint('Impossibile decodificare certificato base64: $e');
          }
        }
      }

      const serverName = String.fromEnvironment(
        'GRPC_TLS_SERVER_NAME',
        defaultValue: '',
      );
      const expectedSubject = String.fromEnvironment(
        'TLS_SUBJECT',
        defaultValue: '',
      );
      const expectedIssuer = String.fromEnvironment(
        'TLS_ISSUER',
        defaultValue: '',
      );

      _channel = GrpcChannelFactory.instance.createChannel(
        host: host,
        port: port,
        secure: useSecureConnection,
        certificates: certBytes,
        authority: serverName.isNotEmpty ? serverName : null,
        expectedSubject: expectedSubject,
        expectedIssuer: expectedIssuer,
        strictTlsMatch: const bool.fromEnvironment(
          'TLS_STRICT_SUBJECT_ISSUER',
          defaultValue: false,
        ),
      );
    } catch (e) {
      _emit(GrpcConnectionStatus.error);
      debugPrint('[gRPC] Errore inizializzazione canale: $e');
      rethrow;
    }

    _client = TradingServiceClient(_channel!, interceptors: interceptors);

    // Health-check con backoff esponenziale (best-effort): non blocca l'app se fallisce
    try {
      final isHealthy = await _waitForHealth(maxAttempts: 5);
      _emit(
        isHealthy
            ? GrpcConnectionStatus.connected
            : GrpcConnectionStatus.unhealthy,
      );
      if (!isHealthy) {
        debugPrint('Avviso: health-check gRPC non riuscito. Stato=unhealthy');
      }
    } catch (e) {
      _emit(GrpcConnectionStatus.error);
      debugPrint('Health-check gRPC ha generato un errore inatteso: $e');
    }

    _initCompleter?.complete();
  }

  /// Chiude il canale gRPC e rilascia tutte le risorse di rete associate.
  ///
  /// Questo metodo dovrebbe essere chiamato quando l'applicazione viene terminata
  /// per garantire una chiusura pulita della connessione.
  Future<void> shutdown() async {
    debugPrint('gRPC chiusura canale...');
    await _channel?.shutdown();
    _channel = null;
    _client = null;
    _initCompleter = null;
    debugPrint('gRPC chiuso.');
    _emit(GrpcConnectionStatus.disconnected);
  }

  // ------------------ Private helpers ------------------
  Future<bool> _waitForHealth({int maxAttempts = 5}) async {
    if (_channel == null) return false;
    final healthClient = health.HealthClient(_channel!);
    var attempt = 0;
    var delayMs = 200;
    while (attempt < maxAttempts) {
      attempt++;
      try {
        await healthClient.check(
          health.HealthCheckRequest(),
          options: CallOptions(timeout: const Duration(seconds: 2)),
        );
        return true;
      } catch (e) {
        debugPrint('[GrpcClient] Health check attempt $attempt failed: $e');
        await Future.delayed(Duration(milliseconds: delayMs));
        delayMs = (delayMs * 2).clamp(200, 5000);
      }
    }
    return false;
  }

  void dispose() {
    _statusController.close();
  }

  /// Resetta lo stato interno per il testing.
  /// NON usare in codice di produzione.
  @visibleForTesting
  void resetForTesting() {
    _channel = null;
    _client = null;
    _initCompleter = null;
    _currentStatus = GrpcConnectionStatus.disconnected;
  }
}
