import 'dart:convert';
import 'package:http/http.dart' as http;

class MLService {
  // For a real Android phone:
  // Replace this with your PC's IPv4 address.

  static const String baseUrl = 'http://127.0.0.1:8000';

  static Future<Map<String, dynamic>> predictRisk({
    required Map<String, dynamic> features,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/predict'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(features),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'ML server error: ${response.statusCode}\n${response.body}',
      );
    }

    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }
}