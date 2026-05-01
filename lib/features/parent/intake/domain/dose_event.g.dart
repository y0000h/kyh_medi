// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dose_event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DoseEventAdapter extends TypeAdapter<DoseEvent> {
  @override
  final int typeId = 3;

  @override
  DoseEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DoseEvent(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      slotId: fields[2] as String,
      medicationId: fields[3] as String,
      scheduledAt: fields[4] as DateTime,
      takenAt: fields[5] as DateTime?,
      status: fields[6] as String,
      createdAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, DoseEvent obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.slotId)
      ..writeByte(3)
      ..write(obj.medicationId)
      ..writeByte(4)
      ..write(obj.scheduledAt)
      ..writeByte(5)
      ..write(obj.takenAt)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoseEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
