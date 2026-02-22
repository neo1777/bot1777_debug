import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/entities/symbol_info.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';

/// Abstract repository for managing symbol information.
///
/// This repository handles fetching and caching trading rules and information
/// for various symbols from the exchange.
abstract class ISymbolInfoRepository {
  /// Retrieves information for a single symbol.
  ///
  /// It first attempts to fetch the data from a local cache. If not available,
  /// it fetches the data from the remote API, updates the cache, and then returns it.
  ///
  /// [symbol]: The trading symbol (e.g., 'BTCUSDC').
  /// Returns a [Future] that completes with an [Either] containing a [Failure]
  /// or the requested [SymbolInfo].
  Future<Either<Failure, SymbolInfo>> getSymbolInfo(String symbol);

  /// Fetches the latest exchange information from the API and updates the local cache.
  ///
  /// This method should be called periodically or at application startup to ensure
  /// the trading rules are up-to-date.
  ///
  /// Returns a [Future] that completes with an [Either] containing a [Failure]
  /// or a [Unit] upon successful refresh.
  Future<Either<Failure, Unit>> refreshSymbolInfoCache();
}
