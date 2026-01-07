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

    throw Exception(_extractErrorMessage(response));
  }

  Future<Map<String, dynamic>> fetchRoomById({required int id}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/rooms/$id');
    final response = await _client.get(uri);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(_extractErrorMessage(response));
  }

  Future<Map<String, dynamic>> createRoom({
    required String token,
    required String name,
    String? description,
    required int capacity,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/rooms');
    final response = await _client.post(
      uri,
      headers: ApiConfig.headers(token: token),
      body: jsonEncode({
        'name': name,
        if (description != null) 'description': description,
        'capacity': capacity,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(_extractErrorMessage(response));
  }

  Future<Map<String, dynamic>> updateRoom({
    required String token,
    required int id,
    String? name,
    String? description,
    int? capacity,
    bool? isAvailable,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/rooms/$id');
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (capacity != null) body['capacity'] = capacity;
    if (isAvailable != null) body['isAvailable'] = isAvailable;

    final response = await _client.patch(
      uri,
      headers: ApiConfig.headers(token: token),
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(_extractErrorMessage(response));
  }

  Future<void> deleteRoom({
    required String token,
    required int id,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/rooms/$id');
    final response = await _client.delete(
      uri,
      headers: ApiConfig.headers(token: token, json: false),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractErrorMessage(response));
    }
  }

  String _extractErrorMessage(http.Response response) {
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
    } catch (_) {}
    return message;
  }

  void dispose() {
    _client.close();
  }
}
