import 'dart:io';

import 'package:grpc/grpc.dart';
import 'package:hive_ce/hive.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:neotradingbotback1777/core/logging/log_stream_service.dart'; // Importa LogStreamService
import 'package:neotradingbotback1777/injection.dart';
import 'package:neotradingbotback1777/presentation/grpc/health_service.dart';
import 'package:neotradingbotback1777/presentation/grpc/interceptors/logging_interceptor.dart';
import 'package:neotradingbotback1777/presentation/grpc/interceptors/api_key_interceptor.dart';
import 'package:neotradingbotback1777/presentation/grpc/trading_service_impl.dart';
import 'package:neotradingbotback1777/domain/services/i_trading_api_service.dart';
import 'package:neotradingbotback1777/infrastructure/network/binance/api_service.dart';
import 'package:neotradingbotback1777/domain/repositories/i_symbol_info_repository.dart';
import 'package:neotradingbotback1777/domain/repositories/strategy_state_repository.dart';
import 'package:neotradingbotback1777/application/use_cases/get_settings_use_case.dart';
import 'package:neotradingbotback1777/application/managers/trading_loop_manager.dart';
import 'package:neotradingbotback1777/domain/entities/strategy_state.dart';
import 'package:neotradingbotback1777/core/config/env_config.dart';

