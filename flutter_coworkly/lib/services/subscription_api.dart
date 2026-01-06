import 'dart:convert';
import 'package:http/http.dart' as http;

class SubscriptionApi {
  // Utilise 10.0.2.2 pour l'émulateur Android ou ton IP locale pour un vrai téléphone
  static const String baseUrl = 'http://192.168.1.48:4000/subscriptions';

  static Future<Map<String, dynamic>> getMySubscription(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur lors de la récupération de l\'abonnement');
    }
  }

  static Future<void> subscribe(String token, String plan) async {
    final response = await http.post(
      Uri.parse('$baseUrl/subscribe'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'plan': plan}),
    );

    if (response.statusCode != 201) {
      throw Exception('Erreur lors de la demande d\'abonnement');
    }
  }
}
