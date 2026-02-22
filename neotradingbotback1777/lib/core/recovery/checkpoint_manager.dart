import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:logger/logger.dart';
import 'package:decimal/decimal.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/fifo_app_trade.dart';

/// Gestore dei checkpoint per la persistenza dello stato e il recovery automatico
///
/// Questo sistema implementa un meccanismo di checkpoint asincrono che salva
/// periodicamente lo stato della strategia su disco, permettendo la ripresa
/// automatica in caso di crash o riavvio dell'applicazione.
class CheckpointManager {
  final String _checkpointDir;
  final Duration _checkpointInterval;
  final Logger _log;
  Timer? _checkpointTimer;

  /// Mappa dei checkpoint per simbolo
  final Map<String, _CheckpointData> _checkpoints = {};

  /// Callback per il salvataggio dello stato
  final Future<void> Function(String symbol, AppStrategyState state)?
      _onStateSave;

  /// Callback per il caricamento dello stato
  final Future<AppStrategyState?> Function(String symbol)? _onStateLoad;

  CheckpointManager({
    String? checkpointDir,
    Duration? checkpointInterval,
    Future<void> Function(String symbol, AppStrategyState state)? onStateSave,
    Future<AppStrategyState?> Function(String symbol)? onStateLoad,
    Logger? logger,
  })  : _checkpointDir = checkpointDir ?? _getDefaultCheckpointDir(),
        _checkpointInterval = checkpointInterval ?? const Duration(minutes: 1),
        _onStateSave = onStateSave,
        _onStateLoad = onStateLoad,
        _log = logger ?? LogManager.getLogger() {
    _initializeCheckpointDir();
  }

