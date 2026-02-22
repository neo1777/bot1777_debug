import 'package:decimal/decimal.dart';
import 'package:hive_ce/hive.dart';
import 'package:neotradingbotback1777/domain/entities/fifo_app_trade.dart';

part 'fifo_app_trade_hive_dto.g.dart';

@HiveType(typeId: 2)
class FifoAppTradeHiveDto extends HiveObject {
  /// Stored as String for exact Decimal precision (Hive doesn't support Decimal natively)
  @HiveField(0)
  String? priceStr;
  @HiveField(1)
  String? quantityStr;
  @HiveField(2)
  int? timestamp;
  @HiveField(3)
  int? roundId;

  static FifoAppTradeHiveDto fromEntity(FifoAppTrade entity) =>
      FifoAppTradeHiveDto()
        ..priceStr = entity.price.toString()
        ..quantityStr = entity.quantity.toString()
        ..timestamp = entity.timestamp
        ..roundId = entity.roundId;

  FifoAppTrade toEntity() => FifoAppTrade(
      price: Decimal.parse(priceStr ?? '0'),
      quantity: Decimal.parse(quantityStr ?? '0'),
      timestamp: timestamp ?? 0,
      roundId: roundId ?? 0);
}
