import 'dart:async';
import 'dart:isolate';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:neotradingbotback1777/core/utils/circuit_breaker.dart';
import 'package:neotradingbotback1777/core/config/env_config.dart';

import 'package:neotradingbotback1777/domain/entities/app_settings.dart';
import 'package:neotradingbotback1777/domain/entities/app_strategy_state.dart';
import 'package:neotradingbotback1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/entities/account_info.dart';
import 'package:neotradingbotback1777/domain/entities/balance.dart';
import 'package:neotradingbotback1777/domain/repositories/account_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/i_symbol_info_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/price_repository.dart';
import 'package:neotradingbotback1777/domain/services/trading_signal_analyzer.dart';
import 'package:neotradingbotback1777/application/services/trading_loop/atomic_action_processor.dart';
import 'package:neotradingbotback1777/application/managers/atomic_state_manager.dart';
import 'package:neotradingbotback1777/domain/services/trade_evaluator_service.dart';
import 'package:neotradingbotback1777/domain/repositories/i_fee_repository.dart';
import 'package:neotradingbotback1777/application/services/trading_loop/trading_loop_warmup_service.dart';
import 'package:neotradingbotback1777/application/services/trading_loop/trading_loop_communication_service.dart';
import 'package:neotradingbotback1777/application/services/trading_loop/trading_loop_pre_flight_check.dart';
import 'package:mutex/mutex.dart';
import 'package:neotradingbotback1777/domain/services/i_trading_api_service.dart';
import 'package:neotradingbotback1777/core/config/trading_constants.dart';

class StartTradingLoopAtomic {
  final PriceRepository _priceRepository;
  final AtomicStateManager _stateManager;
  final GetIt _sl;
  final _log = LogManager.getLogger();

  // Services
  final TradingLoopWarmupService _warmupService = TradingLoopWarmupService();
  final TradingLoopCommunicationService _communicationService =
      TradingLoopCommunicationService();
  final TradingSignalAnalyzer _analyzer;
  final AtomicActionProcessor _processor;
  late final TradingLoopPreFlightCheck _preFlightCheckService;

  // === SISTEMA DI MONITORING LATENZA ===
  DateTime? _lastTickTime;
  int _totalTicks = 0;
  Duration _totalLatency = Duration.zero;
  DateTime? _lastLatencyAlertTime;
  static const Duration _latencyAlertThrottle = Duration(seconds: 30);

  // === INTERNAL STATE ===
  StreamSubscription<Either<Failure, double>>? _priceSubscription;
  final Mutex _processingMutex = Mutex();
  late final CircuitBreaker _buyCircuitBreaker;
  late final CircuitBreaker _sellCircuitBreaker;

  // Execution Throttling State
  DateTime? _lastBuyTime;
  Duration _buyCooldown = Duration.zero;
  DateTime? _lastDcaTime;
  DateTime? _lastDustFailureTime;

  // === BALANCE TRACKING ===
  final AccountRepository _accountRepository;
  StreamSubscription<Either<Failure, AccountInfo>>? _accountSubscription;
  double? _cachedBalance;
  String? _quoteAsset;

  StartTradingLoopAtomic({
    required PriceRepository priceRepository,
    required TradeEvaluatorService tradeEvaluator,
    required AtomicStateManager stateManager,
    required AccountRepository accountRepository,
    required ISymbolInfoRepository symbolInfoRepository,
    required GetIt serviceLocator,
  })  : _priceRepository = priceRepository,
        _stateManager = stateManager,
        _accountRepository = accountRepository,
        _sl = serviceLocator,
        _analyzer = TradingSignalAnalyzer(tradeEvaluator),
        _processor = AtomicActionProcessor(
            stateManager, TradingLoopCommunicationService(), serviceLocator) {
    _preFlightCheckService = TradingLoopPreFlightCheck(
        accountRepository: accountRepository,
        symbolInfoRepository: symbolInfoRepository,
        priceRepository: priceRepository,
        apiService: _sl<ITradingApiService>());

    _buyCircuitBreaker = CircuitBreaker(
      name: 'BuyOrderAtomic',
      config: const CircuitBreakerConfig(
          failureThreshold: 3,
          timeout: Duration(minutes: 2),
          successThreshold: 2,
          monitoringWindow: Duration(minutes: 10),
          failureRateThreshold: 0.6),
    );
    _sellCircuitBreaker = CircuitBreaker(
      name: 'SellOrderAtomic',
      config: const CircuitBreakerConfig(
          failureThreshold: 3,
          timeout: Duration(minutes: 2),
          successThreshold: 2,
          monitoringWindow: Duration(minutes: 10),
          failureRateThreshold: 0.6),
    );
  }

