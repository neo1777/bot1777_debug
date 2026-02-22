import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotfront1777/domain/entities/fee_info.dart';
import 'package:neotradingbotfront1777/domain/failures/failures.dart';
import 'package:neotradingbotfront1777/domain/repositories/i_fee_repository.dart';

import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pb.dart';
import 'package:logger/logger.dart';

import 'package:neotradingbotfront1777/data/mappers/fee_mapper.dart';
import 'package:neotradingbotfront1777/data/datasources/i_trading_remote_datasource.dart';

/// Implementazione del repository per le fee nel frontend
///
/// Si connette al backend per recuperare le informazioni sulle fee
class FeeRepositoryImpl implements IFeeRepository {
  // Cache locale per le fee (TTL di 1 ora)
  final Map<String, _CachedFeeInfo> _cache = {};
  static const Duration _cacheTtl = Duration(hours: 1);
  final Logger _logger = Logger();
  final ITradingRemoteDatasource _datasource;

  FeeRepositoryImpl({required ITradingRemoteDatasource datasource})
    : _datasource = datasource;

  @override
  Future<Either<Failure, FeeInfo>> getSymbolFees(String symbol) async {
    try {
      // Controlla cache locale
      final cached = _cache[symbol];
      if (cached != null && cached.isValid) {
        return Right(cached.feeInfo);
      }

      // Implementazione datasource call
      final result = await _datasource.getSymbolFees(
        GetSymbolFeesRequest(symbol: symbol),
      );

      return result.fold(
        (failure) {
          _logger.w('Errore datasource per fee di $symbol: $failure');
          // Fallback a fee di default
          final defaultFees = FeeInfo.defaultBinance(symbol: symbol);
          _cache[symbol] = _CachedFeeInfo(
            feeInfo: defaultFees,
            timestamp: DateTime.now(),
          );
          return Right(defaultFees);
        },
        (response) {
          final feeInfo = response.toDomain();

          // Salva in cache
          _cache[symbol] = _CachedFeeInfo(
            feeInfo: feeInfo,
            timestamp: DateTime.now(),
          );

          return Right(feeInfo);
        },
      );
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Errore nel recupero fee: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, FeeInfo>>> getAllSymbolFees() async {
    try {
      // Implementazione batch per fee multiple
      final commonSymbols = ['BTCUSDT', 'ETHUSDT', 'ADAUSDT', 'DOTUSDT'];

      // Implementazione Datasource batch
      final result = await _datasource.getAllSymbolFees();

      return result.fold(
        (failure) async {
          _logger.w('Errore datasource batch, fallback a singolo: $failure');
          // Fallback: recupera singolarmente ogni simbolo
          final feeMap = <String, FeeInfo>{};

          for (final symbol in commonSymbols) {
            final fees = await getSymbolFees(symbol);
            fees.fold(
              (failure) => null, // Ignora errori per simboli singoli
              (feeInfo) => feeMap[symbol] = feeInfo,
            );
          }
          return Right(feeMap);
        },
        (response) {
          final feeMap = <String, FeeInfo>{};
          for (final symbolFee in response.symbolFees) {
            final feeInfo = symbolFee.toDomain();

            feeMap[symbolFee.symbol] = feeInfo;

            // Salva in cache
            _cache[symbolFee.symbol] = _CachedFeeInfo(
              feeInfo: feeInfo,
              timestamp: DateTime.now(),
            );
          }
          return Right(feeMap);
        },
      );
    } catch (e) {
      return Left(
        UnexpectedFailure(message: 'Errore nel recupero fee multiple: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, FeeInfo>> refreshSymbolFees(String symbol) async {
    // Rimuovi dalla cache per forzare refresh
    _cache.remove(symbol);
    return getSymbolFees(symbol);
  }

  @override
  Future<void> clearCache() async {
    _cache.clear();
  }

  @override
  bool areFeesValid(String symbol) {
    final cached = _cache[symbol];
    if (cached == null) return false;

    final age = DateTime.now().difference(cached.timestamp);
    return age < _cacheTtl;
  }
}

/// Classe helper per la cache delle fee
class _CachedFeeInfo {
  final FeeInfo feeInfo;
  final DateTime timestamp;

  _CachedFeeInfo({required this.feeInfo, required this.timestamp});

  bool get isValid {
    final age = DateTime.now().difference(timestamp);
    return age < Duration(hours: 1);
  }
}
