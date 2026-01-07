import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class SeatsApi {
  SeatsApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<Map<String, dynamic>>> fetchSeats(
      {required String roomId}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/seats?roomId=$roomId');
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

  Future<Map<String, dynamic>> fetchSeatById({required int id}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/seats/$id');
    final response = await _client.get(uri);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(_extractErrorMessage(response));
  }

  Future<Map<String, dynamic>> createSeat({
    required String token,
    required int roomId,
    required int number,
    String? status,
    double? positionX,
    double? positionY,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/seats');
    final response = await _client.post(
      uri,
      headers: ApiConfig.headers(token: token),
      body: jsonEncode({
        'roomId': roomId,
        'number': number,
        if (status != null) 'status': status,
        if (positionX != null) 'positionX': positionX,
        if (positionY != null) 'positionY': positionY,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(_extractErrorMessage(response));
  }

  Future<Map<String, dynamic>> updateSeat({
    required String token,
    required int id,
    int? number,
    String? status,
    double? positionX,
    double? positionY,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/seats/$id');
    final body = <String, dynamic>{};
    if (number != null) body['number'] = number;
    if (status != null) body['status'] = status;
    if (positionX != null) body['positionX'] = positionX;
    if (positionY != null) body['positionY'] = positionY;

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

  Future<void> deleteSeat({
    required String token,
    required int id,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/seats/$id');
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
