import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class UsersApi {
  final http.Client _client = http.Client();

  Future<List<Map<String, dynamic>>> fetchAllUsers({
    required String token,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/users');
    final response = await _client.get(
      uri,
      headers: ApiConfig.headers(token: token, json: false),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      return [];
    }

    throw Exception('Failed to fetch users: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> fetchUserById({
    required String token,
    required int userId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/users/$userId');
    final response = await _client.get(
      uri,
      headers: ApiConfig.headers(token: token, json: false),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to fetch user: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> updateUserRole({
    required String token,
    required int userId,
    required String role,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/users/$userId/role');
    final response = await _client.patch(
      uri,
      headers: ApiConfig.headers(token: token),
      body: jsonEncode({'role': role}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to update user role: ${response.statusCode}');
  }

  Future<void> deleteUser({
    required String token,
    required int userId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/users/$userId');
    final response = await _client.delete(
      uri,
      headers: ApiConfig.headers(token: token, json: false),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception('Failed to delete user: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> cancelReservation({
    required String token,
    required int reservationId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/users/reservations/$reservationId/cancel');
    final response = await _client.patch(
      uri,
      headers: ApiConfig.headers(token: token),
      body: jsonEncode({}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to cancel reservation: ${response.statusCode}');
  }

  void dispose() {
    _client.close();
  }
}
