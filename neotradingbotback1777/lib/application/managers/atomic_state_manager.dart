import 'dart:async';
import 'package:mutex/mutex.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/strategy_state_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';

/// [AUDIT-PHASE-9] Marker for formal Kilo AI audit.
/// Concurrency safety, atomic state consistency, and resilience review.
class _CacheEntry {
  final AppStrategyState state;
  DateTime lastAccess;
  final DateTime creationTime;
  int accessCount;

  _CacheEntry(this.state)
      : lastAccess = DateTime.now(),
        creationTime = DateTime.now(),
        accessCount = 1;

  void updateAccess() {
    lastAccess = DateTime.now();
    accessCount++;
  }
}

/// Gestore atomico dello stato di trading che garantisce consistenza
/// tra stato in memoria e repository, prevenendo race conditions.
class AtomicStateManager {
  final StrategyStateRepository _strategyStateRepository;
  final Mutex _stateMutex = Mutex();
  final _log = LogManager.getLogger();

  // Se false, l'istanza NON persiste su repository (uso isolate: cache in-memory non autoritativa)
  final bool persistChanges;

  // Cache locale dello stato con timestamp per validazione
  AppStrategyState? _cachedState;

  // Timeout per invalidare la cache — ora configurabile per istanza
  final Duration cacheTimeout;

  // === GESTIONE CACHE AVANZATA ===

  // Cache multi-simbolo per supportare strategie multiple
  final Map<String, _CacheEntry> _multiSymbolCache = {};

  // Limiti configurabili per la cache — per istanza
  final int maxCacheEntries;
  final Duration maxCacheAge;

  // Statistiche della cache per monitoring
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _cacheEvictions = 0;
  int _repositoryFetchFailures = 0;
  DateTime _lastCacheCleanup = DateTime.now();
  DateTime _lastHeartbeat = DateTime.now();

  // === CLEANUP PERIODICO ===
  Timer? _cleanupTimer;

  AtomicStateManager(
    this._strategyStateRepository, {
    this.persistChanges = true,
    this.cacheTimeout = const Duration(seconds: 30),
    this.maxCacheEntries = 50,
    this.maxCacheAge = const Duration(minutes: 30),
  });

  /// Esegue un'operazione atomica sullo stato di trading.
  ///
  /// [operation] riceve lo stato corrente e deve restituire il nuovo stato.
  /// L'operazione è protetta da mutex per garantire atomicità.
  ///
  /// Returns: Either&lt;Failure, AppStrategyState&gt;
  Future<Either<Failure, AppStrategyState>> executeAtomicOperation(
    String symbol,
    Future<Either<Failure, AppStrategyState>> Function(
            AppStrategyState currentState)
        operation,
  ) async {
    return await _stateMutex.protect(() async {
      try {
        // 1. Recupera lo stato più aggiornato
        final currentStateResult = await _getCurrentState(symbol);

        return await currentStateResult.fold(
          (failure) => Left(failure),
          (currentState) async {
            // 2. Esegui l'operazione passando lo stato corrente
            final operationResult = await operation(currentState);

            return await operationResult.fold(
              (failure) => Left(failure),
              (newState) async {
                if (persistChanges) {
                  // 3a. Persistenza autoritativa (contesto main)
                  final saveResult = await _strategyStateRepository
                      .saveStrategyState(newState);
                  return saveResult.fold(
                    (failure) => Left(failure),
                    (_) {
                      // Aggiorna la cache multi-simbolo per coerenza
                      _multiSymbolCache[symbol] = _CacheEntry(newState);
                      // Mantiene anche _cachedState per compatibilità ma non è la fonte primaria qui
                      _cachedState = newState;
                      return Right(newState);
                    },
                  );
                } else {
                  // 3b. Solo aggiornamento cache locale (contesto isolate)
                  _cachedState = newState;
                  return Right(newState);
                }
              },
            );
          },
        );
      } catch (e) {
        return Left(UnexpectedFailure(
          message: 'Errore durante operazione atomica: $e',
        ));
      }
    });
  }

