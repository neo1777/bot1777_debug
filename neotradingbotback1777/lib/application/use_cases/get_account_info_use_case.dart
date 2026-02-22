import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/entities/account_info.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/account_repository.dart';

class GetAccountInfo {
  final AccountRepository _repository;
  GetAccountInfo(this._repository);

  Future<Either<Failure, AccountInfo?>> call() {
    return _repository.getAccountInfo();
  }
}
