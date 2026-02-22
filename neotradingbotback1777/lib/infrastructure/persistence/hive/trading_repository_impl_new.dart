import 'dart:async';
import 'dart:convert';
import 'package:fpdart/fpdart.dart';
import 'package:hive_ce/hive.dart';
import 'package:mutex/mutex.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:neotradingbotback1777/domain/entities/app_trade.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/trading_repository_new.dart';
import 'package:neotradingbotback1777/domain/services/i_trading_api_service.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/app_trade_hive_dto.dart';

/// Implementazione di [TradingRepository] che utilizza Hive per la persistenza.
///
/// Questo repository si concentra esclusivamente sulle operazioni di trading:
/// archiviazione e recupero dei dati di trading, gestione della cronologia,
/// e fornitura di funzionalità di streaming per gli eventi di trading.
///
/// Separato dal God Object originale per seguire il Single Responsibility Principle.
class TradingRepositoryImpl implements TradingRepository {
  final Box<AppTradeHiveDto> _tradesBox;
  final ITradingApiService _apiService;
  final _log = LogManager.getLogger();
  final Mutex _writeMutex = Mutex();

  StreamController<Either<Failure, AppTrade>>? _tradeStreamController;

  TradingRepositoryImpl({
    required Box<AppTradeHiveDto> tradesBox,
    required ITradingApiService apiService,
  })  : _tradesBox = tradesBox,
        _apiService = apiService;

  String get _modePrefix => _apiService.isTestMode ? 'test_' : 'real_';

  String _getTradeKey(AppTrade trade) =>
      '${_modePrefix}${trade.symbol}_${trade.timestamp}_${trade.isBuy ? "BUY" : "SELL"}';

  @override
  Future<Either<Failure, void>> saveTrade(AppTrade trade) async {
    return await _writeMutex.protect(() async {
      try {
        _log.d(
            'Saving trade for ${trade.symbol} (Mode: ${_apiService.isTestMode ? 'TEST' : 'REAL'}): ${trade.isBuy ? "BUY" : "SELL"} ${trade.quantity.toDouble()} @ ${trade.price.toDouble()}');

        // Converte in DTO e salva con chiave prefissata dalla modalità
        final tradeDto = AppTradeHiveDto.fromEntity(trade);
        final key = _getTradeKey(trade);
        await _tradesBox.put(key, tradeDto);

        // Notifica gli ascoltatori dello stream
        _tradeStreamController?.add(Right(trade));

        _log.d('Trade saved successfully for ${trade.symbol}');
        return const Right(null);
      } catch (e, stackTrace) {
        _log.e('Error saving trade for ${trade.symbol}: $e',
            stackTrace: stackTrace);
        return Left(CacheFailure(message: 'Failed to save trade: $e'));
      }
    });
  }

  @override
  Future<Either<Failure, void>> deleteTrade(AppTrade trade) async {
    return await _writeMutex.protect(() async {
      try {
        final key = _getTradeKey(trade);
        if (_tradesBox.containsKey(key)) {
          await _tradesBox.delete(key);
          _log.w('Deleted trade $key as part of compensation/rollback');
        } else {
          _log.w('Trade key $key not found during deleteTrade');
        }
        return const Right(null);
      } catch (e, stackTrace) {
        _log.e('Error deleting trade for ${trade.symbol}: $e',
            stackTrace: stackTrace);
        return Left(CacheFailure(message: 'Failed to delete trade: $e'));
      }
    });
  }

  @override
  Future<Either<Failure, List<AppTrade>>> getAllTrades() async {
    try {
      _log.d(
          'Retrieving all trades (Mode: ${_apiService.isTestMode ? 'TEST' : 'REAL'})');

      final trades = <AppTrade>[];
      final prefix = _modePrefix;

      for (final entry in _tradesBox.toMap().entries) {
        final key = entry.key as String;
        if (key.startsWith(prefix)) {
          trades.add(entry.value.toEntity());
        }
      }

      // Ordina per timestamp (dal più recente)
      trades.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      _log.d('Retrieved ${trades.length} trades');
      return Right(trades);
    } catch (e, stackTrace) {
      _log.e('Error retrieving all trades: $e', stackTrace: stackTrace);
      return Left(CacheFailure(message: 'Failed to retrieve trades: $e'));
    }
  }

