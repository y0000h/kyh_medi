// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'slot_medication.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SlotMedicationAdapter extends TypeAdapter<SlotMedication> {
  @override
  final int typeId = 2;

  @override
  SlotMedication read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SlotMedication(
      slotId: fields[0] as String,
      medicationId: fields[1] as String,
      doseCount: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SlotMedication obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.slotId)
      ..writeByte(1)
      ..write(obj.medicationId)
      ..writeByte(2)
      ..write(obj.doseCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlotMedicationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