  // Consente all'entrypoint di iniettare il SendPort principale dopo la creazione via DI
  void setMainSendPort(SendPort sendPort) {
    _communicationService.setMainSendPort(sendPort);
  }

  Future<bool> call({
    required String symbol,
    required AppSettings settings,
    required AppStrategyState initialState,
  }) async {
    // Forward tutti i log generati in questo isolate verso il main isolate
    _communicationService.startLogForwarding();
    await _priceSubscription?.cancel();
    // Parametrizza cooldown di acquisto da settings
    if (settings.buyCooldownSeconds.isFinite &&
        settings.buyCooldownSeconds > 0) {
      _buyCooldown =
          Duration(milliseconds: (settings.buyCooldownSeconds * 1000).round());
    }

    // SICUREZZA E2E: Se DRY_RUN=true, forziamo la modalità test indipendentemente dall'UI
    AppSettings effectiveSettings = settings;
    if (EnvConfig().getBool('DRY_RUN', false)) {
      _log.w(
          '⚠️ DRY_RUN attivo da ambiente: Forzatura isTestMode=true per $symbol. Ordini reali disabilitati.');
      effectiveSettings = settings.copyWith(isTestMode: true);
    }

    _log.i(
        'Avvio loop di trading atomico per simbolo: $symbol con stato iniziale: ${initialState.status} (TestMode: ${effectiveSettings.isTestMode})');

    // CRITICAL: Ensure the ApiService inside this isolate is set to the correct mode
    // before any network calls (pre-flight or price fetching).
    try {
      _sl
          .get<ITradingApiService>()
          .updateMode(isTestMode: effectiveSettings.isTestMode);
      _log.i(
          'ApiService mode synchronized: ${effectiveSettings.isTestMode ? "TESTNET" : "REAL"}');
    } catch (e) {
      _log.e('Failed to synchronize ApiService mode in isolate: $e');
      throw Exception('Sincronizzazione API Service fallita: $e');
    }

    // Inizializza le fee all'avvio se abilitato il trading con fee consapevoli
    if (effectiveSettings.enableFeeAwareTrading) {
      try {
        final feeRepository = _sl<IFeeRepository>();
        final feesResult = await feeRepository.getSymbolFees(symbol);
        feesResult.fold(
          (failure) => _log
              .w('Failed to initialize fees for $symbol: ${failure.message}'),
          (fees) => _log.i(
              'Fees initialized for $symbol: maker=${fees.makerFee}, taker=${fees.takerFee}'),
        );
      } catch (e) {
        _log.w('Error initializing fees for $symbol: $e');
      }
    }

    final preFlightCheckResult =
        await _preFlightCheckService.execute(symbol, effectiveSettings);
    if (preFlightCheckResult.isLeft()) {
      String failureMessage = 'Pre-flight check failed';
      preFlightCheckResult.fold((failure) {
        failureMessage = failure.message;
        _log.e('Controllo pre-avvio fallito per $symbol: $failureMessage');
        // Notifica immediata al main isolate per rollback stato persistente
        _communicationService.sendErrorSync(
            symbol, 'PRE_FLIGHT_FAILED: $failureMessage');
      }, (_) {});
      return false;
    }

    _warmupService.reset();

    // Primo prezzo con piccolo backoff se nullo
    double? initialPrice;
    const int maxInitialAttempts = 3;
    final Duration initialBackoff = TradingConstants.minBackoff;
    for (int i = 0; i < maxInitialAttempts; i++) {
      final initialPriceResult = await _priceRepository.getCurrentPrice(symbol);
      final fetched = initialPriceResult.fold((_) => null, (p) => p);
      if (fetched != null) {
        initialPrice = fetched;
        break;
      }
      if (i < maxInitialAttempts - 1) {
        await Future.delayed(initialBackoff * (i + 1));
      }
    }

    if (initialPrice != null) {
      await _processingMutex.protect(() async {
        // Se è impostato un limite cicli, inizializza targetRoundId allo start
        if (effectiveSettings.maxCycles > 0) {
          final stateEither = await _stateManager.getState(symbol);
          await stateEither.fold((_) async {}, (st) async {
            if (st.targetRoundId == null) {
              final seeded = st.copyWith(
                  targetRoundId:
                      st.currentRoundId + effectiveSettings.maxCycles);
              await _stateManager.forceUpdateState(seeded);
            }
          });
        }
        await _processPrice(symbol, initialPrice!, effectiveSettings);
      });
    } else {
      _log.w(
          'Prezzo iniziale per $symbol non disponibile dopo tentativi rapidi. Attendo stream.');
    }

    _priceSubscription = _priceRepository.subscribeToPriceStream(symbol).listen(
      (priceOrFailure) async {
        priceOrFailure.fold(
          (failure) =>
              _log.e('Errore nello stream dei prezzi: ${failure.message}'),
          (currentPrice) async {
            await _processingMutex.protect(() async {
              await _processPrice(symbol, currentPrice, effectiveSettings);
            });
          },
        );
      },
      onError: (error) =>
          _log.e('Errore critico nello stream dei prezzi: $error'),
      onDone: () => _log.w('Stream dei prezzi terminato per $symbol'),
    );

    _log.i('Loop di trading atomico avviato per il simbolo $symbol');

    // Inizializza tracciamento bilancio asincrono (non bloccante)
    _initBalanceTracking(symbol);

    return true;
  }

