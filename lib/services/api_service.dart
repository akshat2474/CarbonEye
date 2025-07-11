
import 'dart:convert';
import 'package:carboneye/config.dart';
import 'package:http/http.dart' as http;

class ApiService {
  Future<Map<String, dynamic>> analyzeRegion(List<double> bbox) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/analyze');
    try {
      final response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'bbox_coordinates': bbox,
          'days_back': 30, 
          'resolution': 60,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        
        final errorBody = jsonDecode(response.body);
        print('API Error: ${response.statusCode} - ${errorBody['detail']}');
        throw Exception(
            'Failed to analyze region: ${errorBody['detail'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('Network or parsing error: $e');
      throw Exception('Failed to connect to the analysis service.');
    }
  }

  Future<Map<String, dynamic>> getHealth() async {
    final uri = Uri.parse('${AppConfig.baseUrl}/health');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get health status.');
    }
  }
}
