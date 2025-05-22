import 'dart:io';
import 'package:http/http.dart' as http;

class GoogleStreetViewService {
  static Future<File> fetchStreetViewImage(
    String address,
    String apiKey,
  ) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/streetview?size=1024x1024&location=${Uri.encodeComponent(address)}&key=$apiKey',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final file = File('street_view.png');
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } else {
      throw Exception('Failed to fetch Street View image');
    }
  }
}
