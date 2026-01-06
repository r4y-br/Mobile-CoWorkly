import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class UsersApi {
  UsersApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<Map<String, dynamic>>> fetchAllUsers({
    required String token,
    String? role,
  }) async {
    final queryParams = <String, String>{};
    if (role != null) queryParams['role'] = role;

    final uri = Uri.parse('${ApiConfig.baseUrl}/users')
        .replace(queryParameters: queryParams);
    final response = await _client.get(
      uri,
      headers: ApiConfig.headers(token: token, json: false),
    );

    return _handleListResponse(response);
  }

  Future<Map<String, dynamic>> fetchUserById({
    required String token,
    required int id,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/users/$id');
    final response = await _client.get(
      uri,
      headers: ApiConfig.headers(token: token, json: false),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> createUser({
    required String token,
    required String name,
    required String email,
    required String password,
    String? phone,
    String? role,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/users');
    final response = await _client.post(
      uri,
      headers: ApiConfig.headers(token: token),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        if (phone != null) 'phone': phone,
        if (role != null) 'role': role,
      }),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateUser({
    required String token,
    required int id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? password,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/users/$id');
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (phone != null) body['phone'] = phone;
    if (role != null) body['role'] = role;
    if (password != null && password.isNotEmpty) body['password'] = password;

    final response = await _client.patch(
      uri,
      headers: ApiConfig.headers(token: token),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  Future<void> deleteUser({
    required String token,
    required int id,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/users/$id');
    final response = await _client.delete(
      uri,
      headers: ApiConfig.headers(token: token, json: false),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractErrorMessage(response));
    }
  }

  Future<Map<String, dynamic>> fetchUserStats({
    required String token,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/users/stats');
    final response = await _client.get(
      uri,
      headers: ApiConfig.headers(token: token, json: false),
    );

    return _handleResponse(response);
  }

  List<Map<String, dynamic>> _handleListResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      throw Exception('Expected a list response');
    }

    throw Exception(_extractErrorMessage(response));
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(_extractErrorMessage(response));
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
    } catch (_) {
      // Ignore parse errors and keep the default message.
    }
    return message;
  }

  void dispose() {
    _client.close();
  }
}
