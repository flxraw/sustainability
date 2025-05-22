import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for interacting with DALL·E via OpenAI API
class DalleService {
  final String apiKey;

  DalleService({required this.apiKey});

  /// Generates an image from a textual prompt
  Future<String?> generateImage(String promptText) async {
    final uri = Uri.parse('https://api.openai.com/v1/images/generations');

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'prompt': promptText,
        'n': 1,
        'size': '512x512',
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'][0]['url'];
    } else {
      print('⚠️ Image generation failed: ${response.body}');
      return null;
    }
  }
}