  @override
  Future<Either<Failure, List<AppTrade>>> getTradesBySymbol(
      String symbol) async {
    try {
      _log.d(
          'Retrieving trades for symbol: $symbol (Mode: ${_apiService.isTestMode ? 'TEST' : 'REAL'})');

      final trades = <AppTrade>[];
      final prefix = '${_modePrefix}${symbol}_';

      for (final entry in _tradesBox.toMap().entries) {
        final key = entry.key as String;
        if (key.startsWith(prefix)) {
          trades.add(entry.value.toEntity());
        }
      }

      // Sort by timestamp (newest first)
      trades.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      _log.d('Retrieved ${trades.length} trades for $symbol');
      return Right(trades);
    } catch (e, stackTrace) {
      _log.e('Error retrieving trades for $symbol: $e', stackTrace: stackTrace);
      return Left(
          CacheFailure(message: 'Failed to retrieve trades for $symbol: $e'));
    }
  }

  @override
  Future<Either<Failure, List<AppTrade>>> getTradesByTimeRange(
    int startTime,
    int endTime,
  ) async {
    try {
      _log.d(
          'Retrieving trades from $startTime to $endTime (Mode: ${_apiService.isTestMode ? 'TEST' : 'REAL'})');

      final trades = <AppTrade>[];
      final prefix = _modePrefix;

      for (final entry in _tradesBox.toMap().entries) {
        final key = entry.key as String;
        if (key.startsWith(prefix)) {
          final trade = entry.value.toEntity();
          if (trade.timestamp >= startTime && trade.timestamp <= endTime) {
            trades.add(trade);
          }
        }
      }

      // Sort by timestamp (newest first)
      trades.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      _log.d('Retrieved ${trades.length} trades in time range');
      return Right(trades);
    } catch (e, stackTrace) {
      _log.e('Error retrieving trades by time range: $e',
          stackTrace: stackTrace);
      return Left(
          CacheFailure(message: 'Failed to retrieve trades by time range: $e'));
    }
  }

  @override
  Future<Either<Failure, List<AppTrade>>> getTradesByType(bool isBuy,
      {String? symbol}) async {
    try {
      _log.d(
          'Retrieving ${isBuy ? "BUY" : "SELL"} trades${symbol != null ? " for $symbol" : ""}');

      final trades = <AppTrade>[];
      for (final tradeDto in _tradesBox.values) {
        final trade = tradeDto.toEntity();
        if (trade.isBuy == isBuy) {
          if (symbol != null && trade.symbol != symbol) continue;
          trades.add(trade);
        }
      }

      // Sort by timestamp (newest first)
      trades.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      _log.d('Retrieved ${trades.length} ${isBuy ? "BUY" : "SELL"} trades');
      return Right(trades);
    } catch (e, stackTrace) {
      _log.e('Error retrieving trades by type: $e', stackTrace: stackTrace);
      return Left(
          CacheFailure(message: 'Failed to retrieve trades by type: $e'));
    }
  }

