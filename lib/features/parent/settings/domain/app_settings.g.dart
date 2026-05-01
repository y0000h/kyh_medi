// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 4;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      userMode: fields[0] as String,
      adsRemoved: fields[1] as bool,
      seniorFontScale: fields[2] as double,
      pairedSupabaseUserId: fields[3] as String?,
      fcmToken: fields[4] as String?,
      onboardingDone: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.userMode)
      ..writeByte(1)
      ..write(obj.adsRemoved)
      ..writeByte(2)
      ..write(obj.seniorFontScale)
      ..writeByte(3)
      ..write(obj.pairedSupabaseUserId)
      ..writeByte(4)
      ..write(obj.fcmToken)
      ..writeByte(5)
      ..write(obj.onboardingDone);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
