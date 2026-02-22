import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/entities/symbol_info.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/i_symbol_info_repository.dart';
import 'package:neotradingbotback1777/domain/services/i_trading_api_service.dart';

/// Lightweight in-memory symbol info repository for isolates (no Hive persistence).
class SymbolInfoRepositoryInMemory implements ISymbolInfoRepository {
  final ITradingApiService _api;
  final Map<String, SymbolInfo> _cache = {};

  SymbolInfoRepositoryInMemory(this._api);

  @override
  Future<Either<Failure, SymbolInfo>> getSymbolInfo(String symbol) async {
    final cached = _cache[symbol];
    if (cached != null) return Right(cached);
    // Fetch full exchange info and cache needed symbol
    final exEither = await _api.getExchangeInfo();
    return exEither.fold(
      (f) => Left(f),
      (exchangeInfo) {
        final info = exchangeInfo.symbols.firstWhere(
          (s) => s.symbol == symbol,
          orElse: () => SymbolInfo(
            symbol: symbol,
            minQty: 0,
            maxQty: double.maxFinite,
            stepSize: 0,
            minNotional: 0,
          ),
        );
        _cache[symbol] = info;
        return Right(info);
      },
    );
  }

  @override
  Future<Either<Failure, Unit>> refreshSymbolInfoCache() async {
    final exEither = await _api.getExchangeInfo();
    return exEither.fold(
      (f) => Left(f),
      (exchangeInfo) {
        for (final s in exchangeInfo.symbols) {
          _cache[s.symbol] = s;
        }
        return const Right(unit);
      },
    );
  }
}
