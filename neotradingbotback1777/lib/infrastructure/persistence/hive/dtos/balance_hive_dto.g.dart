// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'balance_hive_dto.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BalanceHiveDtoAdapter extends TypeAdapter<BalanceHiveDto> {
  @override
  final typeId = 6;

  @override
  BalanceHiveDto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BalanceHiveDto()
      ..asset = fields[0] as String?
      ..free = (fields[1] as num?)?.toDouble()
      ..locked = (fields[2] as num?)?.toDouble();
  }

  @override
  void write(BinaryWriter writer, BalanceHiveDto obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.asset)
      ..writeByte(1)
      ..write(obj.free)
      ..writeByte(2)
      ..write(obj.locked);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BalanceHiveDtoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
