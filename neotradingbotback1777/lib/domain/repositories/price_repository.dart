import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/entities/price.dart';
import 'package:neotradingbotback1777/domain/entities/ticker_info.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';

/// Repository interface for price data management.
///
/// This repository handles price information with local caching
/// and real-time streaming capabilities from external APIs.
abstract class PriceRepository {
  /// Saves current price for a trading symbol to local cache.
  ///
  /// [symbol] - The trading pair symbol (e.g., "BTCUSDC")
  /// [price] - The current price to cache
  ///
  /// Returns [Either<Failure, void>] indicating success or failure.
  Future<Either<Failure, void>> saveCurrentPrice(String symbol, double price);

  /// Retrieves the current price for a symbol from cache.
  ///
  /// [symbol] - The trading pair symbol to query
  ///
  /// Returns [Either<Failure, double?>] with cached price or null if not found.
  Future<Either<Failure, double?>> getCurrentPrice(String symbol);

  /// Subscribes to real-time price updates for a symbol.
  ///
  /// Provides a stream of price changes from external API with local caching.
  /// The stream automatically handles reconnection and error recovery.
  ///
  /// [symbol] - The trading pair symbol to monitor
  ///
  /// Returns [Stream<Either<Failure, double>>] with price updates.
  Stream<Either<Failure, double>> subscribeToPriceStream(String symbol);

  /// Gets the last update timestamp for a symbol's price.
  ///
  /// [symbol] - The trading pair symbol to check
  ///
  /// Returns [Either<Failure, DateTime?>] with last update time or null.
  Future<Either<Failure, DateTime?>> getLastPriceUpdate(String symbol);

  /// Clears cached price data for a specific symbol.
  ///
  /// [symbol] - The trading pair symbol to clear
  ///
  /// Returns [Either<Failure, void>] indicating success or failure.
  Future<Either<Failure, void>> clearPriceCache(String symbol);

  /// Clears all cached price data.
  ///
  /// Returns [Either<Failure, void>] indicating success or failure.
  Future<Either<Failure, void>> clearAllPrices();

  /// Gets cached prices for multiple symbols.
  ///
  /// [symbols] - List of trading pair symbols to retrieve
  ///
  /// Returns [Either<Failure, Map<String, double>>] with symbol-price mapping.
  Future<Either<Failure, Map<String, double>>> getPrices(List<String> symbols);

  /// Retrieves 24-hour ticker information for a symbol.
  ///
  /// [symbol] - The trading pair symbol to query
  ///
  /// Returns [Either<Failure, TickerInfo>] with 24h ticker data.
  Future<Either<Failure, TickerInfo>> getTickerInfo(String symbol);

  /// Updates the price in the cache using a Price entity.
  ///
  /// [price] - The Price entity containing the symbol and new price.
  ///
  /// Returns [Either<Failure, Unit>] indicating success or failure.
  Future<Either<Failure, Unit>> updatePrice(Price price);
}
