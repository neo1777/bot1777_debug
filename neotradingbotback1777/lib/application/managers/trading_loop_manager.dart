/// [AUDIT-PHASE-9] - Formal Audit Marker
import 'dart:async';
import 'dart:isolate';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:fpdart/fpdart.dart';
import 'package:decimal/decimal.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:neotradingbotback1777/application/monitoring/isolate_health_monitor.dart';
// entrypoint non atomico rimosso
import 'package:neotradingbotback1777/application/trading_isolate_entrypoint_atomic.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/fifo_app_trade.dart';
import 'package:neotradingbotback1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/app_trade.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/injection.dart';
import 'package:neotradingbotback1777/domain/repositories/strategy_state_repository.dart';
import 'package:neotradingbotback1777/domain/services/trading_transaction_manager.dart';
import 'package:neotradingbotback1777/core/logging/log_stream_service.dart';
import 'package:neotradingbotback1777/application/managers/atomic_state_manager.dart';
import 'package:neotradingbotback1777/domain/entities/log_entry.dart' as domain;
import 'package:neotradingbotback1777/domain/value_objects/amounts.dart';

// I comandi rimangono un'ottima astrazione.
abstract class IsolateCommand {}

class ShutdownCommand implements IsolateCommand {}

class ResetCircuitBreakerCommand implements IsolateCommand {}

class TradingLoopManager {
  final Map<String, Isolate> _isolates = {};
  final Map<String, SendPort> _sendPorts = {};
  final Map<String, ReceivePort> _receivePorts = {};
  final Map<String, Completer<void>> _shutdownCompleters = {};
  final IsolateHealthMonitor _healthMonitor = IsolateHealthMonitor();
  final Logger _logger;

  /// Tracks the last applied state sync version per symbol to reject stale messages.
  final Map<String, int> _lastAppliedStateVersion = {};

  TradingLoopManager() : _logger = LogManager.getLogger() {
    _logger.i('TradingLoopManager initializzato.');
    _healthMonitor.start();
  }

  void _handleSyncErrorState(Map message) async {
    try {
      final symbol = message['symbol'] as String;
      final error = message['error'] as String?;
      _logger.w(
          'Received sync_error_state from atomic isolate for $symbol. Reason: ${error ?? 'n/a'}');

      // Aggiorna health monitor con errore
      _healthMonitor.recordTradingOperation(symbol,
          success: false, error: error);

      // MIGLIORAMENTO ROBUSTEZZA: Implementazione heartbeat e recovery automatico
      // per prevenire race condition e inconsistenze di stato
      await _performIsolateRecovery(symbol, error);

      // Spegni l'isolate se attivo
      _shutdownIsolateGracefully(symbol);
    } catch (e, s) {
      _logger.e('Error processing sync_error_state: $e', stackTrace: s);
    }
  }

  /// Implementa un meccanismo di recovery automatico per gli isolate
  /// per prevenire race condition e inconsistenze di stato
  Future<void> _performIsolateRecovery(String symbol, String? error) async {
    try {
      _logger.i('Starting automatic recovery for isolate $symbol');

      // Step 1: Verifica heartbeat dell'isolate
      final isHealthy = await _checkIsolateHealth(symbol);
      if (!isHealthy) {
        _logger.w(
            'Isolate $symbol not responding to heartbeat, proceeding with recovery');
      }

      // Step 2: Rollback stato persistito a IDLE per coerenza
      final repo = sl<StrategyStateRepository>();
      final current = await repo.getStrategyState(symbol);
      final newState = current
              .getOrElse((_) => null)
              ?.copyWith(status: StrategyState.IDLE) ??
          AppStrategyState(symbol: symbol, status: StrategyState.IDLE);

      // Step 3: Salvataggio atomico con retry per garantire consistenza
      final save = await _saveStateWithRetry(repo, newState, symbol);
      save.fold(
        (f) => _logger.e('Recovery failed for $symbol: ${f.message}'),
        (_) {
          // Invalida cache dell'AtomicStateManager persistente
          try {
            sl<AtomicStateManager>().invalidateCache();
          } catch (e) {
            _logger
                .w('Informing: Cache invalidation failed during recovery: $e');
          }
          _logger.i('Recovery completed for $symbol: state restored to IDLE');
        },
      );

      // Step 4: Logging strutturato per monitoring
      _logger.i('Recovery isolate $symbol completato con successo');
    } catch (e, s) {
      _logger.e('Errore durante recovery isolate $symbol: $e', stackTrace: s);
      // In caso di errore nel recovery, forziamo lo shutdown per sicurezza
      _forceIsolateShutdown(symbol);
    }
  }

