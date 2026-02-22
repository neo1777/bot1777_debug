import 'package:hive_ce/hive.dart';
import 'package:neotradingbotback1777/domain/entities/balance.dart';

part 'balance_hive_dto.g.dart';

@HiveType(typeId: 6)
class BalanceHiveDto extends HiveObject {
  @HiveField(0)
  String? asset;
  @HiveField(1)
  double? free;
  @HiveField(2)
  double? locked;

  static BalanceHiveDto fromEntity(Balance entity) => BalanceHiveDto()
    ..asset = entity.asset
    ..free = entity.free
    ..locked = entity.locked;

  Balance toEntity() => Balance(
        asset: asset ?? '',
        free: free ?? 0.0,
        locked: locked ?? 0.0,
      );
}
