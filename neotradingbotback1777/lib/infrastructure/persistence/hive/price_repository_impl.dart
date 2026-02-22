import 'dart:async';
import 'package:fpdart/fpdart.dart';
import 'package:hive_ce/hive.dart';
import 'package:mutex/mutex.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/price_repository.dart';
import 'package:neotradingbotback1777/domain/services/i_trading_api_service.dart';
import 'package:neotradingbotback1777/domain/entities/ticker_info.dart';
import 'package:neotradingbotback1777/domain/entities/price.dart';

/// Implementation of [PriceRepository] using Hive for persistence.
///
/// This repository manages price data with local caching and
/// real-time streaming capabilities from external APIs.
class PriceRepositoryImpl implements PriceRepository {
  final Box<double> _priceBox;
  final ITradingApiService _apiService;
  final _log = LogManager.getLogger();
  final Mutex _writeMutex = Mutex();

  // Active price streams by symbol
  final Map<String, StreamController<Either<Failure, double>>> _priceStreams =
      {};

  // Upstream API subscriptions for each symbol to allow explicit cancellation
  final Map<String, StreamSubscription<Either<Failure, double>>>
      _apiSubscriptions = {};

  // In-memory timestamp tracking (could be persisted later if needed)
  final Map<String, DateTime> _priceTimestamps = {};

  PriceRepositoryImpl({
    required Box<double> priceBox,
    required ITradingApiService apiService,
  })  : _priceBox = priceBox,
        _apiService = apiService;

  @override
  Future<Either<Failure, void>> saveCurrentPrice(
      String symbol, double price) async {
    return await _writeMutex.protect(() async {
      try {
        //_log.d('Saving price for $symbol: $price');

        await _priceBox.put(symbol, price);
        _priceTimestamps[symbol] = DateTime.now();

        // Notify active streams for this symbol
        // ignore: close_sinks
        final streamController = _priceStreams[symbol];
        streamController?.add(Right(price));

        //_log.t('Price saved for $symbol: $price');
        return const Right(null);
      } catch (e, stackTrace) {
        _log.e('Error saving price for $symbol: $e', stackTrace: stackTrace);
        return Left(
            CacheFailure(message: 'Failed to save price for $symbol: $e'));
      }
    });
  }

  @override
  Future<Either<Failure, double?>> getCurrentPrice(String symbol) async {
    try {
      _log.t('Retrieving price for $symbol from cache');

      final price = _priceBox.get(symbol);
      if (price != null) {
        _log.t('Price found for $symbol: $price');
        return Right(price);
      }

      _log.d('No cached price found for $symbol');
      return const Right(null);
    } catch (e, stackTrace) {
      _log.e('Error retrieving price for $symbol: $e', stackTrace: stackTrace);
      return Left(
          CacheFailure(message: 'Failed to retrieve price for $symbol: $e'));
    }
  }

  @override
  Stream<Either<Failure, double>> subscribeToPriceStream(String symbol) {
    _log.d('Creating price stream for $symbol');

    // Return existing stream if already created
    if (_priceStreams.containsKey(symbol)) {
      _log.d('Returning existing price stream for $symbol');
      return _priceStreams[symbol]!.stream;
    }

    // Create new stream controller with proper lifecycle management
    final StreamController<Either<Failure, double>> streamController =
        StreamController<Either<Failure, double>>.broadcast();

    // Assign onCancel logic
    streamController.onCancel = () async {
      _log.d('Price stream listener cancelled for $symbol');
      // When the last listener cancels, detach from upstream and cleanup if it was the last one
      if (!streamController.hasListener) {
        try {
          await _apiSubscriptions.remove(symbol)?.cancel();
        } catch (e) {
          _log.w('Error cancelling API subscription for $symbol: $e');
        }
        _priceStreams.remove(symbol);
        try {
          // Explicitly close to satisfy linter and release resources
          if (!streamController.isClosed) {
            await streamController.close();
          }
        } catch (e) {
          _log.w('Error closing stream controller for $symbol: $e');
        }
        _log.d('Price stream fully disposed for $symbol (onCancel)');
      }
    };

    _priceStreams[symbol] = streamController;

    // Start API streaming and cache updates
    _startApiPriceStreaming(symbol, streamController);

    return streamController.stream;
  }

