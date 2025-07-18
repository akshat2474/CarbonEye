import 'dart:convert';
import 'package:carboneye/config.dart';
import 'package:http/http.dart' as http;

class ApiService {
  Future<Map<String, dynamic>> getImagesForRegion(List<double> bbox) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/analyze-deforestation');
    try {
      final response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'bbox': bbox,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(
            'Failed to get images: ${errorBody['detail'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Failed to connect to the image service.');
    }
  }
}