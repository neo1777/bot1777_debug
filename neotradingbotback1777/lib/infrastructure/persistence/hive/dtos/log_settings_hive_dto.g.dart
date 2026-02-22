// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_settings_hive_dto.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LogSettingsHiveDtoAdapter extends TypeAdapter<LogSettingsHiveDto> {
  @override
  final typeId = 7;

  @override
  LogSettingsHiveDto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LogSettingsHiveDto()
      ..logLevel = fields[0] as String?
      ..enableFileLogging = fields[1] as bool?
      ..enableConsoleLogging = fields[2] as bool?;
  }

  @override
  void write(BinaryWriter writer, LogSettingsHiveDto obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.logLevel)
      ..writeByte(1)
      ..write(obj.enableFileLogging)
      ..writeByte(2)
      ..write(obj.enableConsoleLogging);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogSettingsHiveDtoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