  void _initBalanceTracking(String symbol) {
    // Tenta di recuperare il bilancio iniziale se disponibile
    _accountRepository.getAccountInfo().then((res) {
      res.fold(
        (_) => null,
        (info) {
          if (info != null) {
            _quoteAsset ??= _inferQuoteAssetSync(symbol, info);
            if (_quoteAsset != null) {
              final bal = info.balances.firstWhere(
                (b) => b.asset == _quoteAsset,
                orElse: () =>
                    Balance(asset: _quoteAsset!, free: 0.0, locked: 0.0),
              );
              _cachedBalance = bal.free;
            }
          }
        },
      );
    });

    _accountSubscription =
        _accountRepository.subscribeToAccountInfoStream().listen(
      (res) {
        res.fold(
          (_) => null,
          (info) {
            _quoteAsset ??= _inferQuoteAssetSync(symbol, info);
            if (_quoteAsset != null) {
              final bal = info.balances.firstWhere(
                (b) => b.asset == _quoteAsset,
                orElse: () =>
                    Balance(asset: _quoteAsset!, free: 0.0, locked: 0.0),
              );
              _cachedBalance = bal.free;
            }
          },
        );
      },
      cancelOnError: false,
    );
  }

  String? _inferQuoteAssetSync(String symbol, AccountInfo accountInfo) {
    String? best;
    for (final b in accountInfo.balances) {
      final asset = b.asset;
      if (asset.isEmpty) continue;
      if (symbol.endsWith(asset)) {
        if (best == null || asset.length > best.length) {
          best = asset;
        }
      }
    }
    return best;
  }

  Future<void> _processPrice(
      String symbol, double currentPrice, AppSettings settings) async {
    try {
      _warmupService.onPriceUpdate(currentPrice);
      _recordTick();

      final stateResult = await _stateManager.getState(symbol);
      await stateResult.fold(
        (failure) async =>
            _log.e('Errore recupero stato per $symbol: ${failure.message}'),
        (currentState) async {
          // 1. Initial Buy Evaluation
          if (_analyzer.shouldBuy(
            currentPrice,
            currentState,
            settings,
            _isInBuyCooldown(),
            _warmupService.canTriggerInitialBuy(settings),
            availableBalance: _cachedBalance,
          )) {
            _lastBuyTime = DateTime.now();
            await _processor.processBuy(
                symbol, settings, currentPrice, _buyCircuitBreaker);
            // Forza rinfresco bilancio dopo un ordine
            _accountRepository.refreshAccountInfo().ignore();
            return;
          }

          // 2. Sell Evaluation
          if (await _analyzer.shouldSell(currentPrice, currentState, settings,
              _isInDustCooldown(settings))) {
            await _processor.processSell(
                symbol, settings, currentPrice, _sellCircuitBreaker);
            // Forza rinfresco bilancio dopo un ordine
            _accountRepository.refreshAccountInfo().ignore();
            return;
          }

          // 3. DCA Evaluation
          if (_analyzer.shouldDca(
            currentPrice,
            currentState,
            settings,
            _isInDcaCooldown(settings),
            availableBalance: _cachedBalance,
          )) {
            _lastDcaTime = DateTime.now();
            await _processor.processDca(
                symbol, settings, currentPrice, _buyCircuitBreaker);
            // Forza rinfresco bilancio dopo un ordine
            _accountRepository.refreshAccountInfo().ignore();
            return;
          }

          // 4. Idle State Transition
          if (currentState.status == StrategyState.IDLE &&
              _warmupService.canTriggerInitialBuy(settings)) {
            _log.d(
                'Warmup completato per $symbol, transizione a MONITORING_FOR_BUY');
            await _stateManager.executeAtomicOperation(
              symbol,
              (state) async => Right(
                  state.copyWith(status: StrategyState.MONITORING_FOR_BUY)),
            );
          }
        },
      );
    } catch (e, stackTrace) {
      _log.e('Errore durante elaborazione prezzo per $symbol: $e',
          stackTrace: stackTrace);
    }
  }

