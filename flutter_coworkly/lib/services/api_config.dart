import 'package:flutter/foundation.dart';

class ApiConfig {
  // 🔧 Configuration des hôtes selon le contexte
  // - PC (Chrome, Windows, macOS) → localhost
  // - Android Emulator → 10.0.2.2
  // - iOS Simulator → localhost
  // - Appareil physique → IP locale de ton PC (ex: 192.168.1.48)

  static const String _localHost = 'localhost';
  static const String _androidEmulatorHost = '10.0.2.2';
  static const String _physicalDeviceHost =
      '192.168.1.48'; // ⚠️ Mets ici l’IP actuelle de ton PC
  static const int _serverPort = 4000;

  /// Retourne l’URL de base selon la plateforme
  static String get baseUrl {
    if (kIsWeb) {
      // Cas Web (Chrome, Edge, etc.)
      return 'http://$_localHost:$_serverPort';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        //  Choisis entre émulateur ou appareil physique
        // Pour l’émulateur Android → 10.0.2.2
        // Pour un smartphone Android → IP locale de ton PC
        return 'http://$_androidEmulatorHost:$_serverPort';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        // Ces plateformes peuvent utiliser localhost directement
        return 'http://$_localHost:$_serverPort';
      default:
        // Fallback → appareil physique
        return 'http://$_physicalDeviceHost:$_serverPort';
    }
  }

  /// Headers par défaut pour les requêtes HTTP
  static Map<String, String> headers({String? token, bool json = true}) {
    final headers = <String, String>{};
    if (json) {
      headers['Content-Type'] = 'application/json';
    }
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
}
