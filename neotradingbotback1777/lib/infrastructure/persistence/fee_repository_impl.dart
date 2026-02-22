import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/core/cache/thread_safe_cache.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:logger/logger.dart';
import 'package:neotradingbotback1777/domain/entities/fee_info.dart';
import 'package:neotradingbotback1777/domain/entities/symbol_info.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/i_fee_repository.dart';
import 'package:neotradingbotback1777/domain/services/i_trading_api_service.dart';

/// Implementazione del repository per le fee
///
/// Gestisce cache, rate limiting e fallback per le fee di Binance
class FeeRepositoryImpl implements IFeeRepository {
  final ITradingApiService _apiService;
  final ThreadSafeCache<String, FeeInfo> _cache;
  final Logger _log;

  // TTL per la cache delle fee (24 ore - le fee cambiano raramente)
  static const Duration _cacheTtl = Duration(hours: 24);

  // Rate limiting per le richieste (max 10 al secondo)
  static const int _maxRequestsPerSecond = 10;
  static const Duration _requestDelay = Duration(milliseconds: 100);

  // Contatore per il rate limiting
  int _requestCount = 0;
  DateTime _lastRequestTime = DateTime.now();

  FeeRepositoryImpl({
    required ITradingApiService apiService,
    ThreadSafeCache<String, FeeInfo>? cache,
    Logger? logManager,
  })  : _apiService = apiService,
        _cache = cache ?? ThreadSafeCache<String, FeeInfo>(name: 'fee_cache'),
        _log = logManager ?? LogManager.getLogger();

  @override
  Future<Either<Failure, FeeInfo>> getSymbolFees(String symbol) async {
    try {
      // 1. Controlla cache locale
      final cachedFees = _cache.get(symbol);
      if (cachedFees != null && areFeesValid(symbol)) {
        // Log solo in debug per evitare spam
        _log.d('Using cached fees for $symbol: $cachedFees');
        return Right(cachedFees);
      }

      // 2. Recupera fee dal servizio API
      final fees = await _fetchFeesFromApi(symbol);

      // 3. Salva in cache se valide
      return fees.fold(
        (failure) => fees,
        (feeInfo) {
          _cache.put(symbol, feeInfo, ttl: _cacheTtl);
          _log.i(
              'Fee cache updated for $symbol: maker=${feeInfo.makerFee}, taker=${feeInfo.takerFee}');
          return fees;
        },
      );
    } catch (e, stackTrace) {
      _log.e('Error getting fees for $symbol: $e', stackTrace: stackTrace);

      // Fallback su fee di default
      final defaultFees = FeeInfo.defaultBinance(symbol: symbol);
      _log.w('Using default fees for $symbol: $defaultFees');
      return Right(defaultFees);
    }
  }

