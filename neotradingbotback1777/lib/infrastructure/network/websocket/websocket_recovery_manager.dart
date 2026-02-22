import 'dart:async';
import 'dart:math';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Stati possibili di una connessione WebSocket
enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  suspended,
  terminated
}

/// Configurazione per il recovery automatico dei WebSocket
class WebSocketRecoveryConfig {
  /// Numero massimo di tentativi di riconnessione
  final int maxRetryAttempts;

  /// Delay iniziale per la riconnessione
  final Duration initialRetryDelay;

  /// Fattore di moltiplicazione per il backoff esponenziale
  final double backoffMultiplier;

  /// Delay massimo tra i tentativi
  final Duration maxRetryDelay;

  /// Durata della sospensione dopo tutti i tentativi falliti
  final Duration suspensionDuration;

  /// Intervallo per controllare la salute della connessione
  final Duration healthCheckInterval;

  /// Timeout per considerare una connessione come non responsiva
  final Duration connectionTimeout;

  /// Jitter massimo per randomizzare i delay
  final Duration maxJitter;

  const WebSocketRecoveryConfig({
    this.maxRetryAttempts = 5,
    this.initialRetryDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxRetryDelay = const Duration(minutes: 5),
    this.suspensionDuration = const Duration(minutes: 10),
    this.healthCheckInterval = const Duration(seconds: 30),
    this.connectionTimeout = const Duration(seconds: 10),
    this.maxJitter = const Duration(milliseconds: 1000),
  });
}

/// Statistiche di una connessione WebSocket
class WebSocketStats {
  final String name;
  final WebSocketConnectionState state;
  final int totalConnections;
  final int failedConnections;
  final int totalReconnections;
  final int currentRetryAttempt;
  final DateTime? lastConnectionTime;
  final DateTime? lastDisconnectionTime;
  final Duration? lastConnectionDuration;
  final Duration? uptime;
  final List<String> recentErrors;

  WebSocketStats({
    required this.name,
    required this.state,
    required this.totalConnections,
    required this.failedConnections,
    required this.totalReconnections,
    required this.currentRetryAttempt,
    this.lastConnectionTime,
    this.lastDisconnectionTime,
    this.lastConnectionDuration,
    this.uptime,
    this.recentErrors = const [],
  });

  double get successRate => totalConnections > 0
      ? (totalConnections - failedConnections) / totalConnections
      : 1.0;

  Map<String, dynamic> toJson() => {
        'name': name,
        'state': state.name,
        'totalConnections': totalConnections,
        'failedConnections': failedConnections,
        'totalReconnections': totalReconnections,
        'currentRetryAttempt': currentRetryAttempt,
        'successRate': successRate,
        'lastConnectionTime': lastConnectionTime?.toIso8601String(),
        'lastDisconnectionTime': lastDisconnectionTime?.toIso8601String(),
        'lastConnectionDuration': lastConnectionDuration?.inSeconds,
        'uptime': uptime?.inSeconds,
        'recentErrors': recentErrors,
      };
}

/// Manager per il recovery automatico delle connessioni WebSocket
class WebSocketRecoveryManager {
  final String name;
  final WebSocketRecoveryConfig config;
  final Future<WebSocketChannel> Function() connectionFactory;
  final void Function(dynamic message)? onMessage;
  final void Function(dynamic error, StackTrace stackTrace)? onError;
  final void Function()? onConnected;
  final void Function()? onDisconnected;
  final _log = LogManager.getLogger();
  final _random = Random();

  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  Timer? _reconnectTimer;
  Timer? _healthCheckTimer;
  Timer? _suspensionTimer;

  WebSocketConnectionState _state = WebSocketConnectionState.disconnected;
  int _retryAttempt = 0;
  int _totalConnections = 0;
  int _failedConnections = 0;
  int _totalReconnections = 0;
  DateTime? _lastConnectionTime;
  DateTime? _lastDisconnectionTime;
  DateTime? _connectionStartTime;
  final List<String> _recentErrors = [];
  bool _disposed = false;

  WebSocketRecoveryManager({
    required this.name,
    required this.connectionFactory,
    this.config = const WebSocketRecoveryConfig(),
    this.onMessage,
    this.onError,
    this.onConnected,
    this.onDisconnected,
  });

  /// Stato corrente della connessione
  WebSocketConnectionState get state => _state;

  /// Indica se la connessione è attiva
  bool get isConnected => _state == WebSocketConnectionState.connected;

  /// Indica se è in corso un tentativo di connessione
  bool get isConnecting =>
      _state == WebSocketConnectionState.connecting ||
      _state == WebSocketConnectionState.reconnecting;

  /// Avvia la connessione WebSocket con recovery automatico
  Future<void> connect() async {
    if (_disposed || isConnecting || isConnected) return;

    _setState(WebSocketConnectionState.connecting);
    _totalConnections++;

    try {
      _log.i('[$name] Connecting to WebSocket (attempt ${_retryAttempt + 1})');
      _connectionStartTime = DateTime.now();

      _channel = await connectionFactory();
      _lastConnectionTime = DateTime.now();
      _retryAttempt = 0;

      _setState(WebSocketConnectionState.connected);
      onConnected?.call();

      _setupChannelListeners();
      _startHealthCheck();

      // _log.i('[$name] WebSocket connected successfully');
    } catch (e) {
      _log.e('[$name] Failed to connect to WebSocket: $e');
      _failedConnections++;
      _addRecentError('Connection failed: $e');

      _setState(WebSocketConnectionState.disconnected);
      _scheduleReconnect();
    }
  }

