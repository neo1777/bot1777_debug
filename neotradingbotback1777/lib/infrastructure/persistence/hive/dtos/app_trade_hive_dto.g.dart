// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_trade_hive_dto.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppTradeHiveDtoAdapter extends TypeAdapter<AppTradeHiveDto> {
  @override
  final typeId = 0;

  @override
  AppTradeHiveDto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppTradeHiveDto()
      ..symbol = fields[0] as String?
      ..price = (fields[1] as num?)?.toDouble()
      ..quantity = (fields[2] as num?)?.toDouble()
      ..isBuy = fields[3] as bool?
      ..timestamp = (fields[4] as num?)?.toInt()
      ..orderStatus = fields[5] as String?;
  }

  @override
  void write(BinaryWriter writer, AppTradeHiveDto obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.symbol)
      ..writeByte(1)
      ..write(obj.price)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.isBuy)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.orderStatus);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppTradeHiveDtoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
