import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ImgBBService {
  static const String _apiKey = '7fbc04402d75e98500edcc9c70d4a291';

  static Future<String> uploadImage(File imageFile) async {
    final http.MultipartRequest request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.imgbb.com/1/upload?key=$_apiKey'),
    );

    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    final http.StreamedResponse response = await request.send();
    final String responseData = await response.stream.bytesToString();
    final dynamic decodedResponse = json.decode(responseData);

    if (response.statusCode != 200) {
      final Map<String, dynamic>? error =
          decodedResponse is Map<String, dynamic>
          ? decodedResponse['error'] as Map<String, dynamic>?
          : null;
      final String message =
          error?['message'] as String? ?? 'ImgBB upload failed.';
      throw StateError(message);
    }

    final Map<String, dynamic>? responseMap =
        decodedResponse is Map<String, dynamic> ? decodedResponse : null;
    final Map<String, dynamic>? data =
        responseMap?['data'] as Map<String, dynamic>?;
    final String? url = data?['url'] as String?;
    if (url == null || url.isEmpty) {
      throw StateError('ImgBB did not return an image URL.');
    }

    return url;
  }
}
