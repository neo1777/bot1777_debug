import 'package:hive_ce/hive.dart';
import 'package:neotradingbotback1777/domain/entities/app_trade.dart';
import 'package:neotradingbotback1777/domain/value_objects/amounts.dart';

part 'app_trade_hive_dto.g.dart';

@HiveType(typeId: 0)
class AppTradeHiveDto extends HiveObject {
  @HiveField(0)
  String? symbol;
  @HiveField(1)
  double? price;
  @HiveField(2)
  double? quantity;
  @HiveField(3)
  bool? isBuy;
  @HiveField(4)
  int? timestamp;
  @HiveField(5)
  String? orderStatus;

  static AppTradeHiveDto fromEntity(AppTrade entity) => AppTradeHiveDto()
    ..symbol = entity.symbol
    ..price = entity.price.toDouble()
    ..quantity = entity.quantity.toDouble()
    ..isBuy = entity.isBuy
    ..timestamp = entity.timestamp
    ..orderStatus = entity.orderStatus;

  AppTrade toEntity() => AppTrade(
      symbol: symbol ?? '',
      price: MoneyAmount.fromDouble(price ?? 0.0),
      quantity: QuantityAmount.fromDouble(quantity ?? 0.0),
      isBuy: isBuy ?? true,
      timestamp: timestamp ?? 0,
      orderStatus: orderStatus ?? 'UNKNOWN');
}
