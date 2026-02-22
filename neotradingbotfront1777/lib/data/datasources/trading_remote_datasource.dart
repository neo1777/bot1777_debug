import 'dart:async'; // unawaited is here
import 'package:grpc/grpc.dart';
import 'package:logger/logger.dart';
import 'package:neotradingbotfront1777/core/utils/log_manager.dart';
import 'package:neotradingbotfront1777/data/datasources/i_trading_remote_datasource.dart';
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pbgrpc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';

class TradingRemoteDatasource implements ITradingRemoteDatasource {
  final TradingServiceClient _client;
  final Logger _logger;

  TradingRemoteDatasource({required TradingServiceClient client})
    : _client = client,
      _logger = LogManager.getLogger();

  Future<Either<Failure, T>> _unaryCall<T>(
    String methodName,
    Future<T> Function(CallOptions options) call, {
    int maxAttempts = 3,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    int attempt = 0;
    int backoffMs = 200;
    while (true) {
      attempt++;
      try {
        // Timeout nativo gRPC tramite CallOptions (deadline)
        // Timeout nativo gRPC tramite CallOptions (deadline)
        final response = await call(CallOptions(timeout: timeout));

        return Right(response);
      } on GrpcError catch (e, s) {
        // Logging specifico
        switch (e.code) {
          case StatusCode.unavailable:
            _logger.w(
              'gRPC Unavailable: $methodName (attempt $attempt/$maxAttempts)',
              error: e,
              stackTrace: s,
            );
            break;
          case StatusCode.deadlineExceeded:
            _logger.w(
              'gRPC Timeout: $methodName (attempt $attempt/$maxAttempts)',
              error: e,
              stackTrace: s,
            );
            break;
          case StatusCode.resourceExhausted:
            _logger.w(
              'gRPC Throttled: $methodName (attempt $attempt/$maxAttempts)',
              error: e,
              stackTrace: s,
            );
            break;
          case StatusCode.unauthenticated:
          case StatusCode.permissionDenied:
            _logger.e(
              'gRPC Auth/Permission error: $methodName',
              error: e,
              stackTrace: s,
            );
            return Left(
              NetworkFailure(
                message: 'Errore di autenticazione: ${e.message}',
                statusCode: e.code,
              ),
            );
          case StatusCode.notFound:
            _logger.w('gRPC NotFound: $methodName', error: e, stackTrace: s);
            // Mappa esplicitamente a NotFoundFailure per permettere alla UI di
            // distinguere il caso "nessuno stato ancora persistito" da errori reali.
            return Left(
              NotFoundFailure(message: e.message ?? 'Risorsa non trovata'),
            );
          case StatusCode.invalidArgument:
            _logger.w(
              'gRPC InvalidArgument: $methodName',
              error: e,
              stackTrace: s,
            );
            return Left(
              ValidationFailure(message: 'Argomento non valido: ${e.message}'),
            );
          default:
            _logger.e(
              'gRPC Error [$methodName]: ${e.codeName} ${e.message ?? ''}'
                  .trim(),
            );
            return Left(
              NetworkFailure(
                message: 'Errore gRPC: ${e.message}',
                statusCode: e.code,
              ),
            );
        }
        // Policy di retry per errori transienti
        if (attempt < maxAttempts &&
            (e.code == StatusCode.unavailable ||
                e.code == StatusCode.deadlineExceeded ||
                e.code == StatusCode.resourceExhausted)) {
          await Future.delayed(Duration(milliseconds: backoffMs));
          backoffMs = (backoffMs * 2).clamp(200, 4000);
          continue;
        }
        return Left(
          NetworkFailure(
            message: 'Errore gRPC dopo $maxAttempts tentativi: ${e.message}',
            statusCode: e.code,
          ),
        );
      } catch (e) {
        _logger.f('gRPC Unhandled [$methodName]: $e');
        return Left(NetworkFailure(message: 'Errore imprevisto: $e'));
      }
    }
  }

  Stream<Either<Failure, T>> _streamCall<T>(
    String methodName,
    Stream<T> Function() call,
  ) {
    return call()
        .handleError((e, s) {
          if (e is GrpcError) {
            switch (e.code) {
              case StatusCode.unavailable:
                _logger.w(
                  'gRPC Stream Unavailable [$methodName]: ${e.codeName}',
                );
                break;
              case StatusCode.deadlineExceeded:
                _logger.w('gRPC Stream Timeout [$methodName]');
                break;
              default:
                _logger.e(
                  'gRPC Stream Error [$methodName]: ${e.codeName} ${e.message ?? ''}'
                      .trim(),
                );
            }
          } else {
            _logger.e('gRPC Stream Error (non-gRPC) [$methodName]: $e');
          }
          // Propaga l'errore per gestione a livello superiore
        })
        .map((data) => Right(data));
  }

  // Settings Management
  @override
  Future<Either<Failure, SettingsResponse>> getSettings() => _unaryCall(
    'getSettings',
    (opts) => _client.getSettings(Empty(), options: opts),
  );

  @override
  Future<Either<Failure, SettingsResponse>> updateSettings(
    UpdateSettingsRequest request,
  ) async {
    final resp = await _unaryCall(
      'updateSettings',
      (opts) => _client.updateSettings(request, options: opts),
    );

    // Estrai warnings se il proto li prevede in futuro
    resp.fold(
      (failure) => {}, // Nessuna azione necessaria per i failure
      (response) {
        try {
          final dynamic anyResp = response;
          final warnings = (anyResp as dynamic).warnings as List<dynamic>?;
          if (warnings != null && warnings.isNotEmpty) {
            _logger.w('updateSettings warnings: ${warnings.join(" | ")}');
          }
        } catch (_) {}
      },
    );

    return resp;
  }

  // Strategy Control
  @override
  Future<Either<Failure, StrategyResponse>> startStrategy(
    StartStrategyRequest request,
  ) => _unaryCall(
    'startStrategy',
    (opts) => _client.startStrategy(request, options: opts),
  );

  @override
  Future<Either<Failure, StrategyResponse>> stopStrategy(
    StopStrategyRequest request,
  ) => _unaryCall(
    'stopStrategy',
    (opts) => _client.stopStrategy(request, options: opts),
  );

  @override
  Future<Either<Failure, StrategyResponse>> pauseTrading(
    PauseTradingRequest request,
  ) => _unaryCall(
    'pauseTrading',
    (opts) => _client.pauseTrading(request, options: opts),
  );

  @override
  Future<Either<Failure, StrategyResponse>> resumeTrading(
    ResumeTradingRequest request,
  ) => _unaryCall(
    'resumeTrading',
    (opts) => _client.resumeTrading(request, options: opts),
  );

  // Data and State (Unary)
  @override
  Future<Either<Failure, StrategyStateResponse>> getStrategyState(
    GetStrategyStateRequest request,
  ) => _unaryCall(
    'getStrategyState',
    (opts) => _client.getStrategyState(request, options: opts),
  );

  @override
  Future<Either<Failure, TradeHistoryResponse>> getTradeHistory() => _unaryCall(
    'getTradeHistory',
    (opts) => _client.getTradeHistory(Empty(), options: opts),
  );

  @override
  Future<Either<Failure, SymbolLimitsResponse>> getSymbolLimits(
    SymbolLimitsRequest request,
  ) => _unaryCall(
    'getSymbolLimits',
    (opts) => _client.getSymbolLimits(request, options: opts),
  );

  @override
  Future<Either<Failure, OpenOrdersResponse>> getOpenOrders(
    OpenOrdersRequest request,
  ) => _unaryCall(
    'getOpenOrders',
    (opts) => _client.getOpenOrders(request, options: opts),
  );

  @override
  Future<Either<Failure, AccountInfoResponse>> getAccountInfo() {
    return _unaryCall(
      'getAccountInfo',
      (opts) => _client.getAccountInfo(Empty(), options: opts),
    );
  }

  @override
  Future<Either<Failure, LogSettingsResponse>> getLogSettings() => _unaryCall(
    'getLogSettings',
    (opts) => _client.getLogSettings(Empty(), options: opts),
  );

  @override
  Future<Either<Failure, LogSettingsResponse>> updateLogSettings(
    UpdateLogSettingsRequest request,
  ) => _unaryCall(
    'updateLogSettings',
    (opts) => _client.updateLogSettings(request, options: opts),
  );

  // Fee Management
  @override
  Future<Either<Failure, SymbolFeesResponse>> getSymbolFees(
    GetSymbolFeesRequest request,
  ) => _unaryCall(
    'getSymbolFees',
    (opts) => _client.getSymbolFees(request, options: opts),
  );

  @override
  Future<Either<Failure, AllSymbolFeesResponse>> getAllSymbolFees() =>
      _unaryCall(
        'getAllSymbolFees',
        (opts) => _client.getAllSymbolFees(Empty(), options: opts),
      );

  // Streaming Methods
  @override
  Stream<Either<Failure, StrategyStateResponse>> subscribeStrategyState(
    GetStrategyStateRequest request,
  ) => _streamCall(
    'subscribeStrategyState',
    () => _client.subscribeStrategyState(request),
  );

  @override
  Stream<Either<Failure, Trade>> subscribeTradeHistory() => _streamCall(
    'subscribeTradeHistory',
    () => _client.subscribeTradeHistory(Empty()),
  );

  @override
  Stream<Either<Failure, AccountInfoResponse>> subscribeAccountInfo() =>
      _streamCall(
        'subscribeAccountInfo',
        () => _client.subscribeAccountInfo(Empty()),
      );

  @override
  Stream<Either<Failure, LogEntry>> subscribeSystemLogs() => _streamCall(
    'subscribeSystemLogs',
    () => _client.subscribeSystemLogs(Empty()),
  );

  @override
  Stream<Either<Failure, PriceResponse>> streamCurrentPrice(
    StreamCurrentPriceRequest request,
  ) => _streamCall(
    'streamCurrentPrice',
    () => _client.streamCurrentPrice(request),
  );

  @override
  Future<Either<Failure, PriceResponse>> getTickerInfo(
    StreamCurrentPriceRequest request,
  ) => _unaryCall(
    'getTickerInfo',
    (opts) => _client.getTickerInfo(request, options: opts),
  );

  @override
  Future<Either<Failure, AvailableSymbolsResponse>> getAvailableSymbols() {
    return _unaryCall(
      'getAvailableSymbols',
      (options) => _client.getAvailableSymbols(Empty(), options: options),
    );
  }

  @override
  Future<Either<Failure, LogEntry>> getWebSocketStats() {
    return _unaryCall(
      'getWebSocketStats',
      (options) => _client.getWebSocketStats(Empty(), options: options),
    );
  }

  // Order Management
  @override
  Future<Either<Failure, CancelOrderResponse>> cancelOrder(
    CancelOrderRequest request,
  ) => _unaryCall(
    'cancelOrder',
    (opts) => _client.cancelOrder(request, options: opts),
  );

  @override
  Future<Either<Failure, CancelOrderResponse>> cancelAllOrders(
    OpenOrdersRequest request,
  ) => _unaryCall(
    'cancelAllOrders',
    (opts) => _client.cancelAllOrders(request, options: opts),
  );

  @override
  Future<Either<Failure, StatusReportResponse>> sendStatusReport() =>
      _unaryCall(
        'sendStatusReport',
        (opts) => _client.sendStatusReport(Empty(), options: opts),
      );

  // Backtest
  @override
  Future<Either<Failure, BacktestResponse>> startBacktest(
    StartBacktestRequest request,
  ) => _unaryCall(
    'startBacktest',
    (opts) => _client.startBacktest(request, options: opts),
  );

  @override
  Future<Either<Failure, BacktestResultsResponse>> getBacktestResults(
    GetBacktestResultsRequest request,
  ) => _unaryCall(
    'getBacktestResults',
    (opts) => _client.getBacktestResults(request, options: opts),
  );
}
