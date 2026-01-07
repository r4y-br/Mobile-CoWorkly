import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class AuthApi {
  AuthApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/register');
    final response = await _client.post(
      uri,
      headers: ApiConfig.headers(),
      body: jsonEncode({
        'email': email,
        'password': password,
        'retypedPassword': password,
        'name': name,
        if (phone != null) 'phone': phone,
      }),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/login');
    final response = await _client.post(
      uri,
      headers: ApiConfig.headers(),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> me({required String token}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/me');
    final response = await _client.get(
      uri,
      headers: ApiConfig.headers(token: token, json: false),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getProfileStats({required String token}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/me/stats');
    final response = await _client.get(
      uri,
      headers: ApiConfig.headers(token: token, json: false),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateProfile({
    required String token,
    String? name,
    String? phone,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/profile');
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;

    final response = await _client.put(
      uri,
      headers: ApiConfig.headers(token: token),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> refreshToken({
    required String refreshToken,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/refresh');
    final response = await _client.post(
      uri,
      headers: ApiConfig.headers(),
      body: jsonEncode({'refreshToken': refreshToken}),
    );

    return _handleResponse(response);
  }

  Future<void> logout({required String token}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/logout');
    final response = await _client.post(
      uri,
      headers: ApiConfig.headers(token: token),
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

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
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
