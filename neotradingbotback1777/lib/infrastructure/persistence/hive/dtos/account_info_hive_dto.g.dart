// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_info_hive_dto.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AccountInfoHiveDtoAdapter extends TypeAdapter<AccountInfoHiveDto> {
  @override
  final typeId = 5;

  @override
  AccountInfoHiveDto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AccountInfoHiveDto()
      ..balances = (fields[0] as HiveList?)?.castHiveList()
      ..totalEstimatedValueUSDC = (fields[1] as num?)?.toDouble();
  }

  @override
  void write(BinaryWriter writer, AccountInfoHiveDto obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.balances)
      ..writeByte(1)
      ..write(obj.totalEstimatedValueUSDC);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountInfoHiveDtoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
