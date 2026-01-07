import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class SeatsApi {
  SeatsApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // Get all seats for a room (public)
  Future<List<Map<String, dynamic>>> fetchSeats({required String roomId}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/seats?roomId=$roomId');
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

  // Get seat by ID (public)
  Future<Map<String, dynamic>> fetchSeatById(String seatId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/seats/$seatId');
    final response = await _client.get(uri);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw _buildError(response);
  }

  // Create seat (admin)
  Future<Map<String, dynamic>> createSeat({
    required String token,
    required String roomId,
    required int number,
    String? status,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/seats');
    final body = <String, dynamic>{
      'roomId': int.tryParse(roomId) ?? roomId,
      'number': number,
    };
    if (status != null) body['status'] = status;

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

  // Update seat (admin)
  Future<Map<String, dynamic>> updateSeat({
    required String token,
    required String seatId,
    int? number,
    String? status,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/seats/$seatId');
    final body = <String, dynamic>{};
    if (number != null) body['number'] = number;
    if (status != null) body['status'] = status;

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

  // Delete seat (admin)
  Future<void> deleteSeat({
    required String token,
    required String seatId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/seats/$seatId');
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
