import 'package:fixnum/fixnum.dart';
import 'package:neotradingbotfront1777/domain/entities/symbol_limits.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pb.dart';

extension SymbolLimitsMapper on SymbolLimitsResponse {
  SymbolLimits toDomain() {
    return SymbolLimits(
      symbol: symbol,
      minQty: minQty,
      maxQty: maxQty,
      stepSize: stepSize,
      minNotional: minNotional,
      makerFee: makerFee,
      takerFee: takerFee,
      feeCurrency: feeCurrency,
      isDiscountActive: isDiscountActive,
      discountPercentage: discountPercentage,
      lastUpdated:
          lastUpdated > Int64.ZERO
              ? DateTime.fromMillisecondsSinceEpoch(lastUpdated.toInt())
              : null,
    );
  }
}

extension SymbolLimitsToDtoMapper on SymbolLimits {
  SymbolLimitsResponse toDto() {
    return SymbolLimitsResponse(
      symbol: symbol,
      minQty: minQty,
      maxQty: maxQty,
      stepSize: stepSize,
      minNotional: minNotional,
      makerFee: makerFee,
      takerFee: takerFee,
      feeCurrency: feeCurrency,
      isDiscountActive: isDiscountActive,
      discountPercentage: discountPercentage,
      lastUpdated:
          lastUpdated != null
              ? Int64(lastUpdated!.millisecondsSinceEpoch)
              : Int64.ZERO,
    );
  }
}
