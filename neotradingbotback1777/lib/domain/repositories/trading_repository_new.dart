import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/entities/app_trade.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';

/// Repository interface for trading operations management.
///
/// This repository focuses solely on trading-related operations:
/// storing and retrieving trade data, managing trading history,
/// and providing streaming capabilities for trade events.
///
/// Responsibilities moved to specialized repositories:
/// - Account/Balance -> AccountRepository
/// - Prices -> PriceRepository
/// - Strategy States -> StrategyStateRepository
/// - Symbol Info -> SymbolInfoRepository
abstract class TradingRepository {
  /// Saves a trading operation to persistence.
  ///
  /// [trade] - The trade operation to save
  ///
  /// Returns [Either<Failure, void>] indicating success or failure.
  Future<Either<Failure, void>> saveTrade(AppTrade trade);

  /// Deletes a specific trading operation from persistence.
  ///
  /// [trade] - The trade operation to delete (identified by symbol/timestamp/type)
  ///
  /// Returns [Either<Failure, void>] indicating success or failure.
  Future<Either<Failure, void>> deleteTrade(AppTrade trade);

  /// Retrieves all saved trading operations.
  ///
  /// Returns [Either<Failure, List<AppTrade>>] with all trades or failure.
  Future<Either<Failure, List<AppTrade>>> getAllTrades();

  /// Retrieves trades filtered by symbol.
  ///
  /// [symbol] - The trading pair symbol to filter by
  ///
  /// Returns [Either<Failure, List<AppTrade>>] with filtered trades.
  Future<Either<Failure, List<AppTrade>>> getTradesBySymbol(String symbol);

  /// Retrieves trades within a specific time range.
  ///
  /// [startTime] - Start timestamp for filtering
  /// [endTime] - End timestamp for filtering
  ///
  /// Returns [Either<Failure, List<AppTrade>>] with filtered trades.
  Future<Either<Failure, List<AppTrade>>> getTradesByTimeRange(
    int startTime,
    int endTime,
  );

  /// Retrieves trades filtered by type (buy/sell).
  ///
  /// [isBuy] - true for buy trades, false for sell trades
  ///
  /// Returns [Either<Failure, List<AppTrade>>] with filtered trades.
  Future<Either<Failure, List<AppTrade>>> getTradesByType(bool isBuy,
      {String? symbol});

  /// Subscribes to a stream of new trade executions.
  ///
  /// Provides real-time notifications when new trades are saved.
  ///
  /// Returns [Stream<Either<Failure, AppTrade>>] with trade updates.
  Stream<Either<Failure, AppTrade>> subscribeToTradesStream();

  /// Gets trading statistics for a symbol.
  ///
  /// [symbol] - The trading pair symbol to analyze
  ///
  /// Returns [Either<Failure, Map<String, dynamic>>] with statistics.
  Future<Either<Failure, Map<String, dynamic>>> getTradingStatistics(
      String symbol);

  /// Gets total trading volume for a symbol.
  ///
  /// [symbol] - The trading pair symbol to calculate volume for
  ///
  /// Returns [Either<Failure, double>] with total volume.
  Future<Either<Failure, double>> getTotalTradingVolume(String symbol);

  /// Gets trade count for a symbol.
  ///
  /// [symbol] - The trading pair symbol to count trades for
  ///
  /// Returns [Either<Failure, int>] with trade count.
  Future<Either<Failure, int>> getTradeCount(String symbol);

  /// Deletes trades older than specified timestamp.
  ///
  /// [beforeTimestamp] - Timestamp before which to delete trades
  ///
  /// Returns [Either<Failure, int>] with number of deleted trades.
  Future<Either<Failure, int>> deleteOldTrades(int beforeTimestamp);

  /// Clears all trading data.
  ///
  /// ⚠️ Warning: This operation is irreversible!
  ///
  /// Returns [Either<Failure, void>] indicating success or failure.
  Future<Either<Failure, void>> clearAllTrades();

  /// Exports trading data for backup or analysis.
  ///
  /// [format] - Export format ('json', 'csv', etc.)
  /// [symbol] - Optional symbol filter
  ///
  /// Returns [Either<Failure, String>] with exported data.
  Future<Either<Failure, String>> exportTrades({
    String format = 'json',
    String? symbol,
  });
}