  /// Recupera lo stato corrente, utilizzando la cache se valida
  /// o il repository se la cache è scaduta o mancante.
  Future<Either<Failure, AppStrategyState>> _getCurrentState(
      String symbol) async {
    // In modalità non persistente (isolate), la cache è la fonte locale di verità
    if (!persistChanges) {
      if (_cachedState != null) {
        return Right(_cachedState!);
      }
      // Se non seedata, crea uno stato iniziale in-memory
      final initialState = AppStrategyState(symbol: symbol);
      _cachedState = initialState;
      return Right(initialState);
    }

    // Modalità persistente (main): usa repository con cache multi-simbolo

    // Controlla se è necessario pulire la cache
    final now = DateTime.now();
    if (now.difference(_lastCacheCleanup) > const Duration(minutes: 5)) {
      _cleanupCache();
    }

    // Controlla se lo stato è in cache
    final cacheEntry = _multiSymbolCache[symbol];
    if (cacheEntry != null) {
      final cacheAge = now.difference(cacheEntry.lastAccess);
      if (cacheAge < cacheTimeout) {
        cacheEntry.updateAccess();
        _cacheHits++;
        return Right(cacheEntry.state);
      } else {
        // Cache scaduta, rimuovi l'entry
        _multiSymbolCache.remove(symbol);
      }
    }

    _cacheMisses++;

    // Recupera lo stato dal repository
    final repositoryResult =
        await _strategyStateRepository.getStrategyState(symbol);

    return repositoryResult.fold(
      (failure) {
        _repositoryFetchFailures++;
        return Left(failure);
      },
      (state) {
        if (state == null) {
          final initialState = AppStrategyState(symbol: symbol);
          _multiSymbolCache[symbol] = _CacheEntry(initialState);
          return Right(initialState);
        }

        // Salva nella cache multi-simbolo
        _multiSymbolCache[symbol] = _CacheEntry(state);
        return Right(state);
      },
    );
  }

  /// Invalida la cache forzando il reload dal repository
  void invalidateCache() {
    _log.i('Invalidating cache. Final stats: ${getCacheStats()}');
    _cachedState = null;
    _multiSymbolCache.clear();
    _repositoryFetchFailures = 0; // NEW: Reset failures on manual invalidation
  }

  /// Invalida la cache per un simbolo specifico
  void invalidateCacheForSymbol(String symbol) {
    _multiSymbolCache.remove(symbol);
  }

  /// Pulisce la cache rimuovendo le entry più vecchie o meno utilizzate.
  ///
  /// Ottimizzato: prima eviction per età, poi LRU solo se necessario.
  void _cleanupCache() {
    final now = DateTime.now();
    final entriesToRemove = <String>{};

    // Fase 1: Rimuovi entry troppo vecchie (O(n) lineare)
    for (final entry in _multiSymbolCache.entries) {
      final age = now.difference(entry.value.creationTime);
      if (age > maxCacheAge) {
        entriesToRemove.add(entry.key);
        _cacheEvictions++;
      }
    }

    // Rimuovi subito le entry scadute
    for (final symbol in entriesToRemove) {
      _multiSymbolCache.remove(symbol);
    }

    // Fase 2: LRU solo se la cache è ancora troppo grande dopo l'eviction per età
    final remaining = _multiSymbolCache.length - maxCacheEntries;
    if (remaining > 0) {
      final sortedEntries = _multiSymbolCache.entries.toList()
        ..sort((a, b) => a.value.lastAccess.compareTo(b.value.lastAccess));

      for (int i = 0; i < remaining; i++) {
        final key = sortedEntries[i].key;
        _multiSymbolCache.remove(key);
        entriesToRemove.add(key);
        _cacheEvictions++;
      }
    }

    if (entriesToRemove.isNotEmpty) {
      _log.d('Cache cleanup: rimosse ${entriesToRemove.length} entry');
    }

    _lastCacheCleanup = now;
  }

  /// Ottiene le statistiche della cache per monitoring
  Map<String, dynamic> getCacheStats() {
    return {
      'totalEntries': _multiSymbolCache.length,
      'cacheHits': _cacheHits,
      'cacheMisses': _cacheMisses,
      'cacheEvictions': _cacheEvictions,
      'hitRate': _cacheHits + _cacheMisses > 0
          ? (_cacheHits / (_cacheHits + _cacheMisses) * 100).toStringAsFixed(2)
          : '0.00',
      'lastCleanup': _lastCacheCleanup.toIso8601String(),
      'maxEntries': maxCacheEntries,
      'maxAgeMinutes': maxCacheAge.inMinutes,
    };
  }

