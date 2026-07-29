import 'dart:io';

class ApiConfig {
  ApiConfig._();

  /// The base URL for the Django backend API.
  /// Automatically selects the correct host based on the platform.
  static String get baseUrl {
    // Android emulator uses 10.0.2.2 to reach host machine's localhost
    // iOS simulator can use localhost directly
    // Physical devices need the machine's LAN IP
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else if (Platform.isIOS) {
      return 'http://127.0.0.1:8000';
    } else {
      // Desktop/web — use localhost
      return 'http://127.0.0.1:8000';
    }
  }

  /// The full URL for the profile endpoint.
  static String get profileUrl => '$baseUrl/api/profile/';
}