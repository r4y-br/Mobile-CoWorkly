import 'package:flutter/material.dart';
import '../services/subscription_api.dart';

class SubscriptionProvider with ChangeNotifier {
  Map<String, dynamic>? _subscription;
  bool _isLoading = false;

  Map<String, dynamic>? get subscription => _subscription;
  bool get isLoading => _isLoading;

  Future<void> fetchSubscription(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      _subscription = await SubscriptionApi.getMySubscription(token);
    } catch (e) {
      debugPrint('Erreur Subscription: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> requestNewSubscription(String token, String plan) async {
    try {
      await SubscriptionApi.subscribe(token, plan);
      await fetchSubscription(token); // Rafraîchir après la demande
    } catch (e) {
      debugPrint('Erreur Subscribe: $e');
      rethrow;
    }
  }
}