  @override
  Future<Either<Failure, Map<String, FeeInfo>>> getAllSymbolFees() async {
    try {
      // Recupera lista simboli attivi
      final symbolsResult = await _apiService.getActiveSymbols();
      return symbolsResult.fold(
        (failure) => Left(failure),
        (symbols) async {
          final feeMap = <String, FeeInfo>{};

          // Recupera fee per ogni simbolo con rate limiting
          for (int i = 0; i < symbols.length; i++) {
            final symbol = symbols[i];

            // Rate limiting
            if (i > 0 && i % _maxRequestsPerSecond == 0) {
              await Future.delayed(_requestDelay);
            }

            final fees = await getSymbolFees(symbol);
            fees.fold(
              (failure) =>
                  _log.w('Failed to get fees for $symbol: ${failure.message}'),
              (feeInfo) => feeMap[symbol] = feeInfo,
            );
          }

          _log.i('Retrieved fees for ${feeMap.length} symbols');
          return Right(feeMap);
        },
      );
    } catch (e, stackTrace) {
      _log.e('Error getting all symbol fees: $e', stackTrace: stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, FeeInfo>> refreshSymbolFees(String symbol) async {
    try {
      // Rimuovi dalla cache per forzare refresh
      _cache.remove(symbol);
      _log.i('Forcing fee refresh for $symbol');

      // Recupera nuove fee
      return await getSymbolFees(symbol);
    } catch (e, stackTrace) {
      _log.e('Error refreshing fees for $symbol: $e', stackTrace: stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  /// Recupera le fee solo se non sono in cache o sono scadute
  /// Riduce le chiamate API non necessarie
  @override
  Future<Either<Failure, FeeInfo>> getSymbolFeesIfNeeded(String symbol) async {
    try {
      // Controlla se le fee sono già in cache e valide
      final cachedFees = _cache.get(symbol);
      if (cachedFees != null && areFeesValid(symbol)) {
        return Right(cachedFees);
      }

      // Solo se necessario, recupera nuove fee
      return await getSymbolFees(symbol);
    } catch (e, stackTrace) {
      _log.e('Error getting fees if needed for $symbol: $e',
          stackTrace: stackTrace);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      _cache.clear();
      _log.i('Fee cache cleared');
    } catch (e, stackTrace) {
      _log.e('Error clearing fee cache: $e', stackTrace: stackTrace);
    }
  }

  @override
  bool areFeesValid(String symbol) {
    final cachedFees = _cache.get(symbol);
    if (cachedFees == null) return false;

    final now = DateTime.now();
    final age = now.difference(cachedFees.lastUpdated);

    return age < _cacheTtl;
  }

  /// Recupera le fee dall'API con fallback
  Future<Either<Failure, FeeInfo>> _fetchFeesFromApi(String symbol) async {
    try {
      // 1. Prova a ottenere fee precise dall'account (richiede autenticazione)
      final preciseFees = await _getPreciseFees(symbol);
      if (preciseFees.isRight()) {
        return preciseFees;
      }

      // 2. Fallback su fee base dal simbolo
      return await _getBaseFees(symbol);
    } catch (e) {
      _log.e('Error fetching fees from API for $symbol: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Ottiene fee precise dall'account Binance
  Future<Either<Failure, FeeInfo>> _getPreciseFees(String symbol) async {
    try {
      // Rate limiting
      await _enforceRateLimit();

      final response = await _apiService.getAccountTradeFees();
      return response.fold(
        (failure) => Left(failure),
        (fees) {
          final symbolFees = fees.firstWhere(
            (f) => f['symbol'] == symbol,
            orElse: () => <String, dynamic>{},
          );

          if (symbolFees.isNotEmpty) {
            return Right(_parsePreciseFees(symbolFees));
          }

          return Left(
              ServerFailure(message: 'No fees found for symbol $symbol'));
        },
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Ottiene fee base dal simbolo (fallback)
  Future<Either<Failure, FeeInfo>> _getBaseFees(String symbol) async {
    try {
      // Rate limiting
      await _enforceRateLimit();

      final response = await _apiService.getExchangeInfo();
      return response.fold(
        (failure) => Left(failure),
        (exchangeInfo) {
          final symbolInfo = exchangeInfo.symbols.firstWhere(
            (s) => s.symbol == symbol,
            orElse: () => const SymbolInfo(
              symbol: '',
              baseAsset: '',
              quoteAsset: '',
              minQty: 0,
              maxQty: 0,
              stepSize: 0,
              minNotional: 0,
              filters: [],
            ),
          );

          if (symbolInfo.symbol.isEmpty) {
            return Left(ServerFailure(message: 'Symbol $symbol not found'));
          }

          return Right(_extractBaseFees(symbol, symbolInfo));
        },
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Estrae fee base dal simbolo
  FeeInfo _extractBaseFees(String symbol, SymbolInfo symbolInfo) {
    // Fee base standard Binance
    double makerFee = 0.001; // 0.1%
    double takerFee = 0.001; // 0.1%

    // Controlla se ci sono fee specifiche nel simbolo
    if (symbolInfo.filters.isNotEmpty) {
      for (final filter in symbolInfo.filters) {
        if (filter['filterType'] == 'PERCENT_PRICE') {
          // Fee percentuali specifiche (se presenti)
          if (filter['multiplierUp'] != null) {
            final fee = double.tryParse(filter['multiplierUp'].toString());
            if (fee != null && fee > 0 && fee < 1) {
              takerFee = fee;
            }
          }
          if (filter['multiplierDown'] != null) {
            final fee = double.tryParse(filter['multiplierDown'].toString());
            if (fee != null && fee > 0 && fee < 1) {
              makerFee = fee;
            }
          }
        }
      }
    }

    return FeeInfo(
      makerFee: makerFee,
      takerFee: takerFee,
      feeCurrency: 'USDT',
      isDiscountActive: false,
      discountPercentage: 0.0,
      lastUpdated: DateTime.now(),
      symbol: symbol,
    );
  }

  /// Parsing delle fee precise dall'account
  FeeInfo _parsePreciseFees(Map<String, dynamic> feeData) {
    final makerFee =
        double.tryParse(feeData['makerCommission'] ?? '0') ?? 0.001;
    final takerFee =
        double.tryParse(feeData['takerCommission'] ?? '0') ?? 0.001;

    // Converti da base points (1 = 0.01%) a decimali
    final makerFeeDecimal = makerFee / 10000;
    final takerFeeDecimal = takerFee / 10000;

    return FeeInfo(
      makerFee: makerFeeDecimal,
      takerFee: takerFeeDecimal,
      feeCurrency: 'USDT',
      isDiscountActive: false,
      discountPercentage: 0.0,
      lastUpdated: DateTime.now(),
      symbol: feeData['symbol'] ?? '',
    );
  }

  /// Applica rate limiting per le richieste
  Future<void> _enforceRateLimit() async {
    final now = DateTime.now();
    final timeSinceLastRequest = now.difference(_lastRequestTime);

    if (timeSinceLastRequest < _requestDelay) {
      await Future.delayed(_requestDelay - timeSinceLastRequest);
    }

    _requestCount++;
    _lastRequestTime = DateTime.now();

    // Reset contatore ogni secondo
    if (_requestCount >= _maxRequestsPerSecond) {
      await Future.delayed(Duration(seconds: 1));
      _requestCount = 0;
    }
  }
}
