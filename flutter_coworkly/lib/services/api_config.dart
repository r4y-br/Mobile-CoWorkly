import 'package:flutter/foundation.dart';

class ApiConfig {
  // Change this to your server's IP address when testing on a physical device
  // For Android emulator use: 'http://10.0.2.2:4000'
  // For iOS simulator use: 'http://localhost:4000'
  // For physical device use your computer's local IP: 'http://192.168.x.x:4000'
  static const String _serverHost = '192.168.1.106';  // Update this!
  static const int _serverPort = 4000;

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://$_serverHost:$_serverPort';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Use 10.0.2.2 for Android emulator, or _serverHost for physical device
        final host = _serverHost == 'localhost' ? '10.0.2.2' : _serverHost;
        return 'http://$host:$_serverPort';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'http://$_serverHost:$_serverPort';
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
}
