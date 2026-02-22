import 'dart:async';
import 'package:fpdart/fpdart.dart';
import 'package:hive_ce/hive.dart';
import 'package:mutex/mutex.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:neotradingbotback1777/domain/entities/account_info.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/account_repository.dart';
import 'package:neotradingbotback1777/domain/services/i_trading_api_service.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/account_info_hive_dto.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/balance_hive_dto.dart';

/// Implementazione di [AccountRepository] che utilizza Hive per la persistenza.
///
/// Questo repository gestisce le informazioni dell'account e i dati del saldo con
/// una strategia cache-first e funzionalità di streaming in tempo reale.
class AccountRepositoryImpl implements AccountRepository {
  final Box<AccountInfoHiveDto> _accountInfoBox;
  final Box<BalanceHiveDto> _balanceBox;
  final ITradingApiService _apiService;
  final _log = LogManager.getLogger();
  final Mutex _writeMutex = Mutex();

  StreamController<Either<Failure, AccountInfo>>? _accountStreamController;

  String get _accountInfoKey =>
      _apiService.isTestMode ? 'test_account_info' : 'real_account_info';

  String _getBalanceKey(String asset) =>
      _apiService.isTestMode ? 'test_balance_$asset' : 'real_balance_$asset';

  AccountRepositoryImpl({
    required Box<AccountInfoHiveDto> accountInfoBox,
    required Box<BalanceHiveDto> balanceBox,
    required ITradingApiService apiService,
  })  : _accountInfoBox = accountInfoBox,
        _balanceBox = balanceBox,
        _apiService = apiService;

  @override
  Future<Either<Failure, void>> saveAccountInfo(AccountInfo accountInfo) async {
    return await _writeMutex.protect(() async {
      try {
        _log.d(
            'Saving account info to cache (mode: ${_apiService.isTestMode ? 'TEST' : 'REAL'})');

        // Nota: _balanceBox è condiviso ma gli asset sono prefissati o isolati
        // Per sicurezza, potremmo pulirlo (rischioso se più modalità sono attive)
        // o semplicemente inserire con chiavi prefissate.
        // La logica originale puliva l'intero box, il che è negativo per l'isolamento.
        // Terremo la pulizia legacy se vogliamo, ma rompe l'isolamento.
        // MIGLIORIAMOLO: puliamo SOLO i saldi della modalità CORRENTE.
        final allKeys = _balanceBox.keys.toList();
        final currentPrefix =
            _apiService.isTestMode ? 'test_balance_' : 'real_balance_';
        for (final key in allKeys) {
          if (key.toString().startsWith(currentPrefix)) {
            await _balanceBox.delete(key);
          }
        }

        for (final balance in accountInfo.balances) {
          final balanceDto = BalanceHiveDto.fromEntity(balance);
          await _balanceBox.put(_getBalanceKey(balance.asset), balanceDto);
        }

        // Ora converte in DTO e salva su Hive (dopo che i saldi sono stati persistiti)
        final accountDto = AccountInfoHiveDto.fromEntity(accountInfo);
        await _accountInfoBox.put(_accountInfoKey, accountDto);

        // Notifica gli ascoltatori dello stream
        _accountStreamController?.add(Right(accountInfo));

        _log.d('Account info saved successfully');
        return const Right(null);
      } catch (e, stackTrace) {
        _log.e('Error saving account info: $e', stackTrace: stackTrace);
        return Left(CacheFailure(message: 'Failed to save account info: $e'));
      }
    });
  }