Future<void> main() async {
  final log = LogManager.getLogger();
  log.i('=================================================================');
  log.i('  Avvio del backend NeoTradingBot...                             ');
  log.i('  I log di esecuzione sono salvati in: neotradbot_execution.log  ');
  log.i('=================================================================');

  // Log security status immediately for operator visibility
  // Intentional early placement before initDependencies()
  logApiKeyAuthStatus();

  try {
    log.i('Inizializzazione dipendenze...');
    await initDependencies();
    log.i('Dipendenze inizializzate con successo.');

    // Pre-caricamento della cache delle informazioni sui simboli
    log.i('Pre-caching SymbolInfo from Binance...');
    final symbolInfoRepo = sl<ISymbolInfoRepository>();
    final result = await symbolInfoRepo.refreshSymbolInfoCache();
    result.fold(
      (failure) =>
          log.f('CRITICAL: Failed to pre-cache symbol info. Error: $failure'),
      (_) => log.i('SymbolInfo cache pre-loaded successfully.'),
    );

    // Costruisce la lista interceptors
    final interceptors = <Interceptor>[loggingInterceptor];
    final authInterceptor = apiKeyInterceptor;
    // L'auth interceptor valida solo se GRPC_API_KEY è configurata
    interceptors.add(authInterceptor);

    final server = Server.create(
      services: [
        sl<TradingServiceImpl>(),
        sl<HealthServiceImpl>(),
      ],
      interceptors: interceptors,
      codecRegistry:
          CodecRegistry(codecs: const [GzipCodec(), IdentityCodec()]),
    );

    // Gestore di shutdown pulito
    final shutdownHandler = (ProcessSignal signal) async {
      log.w('ProcessSignal $signal ricevuto. Avvio shutdown del server...');
      final apiService = sl<ITradingApiService>();
      if (apiService is ApiService) {
        apiService.dispose();
      }
      LogStreamService().dispose();
      await sl<HealthServiceImpl>().dispose();
      await server.shutdown();
      await Hive.close();
      log.i('Server arrestato correttamente.');
      exit(0);
    };

    ProcessSignal.sigint.watch().listen(shutdownHandler);
    if (!Platform.isWindows) {
      ProcessSignal.sigterm.watch().listen(shutdownHandler);
    }

    // 4. Avvia il server
    final env = EnvConfig();
    final port = env.getInt('GRPC_PORT', 50051);
    final certChainPath = env.get('CERT_PATH');
    final privateKeyPath = env.get('KEY_PATH');
    final allowInsecureGrpc = env.getBool('ALLOW_INSECURE_GRPC', false);

    ServerTlsCredentials? tlsCredentials;
    if (certChainPath != null &&
        certChainPath.isNotEmpty &&
        privateKeyPath != null &&
        privateKeyPath.isNotEmpty) {
      final certChainFile = File(certChainPath);
      final privateKeyFile = File(privateKeyPath);

      if (certChainFile.existsSync() && privateKeyFile.existsSync()) {
        log.i('Trovati certificati TLS. Avvio gRPC in modalità sicura...');
        tlsCredentials = ServerTlsCredentials(
          certificate: certChainFile.readAsBytesSync(),
          privateKey: privateKeyFile.readAsBytesSync(),
        );
      } else {
        log.e('ERRORE: Certificati non trovati. Arresto.');
        exit(1);
      }
    } else {
      log.w('Certificati TLS non definiti.');
      if (!allowInsecureGrpc) {
        log.e('TLS richiesto ma certificati mancanti. Arresto.');
        exit(1);
      }
      final strictBoot = env.getBool('STRICT_BOOT', false);
      if (strictBoot) {
        log.f(
            '[SECURITY] STRICT_BOOT attivo: avvio insecure vietato. Arresto.');
        exit(1);
      }
      log.w('⚠️  ============================================================');
      log.w(
          '⚠️  ATTENZIONE: Server in modalità NON SICURA (ALLOW_INSECURE_GRPC=true)');
      log.w('⚠️  Le comunicazioni NON sono cifrate. NON usare in produzione!');
      log.w('⚠️  ============================================================');
    }

    await server.serve(
      address:
          '0.0.0.0', // Esplicitamente binding a tutte le interfacce per la VPS
      port: port,
      security: tlsCredentials,
    );

    final securityMode = tlsCredentials != null ? 'SICURO (TLS)' : 'NON SICURO';
    log.i('Server gRPC in ascolto sulla porta $port in modalità $securityMode');
    // === Auto-recovery opzionale degli isolates ===
    try {
      final strategyStateRepo = sl<StrategyStateRepository>();
      final statesEither = await strategyStateRepo.getAllStrategyStates();
      await statesEither.fold((failure) async {
        log.w(
            'Auto-recovery: impossibile leggere stati strategia: ${failure.message}');
      }, (states) async {
        if (states.isEmpty) return;
        final getSettingsUseCase = sl<GetSettings>();
        final settingsEither = await getSettingsUseCase();
        await settingsEither.fold((f) async {
          log.w('Auto-recovery: impossibile leggere settings: ${f.message}');
        }, (settings) async {
          for (final entry in states.entries) {
            final symbol = entry.key;
            final state = entry.value;
            final isRunningLike =
                state.status == StrategyState.MONITORING_FOR_BUY ||
                    state.status ==
                        StrategyState.POSITION_OPEN_MONITORING_FOR_SELL ||
                    state.status == StrategyState.BUY_ORDER_PLACED ||
                    state.status == StrategyState.SELL_ORDER_PLACED;
            if (state.openTrades.isNotEmpty || isRunningLike) {
              try {
                log.i('Auto-recovery: avvio loop atomico per $symbol');
                await sl<TradingLoopManager>()
                    .startAtomicLoopForSymbol(symbol, settings, state);
              } catch (e, s) {
                log.w('Auto-recovery: avvio loop per $symbol fallito: $e',
                    stackTrace: s);
              }
            }
          }
        });
      });
    } catch (e, s) {
      log.w('Auto-recovery: errore inatteso: $e', stackTrace: s);
    }
  } on Exception catch (e, stackTrace) {
    print('@@@ FATAL ERROR: $e');
    print(stackTrace);
    log.f('ERRORE FATALE DURANTE L\'AVVIO:', error: e, stackTrace: stackTrace);
    exit(1); // Force exit to prevent silent failure
  } catch (e, stackTrace) {
    print('@@@ UNEXPECTED ERROR: $e');
    print(stackTrace);
    log.f('ERRORE INATTESO DURANTE L\'AVVIO:',
        error: e, stackTrace: stackTrace);
    exit(1); // Force exit
  }
}
