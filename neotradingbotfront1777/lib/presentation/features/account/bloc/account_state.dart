import 'package:equatable/equatable.dart';
import 'package:neotradingbotfront1777/domain/entities/account_info.dart';
import 'package:neotradingbotfront1777/domain/entities/balance.dart';
import 'package:neotradingbotfront1777/presentation/features/account/bloc/account_event.dart';

abstract class AccountState extends Equatable {
  const AccountState();

  @override
  List<Object?> get props => [];
}

class AccountInitial extends AccountState {
  const AccountInitial();
}

class AccountLoading extends AccountState {
  const AccountLoading();
}

class AccountLoaded extends AccountState {
  const AccountLoaded({
    required this.accountInfo,
    required this.filteredBalances,
    this.assetFilter,
    this.showOnlyNonZero = true,
    this.isStreaming = false,
    this.sortType = BalanceSortType.alphabetical,
  });

  final AccountInfo accountInfo;
  final List<Balance> filteredBalances;
  final String? assetFilter;
  final bool showOnlyNonZero;
  final bool isStreaming;
  final BalanceSortType sortType;

  // Calculated properties
  double get totalBalanceUSDC => accountInfo.getTotalBalanceInUSDC();

  List<Balance> get nonZeroBalances => accountInfo.nonZeroBalances;

  int get totalAssets => accountInfo.balances.length;

  int get assetsWithBalance => nonZeroBalances.length;

  Balance? get usdcBalance => accountInfo.getBalanceForAsset('USDC');

  Balance? get btcBalance => accountInfo.getBalanceForAsset('BTC');

  Balance? get ethBalance => accountInfo.getBalanceForAsset('ETH');

  List<String> get availableAssets {
    return accountInfo.balances.map((balance) => balance.asset).toSet().toList()
      ..sort();
  }

  @override
  List<Object?> get props => [
    accountInfo,
    filteredBalances,
    assetFilter,
    showOnlyNonZero,
    isStreaming,
    sortType,
  ];

  AccountLoaded copyWith({
    AccountInfo? accountInfo,
    List<Balance>? filteredBalances,
    String? assetFilter,
    bool? showOnlyNonZero,
    bool? isStreaming,
    BalanceSortType? sortType,
  }) {
    return AccountLoaded(
      accountInfo: accountInfo ?? this.accountInfo,
      filteredBalances: filteredBalances ?? this.filteredBalances,
      assetFilter: assetFilter ?? this.assetFilter,
      showOnlyNonZero: showOnlyNonZero ?? this.showOnlyNonZero,
      isStreaming: isStreaming ?? this.isStreaming,
      sortType: sortType ?? this.sortType,
    );
  }
}

class AccountError extends AccountState {
  const AccountError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
