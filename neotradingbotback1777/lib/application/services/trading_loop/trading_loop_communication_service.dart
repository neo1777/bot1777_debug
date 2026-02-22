import 'dart:async';
import 'dart:isolate';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:neotradingbotback1777/core/logging/log_stream_service.dart';
import 'package:neotradingbotback1777/domain/entities/app_trade.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/fifo_app_trade.dart';
import 'dart:math';

class TradingLoopCommunicationService {
  final _log = LogManager.getLogger();
  SendPort? _mainSendPort;

  /// Monotonic version counter for state sync messages.
  /// The main thread uses this to reject stale out-of-order messages.
  int _stateVersion = 0;

  final Map<String, Completer<bool>> _pendingMessages = {};
  final Map<String, int> _messageRetryCount = {};

  static const int _maxRetries = 3;
  static const Duration _ackTimeout = Duration(seconds: 5);
  static const Duration _retryDelay = Duration(milliseconds: 500);

  StreamSubscription? _logForwardSubscription;

  void setMainSendPort(SendPort sendPort) {
    _mainSendPort = sendPort;
  }

  void startLogForwarding() {
    _logForwardSubscription?.cancel();
    _logForwardSubscription = LogStreamService().logStream.listen((entry) {
      final port = _mainSendPort;
      if (port == null) {
        return;
      }
      try {
        port.send({
          'type': 'log_entry',
          'entry': {
            'level': entry.level,
            'message': entry.message,
            'timestamp': entry.timestamp.millisecondsSinceEpoch,
            'serviceName': entry.serviceName,
          }
        });
      } catch (e) {
        _log.w('Failed to forward log entry to main isolate: $e');
      }
    });
  }

  void dispose() {
    _logForwardSubscription?.cancel();
  }

  void sendErrorSync(String symbol, String message) {
    if (_mainSendPort != null) {
      final messageId = _generateId();
      _sendMessageWithRetry(
          _mainSendPort!,
          {
            'type': 'sync_error_state',
            'id': messageId,
            'symbol': symbol,
            'message': message,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          },
          messageId);
    }
  }

  void sendWarningSync(String symbol, String message) {
    if (_mainSendPort != null) {
      final messageId = _generateId();
      _sendMessageWithRetry(
          _mainSendPort!,
          {
            'type': 'sync_warning_state',
            'id': messageId,
            'symbol': symbol,
            'warning': message,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          },
          messageId);
    }
  }

  void sendTradeStateSync(
      String symbol, AppTrade trade, AppStrategyState state) {
    if (_mainSendPort != null) {
      final messageId = _generateId();
      _stateVersion++;
      _sendMessageWithAck(
          _mainSendPort!,
          {
            'type': 'sync_trade_state',
            'id': messageId,
            'version': _stateVersion,
            'symbol': symbol,
            'trade': _encodeTrade(trade),
            'state': _encodeState(state),
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          },
          messageId);
    }
  }

  void _sendMessageWithAck(
      SendPort port, Map<String, dynamic> message, String messageId) {
    final completer = Completer<bool>();
    _pendingMessages[messageId] = completer;

    port.send(message);

    // Timeout per l'ack
    Future.delayed(_ackTimeout, () {
      if (!completer.isCompleted) {
        if (!_pendingMessages.containsKey(messageId)) return; // Già gestito

        // Logica di retry su timeout
        int retries = _messageRetryCount[messageId] ?? 0;
        if (retries < _maxRetries) {
          _messageRetryCount[messageId] = retries + 1;
          _log.w(
              'Timeout ACK per messaggio $messageId. Retry ${retries + 1}/$_maxRetries');
          Future.delayed(_retryDelay, () {
            if (_pendingMessages.containsKey(messageId)) {
              // Riprova invio
              _sendMessageWithAck(port, message, messageId);
            }
          });
        } else {
          _handleMessageSendFailure(port, message, messageId);
        }
      }
    });
  }

  void _sendMessageWithRetry(
      SendPort port, Map<String, dynamic> message, String messageId) {
    // Per messaggi non critici (es. warning) usiamo un fire-and-forget ma con un minimo di robustezza
    try {
      port.send(message);
    } catch (e) {
      int retries = _messageRetryCount[messageId] ?? 0;
      if (retries < _maxRetries) {
        _messageRetryCount[messageId] = retries + 1;
        Future.delayed(_retryDelay, () {
          _sendMessageWithRetry(port, message, messageId);
        });
      } else {
        _log.e(
            'Failed to send message $messageId after $_maxRetries attempts: $e');
      }
    }
  }

  void _handleMessageSendFailure(
      SendPort port, Map<String, dynamic> message, String messageId) {
    _log.e('FALLIMENTO CRITICO INVIO MESSAGGIO $messageId: $message');
    _pendingMessages.remove(messageId);
    _messageRetryCount.remove(messageId);
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(10000).toString();
  }

  Map<String, dynamic> _encodeTrade(AppTrade trade) {
    return {
      'symbol': trade.symbol,
      'price': trade.price.toDouble(),
      'quantity': trade.quantity.toDouble(),
      'isBuy': trade.isBuy,
      'timestamp': trade.timestamp,
      // 'fees': trade.fees?.toDouble() ?? 0.0,
      'orderStatus': trade.orderStatus,
      // 'tradeId': trade.tradeId,
      // 'orderId': trade.orderId,
      'profit': trade.profit?.toDouble() ?? 0.0,
    };
  }

  Map<String, dynamic> _encodeState(AppStrategyState state) {
    return {
      'symbol': state.symbol,
      'status': state.status.name, // Convert enum to string
      'openTrades': state.openTrades.map((t) => _encodeFifoTrade(t)).toList(),
      'totalInvested': state.totalInvested,
      'cumulativeProfit': state.cumulativeProfit,
      'averagePrice': state.averagePrice,
      'currentRoundId': state.currentRoundId,
      'successfulRounds': state.successfulRounds,
      'failedRounds': state.failedRounds,
      // 'lastUpdated': state.lastUpdated, // removed if not exists or if problematic
      'targetRoundId': state.targetRoundId,
    };
  }

  Map<String, dynamic> _encodeFifoTrade(FifoAppTrade trade) {
    return {
      'price': trade.price,
      'quantity': trade.quantity,
      'timestamp': trade.timestamp,
      'roundId': trade.roundId,
    };
  }
}
