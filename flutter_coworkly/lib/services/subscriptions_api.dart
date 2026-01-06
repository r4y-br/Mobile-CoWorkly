import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class SubscriptionsApi {
  SubscriptionsApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<Map<String, dynamic>>> fetchMySubscriptions({
    required String token,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/subscriptions/my');
    final response = await _client.get(
      uri,
      headers: ApiConfig.headers(token: token, json: false),
    );

    return _handleListResponse(response);
  }

  Future<List<Map<String, dynamic>>> fetchAllSubscriptions({
    required String token,
    String? status,
    int? userId,
  }) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    if (userId != null) queryParams['userId'] = userId.toString();

    final uri = Uri.parse('${ApiConfig.baseUrl}/subscriptions')
        .replace(queryParameters: queryParams);
    final response = await _client.get(
      uri,
      headers: ApiConfig.headers(token: token, json: false),
    );

    return _handleListResponse(response);
  }

  Future<Map<String, dynamic>> fetchSubscriptionById({
    required String token,
    required int id,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/subscriptions/$id');
    final response = await _client.get(
      uri,
      headers: ApiConfig.headers(token: token, json: false),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> createSubscription({
    required String token,
    required String plan,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/subscriptions');
    final response = await _client.post(
      uri,
      headers: ApiConfig.headers(token: token),
      body: jsonEncode({'plan': plan}),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> approveSubscription({
    required String token,
    required int id,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/subscriptions/$id/approve');
    final response = await _client.patch(
      uri,
      headers: ApiConfig.headers(token: token),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> cancelSubscription({
    required String token,
    required int id,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/subscriptions/$id/cancel');
    final response = await _client.patch(
      uri,
      headers: ApiConfig.headers(token: token),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> suspendSubscription({
    required String token,
    required int id,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/subscriptions/$id/suspend');
    final response = await _client.patch(
      uri,
      headers: ApiConfig.headers(token: token),
    );

    return _handleResponse(response);
  }

  Future<void> deleteSubscription({
    required String token,
    required int id,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/subscriptions/$id');
    final response = await _client.delete(
      uri,
      headers: ApiConfig.headers(token: token, json: false),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractErrorMessage(response));
    }
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
