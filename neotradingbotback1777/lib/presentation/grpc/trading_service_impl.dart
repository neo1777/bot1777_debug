import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';
import 'package:logger/logger.dart';
import 'package:neotradingbotback1777/application/monitoring/isolate_health_monitor.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:neotradingbotback1777/application/use_cases/get_account_info_use_case.dart';
import 'package:neotradingbotback1777/application/use_cases/send_status_report_use_case.dart';
import 'package:neotradingbotback1777/application/use_cases/get_log_settings_use_case.dart';
import 'package:neotradingbotback1777/application/use_cases/get_open_orders_use_case.dart';
import 'package:neotradingbotback1777/application/use_cases/get_settings_use_case.dart';
import 'package:neotradingbotback1777/application/use_cases/get_strategy_state_use_case.dart';
import 'package:neotradingbotback1777/application/use_cases/get_trade_history_use_case.dart';
import 'package:neotradingbotback1777/application/use_cases/pause_trading_use_case.dart';
import 'package:neotradingbotback1777/application/use_cases/resume_trading_use_case.dart';
import 'package:neotradingbotback1777/application/use_cases/start_strategy_atomic_use_case.dart';
import 'package:neotradingbotback1777/application/use_cases/stop_strategy_use_case.dart';
import 'package:neotradingbotback1777/application/use_cases/update_log_settings_use_case.dart';
import 'package:neotradingbotback1777/application/use_cases/cancel_all_orders_use_case.dart';
import 'package:neotradingbotback1777/application/use_cases/cancel_order_use_case.dart';
import 'package:neotradingbotback1777/application/use_cases/update_settings_use_case.dart';
import 'package:neotradingbotback1777/domain/entities/account_info.dart';
import 'package:neotradingbotback1777/domain/entities/balance.dart';
import 'package:neotradingbotback1777/domain/entities/log_settings.dart';
import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/application/use_cases/run_backtest_use_case.dart';
import 'package:neotradingbotback1777/domain/repositories/backtest_result_repository.dart';
import 'package:neotradingbotback1777/core/utils/decimal_utils.dart';
import 'package:neotradingbotback1777/domain/entities/log_entry.dart' as domain;

import 'package:neotradingbotback1777/domain/repositories/trading_repository_new.dart';
import 'package:neotradingbotback1777/domain/repositories/strategy_state_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/account_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/price_repository.dart';
import 'package:neotradingbotback1777/injection.dart';
import 'package:neotradingbotback1777/domain/services/i_trading_api_service.dart';
import 'package:neotradingbotback1777/core/logging/log_stream_service.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/application/managers/trading_loop_manager.dart';

import 'package:neotradingbotback1777/application/use_cases/get_symbol_limits_use_case.dart';
import 'dart:io';
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart';
import 'package:neotradingbotback1777/generated/proto/trading/v1/trading_service.pb.dart'
    as grpc;
import 'package:neotradingbotback1777/generated/proto/trading/v1/trading_service.pbgrpc.dart';
import 'package:neotradingbotback1777/domain/services/settings_validation_service.dart';
import 'package:neotradingbotback1777/domain/repositories/i_fee_repository.dart';
import 'package:neotradingbotback1777/presentation/grpc/interceptors/validation_interceptor.dart';
import 'package:neotradingbotback1777/core/config/trading_constants.dart';
import 'package:neotradingbotback1777/presentation/grpc/mappers/grpc_mappers.dart';

// Mappers logic moved to lib/presentation/grpc/mappers/grpc_mappers.dart

class TradingServiceImpl extends TradingServiceBase {
  static final Map<String, int> _priceLogCounters = {};
  static final Map<String, DateTime> _lastPriceLogTime = {};
  // Frequenza log stream prezzo configurabile
  static int _priceLogEveryN = TradingConstants.defaultPriceLogEveryN;
  static int _priceLogEverySeconds =
      TradingConstants.defaultPriceLogEverySeconds.inSeconds;
  static final Map<String, int> _stateLogCounters = {};
  static final Map<String, DateTime> _lastStateLogTime = {};

  static void _cleanupLogCounters(String symbol) {
    _priceLogCounters.remove(symbol);
    _lastPriceLogTime.remove(symbol);
    _stateLogCounters.remove(symbol);
    _lastStateLogTime.remove(symbol);
  }

  @override
  Future<grpc.SettingsResponse> getSettings(
      ServiceCall call, Empty request) async {
    final log = LogManager.getLogger();
    // log.d('[GRPC] getSettings | Request received'); // Redundant with LoggingInterceptor
    final useCase = sl<GetSettings>();
    final result = await useCase();
    return result.fold(
      (failure) {
        log.e('[GRPC] getSettings | Error: ${failure.message}');
        throw _mapFailureToGrpcError(failure);
      },
      (settings) {
        final response = grpc.SettingsResponse()..settings = settings.toGrpc();
        log.i('[GRPC] getSettings | Success');
        return response;
      },
    );
  }

