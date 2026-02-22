import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive_ce/hive.dart';
import 'package:mutex/mutex.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/strategy_state_repository.dart';
import 'package:neotradingbotback1777/domain/services/i_trading_api_service.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/app_strategy_state_hive_dto.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/fifo_app_trade_hive_dto.dart';

class StrategyStateRepositoryImpl implements StrategyStateRepository {
  final Box<AppStrategyStateHiveDto> _strategyStateBox;
  final Box<FifoAppTradeHiveDto> _fifoTradeBox;
  final ITradingApiService _apiService;
  final _log = LogManager.getLogger();
  final Mutex _writeMutex = Mutex();

  // Cache in-memory per ridurre accessi a Hive e fungere da single source of truth per questo isolato
  final Map<String, AppStrategyState> _memoryCache = {};

  final Map<String, StreamController<Either<Failure, AppStrategyState>>>
      _stateStreams = {};

  StrategyStateRepositoryImpl({
    required Box<AppStrategyStateHiveDto> strategyStateBox,
    required Box<FifoAppTradeHiveDto> fifoTradeBox,
    required ITradingApiService apiService,
  })  : _strategyStateBox = strategyStateBox,
        _fifoTradeBox = fifoTradeBox,
        _apiService = apiService;

  String get _modePrefix => _apiService.isTestMode ? 'test_' : 'real_';

  String _getStateKey(String symbol) => '${_modePrefix}$symbol';

  String _tradeSignature(
      String price, String quantity, int timestamp, int roundId) {
    // Firma deterministica: usa la rappresentazione stringa e SHA1 standard
    final signatureInput = '$price|$quantity|$timestamp|$roundId';
    // Usa hashing di libreria per ridurre rischio di collisioni e mantenere il codice minimale
    return sha1.convert(utf8.encode(signatureInput)).toString();
  }

  @override
  Future<Either<Failure, void>> saveStrategyState(
      AppStrategyState state) async {
    return await _writeMutex.protect(() => _saveStrategyStateInternal(state));
  }

  /// Logica di salvataggio interna SENZA acquisizione del mutex.
  /// Chiamato da [saveStrategyState] (con mutex) e da
  /// [updateStrategyStateAtomically] (che detiene già il mutex).
  Future<Either<Failure, void>> _saveStrategyStateInternal(
      AppStrategyState state) async {
    try {
      _log.d(
          'Saving strategy state for ${state.symbol} (Mode: ${_apiService.isTestMode ? 'TEST' : 'REAL'})');

      final key = _getStateKey(state.symbol);

      // Aggiorna immediatamente la cache in memoria
      _memoryCache[key] = state;
      // --- LOGICA DI SALVATAGGIO OTTIMIZZATA (DELTA-SAVE) ---
      // Leggiamo sempre da Hive per il delta-save per essere sicuri di cosa c'è su disco
      // e non lasciare trade orfani se la cache fosse per qualche motivo desincronizzata (improbabile ma sicuro)
      final existingStateDto = _strategyStateBox.get(key);
      final Map<String, FifoAppTradeHiveDto> existingBySig = {};
      if (existingStateDto != null) {
        // Gestisce openTrades che può essere nullable
        if (existingStateDto.openTrades != null) {
          for (final dto in existingStateDto.openTrades!) {
            final sig = _tradeSignature(dto.priceStr ?? '0',
                dto.quantityStr ?? '0', dto.timestamp ?? 0, dto.roundId ?? 0);
            existingBySig[sig] = dto;
          }
        }
      }

      final Set<String> newSigs = {};
      final List<FifoAppTradeHiveDto> finalRefs = [];

      // Riusa DTO esistenti se la stessa entry è ancora presente, altrimenti crea nuovo DTO
      for (final trade in state.openTrades) {
        final sig = _tradeSignature(trade.price.toString(),
            trade.quantity.toString(), trade.timestamp, trade.roundId);
        newSigs.add(sig);
        final existing = existingBySig[sig];
        if (existing != null) {
          finalRefs.add(existing);
        } else {
          final newDto = FifoAppTradeHiveDto.fromEntity(trade);
          await _fifoTradeBox.add(newDto);
          finalRefs.add(newDto);
        }
      }

      // Elimina DTO obsoleti non più referenziati
      if (existingStateDto != null && existingStateDto.openTrades != null) {
        final obsolete = existingStateDto.openTrades!
            .where((dto) {
              final sig = _tradeSignature(dto.priceStr ?? '0',
                  dto.quantityStr ?? '0', dto.timestamp ?? 0, dto.roundId ?? 0);
              return !newSigs.contains(sig);
            })
            .map((dto) => dto.key)
            .where((k) => k != null)
            .toList();

        if (obsolete.isNotEmpty) {
          await _fifoTradeBox.deleteAll(obsolete);
        }
      }

      // Costruisci HiveList aggiornata
      final fifoHiveList = HiveList<FifoAppTradeHiveDto>(_fifoTradeBox)
        ..addAll(finalRefs);

      // Aggiorna/crea DTO stato
      final stateDto = AppStrategyStateHiveDto.fromEntity(state, fifoHiveList);
      await _strategyStateBox.put(key, stateDto);

      // Notifica gli ascoltatori dello stream
      // ignore: close_sinks
      final streamController = _stateStreams[key];
      if (streamController != null && !streamController.isClosed) {
        streamController.add(Right(state));
      }

      _log.d('Strategy state saved for ${state.symbol}');
      return const Right(null);
    } catch (e, stackTrace) {
      _log.e('Error saving strategy state for ${state.symbol}: $e',
          stackTrace: stackTrace);
      return Left(CacheFailure(message: 'Failed to save strategy state: $e'));
    }
  }

