// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fifo_app_trade_hive_dto.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FifoAppTradeHiveDtoAdapter extends TypeAdapter<FifoAppTradeHiveDto> {
  @override
  final typeId = 2;

  @override
  FifoAppTradeHiveDto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FifoAppTradeHiveDto()
      ..priceStr = fields[0] as String?
      ..quantityStr = fields[1] as String?
      ..timestamp = (fields[2] as num?)?.toInt()
      ..roundId = (fields[3] as num?)?.toInt();
  }

  @override
  void write(BinaryWriter writer, FifoAppTradeHiveDto obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.priceStr)
      ..writeByte(1)
      ..write(obj.quantityStr)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.roundId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FifoAppTradeHiveDtoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
