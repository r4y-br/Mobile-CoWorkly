import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class SubscriptionApi {
  static final http.Client _client = http.Client();

  // Get my subscription (user)
  static Future<Map<String, dynamic>> getMySubscription(String token) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/subscriptions/me'),
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List && data.isNotEmpty) {
        return _formatSubscription(data.first);
      } else if (data is Map<String, dynamic>) {
        return _formatSubscription(data);
      }
      return {'plan': 'NONE', 'status': 'INACTIVE', 'usedHours': 0, 'totalHours': 0, 'remainingHours': 0};
    } else if (response.statusCode == 404) {
      return {'plan': 'NONE', 'status': 'INACTIVE', 'usedHours': 0, 'totalHours': 0, 'remainingHours': 0};
    } else {
      throw Exception('Error fetching subscription');
    }
  }

  static Map<String, dynamic> _formatSubscription(Map<String, dynamic> sub) {
    final plan = sub['plan'] ?? 'NONE';
    final status = sub['status'] ?? 'INACTIVE';
    int totalHours = 0;
    
    switch (plan) {
      case 'MONTHLY':
        totalHours = 40;
        break;
      case 'QUARTERLY':
        totalHours = 120;
        break;
      case 'SEMI_ANNUAL':
        totalHours = 250;
        break;
    }
    
    final usedHours = sub['usedHours'] ?? 0;
    return {
      'id': sub['id'],
      'plan': plan,
      'status': status,
      'usedHours': usedHours,
      'totalHours': totalHours,
      'remainingHours': totalHours - usedHours,
      'startDate': sub['startDate'],
      'endDate': sub['endDate'],
    };
  }

  // Subscribe to a plan (user)
  static Future<Map<String, dynamic>> subscribe(String token, String plan) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/subscriptions/subscribe'),
      headers: ApiConfig.headers(token: token),
      body: json.encode({'plan': plan}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final error = _parseError(response);
      throw Exception(error);
    }
  }

  // Cancel subscription (user)
  static Future<void> cancelSubscription(String token, int subscriptionId) async {
    final response = await _client.patch(
      Uri.parse('${ApiConfig.baseUrl}/subscriptions/$subscriptionId/cancel'),
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error cancelling subscription');
    }
  }

  // Get all subscriptions (admin)
  static Future<List<Map<String, dynamic>>> getAllSubscriptions(String token) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/subscriptions/all'),
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } else {
      throw Exception('Error fetching subscriptions');
    }
  }

  // Approve subscription (admin)
  static Future<void> approveSubscription(String token, int subscriptionId) async {
    final response = await _client.patch(
      Uri.parse('${ApiConfig.baseUrl}/subscriptions/$subscriptionId/approve'),
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error approving subscription');
    }
  }

  // Suspend subscription (admin)
  static Future<void> suspendSubscription(String token, int subscriptionId) async {
    final response = await _client.patch(
      Uri.parse('${ApiConfig.baseUrl}/subscriptions/$subscriptionId/suspend'),
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error suspending subscription');
    }
  }

  // Delete subscription (admin)
  static Future<void> deleteSubscription(String token, int subscriptionId) async {
    final response = await _client.delete(
      Uri.parse('${ApiConfig.baseUrl}/subscriptions/$subscriptionId'),
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error deleting subscription');
    }
  }

  static String _parseError(http.Response response) {
    try {
      final data = json.decode(response.body);
      if (data is Map<String, dynamic>) {
        return data['message'] ?? data['error'] ?? 'Unknown error';
      }
    } catch (_) {}
    return 'Error (${response.statusCode})';
  }

  static void dispose() {
    _client.close();
  }
}
