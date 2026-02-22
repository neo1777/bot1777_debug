/// [AUDIT-PHASE-9] - Formal Audit Marker
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:neotradingbotback1777/core/config/constants.dart';

import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/infrastructure/network/binance/rate_limiter.dart';

/// Client responsabile della comunicazione HTTP di basso livello con Binance.
/// Gestisce firma, rate limiting, sincronizzazione oraria e code di richieste.
class BinanceApiClient {
  String _apiKey;
  String _secretKey;
  final http.Client _httpClient;
  final Logger _log = LogManager.getLogger();
  final Random _random = Random();

  String _baseUrl;
  String _wsBaseUrl;

  int _timeOffset = 0;
  Timer? _timeSyncTimer;

  late final BinanceRateLimiter _rateLimiter;

  // Code richieste per backpressure
  static final int _maxConcurrentOrder = int.tryParse(
          (Platform.environment['BINANCE_MAX_CONCURRENT_ORDER'] ?? '')
              .trim()) ??
      2;
  static final int _maxConcurrentPerNamespace = int.tryParse(
          (Platform.environment['BINANCE_MAX_CONCURRENT_NAMESPACE'] ?? '')
              .trim()) ??
      2;

  int _inFlightInfo = 0;
  int _inFlightOrder = 0;

  final List<Future<http.Response> Function()> _orderQueue = [];

  final Map<String, List<Future<http.Response> Function()>> _namespaceQueues =
      {};
  final Map<String, int> _namespaceInflight = {};

  BinanceApiClient({
    required String apiKey,
    required String secretKey,
    required http.Client httpClient,
    String? baseUrl,
    String? wsBaseUrl,
  })  : _apiKey = apiKey,
        _secretKey = secretKey,
        _httpClient = httpClient,
        _baseUrl = baseUrl ?? Constants.baseUrl,
        _wsBaseUrl = wsBaseUrl ?? Constants.wsBaseUrl {
    _rateLimiter = BinanceRateLimiter.fromEnv();
  }

  void updateConfig({
    required String apiKey,
    required String secretKey,
    required String baseUrl,
    required String wsBaseUrl,
  }) {
    _apiKey = apiKey;
    _secretKey = secretKey;
    _baseUrl = baseUrl;
    _wsBaseUrl = wsBaseUrl;
    _log.i('BinanceApiClient URLs updated: $baseUrl, $wsBaseUrl');
  }

  /// Override per prevenire esposizione accidentale di chiavi API in log/debug.
  @override
  String toString() =>
      'BinanceApiClient(baseUrl: $_baseUrl, apiKey: ${_apiKey.length > 4 ? '${_apiKey.substring(0, 4)}***' : '***'})';

  String get wsBaseUrl => _wsBaseUrl;

  Future<void> initialize() async {
    // Sincronizzazione oraria non bloccante per evitare stalli all'avvio del server gRPC
    unawaited(_synchronizeTime());
    _timeSyncTimer?.cancel();
    _timeSyncTimer =
        Timer.periodic(const Duration(hours: 1), (_) => _synchronizeTime());
  }

  void dispose() {
    _timeSyncTimer?.cancel();
  }

