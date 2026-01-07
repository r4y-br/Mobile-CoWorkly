import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class RoomsApi {
  RoomsApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // Get all rooms (public)
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

    throw _buildError(response);
  }

  // Get room by ID (public)
  Future<Map<String, dynamic>> fetchRoomById(String roomId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/rooms/$roomId');
    final response = await _client.get(uri);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw _buildError(response);
  }

  // Create room (admin)
  Future<Map<String, dynamic>> createRoom({
    required String token,
    required String name,
    String? description,
    int? capacity,
    String? imageUrl,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/rooms');
    final body = <String, dynamic>{
      'name': name,
    };
    if (description != null) body['description'] = description;
    if (capacity != null) body['capacity'] = capacity;
    if (imageUrl != null) body['imageUrl'] = imageUrl;

    final response = await _client.post(
      uri,
      headers: ApiConfig.headers(token: token),
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw _buildError(response);
  }

  // Update room (admin)
  Future<Map<String, dynamic>> updateRoom({
    required String token,
    required String roomId,
    String? name,
    String? description,
    int? capacity,
    String? imageUrl,
    bool? isActive,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/rooms/$roomId');
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (capacity != null) body['capacity'] = capacity;
    if (imageUrl != null) body['imageUrl'] = imageUrl;
    if (isActive != null) body['isActive'] = isActive;

    final response = await _client.patch(
      uri,
      headers: ApiConfig.headers(token: token),
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw _buildError(response);
  }

  // Delete room (admin)
  Future<void> deleteRoom({
    required String token,
    required String roomId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/rooms/$roomId');
    final response = await _client.delete(
      uri,
      headers: ApiConfig.headers(token: token, json: false),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _buildError(response);
    }
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
