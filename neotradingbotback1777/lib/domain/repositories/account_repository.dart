import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/domain/entities/account_info.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';

/// Repository interface for account and balance management.
///
/// This repository handles account information and balance data,
/// providing both cached data and live streaming capabilities.
/// Follows the cache-first strategy with network fallback.
abstract class AccountRepository {
  /// Saves account information to local cache.
  ///
  /// [accountInfo] - The account information to save
  ///
  /// Returns [Either<Failure, void>] indicating success or failure.
  Future<Either<Failure, void>> saveAccountInfo(AccountInfo accountInfo);

  /// Retrieves account information from cache or network.
  ///
  /// Uses cache-first strategy: tries cache first, then network if not found.
  ///
  /// Returns [Either<Failure, AccountInfo?>] with account info or null if not found.
  Future<Either<Failure, AccountInfo?>> getAccountInfo();

  /// Subscribes to real-time account information updates.
  ///
  /// Provides a stream of account info changes from both local cache updates
  /// and external API streaming.
  ///
  /// Returns [Stream<Either<Failure, AccountInfo>>] with account updates.
  Stream<Either<Failure, AccountInfo>> subscribeToAccountInfoStream();

  /// Clears cached account information.
  ///
  /// Useful for logout scenarios or cache invalidation.
  ///
  /// Returns [Either<Failure, void>] indicating success or failure.
  Future<Either<Failure, void>> clearAccountInfo();

  /// Refreshes account information from the network.
  ///
  /// Forces a network fetch and updates the local cache.
  ///
  /// Returns [Either<Failure, AccountInfo>] with fresh account info.
  Future<Either<Failure, AccountInfo>> refreshAccountInfo();
}
