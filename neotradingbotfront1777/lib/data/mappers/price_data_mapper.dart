import 'package:neotradingbotfront1777/domain/entities/price_data.dart';
import 'package:neotradingbotfront1777/generated/proto/trading/v1/trading_service.pb.dart';

extension PriceResponseMapper on PriceResponse {
  PriceData toDomain(String symbol) {
    return PriceData(
      symbol: symbol,
      price: price,
      timestamp: DateTime.now(),
      priceChange24h: priceChange24h,
      priceChangeAbsolute24h: priceChangeAbsolute24h,
      highPrice24h: highPrice24h,
      lowPrice24h: lowPrice24h,
      volume24h: volume24h,
      priceStr: priceStr,
      priceChange24hStr: priceChange24hStr,
      priceChangeAbsolute24hStr: priceChangeAbsolute24hStr,
      highPrice24hStr: highPrice24hStr,
      lowPrice24hStr: lowPrice24hStr,
      volume24hStr: volume24hStr,
    );
  }
}

extension PriceDataToDtoMapper on PriceData {
  PriceResponse toDto() {
    return PriceResponse(
      price: price,
      priceChange24h: priceChange24h,
      priceChangeAbsolute24h: priceChangeAbsolute24h,
      highPrice24h: highPrice24h,
      lowPrice24h: lowPrice24h,
      volume24h: volume24h,
      priceStr: priceStr,
      priceChange24hStr: priceChange24hStr,
      priceChangeAbsolute24hStr: priceChangeAbsolute24hStr,
      highPrice24hStr: highPrice24hStr,
      lowPrice24hStr: lowPrice24hStr,
      volume24hStr: volume24hStr,
    );
  }
}
