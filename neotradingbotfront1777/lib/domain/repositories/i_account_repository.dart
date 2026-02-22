import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/domain/entities/account_info.dart';

abstract class IAccountRepository {
  Future<Either<Failure, AccountInfo>> getAccountInfo();
  Stream<Either<Failure, AccountInfo>> subscribeAccountInfo();
}