  Future<Either<Failure, http.Response>> sendRequest({
    required String method,
    required String endpoint,
    Map<String, String> params = const {},
    bool isSigned = true,
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    int weight = 1,
  }) async {
    final Map<String, String> mutableParams = Map.of(params);

    // Assicura sincronizzazione oraria prima di richieste signed
    if (isSigned) {
      await _ensureTimeSyncIfNeeded();
    }

    final url = '$_baseUrl$endpoint';
    _log.i(
        '[BinanceApiClient] Sending $method request to: $url (Signed: $isSigned)');
    final isOrderRequest = _isOrderEndpoint(endpoint);

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      // Check rate limiting before making request
      if (!_rateLimiter.canMakeRequest(
          weight: weight, isOrderRequest: isOrderRequest)) {
        final delay = _rateLimiter.getRecommendedDelay();
        _log.w(
            'Rate limit protection: waiting ${delay.inMilliseconds}ms before request');
        await Future.delayed(delay);

        // Recheck after delay
        if (!_rateLimiter.canMakeRequest(
            weight: weight, isOrderRequest: isOrderRequest)) {
          return Left(ServerFailure(
            message: 'Rate limit exceeded, request blocked',
            statusCode: 429,
          ));
        }
      }

      try {
        String fullQueryString = '';
        final headers = <String, String>{'X-MBX-APIKEY': _apiKey};

        if (isSigned) {
          final timestamp = DateTime.now().millisecondsSinceEpoch + _timeOffset;
          mutableParams['timestamp'] = timestamp.toString();

          var recvWindowMs = int.tryParse(
                  (Platform.environment['BINANCE_RECV_WINDOW_MS'] ?? '')
                      .trim()) ??
              5000;

          final original = recvWindowMs;
          if (recvWindowMs < 1000) recvWindowMs = 1000;
          if (recvWindowMs > 60000) recvWindowMs = 60000;

          if (original != recvWindowMs) {
            _log.w(
                'recvWindow clamped to ${recvWindowMs}ms (requested=$original)');
          } else if (recvWindowMs != 5000) {
            _log.w(
                'Using custom recvWindow: ${recvWindowMs}ms (default=5000ms)');
          }

          mutableParams['recvWindow'] = recvWindowMs.toString();

          final queryString = Uri(queryParameters: mutableParams).query;
          final signature = _generateSignature(queryString);
          fullQueryString = '$queryString&signature=$signature';
        } else {
          fullQueryString = Uri(queryParameters: mutableParams).query;
        }

        final uri = Uri.parse('$url?$fullQueryString');

        http.Response response;
        final ns = _namespaceKeyForEndpoint(endpoint);

        if (method == 'POST') {
          response = await _enqueueRequest(
            isOrder: isOrderRequest,
            exec: () => _httpClient
                .post(uri, headers: headers)
                .timeout(Constants.httpTimeout),
            namespace: isOrderRequest ? 'orders' : ns,
          );
        } else if (method == 'PUT') {
          response = await _enqueueRequest(
            isOrder: isOrderRequest,
            exec: () => _httpClient
                .put(uri, headers: headers)
                .timeout(Constants.httpTimeout),
            namespace: isOrderRequest ? 'orders' : ns,
          );
        } else if (method == 'DELETE') {
          response = await _enqueueRequest(
            isOrder: isOrderRequest,
            exec: () => _httpClient
                .delete(uri, headers: headers)
                .timeout(Constants.httpTimeout),
            namespace: isOrderRequest ? 'orders' : ns,
          );
        } else {
          response = await _enqueueRequest(
            isOrder: isOrderRequest,
            exec: () => _httpClient
                .get(uri, headers: headers)
                .timeout(Constants.httpTimeout),
            namespace: isOrderRequest ? 'orders' : ns,
          );
        }

        // Record successful request and update rate limiter from headers
        if (response.statusCode >= 200 && response.statusCode < 300) {
          _rateLimiter.recordRequest(
              weight: weight, isOrderRequest: isOrderRequest);
          _rateLimiter.updateFromHeaders(response.headers);
          return Right(response);
        }

        // Handle rate limiting response
        if (response.statusCode == 429) {
          final retryAfter = response.headers['retry-after'];
          final retryDuration = retryAfter != null
              ? Duration(seconds: int.tryParse(retryAfter) ?? 60)
              : Duration(minutes: 1);

          _rateLimiter.handleRateLimitError(retryAfter: retryDuration);
          _log.w(
              'Rate limited (429) for $endpoint. Waiting $retryDuration before retry...');
          await Future.delayed(retryDuration);
          continue;
        }

        if (response.statusCode >= 500) {
          _log.w(
              'Tentativo ${attempt + 1} fallito per $endpoint con stato ${response.statusCode}. Riprovo...');
          final backoff = initialDelay * pow(2, attempt);
          final jitter = Duration(milliseconds: _random.nextInt(250));
          await Future.delayed(backoff + jitter);
          continue;
        } else {
          _log.e(
              'Errore client non recuperabile per $endpoint: ${response.statusCode} ${response.body}');
          return Left(ServerFailure(
              message: response.body, statusCode: response.statusCode));
        }
      } on TimeoutException {
        if (attempt == maxRetries - 1) {
          return Left(NetworkFailure(
              message: 'Timeout della richiesta dopo $maxRetries tentativi.'));
        }
      } on SocketException catch (e) {
        return Left(NetworkFailure(
            message:
                'Errore di rete: ${e.message}. Controlla la connessione.'));
      } catch (e) {
        return Left(
            UnexpectedFailure(message: 'Errore generico inaspettato: $e'));
      }
    }