  @override
  Future<grpc.SettingsResponse> updateSettings(
      ServiceCall call, grpc.UpdateSettingsRequest request) async {
    final log = LogManager.getLogger();
    // log.d('[GRPC] updateSettings | Request received'); // Redundant

    // Mappatura gRPC -> Domain
    final domainSettings = request.settings.toDomain();

    // Utilizzo del servizio di validazione del Domain layer
    final validationService = sl<SettingsValidationService>();
    final validationResult = validationService.validateSettings(domainSettings);

    if (validationResult.isLeft()) {
      final failure = validationResult.fold(
          (f) => f, (_) => throw Exception('Unexpected error'));
      log.w('[GRPC] updateSettings | Validation failed: ${failure.message}');
      throw GrpcError.invalidArgument(failure.message);
    }

    final validatedSettings =
        validationResult.getOrElse((_) => throw Exception('Unexpected error'));
    log.d('[GRPC] updateSettings | Settings validated successfully');

    // Applicazione dei limiti di sicurezza
    final enforcedSettings =
        validationService.applySecurityLimits(validatedSettings);

    if (enforcedSettings.tradeAmount != validatedSettings.tradeAmount) {
      log.w(
          '[GRPC] updateSettings | tradeAmount clamped to ${enforcedSettings.tradeAmount}');
      try {
        // Emissione log strutturato verso gli stream per visibilità lato client
        LogStreamService().addLog(domain.LogEntry(
          level: 'WARNING',
          message:
              'SETTINGS_CLAMP;field=tradeAmount;client=${validatedSettings.tradeAmount};effective=${enforcedSettings.tradeAmount}',
          timestamp: DateTime.now(),
          serviceName: 'TradingServiceImpl',
        ));
      } catch (e) {
        log.d('Ignored error logging settings clamp: $e');
      }
    }

    final useCase = sl<UpdateSettings>();
    final result = await useCase(enforcedSettings);

    return result.fold(
      (failure) {
        log.e('[GRPC] updateSettings | Error: ${failure.message}');
        throw _mapFailureToGrpcError(failure);
      },
      (success) async {
        // Aggiorna la modalità dell'API Service (Real vs Testnet)
        sl<ITradingApiService>()
            .updateMode(isTestMode: enforcedSettings.isTestMode);

        // Pulisce la cache dell'account per forzare il ricaricamento dei bilanci corretti
        await sl<AccountRepository>().clearAccountInfo();

        // Force immediate refresh from the correct endpoint
        final refreshResult =
            await sl<AccountRepository>().refreshAccountInfo();
        refreshResult.fold(
          (failure) => log.w(
              '[GRPC] Failed to refresh account after mode switch: ${failure.message}'),
          (_) => log.i(
              '[GRPC] Mode switched to ${enforcedSettings.isTestMode ? "TEST" : "REAL"}, account data refreshed'),
        );

        final response = grpc.SettingsResponse()
          ..settings = enforcedSettings.toGrpc();

        // Popola warnings per retrocompatibilità
        final warnings = <String>[];
        if (enforcedSettings.tradeAmount != request.settings.tradeAmount) {
          warnings.add(
              'tradeAmount clamped from ${request.settings.tradeAmount} to ${enforcedSettings.tradeAmount}');
        }
        if (warnings.isNotEmpty) {
          response.warnings.addAll(warnings);
        }

        log.i('[GRPC] updateSettings | Success');
        return response;
      },
    );
  }

  @override
  Future<grpc.StrategyResponse> startStrategy(
      ServiceCall call, grpc.StartStrategyRequest request) async {
    final log = LogManager.getLogger();
    // log.d('[GRPC] startStrategy (ATOMIC) | Request received'); // Redundant

    final symbol = _validateSymbol(request.symbol, 'startStrategy');

    final useCase = sl<StartStrategyAtomic>();
    final getSettingsUseCase = sl<GetSettings>();

    final settingsResult = await getSettingsUseCase();
    return settingsResult.fold(
      (f) {
        log.e(
            '[GRPC_TRACE] startStrategy (ATOMIC) | Error getting settings: ${f.message}');
        throw _mapFailureToGrpcError(f);
      },
      (settings) async {
        final result = await useCase(symbol: symbol, settings: settings);
        return result.fold(
          (f) {
            log.e(
                '[GRPC] startStrategy (ATOMIC) | Error starting strategy: ${f.message}');
            throw _mapFailureToGrpcError(f);
          },
          (_) {
            final response = grpc.StrategyResponse(
                success: true,
                message: 'Strategia atomica avviata per ${request.symbol}');
            log.i('[GRPC] startStrategy (ATOMIC) | Success');
            return response;
          },
        );
      },
    );
  }

  @override
  Future<grpc.StrategyResponse> stopStrategy(
      ServiceCall call, grpc.StopStrategyRequest request) async {
    final log = LogManager.getLogger();
    // log.i('[GRPC_TRACE] stopStrategy | Request received: ${request.toProto3Json()}'); // Redundant
    final useCase = sl<StopStrategy>();
    final result = await useCase(symbol: request.symbol);
    return result.fold(
      (f) {
        log.e('[GRPC_TRACE] stopStrategy | Error: ${f.message}');
        throw _mapFailureToGrpcError(f);
      },
      (_) {
        final response = grpc.StrategyResponse(
            success: true, message: 'Strategia fermata per ${request.symbol}');
        log.i(
            '[GRPC_TRACE] stopStrategy | Sending response: ${response.toProto3Json()}');
        return response;
      },
    );
  }

  @override
  Future<grpc.StrategyResponse> pauseTrading(
      ServiceCall call, grpc.PauseTradingRequest request) async {
    final log = LogManager.getLogger();
    // log.i('[GRPC_TRACE] pauseTrading | Request received: ${request.toProto3Json()}'); // Redundant
    final useCase = sl<PauseTrading>();
    final result = await useCase(symbol: request.symbol);
    return result.fold(
      (f) {
        log.e('[GRPC_TRACE] pauseTrading | Error: ${f.message}');
        throw _mapFailureToGrpcError(f);
      },
      (_) {
        final response = grpc.StrategyResponse(
            success: true, message: 'Acquisti in pausa per ${request.symbol}');
        log.i(
            '[GRPC_TRACE] pauseTrading | Sending response: ${response.toProto3Json()}');
        return response;
      },
    );
  }

  @override
  Future<grpc.StrategyResponse> resumeTrading(
      ServiceCall call, grpc.ResumeTradingRequest request) async {
    final log = LogManager.getLogger();
    // log.i('[GRPC_TRACE] resumeTrading | Request received: ${request.toProto3Json()}'); // Redundant
    final useCase = sl<ResumeTrading>();
    final result = await useCase(symbol: request.symbol);
    return result.fold(
      (f) {
        log.e('[GRPC_TRACE] resumeTrading | Error: ${f.message}');
        throw _mapFailureToGrpcError(f);
      },
      (_) {
        final response = grpc.StrategyResponse(
            success: true, message: 'Acquisti ripresi per ${request.symbol}');
        log.i(
            '[GRPC_TRACE] resumeTrading | Sending response: ${response.toProto3Json()}');
        return response;
      },
    );
  }