  @override
  Future<Either<Failure, DateTime?>> getLastPriceUpdate(String symbol) async {
    try {
      _log.t('Getting last price update timestamp for $symbol');

      final timestamp = _priceTimestamps[symbol];
      return Right(timestamp);
    } catch (e, stackTrace) {
      _log.e('Error getting last update timestamp for $symbol: $e',
          stackTrace: stackTrace);
      return Left(
          CacheFailure(message: 'Failed to get last update for $symbol: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearPriceCache(String symbol) async {
    return await _writeMutex.protect(() async {
      try {
        _log.d('Clearing price cache for $symbol');

        await _priceBox.delete(symbol);
        _priceTimestamps.remove(symbol);

        return const Right(null);
      } catch (e, stackTrace) {
        _log.e('Error clearing price cache for $symbol: $e',
            stackTrace: stackTrace);
        return Left(CacheFailure(
            message: 'Failed to clear price cache for $symbol: $e'));
      }
    });
  }

  @override
  Future<Either<Failure, void>> clearAllPrices() async {
    return await _writeMutex.protect(() async {
      try {
        _log.d('Clearing all price cache');

        await _priceBox.clear();
        _priceTimestamps.clear();

        _log.d('All price cache cleared');
        return const Right(null);
      } catch (e, stackTrace) {
        _log.e('Error clearing all price cache: $e', stackTrace: stackTrace);
        return Left(
            CacheFailure(message: 'Failed to clear all price cache: $e'));
      }
    });
  }

  @override
  Future<Either<Failure, Map<String, double>>> getPrices(
      List<String> symbols) async {
    try {
      _log.d('Getting prices for ${symbols.length} symbols');

      final Map<String, double> prices = {};

      for (final symbol in symbols) {
        final price = _priceBox.get(symbol);
        if (price != null) {
          prices[symbol] = price;
        }
      }

      _log.d('Found prices for ${prices.length}/${symbols.length} symbols');
      return Right(prices);
    } catch (e, stackTrace) {
      _log.e('Error getting multiple prices: $e', stackTrace: stackTrace);
      return Left(CacheFailure(message: 'Failed to get multiple prices: $e'));
    }
  }

  @override
  Future<Either<Failure, TickerInfo>> getTickerInfo(String symbol) async {
    try {
      // _log.d('Getting ticker info for $symbol from API');
      final result = await _apiService.getTickerInfo(symbol);
      return result;
    } catch (e, stackTrace) {
      _log.e('Error getting ticker info for $symbol: $e',
          stackTrace: stackTrace);
      return Left(
          NetworkFailure(message: 'Failed to get ticker info for $symbol: $e'));
    }
  }

  /// Starts API price streaming for a symbol and manages cache updates
  void _startApiPriceStreaming(
    String symbol,
    StreamController<Either<Failure, double>> streamController,
  ) {
    //_log.d('Starting API price streaming for $symbol');

    // ignore: cancel_subscriptions
    final subscription = _apiService.subscribeToPriceStream(symbol).listen(
      (result) {
        result.fold(
          (failure) {
            streamController.add(Left(failure));
          },
          (price) async {
            // Update cache automatically
            await saveCurrentPrice(symbol, price);
          },
        );
      },
      onError: (error, stackTrace) {
        _log.e('Price stream error for $symbol: $error',
            stackTrace: stackTrace);
        streamController
            .add(Left(NetworkFailure(message: 'Stream error: $error')));
      },
      onDone: () {
        _log.w('Price stream closed for $symbol');
        try {
          streamController.close();
        } catch (e) {
          _log.w('Error closing stream controller for $symbol on done: $e');
        }
        _priceStreams.remove(symbol);
        _apiSubscriptions.remove(symbol);
      },
      cancelOnError: false,
    );

    _apiSubscriptions[symbol] = subscription;
  }

  /// Disposes resources and closes all streams
  void dispose() {
    _log.d('Disposing PriceRepositoryImpl');

    for (final sub in _apiSubscriptions.values) {
      try {
        sub.cancel();
      } catch (e) {
        _log.w('Error cancelling API subscription during dispose: $e');
      }
    }
    _apiSubscriptions.clear();

    for (final streamController in _priceStreams.values) {
      try {
        streamController.close();
      } catch (e) {
        _log.w('Error closing stream controller during dispose: $e');
      }
    }
    _priceStreams.clear();

    _log.d('PriceRepositoryImpl disposed');
  }

  @override
  Future<Either<Failure, Unit>> updatePrice(Price price) async {
    return await _writeMutex.protect(() async {
      try {
        await _priceBox.put(price.symbol, price.price);
        _priceTimestamps[price.symbol] = price.timestamp;

        // ignore: close_sinks
        final streamController = _priceStreams[price.symbol];
        streamController?.add(Right(price.price));

        return const Right(unit);
      } catch (e, stackTrace) {
        _log.e('Error updating price for ${price.symbol}: $e',
            stackTrace: stackTrace);
        return Left(CacheFailure(
            message: 'Failed to update price for ${price.symbol}: $e'));
      }
    });
  }
}