    return Left(NetworkFailure(
        message:
            'Falliti tutti i $maxRetries tentativi di richiesta a $endpoint.'));
  }

  Future<void> _ensureTimeSyncIfNeeded() async {
    if (_timeOffset == 0) {
      await _synchronizeTime();
    }
  }

  Future<void> _synchronizeTime() async {
    try {
      final response =
          await _httpClient.get(Uri.parse('$_baseUrl/api/v3/time'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final serverTime = data['serverTime'] as int;
        _timeOffset = serverTime - DateTime.now().millisecondsSinceEpoch;
        _log.d('Orario sincronizzato con Binance. Offset: $_timeOffset ms.');
      } else {
        _log.e(
            'Impossibile sincronizzare l\'orario con Binance. Stato: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      _log.e('BinanceApiClient._synchronizeTime failed',
          error: e, stackTrace: stackTrace);
      _timeOffset = 0;
    }
  }

  String _generateSignature(String data) {
    final key = utf8.encode(_secretKey);
    final bytes = utf8.encode(data);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    return digest.toString();
  }

  String _namespaceKeyForEndpoint(String endpoint) {
    try {
      final parts = endpoint.split('/').where((e) => e.isNotEmpty).toList();
      if (parts.length >= 3) {
        return parts[2];
      }
      return 'default';
    } catch (_) {
      return 'default';
    }
  }

  bool _isOrderEndpoint(String endpoint) {
    final path = endpoint;
    final orderSegment = RegExp(r'(^|/)order($|[/?])', caseSensitive: false);
    return orderSegment.hasMatch(path);
  }

  Future<http.Response> _enqueueRequest({
    required bool isOrder,
    required Future<http.Response> Function() exec,
    String namespace = 'default',
  }) async {
    final completer = Completer<http.Response>();
    task() async {
      try {
        final resp = await exec();
        completer.complete(resp);
        return resp;
      } catch (e, s) {
        completer.completeError(e, s);
        // Preveniamo crash della microtask queue: l'errore è già nel Completer
        return Future.value(http.Response('', 500));
      } finally {
        if (isOrder) {
          _inFlightOrder = (_inFlightOrder - 1).clamp(0, 1 << 30);
          _tryDequeue(isOrder: true);
        } else {
          _inFlightInfo = (_inFlightInfo - 1).clamp(0, 1 << 30);
          _namespaceInflight[namespace] =
              (_namespaceInflight[namespace] ?? 1) - 1;
          if (_namespaceInflight[namespace]! < 0) {
            _namespaceInflight[namespace] = 0;
          }
          _tryDequeue(isOrder: false, namespace: namespace);
        }
      }
    }

    if (!isOrder) {
      _namespaceQueues.putIfAbsent(namespace, () => []);
      _namespaceInflight.putIfAbsent(namespace, () => 0);
      if (_namespaceInflight[namespace]! < _maxConcurrentPerNamespace) {
        _namespaceInflight[namespace] = _namespaceInflight[namespace]! + 1;
        scheduleMicrotask(() {
          task();
        });
      } else {
        _namespaceQueues[namespace]!.add(task);
      }
      return completer.future;
    }

    if (_inFlightOrder < _maxConcurrentOrder) {
      _inFlightOrder++;
      scheduleMicrotask(() {
        task();
      });
    } else {
      _orderQueue.add(task);
    }

    return completer.future;
  }

  void _tryDequeue({required bool isOrder, String namespace = 'default'}) {
    if (isOrder) {
      if (_orderQueue.isNotEmpty && _inFlightOrder < _maxConcurrentOrder) {
        final next = _orderQueue.removeAt(0);
        _inFlightOrder++;
        scheduleMicrotask(() {
          next();
        });
      }
    } else {
      final q = _namespaceQueues[namespace];
      if (q != null &&
          q.isNotEmpty &&
          _namespaceInflight[namespace]! < _maxConcurrentPerNamespace) {
        final nextNs = q.removeAt(0);
        _namespaceInflight[namespace] = _namespaceInflight[namespace]! + 1;
        scheduleMicrotask(() {
          nextNs();
        });
      }
    }
  }

  Map<String, dynamic> getStatistics() {
    final infoNsInflight = Map<String, int>.from(_namespaceInflight);
    final infoNsQueued = _namespaceQueues.map((k, v) => MapEntry(k, v.length));
    return {
      'rateLimiter': _rateLimiter.getStatistics(),
      'http': {
        'inflight': {
          'info': _inFlightInfo,
          'order': _inFlightOrder,
          'perNamespace': infoNsInflight,
        },
        'queued': {
          'orderQueue': _orderQueue.length,
          'perNamespace': infoNsQueued,
        },
      },
    };
  }
}