  @override
  Future<Either<Failure, AppStrategyState?>> getStrategyState(
      String symbol) async {
    try {
      final key = _getStateKey(symbol);
      // 1. Controlla prima la cache in memoria
      if (_memoryCache.containsKey(key)) {
        _log.d('Strategy state cache hit for $symbol');
        return Right(_memoryCache[key]);
      }

      _log.d(
          'Cache miss. Retrieving strategy state from Hive for $symbol (Mode: ${_apiService.isTestMode ? 'TEST' : 'REAL'})');

      final stateDto = _strategyStateBox.get(key);
      if (stateDto != null) {
        final state = stateDto.toEntity();

        // Popola la cache
        _memoryCache[key] = state;

        _log.d('Strategy state found for $symbol and cached');
        return Right(state);
      }

      _log.d('No strategy state found for $symbol');
      return const Right(null);
    } catch (e, stackTrace) {
      _log.e('Error retrieving strategy state for $symbol: $e',
          stackTrace: stackTrace);
      return Left(
          CacheFailure(message: 'Failed to retrieve strategy state: $e'));
    }
  }

  @override
  Stream<Either<Failure, AppStrategyState>> subscribeToStateStream(
      String symbol) {
    _log.d('Creating strategy state stream for $symbol');

    final key = _getStateKey(symbol);
    if (_stateStreams.containsKey(key)) {
      _log.d('Returning existing strategy state stream for $symbol');
      return _stateStreams[key]!.stream;
    }

    final StreamController<Either<Failure, AppStrategyState>> streamController =
        StreamController<Either<Failure, AppStrategyState>>.broadcast();

    streamController.onCancel = () async {
      _log.d('Strategy state stream listener cancelled for $symbol');
      if (!streamController.hasListener) {
        _stateStreams.remove(key);
        if (!streamController.isClosed) {
          await streamController.close();
        }
      }
    };

    _stateStreams[key] = streamController;

    // Se abbiamo dati in cache, emettiamo subito lo stato corrente
    if (_memoryCache.containsKey(key)) {
      streamController.add(Right(_memoryCache[key]!));
    } else {
      // Se non è in cache, proviamo a caricarlo (senza attendere, fire-and-forget per lo stream)
      getStrategyState(symbol).then((result) {
        result.fold((failure) {
          if (!streamController.isClosed) streamController.add(Left(failure));
        }, (state) {
          if (state != null && !streamController.isClosed) {
            streamController.add(Right(state));
          }
        });
      });
    }

    return streamController.stream;
  }

  @override
  Future<Either<Failure, AppStrategyState>> updateStrategyStateAtomically(
    String symbol,
    AppStrategyState Function(AppStrategyState? currentState) updateFunction,
  ) async {
    return await _writeMutex.protect(() async {
      try {
        _log.d('Updating strategy state atomically for $symbol');

        // Usa getStrategyState che controlla la cache
        final currentStateResult = await getStrategyState(symbol);
        final currentState = currentStateResult.fold(
          (failure) => throw ValidationFailure(
              message: 'Failed to get current state: ${failure.message}'),
          (state) => state,
        );

        final updatedState = updateFunction(currentState);

        // _saveStrategyStateInternal aggiornerà la cache
        final saveResult = await _saveStrategyStateInternal(updatedState);
        return saveResult.fold(
          (failure) => Left(failure),
          (_) {
            _log.d('Strategy state updated atomically for $symbol');
            return Right(updatedState);
          },
        );
      } catch (e, stackTrace) {
        _log.e('Error in atomic update for $symbol: $e',
            stackTrace: stackTrace);
        return Left(CacheFailure(message: 'Atomic update failed: $e'));
      }
    });
  }

