import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class NotificationsApi {
  NotificationsApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<Map<String, dynamic>>> fetchNotifications({
    required String token,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/notifications');
    final response = await _client.get(
      uri,
      headers: ApiConfig.headers(token: token),
    );

    if (_isSuccess(response.statusCode)) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      throw Exception('Unexpected response format');
    }

    throw _buildError(response);
  }

  Future<void> markRead({required String token, required String id}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/notifications/$id/read');
    final response = await _client.patch(
      uri,
      headers: ApiConfig.headers(token: token),
    );

    if (!_isSuccess(response.statusCode)) {
      throw _buildError(response);
    }
  }

  Future<void> markAllRead({required String token}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/notifications/read-all');
    final response = await _client.patch(
      uri,
      headers: ApiConfig.headers(token: token),
    );

    if (!_isSuccess(response.statusCode)) {
      throw _buildError(response);
    }
  }

  Future<void> deleteNotification({
    required String token,
    required String id,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/notifications/$id');
    final response = await _client.delete(
      uri,
      headers: ApiConfig.headers(token: token, json: false),
    );

    if (!_isSuccess(response.statusCode)) {
      throw _buildError(response);
    }
  }

  Future<void> deleteAll({required String token}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/notifications');
    final response = await _client.delete(
      uri,
      headers: ApiConfig.headers(token: token, json: false),
    );

    if (!_isSuccess(response.statusCode)) {
      throw _buildError(response);
    }
  }

  void dispose() {
    _client.close();
  }

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

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
}
