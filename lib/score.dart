import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ScoreCalculator {
  final int treeCount;
  final int greenModuleCount;
  final int pollutingModuleCount;
  final int amenityCount;
  final int greenTransportCount;
  final int baseHappiness = 50;

  ScoreCalculator({
    required this.treeCount,
    required this.greenModuleCount,
    required this.pollutingModuleCount,
    required this.amenityCount,
    required this.greenTransportCount,
  });

  Future<int> fetchBasePollution(double lat, double lng) async {
    final apiKey = dotenv.env['GOOGLE_AIR'];
    final url = Uri.parse(
      'https://airquality.googleapis.com/v1/currentConditions:lookup?key=$apiKey',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'location': {'latitude': lat, 'longitude': lng},
        'extraComputations': [
          'HEALTH_RECOMMENDATIONS',
          'DOMINANT_POLLUTANT_CONCENTRATION',
        ],
        'languageCode': 'en',
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['currentConditions'][0]['indexes'][0]['aqi'] as num).round();
    } else {
      throw Exception('Failed to fetch air quality data: ${response.body}');
    }
  }

  Future<int> calculatePollutionScore(double lat, double lng) async {
    final basePollution = await fetchBasePollution(lat, lng);
    int pollutionScore =
        basePollution -
        (treeCount * 4) -
        (greenModuleCount * 2) +
        (pollutingModuleCount * 3);

    return pollutionScore.clamp(0, 100);
  }

  int calculateHappinessScore() {
    int happinessScore =
        baseHappiness +
        (treeCount * 3) +
        (amenityCount * 2) +
        (greenTransportCount * 4) -
        (pollutingModuleCount * 5);

    return happinessScore.clamp(0, 100);
  }
}