  @override
  Future<Either<Failure, void>> resetStrategyState(String symbol) async {
    try {
      _log.d('Resetting strategy state for $symbol');

      final initialState = AppStrategyState(symbol: symbol);
      // save aggiornerà la cache
      return await _saveStrategyStateInternal(initialState);
    } catch (e, stackTrace) {
      _log.e('Error resetting strategy state for $symbol: $e',
          stackTrace: stackTrace);
      return Left(CacheFailure(message: 'Failed to reset strategy state: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, AppStrategyState>>>
      getAllStrategyStates() async {
    try {
      _log.d(
          'Getting all strategy states (Mode: ${_apiService.isTestMode ? 'TEST' : 'REAL'})');

      final Map<String, AppStrategyState> states = {};
      final prefix = _modePrefix;

      for (final entry in _strategyStateBox.toMap().entries) {
        final key = entry.key as String;
        if (key.startsWith(prefix)) {
          final stateDto = entry.value;
          final state = stateDto.toEntity();
          // Gestione sicura del simbolo nullable
          final symbol = stateDto.symbol ?? state.symbol;
          if (symbol.isNotEmpty) {
            states[symbol] = state;

            // Popola la cache in modo opportunistico
            _memoryCache[key] = state;
          }
        }
      }

      _log.d('Found ${states.length} strategy states');
      return Right(states);
    } catch (e, stackTrace) {
      _log.e('Error getting all strategy states: $e', stackTrace: stackTrace);
      return Left(
          CacheFailure(message: 'Failed to get all strategy states: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteStrategyState(String symbol) async {
    return await _writeMutex.protect(() async {
      try {
        _log.d(
            'Deleting strategy state for $symbol (Mode: ${_apiService.isTestMode ? 'TEST' : 'REAL'})');

        final key = _getStateKey(symbol);
        // Rimuovi dalla cache
        _memoryCache.remove(key);

        await _cleanupFifoTrades(symbol);
        await _strategyStateBox.delete(key);

        final streamController = _stateStreams.remove(key);
        await streamController?.close();

        _log.d('Strategy state deleted for $symbol');
        return const Right(null);
      } catch (e, stackTrace) {
        _log.e('Error deleting strategy state for $symbol: $e',
            stackTrace: stackTrace);
        return Left(
            CacheFailure(message: 'Failed to delete strategy state: $e'));
      }
    });
  }

  @override
  Future<Either<Failure, bool>> hasStrategyState(String symbol) async {
    try {
      final key = _getStateKey(symbol);
      final exists = _strategyStateBox.containsKey(key);
      return Right(exists);
    } catch (e, stackTrace) {
      _log.e('Error checking strategy state existence for $symbol: $e',
          stackTrace: stackTrace);
      return Left(CacheFailure(
          message: 'Failed to check strategy state existence: $e'));
    }
  }

  Future<void> _cleanupFifoTrades(String symbol) async {
    try {
      // Cancella solo i trade FIFO referenziati dallo stato del simbolo nel modo corrente
      final key = _getStateKey(symbol);
      final stateDto = _strategyStateBox.get(key);
      if (stateDto == null) {
        _log.d('No previous FIFO trades to clean for $symbol');
        return;
      }

      if (stateDto.openTrades == null) {
        _log.d('No open trades list to clean for $symbol');
        return;
      }

      final keysToDelete = stateDto.openTrades!
          .map((t) => t.key)
          .where((k) => k != null)
          .toList();

      if (keysToDelete.isEmpty) {
        _log.d('No FIFO trades referenced to clean for $symbol');
        return;
      }

      await _fifoTradeBox.deleteAll(keysToDelete);
      _log.d('Cleaned up ${keysToDelete.length} FIFO trades for $symbol');
    } catch (e, stackTrace) {
      _log.e('Error cleaning up FIFO trades for $symbol: $e',
          stackTrace: stackTrace);
      rethrow;
    }
  }

  void dispose() {
    _log.d('Disposing StrategyStateRepositoryImpl');

    for (final streamController in _stateStreams.values) {
      streamController.close();
    }
    _stateStreams.clear();

    _log.d('StrategyStateRepositoryImpl disposed');
  }
}