  @override
  Future<grpc.StrategyStateResponse> getStrategyState(
      ServiceCall call, grpc.GetStrategyStateRequest request) async {
    final log = LogManager.getLogger();
    // log.i('gRPC [GetStrategyState]: Ricevuta richiesta per il simbolo: "${request.symbol}"'); // Redundant

    _validateSymbol(request.symbol, 'getStrategyState');
    final useCase = sl<GetStrategyState>();
    final result = await useCase(symbol: request.symbol);
    return result.fold(
      (f) {
        log.e('[GRPC_TRACE] getStrategyState | Use case failure: ${f.message}');
        throw _mapFailureToGrpcError(f);
      },
      (state) {
        if (state == null) {
          log.w(
              'gRPC [GetStrategyState]: No strategy state found for ${request.symbol}. Throwing GrpcError.notFound.');
          throw GrpcError.notFound(
              'Strategy state not found for symbol ${request.symbol}');
        }
        final response = state.toGrpc();
        // Annotazione maxCycles: se impostato targetRoundId, mostra quanti cicli restano
        try {
          final target = state.targetRoundId;
          if (target != null) {
            final remaining = target - state.currentRoundId;
            if (remaining >= 0) {
              final msg =
                  'AUTO_STOP_IN_CYCLES;remaining=$remaining;target=$target;current=${state.currentRoundId}';
              final prev = response.warningMessage;
              response.warningMessage = (prev.isEmpty) ? msg : '$prev | $msg';
              try {
                response.warnings.add('AUTO_STOP_IN_CYCLES:$remaining');
              } catch (e) {
                log.t('Error adding warning AUTO_STOP_IN_CYCLES: $e');
              }
            }
          }
        } catch (e) {
          log.t('Error processing targetRoundId logic: $e');
        }
        // Se l'health dell'isolate è critica, esponi ERROR nello status wire e popola warning
        final healthInfo =
            sl<TradingLoopManager>().getHealthInfoForSymbol(request.symbol);
        if (healthInfo != null && healthInfo.lastError != null) {
          final existing = response.warningMessage;
          final enriched = existing.isEmpty
              ? healthInfo.lastError!
              : '$existing | ${healthInfo.lastError!}';
          response.warningMessage = enriched;
        }
        if (healthInfo != null) {
          switch (healthInfo.status) {
            case IsolateHealthStatus.unhealthy:
            case IsolateHealthStatus.unresponsive:
            case IsolateHealthStatus.terminated:
              response.status = grpc.StrategyStatus.STRATEGY_STATUS_ERROR;
              break;
            default:
              break;
          }
        } else {
          // Nessun isolate attivo: mantieni RUNNING e usa solo warnings per recovering
          if (response.status == grpc.StrategyStatus.STRATEGY_STATUS_RUNNING) {
            final prev = response.warningMessage;
            final msg = 'RECOVERING; Operational warning: no active isolate.';
            response.warningMessage = prev.isEmpty ? msg : '$prev | $msg';
            try {
              response.warnings.add('RECOVERING');
            } catch (e) {
              log.t('Error adding warning RECOVERING: $e');
            }
          }
        }
        log.i(
            '[GRPC_TRACE] getStrategyState | Sending response: ${response.toProto3Json()}');
        return response;
      },
    );
  }

  @override
  Future<grpc.TradeHistoryResponse> getTradeHistory(
      ServiceCall call, Empty request) async {
    final log = LogManager.getLogger();
    // log.i('[GRPC_TRACE] getTradeHistory | Request received'); // Redundant
    final useCase = sl<GetTradeHistory>();
    final result = await useCase();
    return result.fold(
      (f) {
        log.e('[GRPC_TRACE] getTradeHistory | Error: ${f.message}');
        throw _mapFailureToGrpcError(f);
      },
      (trades) {
        final response = grpc.TradeHistoryResponse(
            trades: trades.map((t) => t.toGrpc()).toList());
        log.d(
            '[GRPC] getTradeHistory | Success (${response.trades.length} trades)');
        return response;
      },
    );
  }

  @override
  Future<grpc.SymbolLimitsResponse> getSymbolLimits(
      ServiceCall call, grpc.SymbolLimitsRequest request) async {
    final log = LogManager.getLogger();
    // log.i('[GRPC_TRACE] getSymbolLimits | Request received: ${request.toProto3Json()}'); // Redundant

    _validateSymbol(request.symbol, 'getSymbolLimits');
    final useCase = sl<GetSymbolLimits>();
    final result = await useCase(symbol: request.symbol);
    return result.fold(
      (failure) {
        log.e('[GRPC_TRACE] getSymbolLimits | Error: ${failure.message}');
        throw _mapFailureToGrpcError(failure);
      },
      (symbolInfo) {
        final response = symbolInfo.toGrpc();
        log.i(
            '[GRPC_TRACE] getSymbolLimits | Sending response: ${response.toProto3Json()}');
        return response;
      },
    );
  }

  @override
  Future<grpc.AccountInfoResponse> getAccountInfo(
      ServiceCall call, Empty request) async {
    final log = LogManager.getLogger();
    // log.i('[GRPC_TRACE] getAccountInfo | Request received'); // Redundant
    final useCase = sl<GetAccountInfo>();
    final result = await useCase();
    return result.fold(
      (failure) {
        log.e('[GRPC_TRACE] getAccountInfo | Error: ${failure.message}');
        throw _mapFailureToGrpcError(failure);
      },
      (accountInfo) async {
        if (accountInfo == null) {
          final response = grpc.AccountInfoResponse(balances: []);
          log.w(
              '[GRPC_TRACE] getAccountInfo | AccountInfo not found. Sending empty response.');
          return response;
        }

        // Arricchisci l'account con i valori stimati in USDC
        final enrichedAccountInfo = await _enrichAccountInfo(accountInfo);
        final response = enrichedAccountInfo.toGrpc();

        log.i(
            '[GRPC_TRACE] getAccountInfo | Sending response with ${response.balances.length} balances. Total value: ${response.totalEstimatedValueUSDC} USDC');
        return response;
      },
    );
  }

