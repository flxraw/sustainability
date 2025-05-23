import 'dart:convert';
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
    final apiKey = const String.fromEnvironment('google_air');
    if (apiKey.isEmpty) {
      throw Exception('google_air API key is missing. Use --dart-define.');
    }

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
      final indexes = data['currentConditions'][0]['indexes'];
      if (indexes != null && indexes.isNotEmpty) {
        return (indexes[0]['aqi'] as num).round();
      } else {
        throw Exception('Invalid air quality data structure');
      }
    } else {
      throw Exception('Failed to fetch air quality data: ${response.body}');
    }
  }

  Future<int> calculatePollutionScore(double lat, double lng) async {
    final basePollution = await fetchBasePollution(lat, lng);
    final score =
        basePollution -
        (treeCount * 4) -
        (greenModuleCount * 2) +
        (pollutingModuleCount * 3);
    return score.clamp(0, 100);
  }

  int calculateHappinessScore() {
    final score =
        baseHappiness +
        (treeCount * 3) +
        (amenityCount * 2) +
        (greenTransportCount * 4) -
        (pollutingModuleCount * 5);
    return score.clamp(0, 100);
  }
}
