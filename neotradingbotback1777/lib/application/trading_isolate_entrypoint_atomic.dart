import 'dart:async';
import 'dart:isolate';
import 'package:get_it/get_it.dart';
import 'package:neotradingbotback1777/application/use_cases/start_trading_loop_atomic_use_case.dart';
import 'package:neotradingbotback1777/application/monitoring/isolate_health_monitor.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/application/managers/atomic_state_manager.dart';
import 'package:neotradingbotback1777/injection.dart'
    show configureAtomicIsolateDependencies;
import 'package:neotradingbotback1777/application/managers/trading_loop_manager.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';

/// Data class to pass necessary information to the atomic isolate entry point.
class AtomicIsolateEntryPointData {
  final SendPort mainSendPort;
  final AppSettings settings;
  final String symbol;
  final AppStrategyState initialState; // Inietta lo stato iniziale

  AtomicIsolateEntryPointData({
    required this.mainSendPort,
    required this.settings,
    required this.symbol,
    required this.initialState,
  });
}

/// Entry point atomico per il trading Isolate.
/// Versione migliorata che risolve i race conditions tramite AtomicStateManager.
Future<void> atomicTradingLoopEntrypoint(
    AtomicIsolateEntryPointData data) async {
  final mainSendPort = data.mainSendPort;
  final isolateReceivePort = ReceivePort();

  // Send the isolate's SendPort back to the main thread for communication.
  mainSendPort.send(isolateReceivePort.sendPort);

  // Initialize separate GetIt instance for this Isolate to avoid conflicts
  final GetIt isolateGetIt = GetIt.asNewInstance();
  await configureAtomicIsolateDependencies(isolateGetIt);

  final startTradingLoopAtomic = isolateGetIt.get<StartTradingLoopAtomic>();
  Timer? heartbeatTimer;
  bool isLoopActive = false;
  int executionCount = 0;
  int errorCount = 0;
  DateTime lastSuccessTime = DateTime.now();

  // Function to send heartbeat to main isolate
  void sendHeartbeat({String? error}) {
    final heartbeat = HeartbeatMessage(
      symbol: data.symbol,
      timestamp: DateTime.now(),
      error: error,
      metrics: {
        'executionCount': executionCount,
        'errorCount': errorCount,
        'lastSuccessTime': lastSuccessTime.toIso8601String(),
        'isLoopActive': isLoopActive,
        'isolateType': 'atomic',
      },
    );
    mainSendPort.send(heartbeat);
  }

  // Start heartbeat timer - send heartbeat every 30 seconds
  heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
    sendHeartbeat();
  });

  // Listen for commands from the main thread.
  isolateReceivePort.listen((message) {
    if (message is ShutdownCommand) {
      LogManager.getLogger().i(
          'Atomic Isolate [${data.symbol}]: Shutdown command received. Cleaning up...');

      // Stop trading loop
      if (isLoopActive) {
        startTradingLoopAtomic.stop();
        isLoopActive = false;
      }

      heartbeatTimer?.cancel();

      // Send acknowledgment to the main thread BEFORE closing the port.
      mainSendPort.send('shutdown_ack');

      isolateReceivePort.close();
      LogManager.getLogger().i('Atomic Isolate [${data.symbol}]: Terminated.');
    } else if (message is ResetCircuitBreakerCommand) {
      LogManager.getLogger().i(
          'Atomic Isolate [${data.symbol}]: Reset Circuit Breaker command received. Resetting...');
      startTradingLoopAtomic.resetCircuitBreakers();
    }
  });

  // Avvia il loop di trading atomico
  try {
    LogManager.getLogger()
        .i('Atomic Isolate [${data.symbol}]: Starting atomic trading loop...');

    // Seed solo in-memory: la persistenza autoritativa avviene nel main
    final atomicStateManager = isolateGetIt.get<AtomicStateManager>();
    atomicStateManager.seedState(data.initialState);
    LogManager.getLogger().i(
        'Atomic Isolate [${data.symbol}]: Initial state seeded in-memory (${data.initialState.status}).');

    // Inietta il SendPort principale per sync trade/stato
    startTradingLoopAtomic.setMainSendPort(mainSendPort);

    final started = await startTradingLoopAtomic.call(
      symbol: data.symbol,
      settings: data.settings,
      initialState: data.initialState, // Passa lo stato iniettato
    );
    if (started) {
      // Handshake al main: loop avviato
      mainSendPort.send({'type': 'loop_started', 'symbol': data.symbol});
      isLoopActive = true;
      executionCount++;
      lastSuccessTime = DateTime.now();
      LogManager.getLogger().i(
          'Atomic Isolate [${data.symbol}]: Atomic trading loop started successfully.');
      // Invia heartbeat di successo
      sendHeartbeat();
    } else {
      // Non avviato: invia heartbeat con errore e non segnare attivo
      final errorMessage =
          'Atomic trading loop did not start due to pre-flight failure or missing price.';
      // Handshake al main: avvio fallito
      mainSendPort.send({
        'type': 'loop_failed',
        'symbol': data.symbol,
        'error': errorMessage
      });
      sendHeartbeat(error: errorMessage);
    }
  } catch (e, stackTrace) {
    errorCount++;
    final errorMessage = 'Error starting atomic trading loop: $e';
    LogManager.getLogger().e('Atomic Isolate [${data.symbol}]: $errorMessage',
        error: e, stackTrace: stackTrace);

    // Send immediate heartbeat with error
    // Handshake al main: avvio fallito
    mainSendPort.send(
        {'type': 'loop_failed', 'symbol': data.symbol, 'error': errorMessage});
    sendHeartbeat(error: errorMessage);

    isLoopActive = false;
  }
}
