import 'package:neotradingbotfront1777/domain/entities/account_info.dart';
import 'package:neotradingbotfront1777/domain/entities/balance.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pb.dart';

extension AccountInfoMapper on AccountInfoResponse {
  AccountInfo toDomain() {
    return AccountInfo(
      balances: balances.map((balance) => balance.toDomain()).toList(),
      totalEstimatedValueUSDC: totalEstimatedValueUSDC,
      totalEstimatedValueUSDCStr: totalEstimatedValueUSDCStr,
    );
  }
}

extension BalanceMapper on BalanceProto {
  Balance toDomain() {
    return Balance(
      asset: asset,
      free: free,
      locked: locked,
      estimatedValueUSDC: estimatedValueUSDC,
      freeStr: freeStr,
      lockedStr: lockedStr,
      estimatedValueUSDCStr: estimatedValueUSDCStr,
    );
  }
}

extension AccountInfoToDtoMapper on AccountInfo {
  AccountInfoResponse toDto() {
    return AccountInfoResponse(
      balances: balances.map((balance) => balance.toDto()).toList(),
    );
  }
}

extension BalanceToDtoMapper on Balance {
  BalanceProto toDto() {
    return BalanceProto(
      asset: asset,
      free: free,
      locked: locked,
      estimatedValueUSDC: estimatedValueUSDC,
      freeStr: freeStr,
      lockedStr: lockedStr,
      estimatedValueUSDCStr: estimatedValueUSDCStr,
    );
  }
}
