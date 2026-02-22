// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_strategy_state_hive_dto.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppStrategyStateHiveDtoAdapter
    extends TypeAdapter<AppStrategyStateHiveDto> {
  @override
  final typeId = 1;

  @override
  AppStrategyStateHiveDto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppStrategyStateHiveDto()
      ..symbol = fields[0] as String?
      ..openTrades = (fields[1] as HiveList?)?.castHiveList()
      ..status = (fields[2] as num?)?.toInt()
      ..currentRoundId = (fields[3] as num?)?.toInt()
      ..cumulativeProfit = (fields[4] as num?)?.toDouble()
      ..successfulRounds = (fields[5] as num?)?.toInt()
      ..failedRounds = (fields[6] as num?)?.toInt()
      ..targetRoundId = (fields[7] as num?)?.toInt();
  }

  @override
  void write(BinaryWriter writer, AppStrategyStateHiveDto obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.symbol)
      ..writeByte(1)
      ..write(obj.openTrades)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.currentRoundId)
      ..writeByte(4)
      ..write(obj.cumulativeProfit)
      ..writeByte(5)
      ..write(obj.successfulRounds)
      ..writeByte(6)
      ..write(obj.failedRounds)
      ..writeByte(7)
      ..write(obj.targetRoundId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppStrategyStateHiveDtoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
