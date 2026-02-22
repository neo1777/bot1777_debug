// This is a generated file - do not edit.
//
// Generated from trading/v1/trading_service.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart' as $0;

import 'trading_service.pb.dart' as $1;

export 'trading_service.pb.dart';

@$pb.GrpcServiceName('trading.v1.TradingService')
class TradingServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  TradingServiceClient(super.channel, {super.options, super.interceptors});

  /// === Impostazioni ===
  $grpc.ResponseFuture<$1.SettingsResponse> getSettings(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getSettings, request, options: options);
  }

  $grpc.ResponseFuture<$1.SettingsResponse> updateSettings(
    $1.UpdateSettingsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateSettings, request, options: options);
  }

  /// === Controllo Strategia ===
  $grpc.ResponseFuture<$1.StrategyResponse> startStrategy(
    $1.StartStrategyRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$startStrategy, request, options: options);
  }

  $grpc.ResponseFuture<$1.StrategyResponse> stopStrategy(
    $1.StopStrategyRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$stopStrategy, request, options: options);
  }

  $grpc.ResponseFuture<$1.StrategyResponse> pauseTrading(
    $1.PauseTradingRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$pauseTrading, request, options: options);
  }

  $grpc.ResponseFuture<$1.StrategyResponse> resumeTrading(
    $1.ResumeTradingRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$resumeTrading, request, options: options);
  }

  /// === Dati e Stato (Unary) ===
  $grpc.ResponseFuture<$1.StrategyStateResponse> getStrategyState(
    $1.GetStrategyStateRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getStrategyState, request, options: options);
  }

  $grpc.ResponseFuture<$1.TradeHistoryResponse> getTradeHistory(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getTradeHistory, request, options: options);
  }

  $grpc.ResponseFuture<$1.SymbolLimitsResponse> getSymbolLimits(
    $1.SymbolLimitsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getSymbolLimits, request, options: options);
  }

  $grpc.ResponseFuture<$1.OpenOrdersResponse> getOpenOrders(
    $1.OpenOrdersRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getOpenOrders, request, options: options);
  }

  $grpc.ResponseFuture<$1.AccountInfoResponse> getAccountInfo(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getAccountInfo, request, options: options);
  }

  $grpc.ResponseFuture<$1.LogSettingsResponse> getLogSettings(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getLogSettings, request, options: options);
  }

  $grpc.ResponseFuture<$1.LogSettingsResponse> updateLogSettings(
    $1.UpdateLogSettingsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateLogSettings, request, options: options);
  }

  /// === Streaming ===
  $grpc.ResponseStream<$1.StrategyStateResponse> subscribeStrategyState(
    $1.GetStrategyStateRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$subscribeStrategyState, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseStream<$1.Trade> subscribeTradeHistory(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$subscribeTradeHistory, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseStream<$1.AccountInfoResponse> subscribeAccountInfo(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$subscribeAccountInfo, $async.Stream.fromIterable([request]),
        options: options);
  }

  /// === NUOVI RPC AGGIUNTI ===
  $grpc.ResponseStream<$1.LogEntry> subscribeSystemLogs(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$subscribeSystemLogs, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseStream<$1.PriceResponse> streamCurrentPrice(
    $1.StreamCurrentPriceRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$streamCurrentPrice, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseFuture<$1.PriceResponse> getTickerInfo(
    $1.StreamCurrentPriceRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getTickerInfo, request, options: options);
  }

  /// Endpoint di monitoraggio: restituisce le statistiche correnti dei WebSocket
  $grpc.ResponseFuture<$1.LogEntry> getWebSocketStats(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getWebSocketStats, request, options: options);
  }

  /// === Gestione Ordini ===
  $grpc.ResponseFuture<$1.CancelOrderResponse> cancelOrder(
    $1.CancelOrderRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$cancelOrder, request, options: options);
  }

  $grpc.ResponseFuture<$1.CancelOrderResponse> cancelAllOrders(
    $1.OpenOrdersRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$cancelAllOrders, request, options: options);
  }

  /// === Gestione Fee ===
  $grpc.ResponseFuture<$1.SymbolFeesResponse> getSymbolFees(
    $1.GetSymbolFeesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getSymbolFees, request, options: options);
  }

  $grpc.ResponseFuture<$1.AllSymbolFeesResponse> getAllSymbolFees(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getAllSymbolFees, request, options: options);
  }

  /// === Utilità e Report ===
  $grpc.ResponseFuture<$1.StatusReportResponse> sendStatusReport(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$sendStatusReport, request, options: options);
  }

  /// === Exchange Info ===
  $grpc.ResponseFuture<$1.AvailableSymbolsResponse> getAvailableSymbols(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getAvailableSymbols, request, options: options);
  }

  /// === Backtesting ===
  $grpc.ResponseFuture<$1.BacktestResponse> startBacktest(
    $1.StartBacktestRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$startBacktest, request, options: options);
  }

  $grpc.ResponseFuture<$1.BacktestResultsResponse> getBacktestResults(
    $1.GetBacktestResultsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getBacktestResults, request, options: options);
  }

  // method descriptors

  static final _$getSettings =
      $grpc.ClientMethod<$0.Empty, $1.SettingsResponse>(
          '/trading.v1.TradingService/GetSettings',
          ($0.Empty value) => value.writeToBuffer(),
          $1.SettingsResponse.fromBuffer);
  static final _$updateSettings =
      $grpc.ClientMethod<$1.UpdateSettingsRequest, $1.SettingsResponse>(
          '/trading.v1.TradingService/UpdateSettings',
          ($1.UpdateSettingsRequest value) => value.writeToBuffer(),
          $1.SettingsResponse.fromBuffer);
  static final _$startStrategy =
      $grpc.ClientMethod<$1.StartStrategyRequest, $1.StrategyResponse>(
          '/trading.v1.TradingService/StartStrategy',
          ($1.StartStrategyRequest value) => value.writeToBuffer(),
          $1.StrategyResponse.fromBuffer);
  static final _$stopStrategy =
      $grpc.ClientMethod<$1.StopStrategyRequest, $1.StrategyResponse>(
          '/trading.v1.TradingService/StopStrategy',
          ($1.StopStrategyRequest value) => value.writeToBuffer(),
          $1.StrategyResponse.fromBuffer);
  static final _$pauseTrading =
      $grpc.ClientMethod<$1.PauseTradingRequest, $1.StrategyResponse>(
          '/trading.v1.TradingService/PauseTrading',
          ($1.PauseTradingRequest value) => value.writeToBuffer(),
          $1.StrategyResponse.fromBuffer);
  static final _$resumeTrading =
      $grpc.ClientMethod<$1.ResumeTradingRequest, $1.StrategyResponse>(
          '/trading.v1.TradingService/ResumeTrading',
          ($1.ResumeTradingRequest value) => value.writeToBuffer(),
          $1.StrategyResponse.fromBuffer);
  static final _$getStrategyState =
      $grpc.ClientMethod<$1.GetStrategyStateRequest, $1.StrategyStateResponse>(
          '/trading.v1.TradingService/GetStrategyState',
          ($1.GetStrategyStateRequest value) => value.writeToBuffer(),
          $1.StrategyStateResponse.fromBuffer);
  static final _$getTradeHistory =
      $grpc.ClientMethod<$0.Empty, $1.TradeHistoryResponse>(
          '/trading.v1.TradingService/GetTradeHistory',
          ($0.Empty value) => value.writeToBuffer(),
          $1.TradeHistoryResponse.fromBuffer);
  static final _$getSymbolLimits =
      $grpc.ClientMethod<$1.SymbolLimitsRequest, $1.SymbolLimitsResponse>(
          '/trading.v1.TradingService/GetSymbolLimits',
          ($1.SymbolLimitsRequest value) => value.writeToBuffer(),
          $1.SymbolLimitsResponse.fromBuffer);
  static final _$getOpenOrders =
      $grpc.ClientMethod<$1.OpenOrdersRequest, $1.OpenOrdersResponse>(
          '/trading.v1.TradingService/GetOpenOrders',
          ($1.OpenOrdersRequest value) => value.writeToBuffer(),
          $1.OpenOrdersResponse.fromBuffer);
  static final _$getAccountInfo =
      $grpc.ClientMethod<$0.Empty, $1.AccountInfoResponse>(
          '/trading.v1.TradingService/GetAccountInfo',
          ($0.Empty value) => value.writeToBuffer(),
          $1.AccountInfoResponse.fromBuffer);
  static final _$getLogSettings =
      $grpc.ClientMethod<$0.Empty, $1.LogSettingsResponse>(
          '/trading.v1.TradingService/GetLogSettings',
          ($0.Empty value) => value.writeToBuffer(),
          $1.LogSettingsResponse.fromBuffer);
  static final _$updateLogSettings =
      $grpc.ClientMethod<$1.UpdateLogSettingsRequest, $1.LogSettingsResponse>(
          '/trading.v1.TradingService/UpdateLogSettings',
          ($1.UpdateLogSettingsRequest value) => value.writeToBuffer(),
          $1.LogSettingsResponse.fromBuffer);
  static final _$subscribeStrategyState =
      $grpc.ClientMethod<$1.GetStrategyStateRequest, $1.StrategyStateResponse>(
          '/trading.v1.TradingService/SubscribeStrategyState',
          ($1.GetStrategyStateRequest value) => value.writeToBuffer(),
          $1.StrategyStateResponse.fromBuffer);
  static final _$subscribeTradeHistory = $grpc.ClientMethod<$0.Empty, $1.Trade>(
      '/trading.v1.TradingService/SubscribeTradeHistory',
      ($0.Empty value) => value.writeToBuffer(),
      $1.Trade.fromBuffer);
  static final _$subscribeAccountInfo =
      $grpc.ClientMethod<$0.Empty, $1.AccountInfoResponse>(
          '/trading.v1.TradingService/SubscribeAccountInfo',
          ($0.Empty value) => value.writeToBuffer(),
          $1.AccountInfoResponse.fromBuffer);
  static final _$subscribeSystemLogs =
      $grpc.ClientMethod<$0.Empty, $1.LogEntry>(
          '/trading.v1.TradingService/SubscribeSystemLogs',
          ($0.Empty value) => value.writeToBuffer(),
          $1.LogEntry.fromBuffer);
  static final _$streamCurrentPrice =
      $grpc.ClientMethod<$1.StreamCurrentPriceRequest, $1.PriceResponse>(
          '/trading.v1.TradingService/StreamCurrentPrice',
          ($1.StreamCurrentPriceRequest value) => value.writeToBuffer(),
          $1.PriceResponse.fromBuffer);
  static final _$getTickerInfo =
      $grpc.ClientMethod<$1.StreamCurrentPriceRequest, $1.PriceResponse>(
          '/trading.v1.TradingService/GetTickerInfo',
          ($1.StreamCurrentPriceRequest value) => value.writeToBuffer(),
          $1.PriceResponse.fromBuffer);
  static final _$getWebSocketStats = $grpc.ClientMethod<$0.Empty, $1.LogEntry>(
      '/trading.v1.TradingService/GetWebSocketStats',
      ($0.Empty value) => value.writeToBuffer(),
      $1.LogEntry.fromBuffer);
  static final _$cancelOrder =
      $grpc.ClientMethod<$1.CancelOrderRequest, $1.CancelOrderResponse>(
          '/trading.v1.TradingService/CancelOrder',
          ($1.CancelOrderRequest value) => value.writeToBuffer(),
          $1.CancelOrderResponse.fromBuffer);
  static final _$cancelAllOrders =
      $grpc.ClientMethod<$1.OpenOrdersRequest, $1.CancelOrderResponse>(
          '/trading.v1.TradingService/CancelAllOrders',
          ($1.OpenOrdersRequest value) => value.writeToBuffer(),
          $1.CancelOrderResponse.fromBuffer);
  static final _$getSymbolFees =
      $grpc.ClientMethod<$1.GetSymbolFeesRequest, $1.SymbolFeesResponse>(
          '/trading.v1.TradingService/GetSymbolFees',
          ($1.GetSymbolFeesRequest value) => value.writeToBuffer(),
          $1.SymbolFeesResponse.fromBuffer);
  static final _$getAllSymbolFees =
      $grpc.ClientMethod<$0.Empty, $1.AllSymbolFeesResponse>(
          '/trading.v1.TradingService/GetAllSymbolFees',
          ($0.Empty value) => value.writeToBuffer(),
          $1.AllSymbolFeesResponse.fromBuffer);
  static final _$sendStatusReport =
      $grpc.ClientMethod<$0.Empty, $1.StatusReportResponse>(
          '/trading.v1.TradingService/SendStatusReport',
          ($0.Empty value) => value.writeToBuffer(),
          $1.StatusReportResponse.fromBuffer);
  static final _$getAvailableSymbols =
      $grpc.ClientMethod<$0.Empty, $1.AvailableSymbolsResponse>(
          '/trading.v1.TradingService/GetAvailableSymbols',
          ($0.Empty value) => value.writeToBuffer(),
          $1.AvailableSymbolsResponse.fromBuffer);
  static final _$startBacktest =
      $grpc.ClientMethod<$1.StartBacktestRequest, $1.BacktestResponse>(
          '/trading.v1.TradingService/StartBacktest',
          ($1.StartBacktestRequest value) => value.writeToBuffer(),
          $1.BacktestResponse.fromBuffer);
  static final _$getBacktestResults = $grpc.ClientMethod<
          $1.GetBacktestResultsRequest, $1.BacktestResultsResponse>(
      '/trading.v1.TradingService/GetBacktestResults',
      ($1.GetBacktestResultsRequest value) => value.writeToBuffer(),
      $1.BacktestResultsResponse.fromBuffer);
}

