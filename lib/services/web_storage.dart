import 'web_storage_stub.dart'
    if (dart.library.html) 'web_storage_web.dart' as storage_impl;

class AppStorage {
  static void setItem(String key, String value) => storage_impl.WebStorage.setItem(key, value);
  static String? getItem(String key) => storage_impl.WebStorage.getItem(key);
  static void removeItem(String key) => storage_impl.WebStorage.removeItem(key);
  static String getApiBaseUrl() => storage_impl.WebStorage.getApiBaseUrl();
}

