import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class ReservationsApi {
  ReservationsApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<Map<String, dynamic>>> fetchReservations({
    required String token,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/reservations');
    final response = await _client.get(
      uri,
      headers: ApiConfig.headers(token: token, json: false),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      throw Exception('Unexpected response format');
    }

    throw _buildError(response);
  }

  Future<Map<String, dynamic>> createReservation({
    required String token,
    required String seatId,
    required String date,
    required String startTime,
    required String endTime,
    String? type,
    double? price,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/reservations');
    // Convert seatId to int for API compatibility
    final seatIdInt = int.tryParse(seatId) ?? seatId;
    final response = await _client.post(
      uri,
      headers: ApiConfig.headers(token: token),
      body: jsonEncode({
        'seatId': seatIdInt,
        'date': date,
        'startTime': startTime,
        'endTime': endTime,
        if (type != null) 'type': type,
        if (price != null) 'price': price,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw _buildError(response);
  }

  Future<void> cancelReservation({
    required String token,
    required String id,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/reservations/$id/cancel');
    final response = await _client.patch(
      uri,
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _buildError(response);
    }
  }

  Future<void> deleteReservation({
    required String token,
    required String id,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/reservations/$id');
    final response = await _client.delete(
      uri,
      headers: ApiConfig.headers(token: token, json: false),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _buildError(response);
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllReservations({
    required String token,
    int? seatId,
    int? userId,
  }) async {
    final queryParams = <String, String>{};
    if (seatId != null) queryParams['seatId'] = seatId.toString();
    if (userId != null) queryParams['userId'] = userId.toString();

    var uri = Uri.parse('${ApiConfig.baseUrl}/reservations');
    if (queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final response = await _client.get(
      uri,
      headers: ApiConfig.headers(token: token, json: false),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      throw Exception('Unexpected response format');
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