  /// Verifica la salute dell'isolate consultando il [IsolateHealthMonitor].
  ///
  /// Il monitor riceve [HeartbeatMessage] periodici dall'isolate (ogni 30s)
  /// e ne traccia lo stato. Questo metodo semplicemente interroga quel dato
  /// invece di implementare un meccanismo heartbeat duplicato.
  Future<bool> _checkIsolateHealth(String symbol) async {
    try {
      if (_sendPorts[symbol] == null) return false;

      final healthInfo = _healthMonitor.getHealthInfo(symbol);
      if (healthInfo == null) {
        _logger.w('Nessuna info di salute disponibile per $symbol');
        return false;
      }

      final isHealthy = healthInfo.status == IsolateHealthStatus.healthy ||
          healthInfo.status == IsolateHealthStatus.degraded;

      if (!isHealthy) {
        _logger
            .w('Isolate $symbol non healthy: status=${healthInfo.status.name}, '
                'lastError=${healthInfo.lastError}');
      }

      return isHealthy;
    } catch (e) {
      _logger.w('Errore durante health check per $symbol: $e');
      return false;
    }
  }

  /// Salvataggio dello stato con retry per garantire consistenza
  Future<Either<Failure, void>> _saveStateWithRetry(
      StrategyStateRepository repo,
      AppStrategyState state,
      String symbol) async {
    const maxRetries = 3;
    const retryDelay = Duration(milliseconds: 100);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final result = await repo.saveStrategyState(state);
        if (result.isRight()) {
          return result;
        }

        if (attempt < maxRetries) {
          _logger.w(
              'Attempt $attempt failed for $symbol, retrying in ${retryDelay.inMilliseconds}ms');
          await Future.delayed(retryDelay);
        }
      } catch (e) {
        _logger.w('Error saving state for $symbol (attempt $attempt): $e');
        if (attempt < maxRetries) {
          await Future.delayed(retryDelay);
        }
      }
    }

    // Se tutti i tentativi falliscono, ritorna l'ultimo errore
    return repo.saveStrategyState(state);
  }

  /// Forza lo shutdown dell'isolate in caso di recovery fallito
  void _forceIsolateShutdown(String symbol) {
    try {
      final isolate = _isolates[symbol];
      if (isolate != null) {
        _logger
            .w('Forcing isolate shutdown for $symbol after recovery failure');
        isolate.kill(priority: Isolate.immediate);
        _isolates.remove(symbol);
        _sendPorts.remove(symbol);
        _receivePorts.remove(symbol);
        _shutdownCompleters.remove(symbol);
      }
    } catch (e) {
      _logger.e('Error during forced shutdown of isolate $symbol: $e');
    }
  }

  void _shutdownIsolateGracefully(String symbol) {
    try {
      final sendPort = _sendPorts[symbol];
      final isolate = _isolates[symbol];
      if (sendPort != null) {
        _logger.i('Sending ShutdownCommand to atomic isolate for $symbol.');
        try {
          sendPort.send(ShutdownCommand());
        } catch (e) {
          _logger.w('Failed to send ShutdownCommand for $symbol: $e');
        }
      } else if (isolate != null) {
        _logger.w('Missing SendPort for $symbol. Immediate isolate kill.');
        try {
          isolate.kill(priority: Isolate.immediate);
        } catch (e) {
          _logger.w('Isolate kill failed for $symbol: $e');
        }
      }
    } catch (e, s) {
      _logger.e('Error during isolate shutdown for $symbol: $e', stackTrace: s);
    }
  }

  void _handleSyncTradeState(Map message) async {
    try {
      final symbol = message['symbol'] as String;

      // --- Stale message rejection via version counter ---
      final version = message['version'] as int?;
      if (version != null) {
        final lastVersion = _lastAppliedStateVersion[symbol] ?? 0;
        if (version <= lastVersion) {
          _logger.w(
              'Skipping stale sync_trade_state for $symbol (version $version <= last applied $lastVersion)');
          return;
        }
        _lastAppliedStateVersion[symbol] = version;
      }

      final tradeMap = (message['trade'] as Map).cast<String, Object?>();
      final stateMap = (message['state'] as Map).cast<String, Object?>();

      final trade = AppTrade(
        symbol: tradeMap['symbol'] as String,
        price: MoneyAmount.fromDouble((tradeMap['price'] as num).toDouble()),
        quantity:
            QuantityAmount.fromDouble((tradeMap['quantity'] as num).toDouble()),
        isBuy: tradeMap['isBuy'] as bool,
        timestamp: (tradeMap['timestamp'] as num).toInt(),
        orderStatus: tradeMap['orderStatus'] as String,
        profit: (tradeMap['profit'] is num)
            ? MoneyAmount.fromDouble((tradeMap['profit'] as num).toDouble())
            : null,
      );

      final openTradesList = (stateMap['openTrades'] as List).map((dynamic t) {
        final tradeData = (t as Map).cast<String, Object?>();
        return FifoAppTrade(
          price: Decimal.parse((tradeData['price'] as num).toString()),
          quantity: Decimal.parse((tradeData['quantity'] as num).toString()),
          timestamp: (tradeData['timestamp'] as num).toInt(),
          roundId: (tradeData['roundId'] as num).toInt(),
        );
      }).toList();

      final newState = AppStrategyState(
        symbol: stateMap['symbol'] as String,
        openTrades: openTradesList,
        status: StrategyState.values[(stateMap['statusIndex'] as num).toInt()],
        currentRoundId: (stateMap['currentRoundId'] as num).toInt(),
        cumulativeProfit: (stateMap['cumulativeProfit'] as num).toDouble(),
        successfulRounds: (stateMap['successfulRounds'] as num).toInt(),
        failedRounds: (stateMap['failedRounds'] as num).toInt(),
      );

      final txn = sl<TradingTransactionManager>();
      final result = await txn.saveTradeAndState(trade, newState);
      result.fold(
        (f) => _logger
            .e('Persistenza centralizzata fallita per $symbol: ${f.message}'),
        (_) {
          _logger.i(
              'Persistenza centralizzata completata per $symbol (trade + stato).');
          // Invalida cache dell'AtomicStateManager persistente per evitare letture stantie
          try {
            sl<AtomicStateManager>().invalidateCache();
          } catch (e) {
            _logger
                .w('Informing: Cache invalidation failed after trade sync: $e');
          }
        },
      );
    } catch (e, s) {
      _logger.e('Errore nel processare sync_trade_state: $e', stackTrace: s);
    }
  }

  Future<void> stopAndRemoveLoop(String symbol) async {
    final sendPort = _sendPorts[symbol];
    final shutdownCompleter = _shutdownCompleters[symbol];

    if (sendPort == null || shutdownCompleter == null) {
      _logger.w(
          'Nessun trading loop in esecuzione trovato per $symbol. Avvio pulizia forzata delle risorse.');
      // Fallback per pulire risorse orfane.
      _isolates.remove(symbol)?.kill(priority: Isolate.immediate);
      _sendPorts.remove(symbol);
      _receivePorts.remove(symbol)?.close();
      _shutdownCompleters.remove(symbol);
      _lastAppliedStateVersion.remove(symbol);

      // Unregister isolate from health monitor
      _healthMonitor.unregisterIsolate(symbol);

      // Pulizia cache calcolata per questo simbolo
      // Pulizia cache calcolata per questo simbolo (REMOVED: Instance-level memoization now used)
      // AppStrategyState.clearCacheForSymbol(symbol);

      return;
    }

    _logger.i('Invio comando di shutdown all\'isolate per $symbol.');
    sendPort.send(ShutdownCommand());

    try {
      final shutdownTimeoutSecs = int.tryParse(
              (Platform.environment['ISOLATE_SHUTDOWN_TIMEOUT_S'] ?? '')
                  .trim()) ??
          5;
      await shutdownCompleter.future
          .timeout(Duration(seconds: shutdownTimeoutSecs));
      _logger.i('Shutdown graduale per $symbol completato con successo.');
    } on TimeoutException {
      _logger
          .e('Timeout durante lo shutdown per $symbol. Avvio pulizia forzata.');
      // Il timeout è un evento eccezionale. La pulizia viene forzata.
      final isolate = _isolates[symbol];
      final receivePort = _receivePorts[symbol];

      // La chiusura della porta attiverà il listener `onDone` che pulirà le mappe.
      receivePort?.close();
      isolate?.kill(priority: Isolate.immediate);
    }
  }

  /// Invia un comando all'isolate per resettare i circuit breaker interni.
  void resetCircuitBreakersForSymbol(String symbol) {
    final sendPort = _sendPorts[symbol];
    if (sendPort != null) {
      _logger.i(
          'Invio comando di reset circuit breaker all\'isolate per $symbol.');
      try {
        sendPort.send(ResetCircuitBreakerCommand());
      } catch (e) {
        _logger.w('Fallito invio ResetCircuitBreakerCommand per $symbol: $e');
      }
    } else {
      _logger.w(
          'Impossibile resettare circuit breaker per $symbol: isolate non trovato.');
    }
  }

  /// Ottieni informazioni di salute per tutti gli isolates
  Map<String, IsolateHealthInfo> getHealthInfo() {
    return _healthMonitor.getAllHealthInfo();
  }

  /// Ottieni informazioni di salute per un isolate specifico
  IsolateHealthInfo? getHealthInfoForSymbol(String symbol) {
    return _healthMonitor.getHealthInfo(symbol);
  }

  /// Ottieni un report di salute completo
  Map<String, dynamic> getHealthReport() {
    return _healthMonitor.generateHealthReport();
  }

  /// Stream di aggiornamenti sulla salute degli isolates
  Stream<Map<String, IsolateHealthInfo>> get healthStream =>
      _healthMonitor.healthStream;

  /// Gestisce i messaggi in ingresso dall'isolate in modo centralizzato
  void _handleIsolateMessage(
    dynamic message,
    String symbol,
    Completer<SendPort> sendPortCompleter,
    Completer<void> shutdownCompleter,
    Completer<String?>? loopStartCompleter,
  ) {
    if (message is SendPort) {
      _logger.d('Ricevuto SendPort dall\'isolate per $symbol.');
      _sendPorts[symbol] = message;
      if (!sendPortCompleter.isCompleted) {
        sendPortCompleter.complete(message);
      }
      // Registra l'isolate nell'health monitor appena disponibile il canale
      _healthMonitor.registerIsolate(symbol);
    } else if (message is HeartbeatMessage) {
      _healthMonitor.processHeartbeat(message);
    } else if (message is Map && message['type'] == 'sync_trade_state') {
      _logger.d(
          'Received sync_trade_state from isolate for $symbol. Persisting in main.');
      _handleSyncTradeState(message);
    } else if (message is Map && message['type'] == 'sync_error_state') {
      _logger.w('Received sync_error_state from isolate for $symbol.');
      _handleSyncErrorState(message);
    } else if (message is Map && message['type'] == 'sync_warning_state') {
      try {
        final warnSym = message['symbol'] as String? ?? symbol;
        final warnMsg = message['warning'] as String? ?? 'Avviso';
        _logger.w('sync_warning_state for $warnSym: $warnMsg');
        _healthMonitor.recordTradingOperation(warnSym,
            success: true, error: warnMsg);
      } catch (e, s) {
        _logger.e('Error handling sync_warning_state: $e', stackTrace: s);
      }
    } else if (message is Map && message['type'] == 'log_entry') {
      try {
        final entryMap = (message['entry'] as Map).cast<String, Object?>();
        final logEntry = domain.LogEntry(
          level: (entryMap['level'] as String?) ?? 'INFO',
          message: (entryMap['message'] as String?) ?? '',
          timestamp: DateTime.fromMillisecondsSinceEpoch(
              (entryMap['timestamp'] as num?)?.toInt() ??
                  DateTime.now().millisecondsSinceEpoch),
          serviceName: (entryMap['serviceName'] as String?) ?? 'Isolate',
        );
        LogStreamService().addLog(logEntry);
      } catch (err, st) {
        _logger.w('Unable to forward log from isolate: $err', stackTrace: st);
      }
    } else if (message is Map && message['type'] == 'loop_started') {
      _logger.i('Handshake: loop_started for $symbol');
      if (loopStartCompleter != null && !loopStartCompleter.isCompleted) {
        loopStartCompleter.complete(null);
      }
    } else if (message is Map && message['type'] == 'loop_failed') {
      final loopStartError = (message['error'] as String?) ?? 'unknown';
      _logger.w('Handshake: loop_failed for $symbol: $loopStartError');
      if (loopStartCompleter != null && !loopStartCompleter.isCompleted) {
        loopStartCompleter.complete(loopStartError);
      }
    } else if (message == 'shutdown_ack') {
      _logger.i('Shutdown confirmed from isolate for $symbol.');
      if (!shutdownCompleter.isCompleted) {
        shutdownCompleter.complete();
      }
    } else if (message is List && message.length == 2) {
      final err = message[0];
      final st = message[1];
      final errMsg = err.toString();
      final isTransient = errMsg.contains('Timeout') ||
          errMsg.contains('temporary') ||
          errMsg.contains('unavailable');
      final category = isTransient ? 'transient' : 'permanent';
      _logger.e('Error from isolate $symbol [$category]: $err',
          stackTrace: StackTrace.fromString(st.toString()));

      // Se siamo in fase di startup e abbiamo un errore, falliamo il sendPortCompleter
      if (!sendPortCompleter.isCompleted) {
        sendPortCompleter.completeError('Isolate error: $err');
      }
    } else {
      _logger.d('Generic message from isolate $symbol: $message');
    }
  }

  /// Avvia un loop di trading atomico per un simbolo specifico.
  /// Versione migliorata che utilizza AtomicStateManager per prevenire race conditions.
  Future<bool> startAtomicLoopForSymbol(String symbol, AppSettings settings,
      AppStrategyState initialState) async {
    if (_isolates.containsKey(symbol)) {
      _logger.w(
          'Attempting to start an atomic trading loop for $symbol which is already running.');
      return true; // consideriamo già "avviato"
    }

    final receivePort = ReceivePort();
    final shutdownCompleter = Completer<void>();

    _receivePorts[symbol] = receivePort;
    _shutdownCompleters[symbol] = shutdownCompleter;

    final isolate = await Isolate.spawn(
      atomicTradingLoopEntrypoint,
      AtomicIsolateEntryPointData(
        mainSendPort: receivePort.sendPort,
        settings: settings,
        symbol: symbol,
        initialState: initialState, // Inietta lo stato iniziale
      ),
      onError: receivePort.sendPort,
      onExit: receivePort.sendPort,
    );
    _isolates[symbol] = isolate;

    final sendPortCompleter = Completer<SendPort>();
    final loopStartCompleter = Completer<String?>();

    // Gestisce la comunicazione dall'isolate atomico
    receivePort.listen(
      (message) {
        _handleIsolateMessage(message, symbol, sendPortCompleter,
            shutdownCompleter, loopStartCompleter);
      },
      onDone: () {
        _logger.w(
            'ReceivePort atomico per $symbol è stato chiuso. Avvio pulizia risorse.');
        if (!shutdownCompleter.isCompleted) {
          shutdownCompleter.complete();
        }
        _isolates.remove(symbol);
        _sendPorts.remove(symbol);
        _receivePorts.remove(symbol);
        _shutdownCompleters.remove(symbol);
        _healthMonitor.unregisterIsolate(symbol);
        _logger
            .i('Risorse per l\'isolate atomico $symbol completamente pulite.');
      },
      onError: (error, stackTrace) {
        _logger.e('Errore di comunicazione con l\'isolate atomico $symbol',
            error: error, stackTrace: stackTrace);
        if (!shutdownCompleter.isCompleted) {
          shutdownCompleter.complete();
        }
      },
    );

    _logger.i('Trading loop atomico per $symbol avviato con successo.');

    // Attendi disponibilità del canale (SendPort)
    final sendPortRetries = int.tryParse(
            (Platform.environment['ISOLATE_SENDPORT_RETRIES'] ?? '').trim()) ??
        1;
    int attempt = 0;
    int baseDelayMs = 300;

    try {
      while (true) {
        attempt++;
        try {
          await sendPortCompleter.future.timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Atomic isolate startup timeout',
                  const Duration(seconds: 10));
            },
          );
          break; // ottenuto
        } on TimeoutException {
          if (attempt > sendPortRetries + 1) {
            rethrow;
          }
          final jitter = Duration(milliseconds: (baseDelayMs / 2).round());
          final delay = Duration(milliseconds: baseDelayMs) + jitter;
          _logger.w(
              'Retry in attesa SendPort per $symbol tra ${delay.inMilliseconds}ms (attempt $attempt/${sendPortRetries + 1})');
          await Future.delayed(delay);
          baseDelayMs = (baseDelayMs * 2).clamp(300, 4000);
          continue;
        }
      }
    } catch (e) {
      _logger.e('Fallimento attesa SendPort per $symbol: $e');
      _cleanupFailedStartup(symbol);
      rethrow;
    }

    // Handshake: attendi esito di avvio del loop
    try {
      final loopStartTimeoutSecs = int.tryParse(
              (Platform.environment['ISOLATE_LOOP_START_TIMEOUT_S'] ?? '')
                  .trim()) ??
          10;
      final errorMsg = await loopStartCompleter.future
          .timeout(Duration(seconds: loopStartTimeoutSecs));
      if (errorMsg != null) {
        _logger.w(
            'Avvio loop atomico non riuscito per $symbol (handshake error: $errorMsg).');
        _cleanupFailedStartup(symbol);
        throw Exception(errorMsg);
      }
      return true;
    } on TimeoutException catch (_) {
      _logger.w(
          'Timeout in attesa di loop_started per $symbol. Considero avvio fallito.');
      _cleanupFailedStartup(symbol);
      return false;
    }
  }

  void _cleanupFailedStartup(String symbol) {
    final isolate = _isolates.remove(symbol);
    isolate?.kill(priority: Isolate.immediate);
    final receivePort = _receivePorts.remove(symbol);
    receivePort?.close();
    _sendPorts.remove(symbol);
    _shutdownCompleters.remove(symbol);
    _lastAppliedStateVersion.remove(symbol);
    // Pulizia cache calcolata per questo simbolo
    // Pulizia cache calcolata per questo simbolo (REMOVED: Instance-level memoization now used)
    // AppStrategyState.clearCacheForSymbol(symbol);
  }

  @Deprecated('Use startAtomicLoopForSymbol instead')
  Future<void> startLoopForSymbol(String symbol, AppSettings settings,
      AppStrategyState initialState) async {
    await startAtomicLoopForSymbol(symbol, settings, initialState);
  }

  /// Pulisce tutte le risorse
  void dispose() {
    _logger.i('Avvio procedura di dispose per TradingLoopManager...');
    _healthMonitor.stop();
    final symbols = _isolates.keys.toList();
    for (final symbol in symbols) {
      _logger.d('Chiusura forzata per l\'isolate $symbol durante il dispose.');
      _isolates[symbol]?.kill(priority: Isolate.immediate);
      _receivePorts[symbol]?.close();
    }
    _isolates.clear();
    _sendPorts.clear();
    _receivePorts.clear();
    _shutdownCompleters.clear();
    // Pulizia totale della cache calcolata
    // Pulizia totale della cache calcolata (REMOVED: Instance-level memoization now used)
    // AppStrategyState.clearAllCache();
    _logger.i('TradingLoopManager disposed.');
  }
}
