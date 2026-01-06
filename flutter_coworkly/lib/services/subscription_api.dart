import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class SubscriptionApi {
  static Future<Map<String, dynamic>> getMySubscription(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/subscriptions/me'),
      headers: ApiConfig.headers(token: token),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur lors de la récupération de l\'abonnement');
    }
  }

  static Future<void> subscribe(String token, String plan) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/subscriptions/subscribe'),
      headers: ApiConfig.headers(token: token),
      body: json.encode({'plan': plan}),
    );

    if (response.statusCode != 201) {
      throw Exception('Erreur lors de la demande d\'abonnement');
    }
  }
}
