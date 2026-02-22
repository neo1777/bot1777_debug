import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/entities/account_info.dart';
import 'package:neotradingbotback1777/domain/entities/order_response.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/entities/ticker_info.dart';
import 'package:neotradingbotback1777/domain/entities/price.dart';
import 'package:neotradingbotback1777/domain/entities/exchange_info.dart';
import 'package:neotradingbotback1777/domain/entities/kline.dart';

/// Abstract interface for trading API operations.
///
/// This interface defines the contract for all trading API operations,
/// ensuring that the Domain layer doesn't depend on specific implementations
/// from the Infrastructure layer, respecting the Dependency Inversion Principle.
abstract class ITradingApiService {
  /// Returns true if the service is in Test Mode (Binance Testnet).
  bool get isTestMode;

  /// Creates a market order on the exchange.
  ///
  /// [symbol] - The trading pair symbol (e.g., "BTCUSDC")
  /// [quantity] - The quantity to buy/sell
  /// [side] - The order side ("BUY" or "SELL")
  /// [clientOrderId] - Optional unique client order ID for deduplication
  ///
  /// Returns [Either<Failure, OrderResponse>] with the order execution result.
  Future<Either<Failure, OrderResponse>> createOrder({
    required String symbol,
    required double quantity,
    required String side,
    String? clientOrderId,
  });

  /// Retrieves account information including balances.
  ///
  /// Returns [Either<Failure, AccountInfo>] with current account state.
  Future<Either<Failure, AccountInfo>> getAccountInfo();

  /// Retrieves all open orders for a specific symbol.
  ///
  /// [symbol] - The trading pair symbol to check
  ///
  /// Returns [Either<Failure, List<Map<String, dynamic>>>] with open orders data.
  Future<Either<Failure, List<Map<String, dynamic>>>> getOpenOrders(
      String symbol);

  /// Subscribes to real-time price updates for a symbol.
  ///
  /// [symbol] - The trading pair symbol to monitor
  ///
  /// Returns [Stream<Either<Failure, double>>] with price updates.
  Stream<Either<Failure, double>> subscribeToPriceStream(String symbol);

  /// Subscribes to real-time account information updates.
  ///
  /// Returns [Stream<Either<Failure, AccountInfo>>] with account updates.
  Stream<Either<Failure, AccountInfo>> subscribeToAccountInfoStream();

  /// Initializes the API service.
  ///
  /// This method should be called before using any other service methods.
  Future<void> initialize();

  /// Disposes of resources and cleans up connections.
  ///
  /// This method should be called when the service is no longer needed.
  void dispose();

  /// Gets WebSocket connection statistics.
  ///
  /// Returns a map containing connection statistics and status information.
  Map<String, dynamic> getWebSocketStats();

  /// Forces reconnection of all WebSocket streams.
  ///
  /// Useful for recovering from connection issues.
  Future<void> forceWebSocketReconnect();

  /// Retrieves 24-hour ticker information for a symbol.
  ///
  /// [symbol] - The trading pair symbol to query
  ///
  /// Returns [Either<Failure, TickerInfo>] with 24h ticker data.
  Future<Either<Failure, TickerInfo>> getTickerInfo(String symbol);

  /// Retrieves the latest price for a symbol via a direct API call.
  ///
  /// This is useful for pre-flight checks or when a real-time stream is not necessary.
  /// [symbol] - The trading pair symbol to query
  ///
  /// Returns [Either<Failure, Price>] with the latest price data.
  Future<Either<Failure, Price>> getLatestPrice(String symbol);

  /// Retrieves full exchange info (symbols, filters) from remote API.
  Future<Either<Failure, ExchangeInfo>> getExchangeInfo();

  /// Retrieves account trade fees for all symbols.
  ///
  /// This endpoint requires authentication and provides precise fee information
  /// including any volume-based discounts or BNB fee discounts.
  ///
  /// Returns [Either<Failure, List<Map<String, dynamic>>>] with fee data.
  Future<Either<Failure, List<Map<String, dynamic>>>> getAccountTradeFees();

  /// Retrieves list of active trading symbols.
  ///
  /// Returns [Either<Failure, List<String>>] with active symbol names.
  Future<Either<Failure, List<String>>> getActiveSymbols();

  /// Cancels a specific open order.
  ///
  /// [symbol] - The trading pair symbol
  /// [orderId] - The ID of the order to cancel
  Future<Either<Failure, void>> cancelOrder({
    required String symbol,
    required int orderId,
  });

  /// Cancels all open orders for a specific symbol.
  ///
  /// [symbol] - The trading pair symbol
  Future<Either<Failure, void>> cancelAllOpenOrders({
    required String symbol,
  });

  /// Updates the trading mode (Real or Testnet).
  ///
  /// [isTestMode] - If true, switches to Binance Testnet URLs.
  void updateMode({required bool isTestMode});

  /// Retrieves historical candlestick data (klines).
  ///
  /// [symbol] - The trading pair symbol
  /// [interval] - The kline interval (e.g., "1m", "1h")
  /// [startTime] - Optional start time in ms
  /// [endTime] - Optional end time in ms
  /// [limit] - Optional limit (max 1000)
  Future<Either<Failure, List<Kline>>> getKlines({
    required String symbol,
    required String interval,
    int? startTime,
    int? endTime,
    int? limit,
  });
}