  /// Inizializza la directory dei checkpoint
  void _initializeCheckpointDir() {
    try {
      final dir = Directory(_checkpointDir);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
        _log.i('[CHECKPOINT] Created checkpoint directory: $_checkpointDir');
      }
    } catch (e) {
      _log.e('[CHECKPOINT] Failed to create checkpoint directory: $e');
    }
  }

  /// Avvia il sistema di checkpoint automatico
  void startAutomaticCheckpoints() {
    _checkpointTimer?.cancel();
    _checkpointTimer = Timer.periodic(_checkpointInterval, (_) {
      _performPeriodicCheckpoint();
    });
    _log.i(
        '[CHECKPOINT] Started automatic checkpoints every ${_checkpointInterval.inSeconds} seconds');
  }

  /// Ferma il sistema di checkpoint automatico
  void stopAutomaticCheckpoints() {
    _checkpointTimer?.cancel();
    _log.i('[CHECKPOINT] Stopped automatic checkpoints');
  }

  /// Salva un checkpoint per un simbolo specifico
  Future<bool> saveCheckpoint(String symbol, AppStrategyState state) async {
    try {
      final checkpointData = _CheckpointData(
        symbol: symbol,
        state: state,
        timestamp: DateTime.now(),
        version: '1.0.0',
      );

      // Salva su disco
      final success = await _saveToDisk(checkpointData);
      if (success) {
        _checkpoints[symbol] = checkpointData;
        _log.i('[CHECKPOINT] Saved checkpoint for $symbol');

        // Notifica il callback se presente
        if (_onStateSave != null) {
          await _onStateSave(symbol, state);
        }

        return true;
      }

      return false;
    } catch (e) {
      _log.e('[CHECKPOINT] Failed to save checkpoint for $symbol: $e');
      return false;
    }
  }

  /// Carica un checkpoint per un simbolo specifico
  Future<AppStrategyState?> loadCheckpoint(String symbol) async {
    try {
      // Prima prova a caricare dalla memoria
      final memoryCheckpoint = _checkpoints[symbol];
      if (memoryCheckpoint != null && !memoryCheckpoint.isExpired) {
        _log.i('[CHECKPOINT] Loaded checkpoint for $symbol from memory');
        return memoryCheckpoint.state;
      }

      // Se non è in memoria o è scaduto, prova a caricare da disco
      final diskCheckpoint = await _loadFromDisk(symbol);
      if (diskCheckpoint != null && !diskCheckpoint.isExpired) {
        _checkpoints[symbol] = diskCheckpoint;
        _log.i('[CHECKPOINT] Loaded checkpoint for $symbol from disk');

        // Notifica il callback se presente
        if (_onStateLoad != null) {
          await _onStateLoad(symbol);
        }

        return diskCheckpoint.state;
      }

      _log.w('[CHECKPOINT] No valid checkpoint found for $symbol');
      return null;
    } catch (e) {
      _log.e('[CHECKPOINT] Failed to load checkpoint for $symbol: $e');
      return null;
    }
  }

  /// Rimuove un checkpoint per un simbolo specifico
  Future<bool> removeCheckpoint(String symbol) async {
    try {
      // Rimuovi dalla memoria
      _checkpoints.remove(symbol);

      // Rimuovi da disco
      final file = File(_getCheckpointFilePath(symbol));
      if (await file.exists()) {
        await file.delete();
        _log.i('[CHECKPOINT] Removed checkpoint for $symbol');
        return true;
      }

      return true;
    } catch (e) {
      _log.e('[CHECKPOINT] Failed to remove checkpoint for $symbol: $e');
      return false;
    }
  }

  /// Esegue un checkpoint periodico per tutti i simboli attivi
  Future<void> _performPeriodicCheckpoint() async {
    try {
      final symbols = _checkpoints.keys.toList();
      int successCount = 0;

      for (final symbol in symbols) {
        final checkpoint = _checkpoints[symbol];
        if (checkpoint != null && !checkpoint.isExpired) {
          final success = await saveCheckpoint(symbol, checkpoint.state);
          if (success) successCount++;
        }
      }

      if (successCount > 0) {
        _log.i(
            '[CHECKPOINT] Periodic checkpoint completed: $successCount/$symbols saved');
      }
    } catch (e) {
      _log.e('[CHECKPOINT] Periodic checkpoint failed: $e');
    }
  }

  /// Salva un checkpoint su disco
  Future<bool> _saveToDisk(_CheckpointData checkpoint) async {
    try {
      final file = File(_getCheckpointFilePath(checkpoint.symbol));
      final jsonData = checkpoint.toJson();
      await file.writeAsString(jsonEncode(jsonData));
      return true;
    } catch (e) {
      _log.e('[CHECKPOINT] Failed to save to disk: $e');
      return false;
    }
  }

  /// Carica un checkpoint da disco
  Future<_CheckpointData?> _loadFromDisk(String symbol) async {
    try {
      final file = File(_getCheckpointFilePath(symbol));
      if (!await file.exists()) return null;

      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      return _CheckpointData.fromJson(jsonData);
    } catch (e) {
      _log.e('[CHECKPOINT] Failed to load from disk: $e');
      return null;
    }
  }

  /// Genera il percorso del file di checkpoint per un simbolo
  String _getCheckpointFilePath(String symbol) {
    final safeSymbol = symbol.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    return path.join(_checkpointDir, '${safeSymbol}_checkpoint.json');
  }

  /// Ottiene la directory di default per i checkpoint
  static String _getDefaultCheckpointDir() {
    final homeDir = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '.';
    return path.join(homeDir, '.neotradingbot', 'checkpoints');
  }

  /// Ottiene le statistiche dei checkpoint
  Map<String, dynamic> getStats() {
    return {
      'activeCheckpoints': _checkpoints.length,
      'checkpointInterval': _checkpointInterval.inSeconds,
      'checkpointDir': _checkpointDir,
      'isAutomaticEnabled': _checkpointTimer != null,
    };
  }

  /// Chiude il gestore dei checkpoint
  void dispose() {
    stopAutomaticCheckpoints();
    _checkpoints.clear();
    _log.i('[CHECKPOINT] Checkpoint manager disposed');
  }
}

/// Dati di un checkpoint
class _CheckpointData {
  final String symbol;
  final AppStrategyState state;
  final DateTime timestamp;
  final String version;

  /// Durata di validità del checkpoint (24 ore)
  static const Duration _validityDuration = Duration(hours: 24);