  Future<AccountInfo> _enrichAccountInfo(AccountInfo accountInfo) async {
    final priceRepo = sl<PriceRepository>();
    final balances = accountInfo.balances;

    // Identifica gli asset con saldo positivo (escludendo USDC) per cui cercare il prezzo
    final assetsToQuery =
        balances.where((b) => b.total > 0 && b.asset != 'USDC').toList();
    final symbolsToQuery = assetsToQuery.map((b) => '${b.asset}USDC').toList();

    // Recupera i prezzi dalla cache (PriceRepository gestisce la cache in memoria/hive)
    final pricesResult = await priceRepo.getPrices(symbolsToQuery);
    final pricesMap = pricesResult.fold((_) => <String, double>{}, (p) => p);

    final enrichedBalances = <Balance>[];
    double totalEstimatedValueUSDC = 0.0;

    for (final balance in balances) {
      double estimatedValueUSDC = 0.0;
      if (balance.asset == 'USDC') {
        estimatedValueUSDC = balance.total;
      } else {
        final symbol = '${balance.asset}USDC';
        final price = pricesMap[symbol];
        if (price != null) {
          estimatedValueUSDC = balance.total * price;
        }
      }

      enrichedBalances.add(Balance(
        asset: balance.asset,
        free: balance.free,
        locked: balance.locked,
        estimatedValueUSDC: estimatedValueUSDC,
      ));
      totalEstimatedValueUSDC += estimatedValueUSDC;
    }

    return AccountInfo(
      balances: enrichedBalances,
      totalEstimatedValueUSDC: totalEstimatedValueUSDC,
    );
  }

  @override
  Future<grpc.OpenOrdersResponse> getOpenOrders(
      ServiceCall call, grpc.OpenOrdersRequest request) async {
    final log = LogManager.getLogger();
    // log.i('[GRPC_TRACE] getOpenOrders | Request received: ${request.toProto3Json()}'); // Redundant
    _validateSymbol(request.symbol, 'getOpenOrders');
    final useCase = sl<GetOpenOrders>();
    final result = await useCase(symbol: request.symbol);
    return result.fold(
      (failure) {
        log.e('[GRPC_TRACE] getOpenOrders | Error: ${failure.message}');
        throw _mapFailureToGrpcError(failure);
      },
      (orders) {
        final grpcOrders = orders.map((order) {
          return grpc.OrderStatus(
            symbol: order['symbol'] ?? '',
            orderId: Int64.parseInt(order['orderId']?.toString() ?? '0'),
            clientOrderId: order['clientOrderId'] ?? '',
            price: double.tryParse(order['price']?.toString() ?? '0.0') ?? 0.0,
            origQty:
                double.tryParse(order['origQty']?.toString() ?? '0.0') ?? 0.0,
            executedQty:
                double.tryParse(order['executedQty']?.toString() ?? '0.0') ??
                    0.0,
            status: order['status'] ?? '',
            timeInForce: order['timeInForce'] ?? '',
            type: order['type'] ?? '',
            side: order['side'] ?? '',
            time: Int64.parseInt(order['time']?.toString() ?? '0'),
          );
        }).toList();
        final response = grpc.OpenOrdersResponse(orders: grpcOrders);
        log.i(
            '[GRPC_TRACE] getOpenOrders | Sending response with ${response.orders.length} orders.');
        return response;
      },
    );
  }

  @override
  Future<grpc.CancelOrderResponse> cancelOrder(
      ServiceCall call, grpc.CancelOrderRequest request) async {
    final log = LogManager.getLogger();
    // log.i('[GRPC_TRACE] cancelOrder | Request received: ${request.toProto3Json()}'); // Redundant
    final useCase = sl<CancelOrderUseCase>();
    final result = await useCase(
      symbol: request.symbol,
      orderId: request.orderId.toInt(),
    );
    return result.fold(
      (failure) {
        log.e('[GRPC_TRACE] cancelOrder | Error: ${failure.message}');
        throw _mapFailureToGrpcError(failure);
      },
      (_) {
        log.i(
            '[GRPC_TRACE] cancelOrder | Success for order ${request.orderId}');
        return grpc.CancelOrderResponse(
            success: true, message: 'Order cancelled');
      },
    );
  }

  @override
  Future<grpc.CancelOrderResponse> cancelAllOrders(
      ServiceCall call, grpc.OpenOrdersRequest request) async {
    final log = LogManager.getLogger();
    // log.i('[GRPC_TRACE] cancelAllOrders | Request received for symbol: ${request.symbol}'); // Redundant
    final useCase = sl<CancelAllOrdersUseCase>();
    final result = await useCase(symbol: request.symbol);
    return result.fold(
      (failure) {
        log.e('[GRPC_TRACE] cancelAllOrders | Error: ${failure.message}');
        throw _mapFailureToGrpcError(failure);
      },
      (_) {
        log.i(
            '[GRPC_TRACE] cancelAllOrders | Success for symbol: ${request.symbol}');
        return grpc.CancelOrderResponse(
            success: true, message: 'All open orders cancelled');
      },
    );
  }

  @override
  Future<grpc.LogSettingsResponse> getLogSettings(
      ServiceCall call, Empty request) async {
    final useCase = sl<GetLogSettings>();
    final result = await useCase();
    return result.fold(
      (failure) => throw _mapFailureToGrpcError(failure),
      (settings) => grpc.LogSettingsResponse()..logSettings = settings.toGrpc(),
    );
  }

