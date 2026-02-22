import 'dart:async';
import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:neotradingbotback1777/domain/entities/price.dart';
import 'package:neotradingbotback1777/domain/entities/ticker_info.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/price_repository.dart';
import 'package:neotradingbotback1777/domain/services/i_trading_api_service.dart';

/// In-memory price repository for isolates: no persistence, only RAM cache + WS stream.
class PriceRepositoryInMemory implements PriceRepository {
  final ITradingApiService _apiService;
  final _log = LogManager.getLogger();
  final Map<String, double> _cache = {};
  final Map<String, DateTime> _timestamps = {};
  final Map<String, StreamSubscription<Either<Failure, double>>> _subs = {};
  final Map<String, StreamController<Either<Failure, double>>> _controllers =
      {};

  PriceRepositoryInMemory({required ITradingApiService apiService})
      : _apiService = apiService;

  @override
  Future<Either<Failure, void>> saveCurrentPrice(
      String symbol, double price) async {
    _cache[symbol] = price;
    _timestamps[symbol] = DateTime.now();
    _controllers[symbol]?.add(Right(price));
    return const Right(null);
  }

  @override
  Future<Either<Failure, double?>> getCurrentPrice(String symbol) async {
    return Right(_cache[symbol]);
  }

  @override
  Stream<Either<Failure, double>> subscribeToPriceStream(String symbol) {
    final controller = _controllers.putIfAbsent(
      symbol,
      () => StreamController<Either<Failure, double>>.broadcast(),
    );
    _subs.putIfAbsent(
        symbol,
        () => _apiService.subscribeToPriceStream(symbol).listen(
              (either) => either.fold(
                (f) => controller.add(Left(f)),
                (price) async {
                  _cache[symbol] = price;
                  _timestamps[symbol] = DateTime.now();
                  controller.add(Right(price));
                },
              ),
              onError: (e, s) =>
                  controller.add(Left(NetworkFailure(message: e.toString()))),
              onDone: () {
                controller.close();
                _controllers.remove(symbol);
                _subs.remove(symbol);
              },
            ));
    return controller.stream;
  }

  @override
  Future<Either<Failure, DateTime?>> getLastPriceUpdate(String symbol) async {
    return Right(_timestamps[symbol]);
  }

  @override
  Future<Either<Failure, void>> clearPriceCache(String symbol) async {
    _cache.remove(symbol);
    _timestamps.remove(symbol);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> clearAllPrices() async {
    _cache.clear();
    _timestamps.clear();
    return const Right(null);
  }

  @override
  Future<Either<Failure, Map<String, double>>> getPrices(
      List<String> symbols) async {
    final Map<String, double> m = {};
    for (final s in symbols) {
      final v = _cache[s];
      if (v != null) m[s] = v;
    }
    return Right(m);
  }

  @override
  Future<Either<Failure, TickerInfo>> getTickerInfo(String symbol) async {
    return _apiService.getTickerInfo(symbol);
  }

  @override
  Future<Either<Failure, Unit>> updatePrice(Price price) async {
    _cache[price.symbol] = price.price;
    _timestamps[price.symbol] = price.timestamp;
    _controllers[price.symbol]?.add(Right(price.price));
    return const Right(unit);
  }

  void dispose() async {
    for (final s in _subs.values) {
      try {
        await s.cancel();
      } catch (e) {
        _log.w('Error cancelling subscription during dispose: $e');
      }
    }
    _subs.clear();
    for (final c in _controllers.values) {
      try {
        await c.close();
      } catch (e) {
        _log.w('Error closing stream controller during dispose: $e');
      }
    }
    _controllers.clear();
  }
}
