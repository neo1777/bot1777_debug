import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/repositories/i_fee_repository.dart';
import 'package:neotradingbotback1777/domain/entities/fee_info.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';

/// Mock condiviso per il repository delle fee per i test
class MockFeeRepository implements IFeeRepository {
  @override
  Future<Either<Failure, FeeInfo>> getSymbolFees(String symbol) async {
    return Right(FeeInfo.defaultBinance(symbol: symbol));
  }

  @override
  Future<Either<Failure, Map<String, FeeInfo>>> getAllSymbolFees() async {
    return Right({
      'BTCUSDC': FeeInfo.defaultBinance(symbol: 'BTCUSDC'),
      'ETHUSDC': FeeInfo.defaultBinance(symbol: 'ETHUSDC'),
      'ADAUSDC': FeeInfo.defaultBinance(symbol: 'ADAUSDC'),
      'DOTUSDC': FeeInfo.defaultBinance(symbol: 'DOTUSDC'),
    });
  }

  @override
  Future<Either<Failure, FeeInfo>> refreshSymbolFees(String symbol) async {
    return Right(FeeInfo.defaultBinance(symbol: symbol));
  }

  @override
  Future<void> clearCache() async {}

  @override
  bool areFeesValid(String symbol) => true;

  @override
  Future<Either<Failure, FeeInfo>> getSymbolFeesIfNeeded(String symbol) async {
    return Right(FeeInfo.defaultBinance(symbol: symbol));
  }
}