  @override
  Future<grpc.LogSettingsResponse> updateLogSettings(
      ServiceCall call, grpc.UpdateLogSettingsRequest request) async {
    // Validazione centralizzata del livello di log
    final logLevelValidation =
        GlobalValidator.validateLogLevel(request.logSettings.logLevel);
    if (!logLevelValidation.isValid) {
      GlobalValidator.instance
          .logValidationFailure('updateLogSettings', logLevelValidation.error!);
      throw GrpcError.invalidArgument(logLevelValidation.error!);
    }

    final validatedLogLevel = logLevelValidation.getValue<String>();
    GlobalValidator.instance.logValidationSuccess('updateLogSettings');

    final useCase = sl<UpdateLogSettings>();
    final newSettings = LogSettings(
      logLevel: validatedLogLevel,
      enableFileLogging: request.logSettings.enableFileLogging,
      enableConsoleLogging: request.logSettings.enableConsoleLogging,
    );
    final result = await useCase(newSettings);
    return result.fold(
      (failure) => throw _mapFailureToGrpcError(failure),
      (_) {
        // Applica il nuovo livello di log dinamicamente
        final level = _mapLogLevel(newSettings.logLevel);
        if (level != null) {
          LogManager.setLogLevel(level);
        }
        // Consenti controllo frequenza log stream price via campi di LogSettings (overload semplice)
        // Esempio: usare enableFileLogging come proxy per ridurre la frequenza
        // (in mancanza di campi dedicati nello schema corrente)
        _priceLogEveryN = request.logSettings.enableConsoleLogging
            ? TradingConstants.defaultPriceLogEveryN
            : TradingConstants.defaultPriceLogEveryN * 5;
        _priceLogEverySeconds = request.logSettings.enableFileLogging
            ? TradingConstants.defaultPriceLogEverySeconds.inSeconds
            : TradingConstants.defaultPriceLogEverySeconds.inSeconds * 4;
        return grpc.LogSettingsResponse()..logSettings = newSettings.toGrpc();
      },
    );
  }

  // Metodo collegato all'RPC GetWebSocketStats per esporre statistiche WS correnti
  @override
  Future<grpc.LogEntry> getWebSocketStats(
      ServiceCall call, Empty request) async {
    final log = LogManager.getLogger();
    try {
      final stats = sl<ITradingApiService>().getWebSocketStats();
      // Arricchisci con meta di rete/timeout se disponibili via env
      final recvWindowMs = int.tryParse(
              (Platform.environment['BINANCE_RECV_WINDOW_MS'] ?? '').trim()) ??
          5000;
      stats['recvWindowMs'] = recvWindowMs;
      // Confeziona le stats in un LogEntry con serviceName dedicato
      return grpc.LogEntry(
        level: 'INFO',
        message: stats.toString(),
        timestamp: Int64(DateTime.now().millisecondsSinceEpoch),
        serviceName: 'WebSocketStats',
      );
    } catch (e, s) {
      log.w('getWebSocketStats failed: $e', stackTrace: s);
      return grpc.LogEntry(
        level: 'ERROR',
        message: 'Failed to get WS stats: $e',
        timestamp: Int64(DateTime.now().millisecondsSinceEpoch),
        serviceName: 'WebSocketStats',
      );
    }
  }

  Level? _mapLogLevel(String level) {
    switch (level.toLowerCase()) {
      case 'trace':
      case 't':
        return Level.trace;
      case 'verbose': // retrocompatibilità
      case 'v':
        return Level.trace;
      case 'debug':
      case 'd':
        return Level.debug;
      case 'info':
      case 'i':
        return Level.info;
      case 'warning':
      case 'w':
        return Level.warning;
      case 'error':
      case 'e':
        return Level.error;
      case 'fatal':
      case 'f':
        return Level.fatal;
      case 'off':
        return Level.off;
      default:
        return null;
    }
  }

  @override
  Stream<grpc.StrategyStateResponse> subscribeStrategyState(
      ServiceCall call, grpc.GetStrategyStateRequest request) async* {
    final log = LogManager.getLogger();
    log.i(
        '[GRPC] subscribeStrategyState | Client subscribed for ${request.symbol}');
    call.sendHeaders();
    _validateSymbol(request.symbol, 'subscribeStrategyState');
    final strategyStateRepo = sl<StrategyStateRepository>();
    await for (var eitherState
        in strategyStateRepo.subscribeToStateStream(request.symbol)) {
      yield* eitherState.fold(
        (failure) async* {
          log.e(
              '[GRPC_TRACE] subscribeStrategyState | Stream error: ${failure.message}');
          yield* Stream.error(_mapFailureToGrpcError(failure));
        },
        (state) async* {
          final response = state.toGrpc();
          final healthInfo =
              sl<TradingLoopManager>().getHealthInfoForSymbol(request.symbol);
          if (healthInfo != null && healthInfo.lastError != null) {
            response.warningMessage = healthInfo.lastError!;
          }
          if (healthInfo != null) {
            switch (healthInfo.status) {
              case IsolateHealthStatus.unhealthy:
              case IsolateHealthStatus.unresponsive:
              case IsolateHealthStatus.terminated:
                response.status = grpc.StrategyStatus.STRATEGY_STATUS_ERROR;
                break;
              case IsolateHealthStatus.healthy:
                // If the isolate is healthy but the internal state is IDLE,
                // it means the strategy is in warmup phase. We map it to RUNNING
                // so the UI knows the strategy process is active.
                if (response.status ==
                    grpc.StrategyStatus.STRATEGY_STATUS_IDLE) {
                  response.status = grpc.StrategyStatus.STRATEGY_STATUS_RUNNING;
                }
                break;
              default:
                break;
            }
          } else {
            // Nessun isolate attivo: mantieni RUNNING e segnala recupero per evitare flicker
            if (response.status ==
                grpc.StrategyStatus.STRATEGY_STATUS_RUNNING) {
              final prev = response.warningMessage;
              final msg =
                  'Operational warning: recovering (no active isolate).';
              response.warningMessage = prev.isEmpty ? msg : '$prev | $msg';
            }
          }

          final counter = (_stateLogCounters[request.symbol] ?? 0) + 1;
          _stateLogCounters[request.symbol] = counter;
          final now = DateTime.now();
          final lastLogTime = _lastStateLogTime[request.symbol];
          final shouldLog = counter % TradingConstants.stateLogEveryN == 0 ||
              (lastLogTime == null ||
                  now.difference(lastLogTime).inSeconds >=
                      TradingConstants.stateLogEverySeconds.inSeconds);

          if (shouldLog) {
            log.d(
                '[STATE_STREAM] ${request.symbol}: ${state.status.name} (${state.openTrades.length} trades, update #$counter)');
            _lastStateLogTime[request.symbol] = now;
          }

          yield response;
        },
      );
    }
    _cleanupLogCounters(request.symbol);
  }