  bool _isInBuyCooldown() =>
      _lastBuyTime != null &&
      DateTime.now().difference(_lastBuyTime!) < _buyCooldown;
  bool _isInDcaCooldown(AppSettings settings) =>
      _lastDcaTime != null &&
      DateTime.now().difference(_lastDcaTime!) <
          (settings.dcaCooldownSeconds > 0
              ? Duration(seconds: settings.dcaCooldownSeconds.round())
              : const Duration(seconds: 3));
  bool _isInDustCooldown(AppSettings settings) =>
      _lastDustFailureTime != null &&
      DateTime.now().difference(_lastDustFailureTime!) <
          (settings.dustRetryCooldownSeconds > 0
              ? Duration(seconds: settings.dustRetryCooldownSeconds.round())
              : const Duration(seconds: 15));

  Future<void> stop() async {
    await _accountSubscription?.cancel();
    await _priceSubscription?.cancel();
    _accountSubscription = null;
    _priceSubscription = null;
    _log.i('Loop di trading atomico fermato.');
  }

  Map<String, dynamic> getCircuitBreakerStats() {
    return {
      'buyCircuitBreaker': _buyCircuitBreaker.getStats(),
      'sellCircuitBreaker': _sellCircuitBreaker.getStats(),
    };
  }

  void resetCircuitBreakers() {
    _buyCircuitBreaker.reset();
    _sellCircuitBreaker.reset();
    _log.i('Circuit breakers resetted manually');
  }

  void dispose() {
    _priceSubscription?.cancel();
    _buyCircuitBreaker.dispose();
    _sellCircuitBreaker.dispose();
    _log.i('StartTradingLoopAtomic disposed successfully');
  }

  /// Registra un tick e calcola la latenza per monitoring
  void _recordTick() {
    final now = DateTime.now();

    if (_lastTickTime != null) {
      final latency = now.difference(_lastTickTime!);
      _totalLatency += latency;
      _totalTicks++;

      // Log latenza elevata con throttling per evitare spam
      if (latency.inMilliseconds > TradingConstants.maxLatencyThresholdMs) {
        final alertCheckTime = DateTime.now();
        if (_lastLatencyAlertTime == null ||
            alertCheckTime.difference(_lastLatencyAlertTime!) >
                _latencyAlertThrottle) {
          _log.w(
              '[LATENCY_ALERT] Tick lento rilevato: ${latency.inMilliseconds}ms');
          _lastLatencyAlertTime = alertCheckTime;
        }
      }
    }

    _lastTickTime = now;
  }

  /// Restituisce statistiche sulla latenza del loop
  Map<String, dynamic> getLatencyStats() {
    if (_totalTicks == 0) {
      return {
        'totalTicks': 0,
        'averageLatency': 0,
        'totalLatency': 0,
      };
    }

    final avgLatency = _totalLatency.inMicroseconds / _totalTicks;

    return {
      'totalTicks': _totalTicks,
      'averageLatency':
          (avgLatency / 1000).toStringAsFixed(2), // in millisecondi
      'totalLatency': _totalLatency.inMilliseconds,
    };
  }
}
