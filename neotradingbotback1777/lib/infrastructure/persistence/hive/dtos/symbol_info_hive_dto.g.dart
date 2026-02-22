// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'symbol_info_hive_dto.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SymbolInfoHiveDtoAdapter extends TypeAdapter<SymbolInfoHiveDto> {
  @override
  final typeId = 4;

  @override
  SymbolInfoHiveDto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SymbolInfoHiveDto()
      ..symbol = fields[0] as String?
      ..minQty = (fields[1] as num?)?.toDouble()
      ..stepSize = (fields[2] as num?)?.toDouble()
      ..maxQty = (fields[3] as num?)?.toDouble()
      ..minNotional = (fields[4] as num?)?.toDouble();
  }

  @override
  void write(BinaryWriter writer, SymbolInfoHiveDto obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.symbol)
      ..writeByte(1)
      ..write(obj.minQty)
      ..writeByte(2)
      ..write(obj.stepSize)
      ..writeByte(3)
      ..write(obj.maxQty)
      ..writeByte(4)
      ..write(obj.minNotional);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SymbolInfoHiveDtoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