  _CheckpointData({
    required this.symbol,
    required this.state,
    required this.timestamp,
    required this.version,
  });

  /// Controlla se il checkpoint è scaduto
  bool get isExpired {
    final now = DateTime.now();
    return now.difference(timestamp) > _validityDuration;
  }

  /// Converte il checkpoint in JSON
  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'state': _stateToJson(state),
      'timestamp': timestamp.toIso8601String(),
      'version': version,
    };
  }

  /// Crea un checkpoint da JSON
  factory _CheckpointData.fromJson(Map<String, dynamic> json) {
    return _CheckpointData(
      symbol: json['symbol'] as String,
      state: _stateFromJson(json['state'] as Map<String, dynamic>),
      timestamp: DateTime.parse(json['timestamp'] as String),
      version: json['version'] as String,
    );
  }

  /// Converte lo stato in JSON con serializzazione completa
  static Map<String, dynamic> _stateToJson(AppStrategyState state) {
    return {
      'symbol': state.symbol,
      'status': state.status.name,
      'currentRoundId': state.currentRoundId,
      'cumulativeProfit': state.cumulativeProfit,
      'successfulRounds': state.successfulRounds,
      'failedRounds': state.failedRounds,
      'targetRoundId': state.targetRoundId,
      'isPriceFrozen': state.isPriceFrozen,
      'lastPriceFreezeTime': state.lastPriceFreezeTime?.toIso8601String(),
      'frozenAveragePrice': state.frozenAveragePrice,
      'currentVolatilityLevel': state.currentVolatilityLevel,
      'priceHistory': state.priceHistory,
      'openTrades':
          state.openTrades.map((trade) => _tradeToJson(trade)).toList(),
    };
  }

  /// Crea lo stato da JSON con deserializzazione completa
  static AppStrategyState _stateFromJson(Map<String, dynamic> json) {
    return AppStrategyState(
      symbol: json['symbol'] as String,
      status: StrategyState.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => StrategyState.IDLE,
      ),
      currentRoundId: json['currentRoundId'] as int? ?? 1,
      cumulativeProfit: json['cumulativeProfit'] as double? ?? 0.0,
      successfulRounds: json['successfulRounds'] as int? ?? 0,
      failedRounds: json['failedRounds'] as int? ?? 0,
      targetRoundId: json['targetRoundId'] as int?,
      isPriceFrozen: json['isPriceFrozen'] as bool? ?? false,
      lastPriceFreezeTime: json['lastPriceFreezeTime'] != null
          ? DateTime.parse(json['lastPriceFreezeTime'] as String)
          : null,
      frozenAveragePrice: json['frozenAveragePrice'] as double?,
      currentVolatilityLevel: json['currentVolatilityLevel'] as double? ?? 0.0,
      priceHistory:
          (json['priceHistory'] as List<dynamic>?)?.cast<double>() ?? [],
      openTrades: (json['openTrades'] as List<dynamic>?)
              ?.map((tradeJson) => _tradeFromJson(tradeJson))
              .toList() ??
          [],
    );
  }

  /// Converte un trade in JSON
  static Map<String, dynamic> _tradeToJson(FifoAppTrade trade) {
    return {
      'price': trade.price.toString(),
      'quantity': trade.quantity.toString(),
      'timestamp': trade.timestamp,
      'roundId': trade.roundId,
      'orderStatus': trade.orderStatus,
      'isExecuted': trade.isExecuted,
    };
  }

  /// Crea un trade da JSON
  static FifoAppTrade _tradeFromJson(Map<String, dynamic> json) {
    return FifoAppTrade(
      price: Decimal.parse((json['price'] is num)
          ? (json['price'] as num).toString()
          : json['price'] as String),
      quantity: Decimal.parse((json['quantity'] is num)
          ? (json['quantity'] as num).toString()
          : json['quantity'] as String),
      timestamp: json['timestamp'] as int,
      roundId: json['roundId'] as int,
      orderStatus: json['orderStatus'] as String? ?? 'FILLED',
      isExecuted: json['isExecuted'] as bool? ?? true,
    );
  }
}
