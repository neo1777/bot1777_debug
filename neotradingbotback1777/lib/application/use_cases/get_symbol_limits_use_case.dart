import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/entities/symbol_info.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/i_symbol_info_repository.dart';

/// Use case to get the trading limits and information for a specific symbol.
///
/// This use case orchestrates the retrieval of symbol information by solely
/// relying on the `ISymbolInfoRepository`. The repository itself is responsible
/// for handling the caching logic (e.g., cache-aside pattern).
class GetSymbolLimits {
  final ISymbolInfoRepository _symbolInfoRepository;

  GetSymbolLimits(this._symbolInfoRepository);

  /// Executes the use case.
  ///
  /// It directly calls the repository to get the symbol information.
  /// The repository will handle fetching from cache or network as needed.
  Future<Either<Failure, SymbolInfo>> call({required String symbol}) async {
    return await _symbolInfoRepository.getSymbolInfo(symbol);
  }
}
