import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pbgrpc.dart';

/// Interfaccia astratta per il datasource remoto di trading.
/// Rispetta il principio di inversione delle dipendenze separando
/// l'implementazione concreta dall'astrazione utilizzata dal repository.
abstract class ITradingRemoteDatasource {
  // Settings Management
  Future<Either<Failure, SettingsResponse>> getSettings();
  Future<Either<Failure, SettingsResponse>> updateSettings(
    UpdateSettingsRequest request,
  );

  // Strategy Control
  Future<Either<Failure, StrategyResponse>> startStrategy(
    StartStrategyRequest request,
  );
  Future<Either<Failure, StrategyResponse>> stopStrategy(
    StopStrategyRequest request,
  );
  Future<Either<Failure, StrategyResponse>> pauseTrading(
    PauseTradingRequest request,
  );
  Future<Either<Failure, StrategyResponse>> resumeTrading(
    ResumeTradingRequest request,
  );

  // Data and State (Unary)
  Future<Either<Failure, StrategyStateResponse>> getStrategyState(
    GetStrategyStateRequest request,
  );
  Future<Either<Failure, TradeHistoryResponse>> getTradeHistory();
  Future<Either<Failure, SymbolLimitsResponse>> getSymbolLimits(
    SymbolLimitsRequest request,
  );
  Future<Either<Failure, OpenOrdersResponse>> getOpenOrders(
    OpenOrdersRequest request,
  );
  Future<Either<Failure, AccountInfoResponse>> getAccountInfo();
  Future<Either<Failure, LogSettingsResponse>> getLogSettings();
  Future<Either<Failure, LogSettingsResponse>> updateLogSettings(
    UpdateLogSettingsRequest request,
  );

  // Fee Management
  Future<Either<Failure, SymbolFeesResponse>> getSymbolFees(
    GetSymbolFeesRequest request,
  );
  Future<Either<Failure, AllSymbolFeesResponse>> getAllSymbolFees();

  // Streaming Methods
  Stream<Either<Failure, StrategyStateResponse>> subscribeStrategyState(
    GetStrategyStateRequest request,
  );
  Stream<Either<Failure, Trade>> subscribeTradeHistory();
  Stream<Either<Failure, AccountInfoResponse>> subscribeAccountInfo();
  Stream<Either<Failure, LogEntry>> subscribeSystemLogs();
  Stream<Either<Failure, PriceResponse>> streamCurrentPrice(
    StreamCurrentPriceRequest request,
  );
  Future<Either<Failure, PriceResponse>> getTickerInfo(
    StreamCurrentPriceRequest request,
  );
  Future<Either<Failure, AvailableSymbolsResponse>> getAvailableSymbols();

  Future<Either<Failure, LogEntry>> getWebSocketStats();

  // Order Management
  Future<Either<Failure, CancelOrderResponse>> cancelOrder(
    CancelOrderRequest request,
  );
  Future<Either<Failure, CancelOrderResponse>> cancelAllOrders(
    OpenOrdersRequest request,
  );

  // Status Report
  Future<Either<Failure, StatusReportResponse>> sendStatusReport();

  // Backtest
  Future<Either<Failure, BacktestResponse>> startBacktest(
    StartBacktestRequest request,
  );
  Future<Either<Failure, BacktestResultsResponse>> getBacktestResults(
    GetBacktestResultsRequest request,
  );
}
