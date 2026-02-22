import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/entities/symbol_info.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';

/// Repository interface for trading symbol information management.
///
/// This repository handles symbol trading rules, limits, and metadata
/// with efficient caching strategies to minimize API calls.
abstract class SymbolInfoRepository {
  /// Saves symbol information to local cache.
  ///
  /// [symbolInfo] - The symbol information to cache
  ///
  /// Returns [Either<Failure, void>] indicating success or failure.
  Future<Either<Failure, void>> saveSymbolInfo(SymbolInfo symbolInfo);

  /// Retrieves symbol information from cache.
  ///
  /// [symbol] - The trading pair symbol to query
  ///
  /// Returns [Either<Failure, SymbolInfo?>] with symbol info or null if not found.
  Future<Either<Failure, SymbolInfo?>> getSymbolInfo(String symbol);

  /// Gets symbol information with cache validation.
  ///
  /// Checks cache expiration and validates data freshness.
  ///
  /// [symbol] - The trading pair symbol to query
  /// [maxAge] - Maximum age of cached data before considering it stale
  ///
  /// Returns [Either<Failure, SymbolInfo?>] with fresh symbol info or null.
  Future<Either<Failure, SymbolInfo?>> getSymbolInfoWithValidation(
    String symbol, {
    Duration maxAge = const Duration(hours: 1),
  });

  /// Gets multiple symbols information efficiently.
  ///
  /// [symbols] - List of trading pair symbols to retrieve
  ///
  /// Returns [Either<Failure, Map<String, SymbolInfo>>] with symbol info mapping.
  Future<Either<Failure, Map<String, SymbolInfo>>> getMultipleSymbolInfo(
    List<String> symbols,
  );

  /// Checks if symbol information is cached and valid.
  ///
  /// [symbol] - The trading pair symbol to check
  /// [maxAge] - Maximum age of cached data
  ///
  /// Returns [Either<Failure, bool>] indicating if valid cache exists.
  Future<Either<Failure, bool>> isSymbolInfoCached(
    String symbol, {
    Duration maxAge = const Duration(hours: 1),
  });

  /// Clears cached symbol information.
  ///
  /// [symbol] - The trading pair symbol to clear, or null to clear all
  ///
  /// Returns [Either<Failure, void>] indicating success or failure.
  Future<Either<Failure, void>> clearSymbolInfoCache([String? symbol]);

  /// Gets cache statistics for symbol information.
  ///
  /// Returns [Either<Failure, Map<String, dynamic>>] with cache stats.
  Future<Either<Failure, Map<String, dynamic>>> getCacheStatistics();

  /// Updates symbol information timestamp for cache management.
  ///
  /// [symbol] - The trading pair symbol to update
  ///
  /// Returns [Either<Failure, void>] indicating success or failure.
  Future<Either<Failure, void>> updateSymbolInfoTimestamp(String symbol);
}