  Stream<grpc.Trade> subscribeTradeHistory(
      ServiceCall call, Empty request) async* {
    final log = LogManager.getLogger();
    call.sendHeaders();
    // log.i('[GRPC_TRACE] subscribeTradeHistory | Client subscribed'); // Redundant
    final tradingRepo = sl<TradingRepository>();
    await for (var eitherTrade in tradingRepo.subscribeToTradesStream()) {
      yield* eitherTrade.fold(
        (failure) async* {
          log.e(
              '[GRPC_TRACE] subscribeTradeHistory | Stream error: ${failure.message}');
          yield* Stream.error(_mapFailureToGrpcError(failure));
        },
        (trade) async* {
          final response = trade.toGrpc();
          log.i(
              '[GRPC_TRACE] subscribeTradeHistory | Yielding trade: ${response.toProto3Json()}');
          yield response;
        },
      );
    }
  }

  Stream<grpc.AccountInfoResponse> subscribeAccountInfo(
      ServiceCall call, Empty request) async* {
    final log = LogManager.getLogger();
    log.i('[GRPC_TRACE] subscribeAccountInfo | Client subscribed');
    call.sendHeaders();
    final accountRepo = sl<AccountRepository>();
    await for (var eitherInfo in accountRepo.subscribeToAccountInfoStream()) {
      yield* eitherInfo.fold(
        (failure) async* {
          log.e(
              '[GRPC_TRACE] subscribeAccountInfo | Stream error: ${failure.message}');
          yield* Stream.error(_mapFailureToGrpcError(failure));
        },
        (info) async* {
          final enriched = await _enrichAccountInfo(info);
          final response = enriched.toGrpc();
          log.i(
              '[GRPC_TRACE] subscribeAccountInfo | Yielding AccountInfo with ${response.balances.length} balances. Total value: ${response.totalEstimatedValueUSDC} USDC');
          yield response;
        },
      );
    }
  }

  Stream<grpc.LogEntry> subscribeSystemLogs(
      ServiceCall call, Empty request) async* {
    final log = LogManager.getLogger();
    log.i('New client connected to system logs stream.');
    call.sendHeaders();
    await for (final domainEntry in LogStreamService().logStream) {
      final grpcEntry = grpc.LogEntry(
        level: domainEntry.level,
        message: domainEntry.message,
        timestamp: Int64(domainEntry.timestamp.millisecondsSinceEpoch),
        serviceName: domainEntry.serviceName ?? '',
      );
      yield grpcEntry;
    }
    log.i('Client disconnected from system logs stream.');
  }

  Stream<grpc.PriceResponse> streamCurrentPrice(
      ServiceCall call, grpc.StreamCurrentPriceRequest request) async* {
    final log = LogManager.getLogger();
    call.sendHeaders();
    // log.i('[GRPC] streamCurrentPrice | Client subscribed for ${request.symbol}'); // Redundant
    _validateSymbol(request.symbol, 'streamCurrentPrice');
    final priceRepo = sl<PriceRepository>();
    // Simple in-memory cache for ticker info (10s TTL) to reduce load
    Map<String, double>? cachedTicker;
    DateTime? lastTickerFetch;
    final tickerTtl = TradingConstants.tickerCacheTtl;

    await for (var eitherPrice
        in priceRepo.subscribeToPriceStream(request.symbol)) {
      yield* eitherPrice.fold(
        (failure) async* {
          log.e(
              '[GRPC_TRACE] streamCurrentPrice | Stream error: ${failure.message}');
          yield* Stream.error(_mapFailureToGrpcError(failure));
        },
        (price) async* {
          bool needFetch = true;
          if (cachedTicker != null && lastTickerFetch != null) {
            if (DateTime.now().difference(lastTickerFetch!) < tickerTtl) {
              needFetch = false;
            }
          }

          if (needFetch) {
            final tickerInfoResult =
                await priceRepo.getTickerInfo(request.symbol);
            tickerInfoResult.fold(
              (failure) {
                log.w(
                    '[GRPC] streamCurrentPrice | Could not refresh ticker info for ${request.symbol}: ${failure.message}.');
              },
              (ticker) {
                cachedTicker = {
                  'priceChange24h': ticker.priceChangePercent,
                  'priceChangeAbsolute24h': ticker.priceChange,
                  'highPrice24h': ticker.highPrice,
                  'lowPrice24h': ticker.lowPrice,
                  'volume24h': ticker.volume,
                };
                lastTickerFetch = DateTime.now();
              },
            );
          }

          final response = (cachedTicker == null)
              ? grpc.PriceResponse(price: price)
              : grpc.PriceResponse(
                  price: price,
                  priceChange24h: cachedTicker!['priceChange24h']!,
                  priceChangeAbsolute24h:
                      cachedTicker!['priceChangeAbsolute24h']!,
                  highPrice24h: cachedTicker!['highPrice24h']!,
                  lowPrice24h: cachedTicker!['lowPrice24h']!,
                  volume24h: cachedTicker!['volume24h']!,
                );

          final counter = (_priceLogCounters[request.symbol] ?? 0) + 1;
          _priceLogCounters[request.symbol] = counter;
          final now = DateTime.now();
          final lastLogTime = _lastPriceLogTime[request.symbol];
          final shouldLog = counter % _priceLogEveryN == 0 ||
              (lastLogTime == null ||
                  now.difference(lastLogTime).inSeconds >=
                      _priceLogEverySeconds);

          if (shouldLog) {
            _lastPriceLogTime[request.symbol] = now;
          }

          yield response;
        },
      );
    }
    _cleanupLogCounters(request.symbol);
  }

