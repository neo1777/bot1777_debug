import 'package:fpdart/fpdart.dart';
import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';
import 'package:mutex/mutex.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:neotradingbotback1777/domain/entities/symbol_info.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/i_symbol_info_repository.dart';
import 'package:neotradingbotback1777/domain/services/i_trading_api_service.dart';
// ignore: unused_import
import 'package:neotradingbotback1777/infrastructure/network/binance/api_service.dart';
import 'package:neotradingbotback1777/infrastructure/persistence/hive/dtos/symbol_info_hive_dto.dart';

@LazySingleton(as: ISymbolInfoRepository)
class SymbolInfoRepositoryImpl implements ISymbolInfoRepository {
  final ITradingApiService _apiService;
  final Box<SymbolInfoHiveDto> _symbolInfoBox;
  final _log = LogManager.getLogger();
  final Mutex _writeMutex = Mutex();

  SymbolInfoRepositoryImpl(
      this._apiService, @Named('symbolInfoBox') this._symbolInfoBox);

  String get _modePrefix => _apiService.isTestMode ? 'test_' : 'real_';

  String _getSymbolKey(String symbol) => '${_modePrefix}$symbol';

  @override
  Future<Either<Failure, SymbolInfo>> getSymbolInfo(String symbol) async {
    try {
      final key = _getSymbolKey(symbol);
      // 1. Attempt to retrieve from cache first for performance.
      final cachedDto = _symbolInfoBox.get(key);
      if (cachedDto != null) {
        _log.d(
            'SymbolInfo for $symbol found in cache (Mode: ${_apiService.isTestMode ? 'TEST' : 'REAL'}).');
        return Right(cachedDto.toEntity());
      }

      // 2. If not in cache, it's a critical issue if the cache is supposed to be pre-loaded.
      // We'll attempt a refresh as a recovery mechanism.
      _log.w(
          'SymbolInfo for $symbol not in cache for current mode. Attempting a full cache refresh...');
      final refreshResult = await refreshSymbolInfoCache();

      return refreshResult.fold(
        (failure) => Left(failure),
        (_) {
          final newKey = _getSymbolKey(symbol);
          final newDto = _symbolInfoBox.get(newKey);
          if (newDto != null) {
            _log.i(
                'SymbolInfo cache refreshed. Successfully found info for $symbol.');
            return Right(newDto.toEntity());
          } else {
            _log.e(
                'CRITICAL: SymbolInfo for $symbol not found even after a cache refresh.');
            return Left(ServerFailure(
                message:
                    'SymbolInfo for $symbol not found. The symbol may be invalid or delisted.'));
          }
        },
      );
    } catch (e, st) {
      _log.e('Failed to get SymbolInfo for $symbol', error: e, stackTrace: st);
      return Left(UnexpectedFailure(
          message:
              'An unexpected error occurred while getting SymbolInfo for $symbol: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> refreshSymbolInfoCache() async {
    try {
      _log.i(
          'Refreshing all symbol info from Binance API (Mode: ${_apiService.isTestMode ? 'TEST' : 'REAL'})...');
      final exchangeInfoResult = await _apiService.getExchangeInfo();

      return await exchangeInfoResult.fold(
        (failure) {
          _log.e('Failed to fetch exchange info from Binance API.',
              error: failure);
          return Left(failure);
        },
        (exchangeInfo) async {
          return await _writeMutex.protect(() async {
            // Clear only symbols belonging to the current mode
            final prefix = _modePrefix;
            final keysToDelete = _symbolInfoBox.keys
                .where((k) => k.toString().startsWith(prefix))
                .toList();
            await _symbolInfoBox.deleteAll(keysToDelete);

            final Map<String, SymbolInfoHiveDto> symbolDtoMap = {
              for (var entity in exchangeInfo.symbols)
                _getSymbolKey(entity.symbol):
                    SymbolInfoHiveDto.fromEntity(entity)
            };
            await _symbolInfoBox.putAll(symbolDtoMap);
            _log.i(
                'SymbolInfo cache updated successfully with ${symbolDtoMap.length} symbols for current mode.');
            return const Right(unit);
          });
        },
      );
    } catch (e, st) {
      _log.e('An unexpected error occurred during SymbolInfo cache refresh',
          error: e, stackTrace: st);
      return Left(UnexpectedFailure(
          message: 'Failed to refresh SymbolInfo cache: ${e.toString()}'));
    }
  }
}