  /// Disconnette il WebSocket
  Future<void> disconnect() async {
    _log.i('[$name] Disconnecting WebSocket');

    _stopTimers();
    await _closeChannel();
    _setState(WebSocketConnectionState.disconnected);
    onDisconnected?.call();
  }

  /// Chiude definitivamente il manager
  Future<void> dispose() async {
    _disposed = true;
    _log.i('[$name] Disposing WebSocket recovery manager');

    _stopTimers();
    await _closeChannel();
    _setState(WebSocketConnectionState.terminated);
  }

  /// Forza una riconnessione
  Future<void> forceReconnect() async {
    _log.i('[$name] Forcing WebSocket reconnection');

    await _closeChannel();
    _retryAttempt = 0;
    _setState(WebSocketConnectionState.disconnected);

    if (!_disposed) {
      await connect();
    }
  }

  /// Ottieni le statistiche della connessione
  WebSocketStats getStats() {
    Duration? uptime;
    Duration? lastConnectionDuration;

    if (_connectionStartTime != null && isConnected) {
      uptime = DateTime.now().difference(_connectionStartTime!);
    }

    if (_lastConnectionTime != null && _lastDisconnectionTime != null) {
      lastConnectionDuration =
          _lastDisconnectionTime!.difference(_lastConnectionTime!);
    }

    return WebSocketStats(
      name: name,
      state: _state,
      totalConnections: _totalConnections,
      failedConnections: _failedConnections,
      totalReconnections: _totalReconnections,
      currentRetryAttempt: _retryAttempt,
      lastConnectionTime: _lastConnectionTime,
      lastDisconnectionTime: _lastDisconnectionTime,
      lastConnectionDuration: lastConnectionDuration,
      uptime: uptime,
      recentErrors: List.from(_recentErrors),
    );
  }

  void _setupChannelListeners() {
    _channelSubscription = _channel?.stream.listen(
      (message) {
        try {
          onMessage?.call(message);
        } catch (e, stackTrace) {
          _log.e('[$name] Error processing WebSocket message: $e',
              stackTrace: stackTrace);
          onError?.call(e, stackTrace);
        }
      },
      onError: (error, stackTrace) {
        _log.e('[$name] WebSocket stream error: $error',
            stackTrace: stackTrace);
        _addRecentError('Stream error: $error');
        onError?.call(error, stackTrace);
        _handleDisconnection();
      },
      onDone: () {
        _log.w('[$name] WebSocket stream closed');
        _handleDisconnection();
      },
    );
  }

  void _handleDisconnection() {
    if (_disposed || _state == WebSocketConnectionState.disconnected) return;

    _lastDisconnectionTime = DateTime.now();
    _setState(WebSocketConnectionState.disconnected);
    onDisconnected?.call();

    _stopHealthCheck();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed || _state == WebSocketConnectionState.suspended) return;

    if (_retryAttempt >= config.maxRetryAttempts) {
      _log.w(
          '[$name] Max retry attempts reached. Suspending for ${config.suspensionDuration.inMinutes} minutes');
      _setState(WebSocketConnectionState.suspended);

      _suspensionTimer = Timer(config.suspensionDuration, () {
        if (!_disposed) {
          _log.i('[$name] Suspension period ended. Resetting retry counter');
          _retryAttempt = 0;
          _setState(WebSocketConnectionState.disconnected);
          connect();
        }
      });
      return;
    }

    _retryAttempt++;
    _totalReconnections++;

    final baseDelay = config.initialRetryDelay;
    final exponentialDelay = Duration(
        milliseconds: (baseDelay.inMilliseconds *
                pow(config.backoffMultiplier, _retryAttempt - 1))
            .round());

    final cappedDelay = Duration(
        milliseconds: min(exponentialDelay.inMilliseconds,
            config.maxRetryDelay.inMilliseconds));

    final jitter = Duration(
        milliseconds: _random.nextInt(config.maxJitter.inMilliseconds));

    final totalDelay = cappedDelay + jitter;

    _log.i(
        '[$name] Scheduling reconnection in ${totalDelay.inSeconds} seconds (attempt $_retryAttempt/${config.maxRetryAttempts})');

    _setState(WebSocketConnectionState.reconnecting);
    _reconnectTimer = Timer(totalDelay, () {
      if (!_disposed) {
        connect();
      }
    });
  }

  void _startHealthCheck() {
    _healthCheckTimer = Timer.periodic(config.healthCheckInterval, (_) {
      if (_channel?.closeCode != null) {
        _log.w(
            '[$name] Health check detected closed connection (code: ${_channel?.closeCode})');
        _handleDisconnection();
      }
    });
  }

  void _stopHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
  }

  void _stopTimers() {
    _reconnectTimer?.cancel();
    _healthCheckTimer?.cancel();
    _suspensionTimer?.cancel();
    _reconnectTimer = null;
    _healthCheckTimer = null;
    _suspensionTimer = null;
  }

  Future<void> _closeChannel() async {
    try {
      await _channelSubscription?.cancel();
      await _channel?.sink.close();
    } catch (e) {
      _log.w('[$name] Error closing WebSocket channel: $e');
    } finally {
      _channelSubscription = null;
      _channel = null;
    }
  }

  void _setState(WebSocketConnectionState newState) {
    if (_state != newState) {
      _log.d('[$name] State transition: ${_state.name} -> ${newState.name}');
      _state = newState;
    }
  }

  void _addRecentError(String error) {
    _recentErrors.add('${DateTime.now().toIso8601String()}: $error');

    // Keep only the last 10 errors
    if (_recentErrors.length > 10) {
      _recentErrors.removeAt(0);
    }
  }
}