  /// Forza la pulizia della cache
  void forceCacheCleanup() {
    _cleanupCache();
  }

  /// Avvia il cleanup periodico automatico della cache
  void startPeriodicCleanup({Duration interval = const Duration(minutes: 5)}) {
    stopPeriodicCleanup(); // Ferma eventuali timer esistenti

    _cleanupTimer = Timer.periodic(interval, (timer) {
      _log.d('Esecuzione cleanup periodico cache...');
      _cleanupCache();
    });

    _log.i(
        'Cleanup periodico cache avviato con intervallo: ${interval.inMinutes} minuti');
  }

  /// Ferma il cleanup periodico automatico
  void stopPeriodicCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _log.d('Cleanup periodico cache fermato');
  }

  /// Esegue un heartbeat periodico per monitorare la salute del sistema
  Future<void> performHeartbeat() async {
    final now = DateTime.now();

    // Esegui heartbeat ogni 30 secondi
    if (now.difference(_lastHeartbeat).inSeconds >= 30) {
      final stats = _getSystemHealthStats();
      _log.i('[HEARTBEAT] Statistiche sistema: $stats');

      // Kilo AI: Restore cleanup during heartbeat to prevent accumulation
      _cleanupCache();

      _lastHeartbeat = now;

      // NEW: Periodically reset failure counter to handle transient issues
      // Reset window every 1 hour (as suggested by "lifetime counter never reset")
      if (now.difference(_lastCacheCleanup).inHours >= 1) {
        _repositoryFetchFailures = 0;
        _lastCacheCleanup = now; // Reuse this timestamp for window reset
      }
    }
  }

  /// Calcola statistiche sulla salute del sistema
  Map<String, dynamic> _getSystemHealthStats() {
    final cacheStats = getCacheStats();

    return {
      'timestamp': DateTime.now().toIso8601String(),
      'cache': cacheStats,
      'systemHealth': _isSystemHealthy(),
    };
  }

  /// Controlla se il sistema è in salute basato sulle metriche
  bool _isSystemHealthy() {
    // Sistema considerato non sano se:
    // 1. Cache troppo piena (> 80% del limite)
    // 2. Troppi errori di recupero dal repository (non semplici miss)

    final cacheStats = getCacheStats();

    final totalEntries = cacheStats['totalEntries'] as int;
    final repoFailures = _repositoryFetchFailures;

    final cacheTooFull = totalEntries > (maxCacheEntries * 0.8);
    final tooManyErrors = repoFailures > 10; // Soglia per errori reali

    return !cacheTooFull && !tooManyErrors;
  }

  /// Ottiene lo stato corrente senza modificarlo (solo lettura)
  Future<Either<Failure, AppStrategyState>> getState(String symbol) async {
    return await _stateMutex.protect(() async {
      return await _getCurrentState(symbol);
    });
  }

  /// Forza il salvataggio dello stato senza operazioni aggiuntive
  Future<Either<Failure, void>> forceUpdateState(AppStrategyState state) async {
    return await _stateMutex.protect(() async {
      if (persistChanges) {
        final saveResult =
            await _strategyStateRepository.saveStrategyState(state);
        return saveResult.fold(
          (failure) => Left(failure),
          (_) {
            // Aggiorna la cache multi-simbolo
            _multiSymbolCache[state.symbol] = _CacheEntry(state);
            return const Right(null);
          },
        );
      } else {
        // Solo aggiornamento in-memory
        _cachedState = state;
        return const Right(null);
      }
    });
  }

  /// Inietta uno stato iniziale direttamente nella cache locale (senza persistere)
  void seedState(AppStrategyState state) {
    if (persistChanges) {
      // Modalità persistente: usa cache multi-simbolo
      _multiSymbolCache[state.symbol] = _CacheEntry(state);
    } else {
      // Modalità non persistente: usa cache singola
      _cachedState = state;
    }
  }

  /// Pulisce le risorse utilizzate dal manager
  void dispose() {
    _cachedState = null;
    _multiSymbolCache.clear();
    _cacheHits = 0;
    _cacheMisses = 0;
    _cacheEvictions = 0;
    _repositoryFetchFailures = 0; // NEW: Reset on dispose
    _lastCacheCleanup = DateTime.now();
    stopPeriodicCleanup(); // Assicurati di fermare il timer al dispose
  }
}