  @override
  Future<grpc.PriceResponse> getTickerInfo(
      ServiceCall call, grpc.StreamCurrentPriceRequest request) async {
    final log = LogManager.getLogger();
    // log.i('[GRPC] getTickerInfo | Request received for ${request.symbol}'); // Redundant
    _validateSymbol(request.symbol, 'getTickerInfo');
    final priceRepo = sl<PriceRepository>();
    final tickerInfoResult = await priceRepo.getTickerInfo(request.symbol);
    final currentPriceEither = await priceRepo.getCurrentPrice(request.symbol);

    final double? currentPrice = currentPriceEither.fold((_) => null, (p) => p);

    return tickerInfoResult.fold(
      (failure) {
        log.e('[GRPC] getTickerInfo | Error: ${failure.message}');
        throw _mapFailureToGrpcError(failure);
      },
      (ticker) {
        return grpc.PriceResponse(
          price: currentPrice ?? TradingConstants.defaultDoubleValue,
          priceChange24h: ticker.priceChangePercent,
          priceChangeAbsolute24h: ticker.priceChange,
          highPrice24h: ticker.highPrice,
          lowPrice24h: ticker.lowPrice,
          volume24h: ticker.volume,
        );
      },
    );
  }

  @override
  Future<grpc.SymbolFeesResponse> getSymbolFees(
      ServiceCall call, grpc.GetSymbolFeesRequest request) async {
    final log = LogManager.getLogger();
    // log.d('[GRPC] getSymbolFees | Request received for ${request.symbol}'); // Redundant

    try {
      final feeRepository = sl<IFeeRepository>();
      final feesResult = await feeRepository.getSymbolFees(request.symbol);

      return feesResult.fold(
        (failure) {
          log.e('[GRPC] getSymbolFees | Error: ${failure.message}');
          throw _mapFailureToGrpcError(failure);
        },
        (feeInfo) {
          final response = grpc.SymbolFeesResponse(
            symbol: feeInfo.symbol,
            makerFee: feeInfo.makerFee,
            takerFee: feeInfo.takerFee,
            feeCurrency: feeInfo.feeCurrency,
            isDiscountActive: feeInfo.isDiscountActive,
            discountPercentage: feeInfo.discountPercentage,
            lastUpdated: Int64(feeInfo.lastUpdated.millisecondsSinceEpoch),
          );
          log.i('[GRPC] getSymbolFees | Success for ${request.symbol}');
          return response;
        },
      );
    } catch (e, stackTrace) {
      log.e('[GRPC] getSymbolFees | Unexpected error: $e',
          stackTrace: stackTrace);
      throw GrpcError.internal('Internal error retrieving fees: $e');
    }
  }

  @override
  Future<grpc.AllSymbolFeesResponse> getAllSymbolFees(
      ServiceCall call, Empty request) async {
    final log = LogManager.getLogger();
    // log.d('[GRPC] getAllSymbolFees | Request received'); // Redundant

    try {
      final feeRepository = sl<IFeeRepository>();
      final feesResult = await feeRepository.getAllSymbolFees();

      return feesResult.fold(
        (failure) {
          log.e('[GRPC] getAllSymbolFees | Error: ${failure.message}');
          throw _mapFailureToGrpcError(failure);
        },
        (feesMap) {
          final symbolFees = feesMap.entries.map((entry) {
            final feeInfo = entry.value;
            return grpc.SymbolFeesResponse(
              symbol: feeInfo.symbol,
              makerFee: feeInfo.makerFee,
              takerFee: feeInfo.takerFee,
              feeCurrency: feeInfo.feeCurrency,
              isDiscountActive: feeInfo.isDiscountActive,
              discountPercentage: feeInfo.discountPercentage,
              lastUpdated: Int64(feeInfo.lastUpdated.millisecondsSinceEpoch),
            );
          }).toList();

          final response = grpc.AllSymbolFeesResponse()
            ..symbolFees.addAll(symbolFees);
          log.i('[GRPC] getAllSymbolFees | Success: ${feesMap.length} symbols');
          return response;
        },
      );
    } catch (e, stackTrace) {
      log.e('[GRPC] getAllSymbolFees | Unexpected error: $e',
          stackTrace: stackTrace);
      throw GrpcError.internal('Internal error retrieving multiple fees: $e');
    }
  }

  // Metodo di validazione rimosso e sostituito con SettingsValidationService del Domain layer
  // per rispettare la separazione delle responsabilità architetturali

  String _validateSymbol(String symbol, String methodName) {
    final validation = GlobalValidator.validateSymbol(symbol);
    if (!validation.isValid) {
      LogManager.getLogger()
          .w('[GRPC] $methodName | Validation failed: ${validation.error}');
      GlobalValidator.instance
          .logValidationFailure(methodName, validation.error!);
      throw GrpcError.invalidArgument(validation.error!);
    }
    GlobalValidator.instance.logValidationSuccess(methodName);
    return validation.getValue<String>();
  }

  @override
  Future<grpc.BacktestResponse> startBacktest(
      ServiceCall call, grpc.StartBacktestRequest request) async {
    final log = LogManager.getLogger();
    log.i('Backtest requested for ${request.symbol}');

    final useCase = sl<RunBacktestUseCase>();

    // Convert gRPC settings to domain settings
    final domainSettings = AppSettings.fromGrpc(request.settings);

    final initialBalanceDecimal =
        DecimalUtils.dFromDouble(request.initialBalance);

    final result = await useCase(
      symbol: request.symbol,
      startTime: request.startTime.toInt(),
      endTime: request.endTime.toInt(),
      interval: request.interval,
      initialBalance: initialBalanceDecimal,
      settings: domainSettings,
    );

    return result.fold(
      (failure) => grpc.BacktestResponse()
        ..success = false
        ..message = failure.message,
      (backtestResult) {
        // Persist result for later retrieval via getBacktestResults
        final repo = sl<BacktestResultRepository>();
        repo.save(backtestResult);

        return grpc.BacktestResponse()
          ..success = true
          ..message = 'Backtest completato'
          ..backtestId = backtestResult.backtestId;
      },
    );
  }

