// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings_hive_dto.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsHiveDtoAdapter extends TypeAdapter<AppSettingsHiveDto> {
  @override
  final typeId = 3;

  @override
  AppSettingsHiveDto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettingsHiveDto()
      ..tradeAmount = (fields[0] as num?)?.toDouble()
      ..profitTargetPercentage = (fields[1] as num?)?.toDouble()
      ..stopLossPercentage = (fields[2] as num?)?.toDouble()
      ..dcaDecrementPercentage = (fields[3] as num?)?.toDouble()
      ..maxOpenTrades = (fields[4] as num?)?.toInt()
      ..isTestMode = fields[5] as bool?
      ..buyOnStart = fields[6] as bool?
      ..initialWarmupTicks = (fields[7] as num?)?.toInt()
      ..initialWarmupSeconds = (fields[8] as num?)?.toDouble()
      ..initialSignalThresholdPct = (fields[9] as num?)?.toDouble()
      ..dcaCooldownSeconds = (fields[10] as num?)?.toDouble()
      ..dustRetryCooldownSeconds = (fields[11] as num?)?.toDouble()
      ..maxTradeAmountCap = (fields[12] as num?)?.toDouble()
      ..dcaCompareAgainstAverage = fields[13] as bool?
      ..maxBuyOveragePct = (fields[14] as num?)?.toDouble()
      ..maxCycles = (fields[15] as num?)?.toInt()
      ..enableFeeAwareTrading = fields[16] as bool?
      ..fixedQuantity = (fields[17] as num?)?.toDouble()
      ..strictBudget = fields[18] as bool?
      ..buyOnStartRespectWarmup = fields[19] as bool?
      ..buyCooldownSeconds = (fields[20] as num?)?.toDouble();
  }

  @override
  void write(BinaryWriter writer, AppSettingsHiveDto obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.tradeAmount)
      ..writeByte(1)
      ..write(obj.profitTargetPercentage)
      ..writeByte(2)
      ..write(obj.stopLossPercentage)
      ..writeByte(3)
      ..write(obj.dcaDecrementPercentage)
      ..writeByte(4)
      ..write(obj.maxOpenTrades)
      ..writeByte(5)
      ..write(obj.isTestMode)
      ..writeByte(6)
      ..write(obj.buyOnStart)
      ..writeByte(7)
      ..write(obj.initialWarmupTicks)
      ..writeByte(8)
      ..write(obj.initialWarmupSeconds)
      ..writeByte(9)
      ..write(obj.initialSignalThresholdPct)
      ..writeByte(10)
      ..write(obj.dcaCooldownSeconds)
      ..writeByte(11)
      ..write(obj.dustRetryCooldownSeconds)
      ..writeByte(12)
      ..write(obj.maxTradeAmountCap)
      ..writeByte(13)
      ..write(obj.dcaCompareAgainstAverage)
      ..writeByte(14)
      ..write(obj.maxBuyOveragePct)
      ..writeByte(15)
      ..write(obj.maxCycles)
      ..writeByte(16)
      ..write(obj.enableFeeAwareTrading)
      ..writeByte(17)
      ..write(obj.fixedQuantity)
      ..writeByte(18)
      ..write(obj.strictBudget)
      ..writeByte(19)
      ..write(obj.buyOnStartRespectWarmup)
      ..writeByte(20)
      ..write(obj.buyCooldownSeconds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsHiveDtoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
