import 'package:hive/hive.dart';

part 'design.g.dart';

@HiveType(typeId: 0)
class Design extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String creator;

  @HiveField(2)
  final String base64Image;

  @HiveField(3)
  final double pollutionScore;

  @HiveField(4)
  final double happinessScore;

  Design({
    required this.name,
    required this.creator,
    required this.base64Image,
    required this.pollutionScore,
    required this.happinessScore,
  });
}