  @override
  Stream<Either<Failure, AppTrade>> subscribeToTradesStream() {
    _tradeStreamController ??=
        StreamController<Either<Failure, AppTrade>>.broadcast(
      onListen: () {
        _log.d('Trade stream listener added');
      },
      onCancel: () {
        _log.d('Trade stream listener cancelled');
      },
    );

    return _tradeStreamController!.stream;
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getTradingStatistics(
      String symbol) async {
    try {
      _log.d('Calculating trading statistics for $symbol');

      final tradesResult = await getTradesBySymbol(symbol);
      return tradesResult.fold(
        (failure) => Left(failure),
        (trades) {
          final buyTrades = trades.where((t) => t.isBuy).toList();
          final sellTrades = trades.where((t) => !t.isBuy).toList();

          final totalBuyVolume = buyTrades.fold(
              0.0,
              (sum, trade) =>
                  sum + (trade.price.toDouble() * trade.quantity.toDouble()));
          final totalSellVolume = sellTrades.fold(
              0.0,
              (sum, trade) =>
                  sum + (trade.price.toDouble() * trade.quantity.toDouble()));

          final stats = {
            'symbol': symbol,
            'total_trades': trades.length,
            'buy_trades': buyTrades.length,
            'sell_trades': sellTrades.length,
            'total_buy_volume': totalBuyVolume,
            'total_sell_volume': totalSellVolume,
            'net_volume': totalSellVolume - totalBuyVolume,
            'first_trade': trades.isNotEmpty
                ? DateTime.fromMillisecondsSinceEpoch(trades.last.timestamp)
                    .toIso8601String()
                : null,
            'last_trade': trades.isNotEmpty
                ? DateTime.fromMillisecondsSinceEpoch(trades.first.timestamp)
                    .toIso8601String()
                : null,
          };

          return Right(stats);
        },
      );
    } catch (e, stackTrace) {
      _log.e('Error calculating statistics for $symbol: $e',
          stackTrace: stackTrace);
      return Left(CacheFailure(message: 'Failed to calculate statistics: $e'));
    }
  }

  @override
  Future<Either<Failure, double>> getTotalTradingVolume(String symbol) async {
    try {
      final tradesResult = await getTradesBySymbol(symbol);
      return tradesResult.fold(
        (failure) => Left(failure),
        (trades) {
          final totalVolume = trades.fold(
              0.0,
              (sum, trade) =>
                  sum + (trade.price.toDouble() * trade.quantity.toDouble()));
          return Right(totalVolume);
        },
      );
    } catch (e, stackTrace) {
      _log.e('Error calculating total volume for $symbol: $e',
          stackTrace: stackTrace);
      return Left(
          CacheFailure(message: 'Failed to calculate total volume: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getTradeCount(String symbol) async {
    try {
      final tradesResult = await getTradesBySymbol(symbol);
      return tradesResult.fold(
        (failure) => Left(failure),
        (trades) => Right(trades.length),
      );
    } catch (e, stackTrace) {
      _log.e('Error getting trade count for $symbol: $e',
          stackTrace: stackTrace);
      return Left(CacheFailure(message: 'Failed to get trade count: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> deleteOldTrades(int beforeTimestamp) async {
    return await _writeMutex.protect(() async {
      try {
        _log.d(
            'Deleting trades before timestamp: $beforeTimestamp (Mode: ${_apiService.isTestMode ? 'TEST' : 'REAL'})');

        final keysToDelete = <String>[];
        final prefix = _modePrefix;
        for (final entry in _tradesBox.toMap().entries) {
          final key = entry.key as String;
          if (!key.startsWith(prefix)) continue;

          final trade = entry.value.toEntity();
          if (trade.timestamp < beforeTimestamp) {
            keysToDelete.add(key);
          }
        }

        for (final key in keysToDelete) {
          await _tradesBox.delete(key);
        }

        _log.d('Deleted ${keysToDelete.length} old trades');
        return Right(keysToDelete.length);
      } catch (e, stackTrace) {
        _log.e('Error deleting old trades: $e', stackTrace: stackTrace);
        return Left(CacheFailure(message: 'Failed to delete old trades: $e'));
      }
    });
  }

  @override
  Future<Either<Failure, void>> clearAllTrades() async {
    return await _writeMutex.protect(() async {
      try {
        _log.w(
            'Clearing ALL trades for current mode (Mode: ${_apiService.isTestMode ? 'TEST' : 'REAL'})');

        final keysToDelete = <String>[];
        final prefix = _modePrefix;
        for (final key in _tradesBox.keys) {
          if (key.toString().startsWith(prefix)) {
            keysToDelete.add(key.toString());
          }
        }

        for (final key in keysToDelete) {
          await _tradesBox.delete(key);
        }

        _log.w('All trades for current mode have been cleared');
        return const Right(null);
      } catch (e, stackTrace) {
        _log.e('Error clearing all trades: $e', stackTrace: stackTrace);
        return Left(CacheFailure(message: 'Failed to clear all trades: $e'));
      }
    });
  }

  @override
  Future<Either<Failure, String>> exportTrades({
    String format = 'json',
    String? symbol,
  }) async {
    try {
      _log.d(
          'Exporting trades in $format format${symbol != null ? " for $symbol" : ""}');

      final tradesResult = symbol != null
          ? await getTradesBySymbol(symbol)
          : await getAllTrades();

      return tradesResult.fold(
        (failure) => Left(failure),
        (trades) {
          if (format.toLowerCase() == 'json') {
            // Esportazione JSON semplice - potrebbe essere migliorata con una serializzazione JSON appropriata
            final tradesList = trades
                .map((trade) => {
                      'symbol': trade.symbol,
                      'price': trade.price.toDouble(),
                      'quantity': trade.quantity.toDouble(),
                      'isBuy': trade.isBuy,
                      'timestamp': trade.timestamp,
                      'orderStatus': trade.orderStatus,
                      'datetime':
                          DateTime.fromMillisecondsSinceEpoch(trade.timestamp)
                              .toIso8601String(),
                    })
                .toList();

            final exportData = {
              'export_timestamp': DateTime.now().toIso8601String(),
              'total_trades': trades.length,
              'symbol_filter': symbol,
              'trades': tradesList,
            };

            return Right(jsonEncode(exportData));
          } else {
            return Left(ValidationFailure(
                message: 'Unsupported export format: $format'));
          }
        },
      );
    } catch (e, stackTrace) {
      _log.e('Error exporting trades: $e', stackTrace: stackTrace);
      return Left(CacheFailure(message: 'Failed to export trades: $e'));
    }
  }

  /// Disposes resources and closes streams
  void dispose() {
    _tradeStreamController?.close();
    _tradeStreamController = null;
    _log.d('TradingRepositoryImpl disposed');
  }
}
