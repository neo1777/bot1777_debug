import 'package:equatable/equatable.dart';
import 'balance.dart';

class AccountInfo extends Equatable {
  const AccountInfo({
    required this.balances,
    this.totalEstimatedValueUSDC = 0.0,
    this.totalEstimatedValueUSDCStr = '',
  });

  final List<Balance> balances;
  final double totalEstimatedValueUSDC;
  final String totalEstimatedValueUSDCStr;

  Balance? getBalanceForAsset(String asset) {
    try {
      return balances.firstWhere((balance) => balance.asset == asset);
    } catch (_) {
      return null;
    }
  }

  List<Balance> get nonZeroBalances {
    return balances.where((balance) => balance.total > 0).toList();
  }

  double getTotalBalanceInUSDC() {
    return totalEstimatedValueUSDC > 0
        ? totalEstimatedValueUSDC
        : (getBalanceForAsset('USDC')?.total ?? 0.0);
  }

  @override
  List<Object?> get props => [
    balances,
    totalEstimatedValueUSDC,
    totalEstimatedValueUSDCStr,
  ];

  @override
  String toString() =>
      'AccountInfo(balances: ${balances.length}, totalValue: $totalEstimatedValueUSDC)';

  AccountInfo copyWith({
    List<Balance>? balances,
    double? totalEstimatedValueUSDC,
    String? totalEstimatedValueUSDCStr,
  }) {
    return AccountInfo(
      balances: balances ?? this.balances,
      totalEstimatedValueUSDC:
          totalEstimatedValueUSDC ?? this.totalEstimatedValueUSDC,
      totalEstimatedValueUSDCStr:
          totalEstimatedValueUSDCStr ?? this.totalEstimatedValueUSDCStr,
    );
  }
}
