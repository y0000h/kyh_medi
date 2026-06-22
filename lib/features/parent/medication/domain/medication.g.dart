// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medication.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MedicationAdapter extends TypeAdapter<Medication> {
  @override
  final int typeId = 0;

  @override
  Medication read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Medication(
      id: fields[0] as String,
      name: fields[1] as String,
      photoPath: fields[2] as String?,
      memo: fields[3] as String?,
      colorHex: fields[4] as String?,
      createdAt: fields[5] as DateTime,
      deletedAt: fields[6] as DateTime?,
      mealTiming: fields[7] as int?,
      dose: fields[8] as String?,
      startDate: fields[9] as DateTime?,
      endDate: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Medication obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.photoPath)
      ..writeByte(3)
      ..write(obj.memo)
      ..writeByte(4)
      ..write(obj.colorHex)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.deletedAt)
      ..writeByte(7)
      ..write(obj.mealTiming)
      ..writeByte(8)
      ..write(obj.dose)
      ..writeByte(9)
      ..write(obj.startDate)
      ..writeByte(10)
      ..write(obj.endDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
