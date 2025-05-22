import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class DalleService {
  final String authToken;

  DalleService({required this.authToken});

  Future<String?> generateImage(String promptText) async {
    final uri = Uri.parse('https://api.openai.com/v1/images/generations');

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'prompt': promptText, 'n': 1, 'size': '512x512'}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'][0]['url'];
    } else {
      print('⚠️ Image generation failed: ${response.body}');
      return null;
    }
  }

  Future<String?> editImage({
    required File imageFile,
    required String promptText,
  }) async {
    final uri = Uri.parse('https://api.openai.com/v1/images/edits');
    final maskFile = await createTransparentMask(imageFile);

    final request =
        http.MultipartRequest('POST', uri)
          ..headers['Authorization'] = 'Bearer $authToken'
          ..fields['prompt'] = promptText
          ..fields['n'] = '1'
          ..fields['size'] = '1024x1024'
          ..files.add(
            await http.MultipartFile.fromPath('image', imageFile.path),
          )
          ..files.add(await http.MultipartFile.fromPath('mask', maskFile.path));

    final streamed = await request.send();

    if (streamed.statusCode == 200) {
      final resBody = await streamed.stream.bytesToString();
      final json = jsonDecode(resBody);
      return json['data'][0]['url'];
    } else {
      print("⚠️ Edit operation failed: ${streamed.statusCode}");
      return null;
    }
  }

  Future<String?> processImageFromBytes({
    required Uint8List imageBytes,
    required String promptText,
    required String tempDirPath,
  }) async {
    final tempImageFile = File('$tempDirPath/composite_temp.png');
    await tempImageFile.writeAsBytes(imageBytes);
    return await editImage(imageFile: tempImageFile, promptText: promptText);
  }

  Future<File> createTransparentMask(File originalImageFile) async {
    final bytes = await originalImageFile.readAsBytes();
    final original = img.decodeImage(bytes);

    if (original == null) {
      throw Exception('⚠️ Failed to decode image');
    }

    final mask = img.Image(width: original.width, height: original.height);
    for (int y = 0; y < mask.height; y++) {
      for (int x = 0; x < mask.width; x++) {
        mask.setPixelRgba(x, y, 0, 0, 0, 0);
      }
    }

    final maskPath = '${originalImageFile.parent.path}/generated_mask.png';
    final maskFile = File(maskPath);
    await maskFile.writeAsBytes(img.encodePng(mask));
    return maskFile;
  }
}