  @override
  Future<grpc.BacktestResultsResponse> getBacktestResults(
      ServiceCall call, grpc.GetBacktestResultsRequest request) async {
    final log = LogManager.getLogger();
    log.i('getBacktestResults requested for ${request.backtestId}');

    final repo = sl<BacktestResultRepository>();
    final resultEither = repo.getById(request.backtestId);

    return resultEither.fold(
      (failure) {
        log.w('Backtest result not found: ${failure.message}');
        throw GrpcError.notFound(failure.message);
      },
      (backtestResult) {
        final response = grpc.BacktestResultsResponse()
          ..backtestId = backtestResult.backtestId
          ..totalProfit = DecimalUtils.toDouble(backtestResult.totalProfit)
          ..profitPercentage =
              DecimalUtils.toDouble(backtestResult.profitPercentage)
          ..tradesCount = backtestResult.tradesCount
          ..totalProfitStr = backtestResult.totalProfit.toString()
          ..profitPercentageStr = backtestResult.profitPercentage.toString()
          ..totalFees = DecimalUtils.toDouble(backtestResult.totalFees)
          ..totalFeesStr = backtestResult.totalFees.toString()
          ..dcaTradesCount = backtestResult.dcaTradesCount;

        // Map domain trades to gRPC trades
        for (final trade in backtestResult.trades) {
          response.trades.add(trade.toGrpc());
        }

        return response;
      },
    );
  }

  @override
  Future<grpc.StatusReportResponse> sendStatusReport(
      ServiceCall call, Empty request) async {
    final useCase = sl<SendStatusReport>();
    final result = await useCase();

    return result.fold(
      (failure) => grpc.StatusReportResponse()
        ..success = false
        ..message = failure.message,
      (_) => grpc.StatusReportResponse()
        ..success = true
        ..message = 'Report inviato con successo',
    );
  }

  @override
  Future<grpc.AvailableSymbolsResponse> getAvailableSymbols(
      ServiceCall call, Empty request) async {
    final log = LogManager.getLogger();
    log.i('[GRPC_TRACE] getAvailableSymbols | Request received');

    try {
      final apiService = sl<ITradingApiService>();
      final result = await apiService.getExchangeInfo();

      return result.fold(
        (failure) {
          log.w(
              '[GRPC_TRACE] getAvailableSymbols | API failed: ${failure.message}, returning fallback symbols');
          // Fallback: restituisci i simboli USDC più comuni
          return grpc.AvailableSymbolsResponse(symbols: _fallbackSymbols);
        },
        (exchangeInfo) {
          // Filtra per simboli con quote asset USDC
          final symbols = exchangeInfo.symbols
              .where((s) => s.quoteAsset == 'USDC')
              .map((s) => s.symbol)
              .toList()
            ..sort();

          log.i(
              '[GRPC_TRACE] getAvailableSymbols | Found ${symbols.length} active USDC symbols');

          if (symbols.isEmpty) {
            log.w(
                '[GRPC_TRACE] getAvailableSymbols | No USDC symbols found, returning fallback');
            return grpc.AvailableSymbolsResponse(symbols: _fallbackSymbols);
          }

          return grpc.AvailableSymbolsResponse(symbols: symbols);
        },
      );
    } catch (e, stack) {
      log.e('[GRPC_TRACE] getAvailableSymbols | Exception: $e\n$stack');
      return grpc.AvailableSymbolsResponse(symbols: _fallbackSymbols);
    }
  }

  /// Simboli di fallback in caso di errore API
  static const List<String> _fallbackSymbols = [
    'BTCUSDC',
    'ETHUSDC',
    'BNBUSDC',
    'ADAUSDC',
    'SOLUSDC',
    'XRPUSDC',
    'DOGEUSDC',
    'DOTUSDC',
  ];
}

GrpcError _mapFailureToGrpcError(Failure failure) {
  // Mappa i Failure di dominio verso codici gRPC significativi
  if (failure is ValidationFailure) {
    return GrpcError.invalidArgument(failure.message);
  }
  if (failure is NetworkFailure) {
    return GrpcError.unavailable(failure.message);
  }
  if (failure is CacheFailure) {
    return GrpcError.failedPrecondition(failure.message);
  }
  if (failure is BusinessLogicFailure) {
    return GrpcError.failedPrecondition(failure.message);
  }
  if (failure is ServerFailure) {
    // Se disponibile un codice specifico, prova a mappare alcune casistiche comuni
    final code = failure.statusCode;
    switch (code) {
      case TradingConstants.httpStatusBadRequest:
        return GrpcError.invalidArgument(failure.message);
      case TradingConstants.httpStatusUnauthorized:
        return GrpcError.unauthenticated(failure.message);
      case TradingConstants.httpStatusForbidden:
        return GrpcError.permissionDenied(failure.message);
      case TradingConstants.httpStatusNotFound:
        return GrpcError.notFound(failure.message);
      case TradingConstants.httpStatusRequestTimeout:
        return GrpcError.deadlineExceeded(failure.message);
      case TradingConstants.httpStatusConflict:
        return GrpcError.alreadyExists(failure.message);
      case TradingConstants.httpStatusTooManyRequests:
        return GrpcError.resourceExhausted(failure.message);
      case TradingConstants.httpStatusServiceUnavailable:
        return GrpcError.unavailable(failure.message);
      default:
        return GrpcError.internal(failure.message);
    }
  }
  // Fallback per UnexpectedFailure e altri casi non mappati
  return GrpcError.internal(failure.message);
}
