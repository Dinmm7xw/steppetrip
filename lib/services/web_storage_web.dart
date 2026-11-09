// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class WebStorage {
  static void setItem(String key, String value) {
    try {
      html.window.localStorage[key] = value;
    } catch (_) {}
  }

  static String? getItem(String key) {
    try {
      return html.window.localStorage[key];
    } catch (_) {
      return null;
    }
  }

  static void removeItem(String key) {
    try {
      html.window.localStorage.remove(key);
    } catch (_) {}
  }

  static String getApiBaseUrl() {
    try {
      final host = html.window.location.hostname;
      if (host != null && host.isNotEmpty) {
        return 'http://$host:8080';
      }
    } catch (_) {}
    return 'http://localhost:8080';
  }
}