@$pb.GrpcServiceName('trading.v1.TradingService')
abstract class TradingServiceBase extends $grpc.Service {
  $core.String get $name => 'trading.v1.TradingService';

  TradingServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.Empty, $1.SettingsResponse>(
        'GetSettings',
        getSettings_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($1.SettingsResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$1.UpdateSettingsRequest, $1.SettingsResponse>(
            'UpdateSettings',
            updateSettings_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $1.UpdateSettingsRequest.fromBuffer(value),
            ($1.SettingsResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$1.StartStrategyRequest, $1.StrategyResponse>(
            'StartStrategy',
            startStrategy_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $1.StartStrategyRequest.fromBuffer(value),
            ($1.StrategyResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.StopStrategyRequest, $1.StrategyResponse>(
        'StopStrategy',
        stopStrategy_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $1.StopStrategyRequest.fromBuffer(value),
        ($1.StrategyResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.PauseTradingRequest, $1.StrategyResponse>(
        'PauseTrading',
        pauseTrading_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $1.PauseTradingRequest.fromBuffer(value),
        ($1.StrategyResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$1.ResumeTradingRequest, $1.StrategyResponse>(
            'ResumeTrading',
            resumeTrading_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $1.ResumeTradingRequest.fromBuffer(value),
            ($1.StrategyResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.GetStrategyStateRequest,
            $1.StrategyStateResponse>(
        'GetStrategyState',
        getStrategyState_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $1.GetStrategyStateRequest.fromBuffer(value),
        ($1.StrategyStateResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $1.TradeHistoryResponse>(
        'GetTradeHistory',
        getTradeHistory_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($1.TradeHistoryResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$1.SymbolLimitsRequest, $1.SymbolLimitsResponse>(
            'GetSymbolLimits',
            getSymbolLimits_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $1.SymbolLimitsRequest.fromBuffer(value),
            ($1.SymbolLimitsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.OpenOrdersRequest, $1.OpenOrdersResponse>(
        'GetOpenOrders',
        getOpenOrders_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.OpenOrdersRequest.fromBuffer(value),
        ($1.OpenOrdersResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $1.AccountInfoResponse>(
        'GetAccountInfo',
        getAccountInfo_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($1.AccountInfoResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $1.LogSettingsResponse>(
        'GetLogSettings',
        getLogSettings_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($1.LogSettingsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.UpdateLogSettingsRequest,
            $1.LogSettingsResponse>(
        'UpdateLogSettings',
        updateLogSettings_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $1.UpdateLogSettingsRequest.fromBuffer(value),
        ($1.LogSettingsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.GetStrategyStateRequest,
            $1.StrategyStateResponse>(
        'SubscribeStrategyState',
        subscribeStrategyState_Pre,
        false,
        true,
        ($core.List<$core.int> value) =>
            $1.GetStrategyStateRequest.fromBuffer(value),
        ($1.StrategyStateResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $1.Trade>(
        'SubscribeTradeHistory',
        subscribeTradeHistory_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($1.Trade value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $1.AccountInfoResponse>(
        'SubscribeAccountInfo',
        subscribeAccountInfo_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($1.AccountInfoResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $1.LogEntry>(
        'SubscribeSystemLogs',
        subscribeSystemLogs_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($1.LogEntry value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$1.StreamCurrentPriceRequest, $1.PriceResponse>(
            'StreamCurrentPrice',
            streamCurrentPrice_Pre,
            false,
            true,
            ($core.List<$core.int> value) =>
                $1.StreamCurrentPriceRequest.fromBuffer(value),
            ($1.PriceResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$1.StreamCurrentPriceRequest, $1.PriceResponse>(
            'GetTickerInfo',
            getTickerInfo_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $1.StreamCurrentPriceRequest.fromBuffer(value),
            ($1.PriceResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $1.LogEntry>(
        'GetWebSocketStats',
        getWebSocketStats_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($1.LogEntry value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$1.CancelOrderRequest, $1.CancelOrderResponse>(
            'CancelOrder',
            cancelOrder_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $1.CancelOrderRequest.fromBuffer(value),
            ($1.CancelOrderResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$1.OpenOrdersRequest, $1.CancelOrderResponse>(
            'CancelAllOrders',
            cancelAllOrders_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $1.OpenOrdersRequest.fromBuffer(value),
            ($1.CancelOrderResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$1.GetSymbolFeesRequest, $1.SymbolFeesResponse>(
            'GetSymbolFees',
            getSymbolFees_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $1.GetSymbolFeesRequest.fromBuffer(value),
            ($1.SymbolFeesResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $1.AllSymbolFeesResponse>(
        'GetAllSymbolFees',
        getAllSymbolFees_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($1.AllSymbolFeesResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $1.StatusReportResponse>(
        'SendStatusReport',
        sendStatusReport_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($1.StatusReportResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $1.AvailableSymbolsResponse>(
        'GetAvailableSymbols',
        getAvailableSymbols_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($1.AvailableSymbolsResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$1.StartBacktestRequest, $1.BacktestResponse>(
            'StartBacktest',
            startBacktest_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $1.StartBacktestRequest.fromBuffer(value),
            ($1.BacktestResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.GetBacktestResultsRequest,
            $1.BacktestResultsResponse>(
        'GetBacktestResults',
        getBacktestResults_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $1.GetBacktestResultsRequest.fromBuffer(value),
        ($1.BacktestResultsResponse value) => value.writeToBuffer()));
  }

  $async.Future<$1.SettingsResponse> getSettings_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return getSettings($call, await $request);
  }

  $async.Future<$1.SettingsResponse> getSettings(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$1.SettingsResponse> updateSettings_Pre($grpc.ServiceCall $call,
      $async.Future<$1.UpdateSettingsRequest> $request) async {
    return updateSettings($call, await $request);
  }

  $async.Future<$1.SettingsResponse> updateSettings(
      $grpc.ServiceCall call, $1.UpdateSettingsRequest request);

  $async.Future<$1.StrategyResponse> startStrategy_Pre($grpc.ServiceCall $call,
      $async.Future<$1.StartStrategyRequest> $request) async {
    return startStrategy($call, await $request);
  }

  $async.Future<$1.StrategyResponse> startStrategy(
      $grpc.ServiceCall call, $1.StartStrategyRequest request);

  $async.Future<$1.StrategyResponse> stopStrategy_Pre($grpc.ServiceCall $call,
      $async.Future<$1.StopStrategyRequest> $request) async {
    return stopStrategy($call, await $request);
  }

  $async.Future<$1.StrategyResponse> stopStrategy(
      $grpc.ServiceCall call, $1.StopStrategyRequest request);

  $async.Future<$1.StrategyResponse> pauseTrading_Pre($grpc.ServiceCall $call,
      $async.Future<$1.PauseTradingRequest> $request) async {
    return pauseTrading($call, await $request);
  }

  $async.Future<$1.StrategyResponse> pauseTrading(
      $grpc.ServiceCall call, $1.PauseTradingRequest request);

  $async.Future<$1.StrategyResponse> resumeTrading_Pre($grpc.ServiceCall $call,
      $async.Future<$1.ResumeTradingRequest> $request) async {
    return resumeTrading($call, await $request);
  }

  $async.Future<$1.StrategyResponse> resumeTrading(
      $grpc.ServiceCall call, $1.ResumeTradingRequest request);

  $async.Future<$1.StrategyStateResponse> getStrategyState_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.GetStrategyStateRequest> $request) async {
    return getStrategyState($call, await $request);
  }

  $async.Future<$1.StrategyStateResponse> getStrategyState(
      $grpc.ServiceCall call, $1.GetStrategyStateRequest request);

  $async.Future<$1.TradeHistoryResponse> getTradeHistory_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return getTradeHistory($call, await $request);
  }

  $async.Future<$1.TradeHistoryResponse> getTradeHistory(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$1.SymbolLimitsResponse> getSymbolLimits_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.SymbolLimitsRequest> $request) async {
    return getSymbolLimits($call, await $request);
  }

  $async.Future<$1.SymbolLimitsResponse> getSymbolLimits(
      $grpc.ServiceCall call, $1.SymbolLimitsRequest request);

  $async.Future<$1.OpenOrdersResponse> getOpenOrders_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.OpenOrdersRequest> $request) async {
    return getOpenOrders($call, await $request);
  }

  $async.Future<$1.OpenOrdersResponse> getOpenOrders(
      $grpc.ServiceCall call, $1.OpenOrdersRequest request);

  $async.Future<$1.AccountInfoResponse> getAccountInfo_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return getAccountInfo($call, await $request);
  }

  $async.Future<$1.AccountInfoResponse> getAccountInfo(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$1.LogSettingsResponse> getLogSettings_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return getLogSettings($call, await $request);
  }

  $async.Future<$1.LogSettingsResponse> getLogSettings(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$1.LogSettingsResponse> updateLogSettings_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.UpdateLogSettingsRequest> $request) async {
    return updateLogSettings($call, await $request);
  }

  $async.Future<$1.LogSettingsResponse> updateLogSettings(
      $grpc.ServiceCall call, $1.UpdateLogSettingsRequest request);

  $async.Stream<$1.StrategyStateResponse> subscribeStrategyState_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.GetStrategyStateRequest> $request) async* {
    yield* subscribeStrategyState($call, await $request);
  }

  $async.Stream<$1.StrategyStateResponse> subscribeStrategyState(
      $grpc.ServiceCall call, $1.GetStrategyStateRequest request);

  $async.Stream<$1.Trade> subscribeTradeHistory_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async* {
    yield* subscribeTradeHistory($call, await $request);
  }

  $async.Stream<$1.Trade> subscribeTradeHistory(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Stream<$1.AccountInfoResponse> subscribeAccountInfo_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async* {
    yield* subscribeAccountInfo($call, await $request);
  }

  $async.Stream<$1.AccountInfoResponse> subscribeAccountInfo(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Stream<$1.LogEntry> subscribeSystemLogs_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async* {
    yield* subscribeSystemLogs($call, await $request);
  }

  $async.Stream<$1.LogEntry> subscribeSystemLogs(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Stream<$1.PriceResponse> streamCurrentPrice_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.StreamCurrentPriceRequest> $request) async* {
    yield* streamCurrentPrice($call, await $request);
  }

  $async.Stream<$1.PriceResponse> streamCurrentPrice(
      $grpc.ServiceCall call, $1.StreamCurrentPriceRequest request);

  $async.Future<$1.PriceResponse> getTickerInfo_Pre($grpc.ServiceCall $call,
      $async.Future<$1.StreamCurrentPriceRequest> $request) async {
    return getTickerInfo($call, await $request);
  }

  $async.Future<$1.PriceResponse> getTickerInfo(
      $grpc.ServiceCall call, $1.StreamCurrentPriceRequest request);

  $async.Future<$1.LogEntry> getWebSocketStats_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return getWebSocketStats($call, await $request);
  }

  $async.Future<$1.LogEntry> getWebSocketStats(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$1.CancelOrderResponse> cancelOrder_Pre($grpc.ServiceCall $call,
      $async.Future<$1.CancelOrderRequest> $request) async {
    return cancelOrder($call, await $request);
  }

  $async.Future<$1.CancelOrderResponse> cancelOrder(
      $grpc.ServiceCall call, $1.CancelOrderRequest request);

  $async.Future<$1.CancelOrderResponse> cancelAllOrders_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.OpenOrdersRequest> $request) async {
    return cancelAllOrders($call, await $request);
  }

  $async.Future<$1.CancelOrderResponse> cancelAllOrders(
      $grpc.ServiceCall call, $1.OpenOrdersRequest request);

  $async.Future<$1.SymbolFeesResponse> getSymbolFees_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.GetSymbolFeesRequest> $request) async {
    return getSymbolFees($call, await $request);
  }

  $async.Future<$1.SymbolFeesResponse> getSymbolFees(
      $grpc.ServiceCall call, $1.GetSymbolFeesRequest request);

  $async.Future<$1.AllSymbolFeesResponse> getAllSymbolFees_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return getAllSymbolFees($call, await $request);
  }

  $async.Future<$1.AllSymbolFeesResponse> getAllSymbolFees(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$1.StatusReportResponse> sendStatusReport_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return sendStatusReport($call, await $request);
  }

  $async.Future<$1.StatusReportResponse> sendStatusReport(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$1.AvailableSymbolsResponse> getAvailableSymbols_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return getAvailableSymbols($call, await $request);
  }

  $async.Future<$1.AvailableSymbolsResponse> getAvailableSymbols(
      $grpc.ServiceCall call, $0.Empty request);

  $async.Future<$1.BacktestResponse> startBacktest_Pre($grpc.ServiceCall $call,
      $async.Future<$1.StartBacktestRequest> $request) async {
    return startBacktest($call, await $request);
  }

  $async.Future<$1.BacktestResponse> startBacktest(
      $grpc.ServiceCall call, $1.StartBacktestRequest request);

  $async.Future<$1.BacktestResultsResponse> getBacktestResults_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$1.GetBacktestResultsRequest> $request) async {
    return getBacktestResults($call, await $request);
  }

  $async.Future<$1.BacktestResultsResponse> getBacktestResults(
      $grpc.ServiceCall call, $1.GetBacktestResultsRequest request);
}
