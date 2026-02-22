import 'package:hive_ce/hive.dart';
import 'package:neotradingbotback1777/domain/entities/symbol_info.dart';

part 'symbol_info_hive_dto.g.dart';

@HiveType(typeId: 4)
class SymbolInfoHiveDto extends HiveObject {
  @HiveField(0)
  String? symbol;

  @HiveField(1)
  double? minQty;

  @HiveField(2)
  double? stepSize;

  @HiveField(3)
  double? maxQty;

  @HiveField(4)
  double? minNotional;

  /// Converte un'entità di dominio [SymbolInfo] in un [SymbolInfoHiveDto].
  static SymbolInfoHiveDto fromEntity(SymbolInfo entity) {
    return SymbolInfoHiveDto()
      ..symbol = entity.symbol
      ..minQty = entity.minQty
      ..stepSize = entity.stepSize
      ..maxQty = entity.maxQty
      ..minNotional = entity.minNotional;
  }

  /// Converte questo DTO in un'entità di dominio [SymbolInfo].
  SymbolInfo toEntity() {
    return SymbolInfo(
      symbol: symbol ?? '',
      minQty: minQty ?? 0.0,
      stepSize: stepSize ?? 0.0,
      maxQty: maxQty ?? 0.0,
      minNotional: minNotional ?? 0.0,
    );
  }
}