  @override
  Future<Either<Failure, AccountInfo?>> getAccountInfo() async {
    try {
      final currentMode = _apiService.isTestMode ? 'TEST' : 'REAL';
      _log.d(
          'Retrieving account info (mode: $currentMode, key: $_accountInfoKey)');

      // Prova prima la cache
      final cachedDto = _accountInfoBox.get(_accountInfoKey);
      if (cachedDto != null) {
        final accountInfo = cachedDto.toEntity();
        _log.i('Account info found in cache for $currentMode mode');
        return Right(accountInfo);
      }

      // Cache miss - prova la rete
      _log.d(
          'Account info not in cache for $currentMode mode, fetching from network');
      final refreshResult = await refreshAccountInfo();
      return refreshResult.fold(
        (failure) => Left(failure),
        (accountInfo) => Right(accountInfo),
      );
    } catch (e, stackTrace) {
      _log.e('Error retrieving account info: $e', stackTrace: stackTrace);
      return Left(CacheFailure(message: 'Failed to retrieve account info: $e'));
    }
  }

  @override
  Stream<Either<Failure, AccountInfo>> subscribeToAccountInfoStream() {
    _accountStreamController ??=
        StreamController<Either<Failure, AccountInfo>>.broadcast(
      onListen: () {
        _log.d('Account info stream listener added');
        // Avvia lo streaming API
        _startApiStreaming();
      },
      onCancel: () {
        _log.d('Account info stream listener cancelled');
      },
    );

    return _accountStreamController!.stream;
  }

  @override
  Future<Either<Failure, void>> clearAccountInfo() async {
    return await _writeMutex.protect(() async {
      try {
        _log.i('Clearing all account info caches (both REAL and TEST modes)');

        // Pulisce entrambe le chiavi di cache possibili per evitare dati obsoleti
        // Questo è critico quando si cambia modalità per evitare di mostrare saldi errati
        await _accountInfoBox.delete('real_account_info');
        await _accountInfoBox.delete('test_account_info');

        // Pulisce i saldi per entrambe le modalità
        final allKeys = _balanceBox.keys.toList();
        for (final key in allKeys) {
          final keyStr = key.toString();
          if (keyStr.startsWith('test_balance_') ||
              keyStr.startsWith('real_balance_')) {
            await _balanceBox.delete(key);
          }
        }

        _log.d('Cleared account info caches for all modes');
        return const Right(null);
      } catch (e, stackTrace) {
        _log.e('Error clearing account info: $e', stackTrace: stackTrace);
        return Left(CacheFailure(message: 'Failed to clear account info: $e'));
      }
    });
  }

  @override
  Future<Either<Failure, AccountInfo>> refreshAccountInfo() async {
    try {
      _log.d('Refreshing account info from API');

      final result = await _apiService.getAccountInfo();
      return result.fold(
        (failure) {
          _log.e('Failed to refresh account info: ${failure.message}');
          return Left(failure);
        },
        (accountInfo) async {
          // Salva nella cache
          final saveResult = await saveAccountInfo(accountInfo);
          return saveResult.fold(
            (failure) => Left(failure),
            (_) {
              _log.d('Account info refreshed and cached successfully');
              return Right(accountInfo);
            },
          );
        },
      );
    } catch (e, stackTrace) {
      _log.e('Error refreshing account info: $e', stackTrace: stackTrace);
      return Left(
          NetworkFailure(message: 'Failed to refresh account info: $e'));
    }
  }

  /// Avvia lo streaming API e aggiorna la cache automaticamente
  void _startApiStreaming() {
    _apiService.subscribeToAccountInfoStream().listen(
      (result) {
        result.fold(
          (failure) {
            _log.w('Account info stream error: ${failure.message}');
            _accountStreamController?.add(Left(failure));
          },
          (accountInfo) async {
            _log.d('Received account info update from API stream');
            // Aggiorna la cache automaticamente
            await saveAccountInfo(accountInfo);
          },
        );
      },
      onError: (error, stackTrace) {
        _log.e('Account info stream error: $error', stackTrace: stackTrace);
        _accountStreamController
            ?.add(Left(NetworkFailure(message: 'Stream error: $error')));
      },
    );
  }

  /// Rilascia le risorse e chiude gli stream
  void dispose() {
    _accountStreamController?.close();
    _accountStreamController = null;
    _log.d('AccountRepositoryImpl disposed');
  }
}
