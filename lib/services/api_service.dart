import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Use 10.0.2.2 for Android emulator, localhost for iOS simulator
  static const String _baseUrl = 'http://10.0.2.2:5001';

  static Future<Map<String, dynamic>> getAllData(String farmer, String field) async {
    final uri = Uri.parse('$_baseUrl/get_all_data').replace(
      queryParameters: {'farmer': farmer, 'field': field},
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch data: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> predict(String farmer, String field) async {
    final uri = Uri.parse('$_baseUrl/predict').replace(
      queryParameters: {'farmer': farmer, 'field': field},
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch prediction: ${response.statusCode}');
  }

  /// Extract current NPK from /get_all_data response.
  /// Path: ThingSpeak Data -> [farmer] -> [field] -> {n, p, k}
  static Map<String, double> extractCurrentNpk(
      Map<String, dynamic> data, String farmer, String field) {
    try {
      final thingSpeak = data['ThingSpeak Data'] as Map<String, dynamic>;
      final farmerData = thingSpeak[farmer] as Map<String, dynamic>;
      final fieldData = farmerData[field] as Map<String, dynamic>;
      return {
        'N': (fieldData['n'] as num).toDouble(),
        'P': (fieldData['p'] as num).toDouble(),
        'K': (fieldData['k'] as num).toDouble(),
      };
    } catch (e) {
      throw Exception('Could not parse NPK from ThingSpeak Data: $e');
    }
  }

  /// Extract predicted NPK from /predict response.
  /// Path: prediction -> {N, P, K}
  static Map<String, double> extractPredictedNpk(Map<String, dynamic> data) {
    try {
      final prediction = data['prediction'] as Map<String, dynamic>;
      return {
        'N': (prediction['N'] as num).toDouble(),
        'P': (prediction['P'] as num).toDouble(),
        'K': (prediction['K'] as num).toDouble(),
      };
    } catch (e) {
      throw Exception('Could not parse predicted NPK: $e');
    }
  }

  /// Extract all 14 input_features from /predict response.
  static Map<String, double> extractInputFeatures(Map<String, dynamic> data) {
    try {
      final features = data['input_features'] as Map<String, dynamic>;
      return features.map((key, value) => MapEntry(key, (value as num).toDouble()));
    } catch (e) {
      throw Exception('Could not parse input features: $e');
    }
  }
}
