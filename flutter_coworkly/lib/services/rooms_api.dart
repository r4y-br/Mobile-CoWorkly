import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class RoomsApi {
  RoomsApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<Map<String, dynamic>>> fetchRooms() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/rooms');
    final response = await _client.get(uri);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      throw Exception('Unexpected response format');
    }

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

    throw Exception(message);
  }

  void dispose() {
    _client.close();
  }
}
