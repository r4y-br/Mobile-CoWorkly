import 'package:flutter/foundation.dart';

class ApiConfig {
  // ============================================
  // PRODUCTION CONFIGURATION
  // ============================================
  // For production: Set your production server URL here
  // Example: 'api.coworkly.com' or your server's public IP
  //
  // For development:
  // - Android emulator: Use '10.0.2.2'
  // - iOS simulator: Use 'localhost'
  // - Physical device: Use your computer's local IP (e.g., '192.168.x.x')
  // ============================================

  // Set to true for production deployment
  static const bool _isProduction = false;

  // Production server configuration
  static const String _productionHost = 'api.coworkly.com';
  static const int _productionPort = 443;
  static const bool _productionUseHttps = true;

  // Development server configuration
  // Using 'localhost' works for:
  // - Android Emulator (auto-converts to 10.0.2.2)
  // - iOS Simulator (uses localhost directly)
  // - Physical Android devices (use: adb reverse tcp:4000 tcp:4000)
  // - Physical iOS devices (ensure device and Mac are on same network, then use computer's local IP)
  static const String _developmentHost = 'localhost';
  static const int _developmentPort = 4000;

  static String get baseUrl {
    if (_isProduction) {
      final protocol = _productionUseHttps ? 'https' : 'http';
      return '$protocol://$_productionHost${_productionPort != 443 && _productionPort != 80 ? ':$_productionPort' : ''}';
    }

    // Development mode
    if (kIsWeb) {
      return 'http://$_developmentHost:$_developmentPort';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Use 10.0.2.2 for Android emulator, or _developmentHost for physical device
        final host =
            _developmentHost == 'localhost' ? '10.0.2.2' : _developmentHost;
        return 'http://$host:$_developmentPort';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'http://$_developmentHost:$_developmentPort';
    }
  }

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

  // Timeout configurations
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
