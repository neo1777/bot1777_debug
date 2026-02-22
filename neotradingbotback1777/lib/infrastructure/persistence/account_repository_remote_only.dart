import 'dart:async';
import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/entities/account_info.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';
import 'package:neotradingbotback1777/domain/repositories/account_repository.dart';
import 'package:neotradingbotback1777/domain/services/i_trading_api_service.dart';

/// Account repository that avoids local persistence, using only remote API and live stream.
class AccountRepositoryRemoteOnly implements AccountRepository {
  final ITradingApiService _apiService;

  AccountRepositoryRemoteOnly({required ITradingApiService apiService})
      : _apiService = apiService;

  @override
  Future<Either<Failure, void>> saveAccountInfo(AccountInfo accountInfo) async {
    // No-op: remote-only implementation does not persist locally
    return const Right(null);
  }

  @override
  Future<Either<Failure, AccountInfo?>> getAccountInfo() async {
    // Always fetch from network best-effort
    final res = await _apiService.getAccountInfo();
    return res.fold(
      (failure) => Left(failure),
      (accountInfo) => Right(accountInfo),
    );
  }

  @override
  Stream<Either<Failure, AccountInfo>> subscribeToAccountInfoStream() {
    return _apiService.subscribeToAccountInfoStream();
  }

  @override
  Future<Either<Failure, void>> clearAccountInfo() async {
    // No-op
    return const Right(null);
  }

  @override
  Future<Either<Failure, AccountInfo>> refreshAccountInfo() async {
    return _apiService.getAccountInfo();
  }
}
