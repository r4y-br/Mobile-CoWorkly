import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class StatsApi {
  StatsApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> fetchDashboardStats({
    required String token,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/stats/dashboard');
    final response = await _client.get(
      uri,
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw _buildError(response);
  }

  Future<List<Map<String, dynamic>>> fetchWeeklyStats({
    required String token,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/stats/weekly');
    final response = await _client.get(
      uri,
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final weeklyStats = decoded['weeklyStats'] as List?;
      if (weeklyStats != null) {
        return weeklyStats.cast<Map<String, dynamic>>();
      }
      return [];
    }

    throw _buildError(response);
  }

  Exception _buildError(http.Response response) {
    var message = 'Request failed (${response.statusCode})';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        if (decoded['errors'] is List) {
          message = (decoded['errors'] as List).join(', ');
        } else if (decoded['error'] is String) {
          message = decoded['error'] as String;
        } else if (decoded['message'] is String) {
          message = decoded['message'] as String;
        }
      }
    } catch (_) {
      // Ignore parse errors and keep the default message.
    }

    return Exception(message);
  }

  void dispose() {
    _client.close();
  }
}
