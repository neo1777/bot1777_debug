import 'package:equatable/equatable.dart';

abstract class AccountEvent extends Equatable {
  const AccountEvent();

  @override
  List<Object?> get props => [];
}

class LoadAccountInfo extends AccountEvent {
  const LoadAccountInfo();
}

class WatchAccountInfo extends AccountEvent {
  const WatchAccountInfo({this.isStreaming = true});

  final bool isStreaming;

  @override
  List<Object?> get props => [isStreaming];
}

class RefreshAccountInfo extends AccountEvent {
  const RefreshAccountInfo();
}

class FilterBalancesByAsset extends AccountEvent {
  const FilterBalancesByAsset(this.asset);

  final String? asset;

  @override
  List<Object?> get props => [asset];
}

class ShowOnlyNonZeroBalances extends AccountEvent {
  const ShowOnlyNonZeroBalances(this.showOnlyNonZero);

  final bool showOnlyNonZero;

  @override
  List<Object?> get props => [showOnlyNonZero];
}

enum BalanceSortType {
  alphabetical,
  alphabeticalDesc,
  freeBalance,
  freeBalanceDesc,
  totalBalance,
  totalBalanceDesc,
  lockedBalance,
  lockedBalanceDesc,
}

class SortBalances extends AccountEvent {
  const SortBalances(this.sortType);

  final BalanceSortType sortType;

  @override
  List<Object?> get props => [sortType];
}
