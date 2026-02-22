import 'package:neotradingbotfront1777/domain/entities/fee_info.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pb.dart';
import 'package:fixnum/fixnum.dart';

/// Extension to map FeeProto to FeeInfo domain entity
extension FeeMapper on SymbolFeesResponse {
  /// Converts SymbolFeesResponse proto to FeeInfo domain entity
  FeeInfo toDomain() {
    return FeeInfo(
      symbol: symbol,
      makerFee: makerFee,
      takerFee: takerFee,
      feeCurrency: feeCurrency,
      isDiscountActive: isDiscountActive,
      discountPercentage: discountPercentage,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(lastUpdated.toInt()),
    );
  }
}

/// Extension to map FeeInfo domain entity to SymbolFeesResponse proto
extension FeeInfoToProto on FeeInfo {
  /// Converts FeeInfo domain entity to SymbolFeesResponse proto
  SymbolFeesResponse toDto() {
    return SymbolFeesResponse()
      ..symbol = symbol
      ..makerFee = makerFee
      ..takerFee = takerFee
      ..feeCurrency = feeCurrency
      ..isDiscountActive = isDiscountActive
      ..discountPercentage = discountPercentage
      ..lastUpdated = Int64(lastUpdated.millisecondsSinceEpoch);
  }
}
