import 'dart:async';
import 'dart:convert';
import 'package:neotradingbotback1777/core/config/api_keys_config.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:neotradingbotback1777/core/config/constants.dart';

import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:neotradingbotback1777/core/monitoring/business_metrics_monitor.dart';
import 'package:neotradingbotback1777/core/utils/unique_id_generator.dart';
import 'package:neotradingbotback1777/core/utils/json_parser.dart';
import 'package:neotradingbotback1777/core/utils/circuit_breaker.dart';
import 'package:neotradingbotback1777/domain/entities/account_info.dart';
import 'package:neotradingbotback1777/domain/entities/balance.dart';
import 'package:neotradingbotback1777/domain/entities/order_response.dart';
// duplicate removed
import 'package:neotradingbotback1777/domain/entities/ticker_info.dart';
import 'package:neotradingbotback1777/domain/entities/price.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/services/i_trading_api_service.dart';
import 'package:neotradingbotback1777/domain/entities/exchange_info.dart';
import 'package:neotradingbotback1777/domain/entities/kline.dart';
import 'package:neotradingbotback1777/infrastructure/network/websocket/websocket_recovery_manager.dart';
import 'package:neotradingbotback1777/infrastructure/network/binance/client/binance_api_client.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ApiService implements ITradingApiService {
  final BinanceApiClient _apiClient;
  final Logger _log = LogManager.getLogger();
  final BusinessMetricsMonitor _businessMetricsMonitor;

  Timer? _listenKeyKeepAliveTimer;
  int _listenKeyKeepAliveFailures = 0;
  bool _isTestMode = false;

  // --- Costanti Circuit Breaker ---
  static const _orderCBConfig = CircuitBreakerConfig(
    failureThreshold: 3,
    timeout: Duration(minutes: 2),
    successThreshold: 2,
    monitoringWindow: Duration(minutes: 5),
    failureRateThreshold: 0.4,
  );
  static const _infoCBConfig = CircuitBreakerConfig(
    failureThreshold: 5,
    timeout: Duration(minutes: 1),
    successThreshold: 3,
    monitoringWindow: Duration(minutes: 3),
    failureRateThreshold: 0.5,
  );
  static const _accountCBConfig = CircuitBreakerConfig(
    failureThreshold: 4,
    timeout: Duration(minutes: 1, seconds: 30),
    successThreshold: 2,
    monitoringWindow: Duration(minutes: 4),
    failureRateThreshold: 0.45,
  );
  static const _listenKeyKeepAliveDuration = Duration(minutes: 25);

  // Circuit breakers per diversi tipi di operazioni
  late final CircuitBreaker _orderCircuitBreaker;
  late final CircuitBreaker _infoCircuitBreaker;
  late final CircuitBreaker _accountCircuitBreaker;

  StreamController<Either<Failure, double>>? _priceStreamController;
  WebSocketRecoveryManager? _priceStreamManager;
  String? _currentPriceSymbol;
  int _priceListenerCount = 0;

  StreamController<Either<Failure, AccountInfo>>? _accountInfoStreamController;
  WebSocketRecoveryManager? _accountInfoStreamManager;
  int _accountInfoListenerCount = 0;

  final ApiKeysConfig _apiKeysConfig;

  // Cache per ExchangeInfo
  ExchangeInfo? _exchangeInfoCache;
  DateTime? _exchangeInfoCacheTime;
  static const _exchangeInfoCacheTTL = Duration(minutes: 5);

  @override
  bool get isTestMode => _isTestMode;

  ApiService({
    required ApiKeysConfig apiKeysConfig,
    required http.Client httpClient,
    required BusinessMetricsMonitor businessMetricsMonitor,
    bool initialTestMode = false,
  })  : _apiKeysConfig = apiKeysConfig,
        _isTestMode = initialTestMode,
        _businessMetricsMonitor = businessMetricsMonitor,
        _apiClient = BinanceApiClient(
          apiKey: apiKeysConfig.apiKey,
          secretKey: apiKeysConfig.secretKey,
          httpClient: httpClient,
        ) {
    _log.t(
        'ApiService inizializzato con modalità: ${_isTestMode ? "TESTNET" : "REAL"}');
    _initializeCircuitBreakers();
  }

  /// Inizializza i circuit breaker per diversi tipi di operazioni
  void _initializeCircuitBreakers() {
    _orderCircuitBreaker = CircuitBreaker(
      name: 'BinanceOrders',
      config: _orderCBConfig,
    );
    _infoCircuitBreaker = CircuitBreaker(
      name: 'BinanceInfo',
      config: _infoCBConfig,
    );
    _accountCircuitBreaker = CircuitBreaker(
      name: 'BinanceAccount',
      config: _accountCBConfig,
    );
    _log.i('Circuit breakers initialized for Binance API');
  }

  /// Helper generico per estrarre il risultato da un CircuitBreakerResult.
  /// Gestisce type erasure, CB rejection, e logging/metriche.
  Either<Failure, T> _unwrapCircuitBreakerResult<T>(
    CircuitBreakerResult<dynamic> result,
    String operationName,
  ) {
    if (result.rejectedByCircuitBreaker) {
      _log.w('$operationName rejected by circuit breaker: ${result.error}');
      _businessMetricsMonitor.recordNetworkError(
          operationName, 'Circuit breaker rejected');
      return Left(ServerFailure(
        message: '$operationName temporarily unavailable due to API issues',
        statusCode: 503,
      ));
    }
    if (!result.success) {
      _log.e('$operationName failed: ${result.error}');
      _businessMetricsMonitor.recordNetworkError(
          operationName, result.error.toString());
      return Left(ServerFailure(
        message: 'Errore in $operationName: ${result.error}',
        statusCode: 500,
      ));
    }
    final cbResult = result.result;
    if (cbResult is Right) {
      return Right(cbResult.value as T);
    } else if (cbResult is Left) {
      return Left(cbResult.value as Failure);
    }
    _log.e(
        '$operationName: unexpected CB result type: ${cbResult.runtimeType}');
    return Left(ServerFailure(
      message: 'Unexpected result type from $operationName',
      statusCode: 500,
    ));
  }

  @override
  Future<void> initialize() async {
    await _apiClient.initialize();
    _initializeStreams();
  }

  void _initializeStreams() {
    _accountInfoStreamController =
        StreamController<Either<Failure, AccountInfo>>.broadcast(
      onListen: () => _connectToAccountInfoStreamWithRecovery(),
      onCancel: () {
        _accountInfoStreamManager?.disconnect();
      },
    );
  }

  @override
  Future<Either<Failure, OrderResponse>> createOrder({
    required String symbol,
    required double quantity,
    required String side,
    String? clientOrderId,
  }) async {
    const endpoint = '/api/v3/order';

    // Generate unique client order ID for deduplication protection
    final uniqueOrderId =
        clientOrderId ?? UniqueIdGenerator.generateStringId('BOT_${symbol}');

    final params = {
      'symbol': symbol,
      'side': side,
      'type': 'MARKET',
      // La quantità è già formattata a stepSize a monte (use case). Evita fixed-decimal superflui.
      'quantity': _formatQuantityForBinance(quantity),
      'newOrderRespType': 'FULL',
      'newClientOrderId': uniqueOrderId, // Protection against duplicate orders
    };

    // Utilizza il circuit breaker per operazioni di trading
    final stopwatch = Stopwatch()..start();
    final result = await _orderCircuitBreaker.execute(() async {
      final response = await _sendSignedRequest(
          method: 'POST', endpoint: endpoint, params: params, weight: 10);

      return response.fold(
        (failure) {
          // Registra errore di rete
          _businessMetricsMonitor.recordNetworkError(
              'createOrder', failure.message);
          return Left(failure);
        },
        (httpResponse) {
          // Safe JSON parsing
          final jsonResult = JsonParser.safeDecode(httpResponse.body);
          return jsonResult.fold(
            (failure) => Left(failure),
            (data) {
              // Safe OrderResponse parsing
              final orderResult = OrderResponse.fromJson(data);
              return orderResult.fold(
                (error) => Left(ValidationFailure(
                    message: 'Order response parsing failed: $error')),
                (orderResponse) => Right(orderResponse),
              );
            },
          );
        },
      );
    });

    stopwatch.stop();

    // Registra il tempo di esecuzione
    _businessMetricsMonitor.recordOperationDuration(
        'createOrder', stopwatch.elapsed);

    return _unwrapCircuitBreakerResult<OrderResponse>(result, 'createOrder');
  }

  /// Regex pre-compilata per rimozione zeri finali (evita ri-compilazione per ogni ordine).
  static final RegExp _trailingZerosRegex = RegExp(r'0+$');

  /// Converte la quantità in stringa senza forzare una precisione fissa, mantenendo
  /// le cifre significative necessarie ed evitando trailing zeros inutili.
  String _formatQuantityForBinance(double quantity) {
    // Usa un numero elevato di decimali e poi rimuove zeri finali e punto.
    String formattedString = quantity.toStringAsFixed(16);
    if (formattedString.contains('.')) {
      // Rimuove zeri finali dopo la virgola
      formattedString = formattedString.replaceAll(_trailingZerosRegex, '');
      // Rimuove eventuale punto finale
      if (formattedString.endsWith('.')) {
        formattedString =
            formattedString.substring(0, formattedString.length - 1);
      }
    }
    return formattedString.isEmpty ? '0' : formattedString;
  }

  @override
  Future<Either<Failure, AccountInfo>> getAccountInfo() async {
    const endpoint = '/api/v3/account';
    _log.d('ApiService.getAccountInfo() started');

    final stopwatch = Stopwatch()..start();
    final result = await _accountCircuitBreaker.execute(() async {
      final response = await _sendSignedRequest(
          method: 'GET', endpoint: endpoint, weight: 10);
      _log.d(
          'ApiService.getAccountInfo() response type: ${response.runtimeType}');

      return response.fold((failure) {
        _log.e('getAccountInfo failed: ${failure.message}');
        _businessMetricsMonitor.recordNetworkError(
            'getAccountInfo', failure.message);
        return Left(failure);
      }, (httpResponse) {
        // Safe JSON parsing
        final jsonResult = JsonParser.safeDecode(httpResponse.body);
        return jsonResult.fold(
          (failure) => Left(failure),
          (data) {
            final balancesResult =
                JsonParser.safeExtractList<Balance>(data, 'balances', (b) {
              if (b is! Map<String, dynamic>) {
                // Log dell'errore e ritorno di un balance di default per evitare crash
                _log.w(
                    'Balance item non valido: tipo ${b.runtimeType}, atteso Map<String, dynamic>');
                return Balance(asset: '', free: 0.0, locked: 0.0);
              }

              final assetResult = JsonParser.safeExtract<String>(
                  b, 'asset', (v) => v.toString());
              final freeResult = JsonParser.safeParseDouble(b['free'], 'free');
              final lockedResult =
                  JsonParser.safeParseDouble(b['locked'], 'locked');

              if (assetResult.isLeft() ||
                  freeResult.isLeft() ||
                  lockedResult.isLeft()) {
                _log.w(
                    'Dati di balance non validi per asset ${b['asset']}: assetResult=${assetResult.isLeft()}, freeResult=${freeResult.isLeft()}, lockedResult=${lockedResult.isLeft()}');
                return Balance(asset: '', free: 0.0, locked: 0.0);
              }

              return Balance(
                asset: assetResult.getOrElse((_) => ''),
                free: freeResult.getOrElse((_) => 0.0),
                locked: lockedResult.getOrElse((_) => 0.0),
              );
            });

            return balancesResult.fold(
              (failure) => Left(failure),
              (balances) {
                _log.d('getAccountInfo: balances=${balances.length}');
                return Right(AccountInfo(balances: balances));
              },
            );
          },
        );
      });
    });

    stopwatch.stop();

    // Registra il tempo di esecuzione
    _businessMetricsMonitor.recordOperationDuration(
        'getAccountInfo', stopwatch.elapsed);

    return _unwrapCircuitBreakerResult<AccountInfo>(result, 'getAccountInfo');
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getOpenOrders(
      String symbol) async {
    const endpoint = '/api/v3/openOrders';
    final params = {'symbol': symbol};
    _log.d('getOpenOrders: started for $symbol');

    try {
      final response = await _sendSignedRequest(
          method: 'GET', endpoint: endpoint, params: params);
      return response.fold(
        (failure) {
          _log.e('getOpenOrders failed for $symbol: ${failure.message}');
          return Left(failure);
        },
        (httpResponse) {
          final jsonResult = JsonParser.safeDecodeList(httpResponse.body);
          return jsonResult.fold(
            (failure) => Left(failure),
            (data) {
              _log.d('getOpenOrders: count=${data.length} for $symbol');
              return Right(data.cast<Map<String, dynamic>>());
            },
          );
        },
      );
    } catch (e) {
      _log.f('getOpenOrders critical exception: $e');
      return Left(
          ServerFailure(message: 'Errore imprevisto in getOpenOrders: $e'));
    }
  }

  Future<Either<Failure, http.Response>> _sendSignedRequest({
    required String method,
    required String endpoint,
    Map<String, String> params = const {},
    bool isSigned = true,
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    int weight = 1,
  }) {
    return _apiClient.sendRequest(
      method: method,
      endpoint: endpoint,
      params: params,
      isSigned: isSigned,
      maxRetries: maxRetries,
      initialDelay: initialDelay,
      weight: weight,
    );
  }

  @override
  Stream<Either<Failure, double>> subscribeToPriceStream(String symbol) {
    _currentPriceSymbol = symbol;

    // Create controller with lifecycle: connect on first listener, disconnect on last cancel
    _priceStreamController ??=
        StreamController<Either<Failure, double>>.broadcast(
      onListen: () async {
        try {
          if (_priceStreamManager == null && _currentPriceSymbol != null) {
            await _connectToPriceStreamWithRecovery(_currentPriceSymbol!);
          } else if (_priceStreamManager != null &&
              !_priceStreamManager!.isConnected) {
            await _priceStreamManager!.connect();
          }
        } catch (e, st) {
          _log.w('Failed to start price stream on listen: $e', stackTrace: st);
        }
      },
      onCancel: () async {
        try {
          // When the last subscriber cancels, disconnect the WS and release resources
          await _priceStreamManager?.disconnect();
          await _priceStreamManager?.dispose();
        } catch (e) {
          _log.w('Error while disposing price WS manager: $e');
        } finally {
          _priceStreamManager = null;
          _currentPriceSymbol = null;
          try {
            await _priceStreamController?.close();
          } catch (e) {
            _log.d('Ignored error closing price stream controller: $e');
          }
          _priceStreamController = null;
        }
      },
    );

    // If controller already exists and symbol changes while listeners are active, force reconnect
    if (_priceStreamManager != null && _currentPriceSymbol != null) {
      // Reconnect to the new symbol
      unawaited(_connectToPriceStreamWithRecovery(_currentPriceSymbol!));
    }

    // Wrap the broadcast stream to count individual subscriptions
    final wrapper = StreamController<Either<Failure, double>>(
      onListen: () {
        _priceListenerCount++;
      },
    );
    final sub = _priceStreamController!.stream.listen(
      (e) => wrapper.add(e),
      onError: (err, st) => wrapper.addError(err, st),
      onDone: () => wrapper.close(),
    );
    wrapper.onCancel = () async {
      _priceListenerCount = (_priceListenerCount - 1).clamp(0, 1 << 31);
      await sub.cancel();
    };
    return wrapper.stream;
  }

  @override
  Stream<Either<Failure, AccountInfo>> subscribeToAccountInfoStream() {
    _accountInfoStreamController ??=
        StreamController<Either<Failure, AccountInfo>>.broadcast(
      onListen: () => _connectToAccountInfoStreamWithRecovery(),
      onCancel: () {
        _accountInfoStreamManager?.disconnect();
      },
    );
    // Wrap to count individual listeners
    final wrapper = StreamController<Either<Failure, AccountInfo>>(
      onListen: () {
        _accountInfoListenerCount++;
      },
      onCancel: () async {
        _accountInfoListenerCount =
            (_accountInfoListenerCount - 1).clamp(0, 1 << 31);
      },
    );
    final sub = _accountInfoStreamController!.stream.listen(
      (e) => wrapper.add(e),
      onError: (err, st) => wrapper.addError(err, st),
      onDone: () => wrapper.close(),
    );
    wrapper.onCancel = () async {
      _accountInfoListenerCount =
          (_accountInfoListenerCount - 1).clamp(0, 1 << 31);
      await sub.cancel();
    };
    return wrapper.stream;
  }

  /// Connect to price stream with automatic recovery
  Future<void> _connectToPriceStreamWithRecovery(String symbol) async {
    if (_priceStreamManager != null) {
      await _priceStreamManager!.dispose();
    }

    _priceStreamManager = WebSocketRecoveryManager(
      name: 'PriceStream_$symbol',
      connectionFactory: () async {
        final streamUrl =
            '${_apiClient.wsBaseUrl}/ws/${symbol.toLowerCase()}@trade';
        return WebSocketChannel.connect(Uri.parse(streamUrl));
      },
      config: const WebSocketRecoveryConfig(
        maxRetryAttempts: 5,
        initialRetryDelay: Duration(seconds: 1),
        maxRetryDelay: Duration(minutes: 2),
        suspensionDuration: Duration(minutes: 5),
        healthCheckInterval: Duration(seconds: 30),
      ),
      onMessage: (message) {
        try {
          final streamData =
              jsonDecode(message as String) as Map<String, dynamic>;
          final raw = streamData['p'];
          if (raw == null) {
            return; // ignora messaggi senza prezzo
          }
          final price =
              (raw is num) ? raw.toDouble() : double.tryParse(raw.toString());
          if (price == null || !price.isFinite || price <= 0) {
            _priceStreamController?.add(
              Left(ValidationFailure(
                  message: 'Price parsing error: invalid value')),
            );
            return;
          }
          _priceStreamController?.add(Right(price));
        } on FormatException catch (e) {
          _priceStreamController?.add(
              Left(ValidationFailure(message: 'Price parsing error: $e')));
        }
      },
      onError: (error, stackTrace) {
        _log.e('Price WebSocket error: $error', stackTrace: stackTrace);
        _priceStreamController
            ?.add(Left(NetworkFailure(message: 'Price stream error: $error')));
      },
      onConnected: () {
        // _log.i('Price WebSocket connected for symbol: $symbol');
      },
      onDisconnected: () {
        // _log.w('Price WebSocket disconnected for symbol: $symbol');
      },
    );

    await _priceStreamManager!.connect();
  }

  /// Connect to account info stream with automatic recovery
  Future<void> _connectToAccountInfoStreamWithRecovery() async {
    if (_accountInfoStreamManager != null) {
      await _accountInfoStreamManager!.dispose();
    }

    _accountInfoStreamManager = WebSocketRecoveryManager(
      name: 'AccountInfoStream',
      connectionFactory: () async {
        // Usa _apiClient per ottenere la listenKey
        _log.i('Requesting listen key from Binance...');

        // POST /api/v3/userDataStream (richiede solo API Key header, gestito da client)
        // Usiamo sendRequest. userDataStream torna {"listenKey": "..."}
        try {
          final responseEither = await _apiClient.sendRequest(
            method: 'POST',
            endpoint: '/api/v3/userDataStream',
            isSigned: false,
          );

          return responseEither.fold(
            (failure) {
              _log.e('Failed to get listen key: ${failure.message}');
              // Lanciamo eccezione per triggerare il retry del WebSocketRecoveryManager
              throw Exception('Listen key request failed: ${failure.message}');
            },
            (response) {
              final data = jsonDecode(response.body) as Map<String, dynamic>;
              final listenKey = data['listenKey'] as String;
              _log.i('Listen key received successfully.');

              _setupListenKeyKeepAlive(listenKey);

              final streamUrl = '${_apiClient.wsBaseUrl}/ws/$listenKey';
              return WebSocketChannel.connect(Uri.parse(streamUrl));
            },
          );
        } catch (e) {
          _log.e('Exception getting listen key: $e');
          // Rilanciamo per triggerare il retry del WebSocketRecoveryManager
          rethrow;
        }
      },
      config: const WebSocketRecoveryConfig(
        maxRetryAttempts: 5,
        initialRetryDelay: Duration(seconds: 2),
        maxRetryDelay: Duration(minutes: 5),
        suspensionDuration: Duration(minutes: 10),
        healthCheckInterval: Duration(seconds: 30),
      ),
      onMessage: (message) {
        try {
          final data = jsonDecode(message as String) as Map<String, dynamic>;
          final eventType = data['e'] as String?;
          if (eventType == 'outboundAccountPosition' ||
              eventType == 'balanceUpdate') {
            // Trigger account info refresh
            getAccountInfo().then((result) {
              result.fold(
                (failure) => _accountInfoStreamController?.add(Left(failure)),
                (accountInfo) =>
                    _accountInfoStreamController?.add(Right(accountInfo)),
              );
            });
          }
        } on FormatException catch (e, stackTrace) {
          _log.w('Error parsing account info WebSocket message: $e',
              stackTrace: stackTrace);
        }
      },
      onError: (error, stackTrace) {
        _log.e('Account info WebSocket error: $error', stackTrace: stackTrace);
        _accountInfoStreamController?.add(
            Left(NetworkFailure(message: 'Account info stream error: $error')));
      },
      onConnected: () {
        _log.i('Account info WebSocket connected');
      },
      onDisconnected: () {
        _log.w('Account info WebSocket disconnected');
      },
    );

    await _accountInfoStreamManager!.connect();
  }

  void _setupListenKeyKeepAlive(String listenKey) {
    _listenKeyKeepAliveTimer?.cancel();
    // Anticipa keep-alive a 25 minuti
    _listenKeyKeepAliveTimer =
        Timer.periodic(_listenKeyKeepAliveDuration, (_) async {
      try {
        // PUT /api/v3/userDataStream?listenKey=...
        // Nota: la documentazione dice parametro listenKey.
        final params = {'listenKey': listenKey};
        final responseEither = await _apiClient.sendRequest(
          method: 'PUT',
          endpoint: '/api/v3/userDataStream',
          params: params,
          isSigned: false,
        );

        responseEither.fold(
          (failure) {
            _log.w('Failed to keep-alive listen key: ${failure.message}');
            _handleKeepAliveFailure();
          },
          (response) {
            _log.t('Listen key keep-alive succeeded');
            _listenKeyKeepAliveFailures = 0;
          },
        );
      } catch (e) {
        _log.w('Listen key keep-alive error: $e');
      }
    });
  }

  Future<void> _handleKeepAliveFailure() async {
    // Logica semplificata: se fallisce, forziamo reconnect dopo qualche tentativo
    // Per brevità qui forziamo reconnect diretto se fallisce ripetutamente
    _listenKeyKeepAliveFailures++;
    if (_listenKeyKeepAliveFailures >= 3) {
      _log.w('Keep-alive failed repeatedly. Forcing reconnect.');
      await _accountInfoStreamManager?.forceReconnect();
      _listenKeyKeepAliveFailures = 0;
    }
  }

  /// Get WebSocket connection statistics
  @override
  Map<String, dynamic> getWebSocketStats() {
    final clientStats = _apiClient.getStatistics();
    return {
      'priceStream': _priceStreamManager?.getStats().toJson(),
      'accountInfoStream': _accountInfoStreamManager?.getStats().toJson(),
      'currentPriceSymbol': _currentPriceSymbol,
      'priceListeners': _priceListenerCount,
      'accountInfoListeners': _accountInfoListenerCount,
      'accountListenKeyKeepAliveFailures': _listenKeyKeepAliveFailures,
      'apiClient': clientStats,
      'circuitBreakers': {
        'orders': _orderCircuitBreaker.getStats(),
        'info': _infoCircuitBreaker.getStats(),
        'account': _accountCircuitBreaker.getStats(),
      },
    };
  }

  /// Force reconnection of all WebSocket streams
  @override
  Future<void> forceWebSocketReconnect() async {
    _log.i('Forcing WebSocket reconnection for all streams');

    await _priceStreamManager?.forceReconnect();
    await _accountInfoStreamManager?.forceReconnect();
  }

  @override
  Future<Either<Failure, void>> cancelOrder({
    required String symbol,
    required int orderId,
  }) async {
    const endpoint = '/api/v3/order';
    final params = {
      'symbol': symbol,
      'orderId': orderId.toString(),
    };

    final result = await _orderCircuitBreaker.execute(() async {
      final response = await _sendSignedRequest(
          method: 'DELETE', endpoint: endpoint, params: params, weight: 1);

      return response.fold(
        (failure) => Left(failure),
        (httpResponse) {
          if (httpResponse.statusCode == 200) {
            return const Right(null);
          } else {
            return Left(ServerFailure(
                message: 'Cancellazione ordine fallita: ${httpResponse.body}',
                statusCode: httpResponse.statusCode));
          }
        },
      );
    });

    return _unwrapCircuitBreakerResult<void>(result, 'cancelOrder');
  }

  @override
  Future<Either<Failure, void>> cancelAllOpenOrders({
    required String symbol,
  }) async {
    const endpoint = '/api/v3/openOrders';
    final params = {'symbol': symbol};

    final result = await _orderCircuitBreaker.execute(() async {
      final response = await _sendSignedRequest(
          method: 'DELETE', endpoint: endpoint, params: params, weight: 1);

      return response.fold(
        (failure) => Left(failure),
        (httpResponse) {
          if (httpResponse.statusCode == 200) {
            return const Right(null);
          } else {
            return Left(ServerFailure(
                message: 'Cancellazione ordini fallita: ${httpResponse.body}',
                statusCode: httpResponse.statusCode));
          }
        },
      );
    });

    return _unwrapCircuitBreakerResult<void>(result, 'cancelAllOpenOrders');
  }

  @override
  void dispose() {
    _apiClient.dispose();
    _listenKeyKeepAliveTimer?.cancel();
    _priceStreamManager?.dispose();
    _accountInfoStreamManager?.dispose();
    _priceStreamController?.close();
    _accountInfoStreamController?.close();

    // Dispose circuit breakers
    _orderCircuitBreaker.dispose();
    _infoCircuitBreaker.dispose();
    _accountCircuitBreaker.dispose();

    _log.i('ApiService disposed.');
  }

  @override
  void updateMode({required bool isTestMode}) {
    _isTestMode = isTestMode;
    final (apiKey, secretKey) =
        _apiKeysConfig.getKeysForMode(isTestMode: isTestMode);

    if (isTestMode) {
      _apiClient.updateConfig(
        apiKey: apiKey,
        secretKey: secretKey,
        baseUrl: Constants.testnetBaseUrl,
        wsBaseUrl: Constants.testnetWsBaseUrl,
      );
    } else {
      _apiClient.updateConfig(
        apiKey: apiKey,
        secretKey: secretKey,
        baseUrl: Constants.baseUrl,
        wsBaseUrl: Constants.wsBaseUrl,
      );
    }
    // Forza la riconnessione dei WebSocket per applicare i nuovi URL
    forceWebSocketReconnect();
  }

  @override
  Future<Either<Failure, TickerInfo>> getTickerInfo(String symbol) async {
    const endpoint = '/api/v3/ticker/24hr';
    final params = {'symbol': symbol};

    try {
      final response = await _sendSignedRequest(
          method: 'GET', endpoint: endpoint, params: params, isSigned: false);
      return response.fold(
        (failure) {
          _log.e('getTickerInfo failed for $symbol: ${failure.message}');
          return Left(failure);
        },
        (httpResponse) {
          final tickerData = jsonDecode(httpResponse.body);
          return Right(TickerInfo.fromJson(tickerData));
        },
      );
    } catch (e) {
      _log.f('getTickerInfo critical exception: $e');
      return Left(
          ServerFailure(message: 'Errore imprevisto in getTickerInfo: $e'));
    }
  }

  // getExchangeInfo() già definito più sotto in questo file

  @override
  Future<Either<Failure, ExchangeInfo>> getExchangeInfo() async {
    const endpoint = '/api/v3/exchangeInfo';
    _log.d('getExchangeInfo: started');

    // Controlla cache
    if (_exchangeInfoCache != null && _exchangeInfoCacheTime != null) {
      final elapsed = DateTime.now().difference(_exchangeInfoCacheTime!);
      if (elapsed < _exchangeInfoCacheTTL) {
        _log.d(
            'getExchangeInfo: returning cached result (${elapsed.inSeconds}s old)');
        return Right(_exchangeInfoCache!);
      }
    }

    try {
      final response = await _sendSignedRequest(
          method: 'GET', endpoint: endpoint, isSigned: false, weight: 10);
      return response.fold(
        (failure) {
          _log.e('getExchangeInfo failed: ${failure.message}');
          return Left(failure);
        },
        (httpResponse) {
          final jsonResult = JsonParser.safeDecode(httpResponse.body);
          return jsonResult.fold(
            (failure) => Left(failure),
            (data) {
              try {
                final exchangeInfo = ExchangeInfo.fromJson(data);
                _exchangeInfoCache = exchangeInfo;
                _exchangeInfoCacheTime = DateTime.now();
                return Right(exchangeInfo);
              } catch (e, st) {
                _log.e('ExchangeInfo parse error', error: e, stackTrace: st);
                return Left(ValidationFailure(
                    message: 'Failed to parse ExchangeInfo: $e'));
              }
            },
          );
        },
      );
    } catch (e) {
      _log.f('getExchangeInfo critical exception: $e');
      return Left(
          ServerFailure(message: 'Errore imprevisto in getExchangeInfo: $e'));
    }
  }

  @override
  Future<Either<Failure, Price>> getLatestPrice(String symbol) async {
    const endpoint = '/api/v3/ticker/price';
    final params = {'symbol': symbol};
    _log.d('getLatestPrice: started for $symbol');

    try {
      final response = await _sendSignedRequest(
          method: 'GET', endpoint: endpoint, params: params, isSigned: false);
      return response.fold(
        (failure) {
          _log.e('getLatestPrice failed for $symbol: ${failure.message}');
          return Left(failure);
        },
        (httpResponse) {
          final jsonResult = JsonParser.safeDecode(httpResponse.body);
          return jsonResult.fold(
            (failure) => Left(failure),
            (data) {
              final priceValue =
                  JsonParser.safeParseDouble(data['price'], 'price');
              final symbolValue =
                  JsonParser.safeExtract<String>(data, 'symbol', (v) => v);

              return priceValue.fold(
                (failure) => Left(failure),
                (price) => symbolValue.fold(
                  (failure) => Left(failure),
                  (symbol) => Right(Price(
                      symbol: symbol, price: price, timestamp: DateTime.now())),
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      return Left(
          ServerFailure(message: 'Errore imprevisto in getLatestPrice: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>>
      getAccountTradeFees() async {
    const endpoint = '/sapi/v1/account/tradeFee';
    _log.d('getAccountTradeFees: started');

    if (_isTestMode) {
      _log.w('getAccountTradeFees skipped in Test Mode (SAPI not available)');
      return Left(ServerFailure(
          message:
              'Trade fees precise non disponibili in Test Mode (SAPI limitazione)',
          statusCode: 404));
    }

    try {
      final response = await _sendSignedRequest(
          method: 'GET', endpoint: endpoint, isSigned: true, weight: 1);
      return response.fold(
        (failure) {
          _log.e('getAccountTradeFees failed: ${failure.message}');
          return Left(failure);
        },
        (httpResponse) {
          final jsonResult = JsonParser.safeDecode(httpResponse.body);
          return jsonResult.fold(
            (failure) => Left(failure),
            (data) {
              try {
                final fees = data as List<dynamic>;
                return Right(
                    fees.map((f) => f as Map<String, dynamic>).toList());
              } catch (e, st) {
                _log.e('AccountTradeFees parse error',
                    error: e, stackTrace: st);
                return Left(ValidationFailure(
                    message: 'Failed to parse AccountTradeFees: $e'));
              }
            },
          );
        },
      );
    } catch (e) {
      _log.f('getAccountTradeFees critical exception: $e');
      return Left(ServerFailure(
          message: 'Errore imprevisto in getAccountTradeFees: $e'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getActiveSymbols() async {
    const endpoint = '/api/v3/exchangeInfo';
    _log.d('getActiveSymbols: started');

    try {
      final response = await _sendSignedRequest(
          method: 'GET', endpoint: endpoint, isSigned: false, weight: 10);
      return response.fold(
        (failure) {
          _log.e('getActiveSymbols failed: ${failure.message}');
          return Left(failure);
        },
        (httpResponse) {
          final jsonResult = JsonParser.safeDecode(httpResponse.body);
          return jsonResult.fold(
            (failure) => Left(failure),
            (data) {
              try {
                final symbols = data['symbols'] as List<dynamic>;

                // Filtra solo simboli attivi per trading
                final activeSymbols = symbols
                    .map((s) => s as Map<String, dynamic>)
                    .where((s) => s['status'] == 'TRADING')
                    .map((s) => s['symbol'] as String)
                    .toList();

                return Right(activeSymbols);
              } catch (e, st) {
                _log.e('ActiveSymbols parse error', error: e, stackTrace: st);
                return Left(ValidationFailure(
                    message: 'Failed to parse ActiveSymbols: $e'));
              }
            },
          );
        },
      );
    } catch (e) {
      _log.f('getActiveSymbols critical exception: $e');
      return Left(
          ServerFailure(message: 'Errore imprevisto in getActiveSymbols: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Kline>>> getKlines({
    required String symbol,
    required String interval,
    int? startTime,
    int? endTime,
    int? limit,
  }) async {
    const endpoint = '/api/v3/klines';
    final params = {
      'symbol': symbol,
      'interval': interval,
    };
    if (startTime != null) params['startTime'] = startTime.toString();
    if (endTime != null) params['endTime'] = endTime.toString();
    if (limit != null) params['limit'] = limit.toString();

    try {
      final result = await _infoCircuitBreaker.execute(() async {
        final response = await _apiClient.sendRequest(
          method: 'GET',
          endpoint: endpoint,
          params: params,
          isSigned: false,
        );

        return response.fold(
          (failure) => Left(failure),
          (httpResponse) {
            final jsonResult = JsonParser.safeDecodeList(httpResponse.body);
            return jsonResult.fold(
              (failure) => Left(failure),
              (data) {
                final List<Kline> klines = [];
                for (var item in data) {
                  if (item is List && item.length >= 11) {
                    klines.add(Kline(
                      openTime: item[0] as int,
                      open: double.parse(item[1].toString()),
                      high: double.parse(item[2].toString()),
                      low: double.parse(item[3].toString()),
                      close: double.parse(item[4].toString()),
                      volume: double.parse(item[5].toString()),
                      closeTime: item[6] as int,
                      quoteAssetVolume: double.parse(item[7].toString()),
                      numberOfTrades: item[8] as int,
                      takerBuyBaseAssetVolume: double.parse(item[9].toString()),
                      takerBuyQuoteAssetVolume:
                          double.parse(item[10].toString()),
                    ));
                  }
                }
                return Right(klines);
              },
            );
          },
        );
      });

      if (result.rejectedByCircuitBreaker) {
        return Left(ServerFailure(
            message: 'Klines API temporarily unavailable', statusCode: 503));
      }

      final dynamic circuitResult = result.result;
      if (circuitResult is Either<Failure, List<Kline>>) {
        return circuitResult;
      }

      return Left(
          UnexpectedFailure(message: 'Unexpected error fetching klines'));
    } catch (e) {
      return Left(ServerFailure(message: 'Errore imprevisto in getKlines: $e'));
    }
  }
}
