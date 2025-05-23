// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'design.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DesignAdapter extends TypeAdapter<Design> {
  @override
  final int typeId = 0;

  @override
  Design read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Design(
      name: fields[0] as String,
      creator: fields[1] as String,
      base64Image: fields[2] as String,
      pollutionScore: fields[3] as double,
      happinessScore: fields[4] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Design obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.creator)
      ..writeByte(2)
      ..write(obj.base64Image)
      ..writeByte(3)
      ..write(obj.pollutionScore)
      ..writeByte(4)
      ..write(obj.happinessScore);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DesignAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
