import 'dart:convert';
import 'package:http/http.dart' as http;
import 'web_storage.dart';

/// Supabase Cloud PostgreSQL интеграциясы (REST API v1)
class SupabaseConfig {
  // Supabase Project URL және Publishable Key:
  static String defaultUrl = 'https://tbuezeoqfcwyshxtnxiz.supabase.co';
  static String defaultAnonKey = 'sb_publishable_aDz8nUrzVwcp_hIZEfzcug_ZLNwflnw';

  static String get url {
    final saved = AppStorage.getItem('stp_supabase_url');
    if (saved != null && saved.trim().isNotEmpty) return saved.trim();
    return defaultUrl.trim();
  }

  static String get anonKey {
    final saved = AppStorage.getItem('stp_supabase_key');
    if (saved != null && saved.trim().isNotEmpty) return saved.trim();
    return defaultAnonKey.trim();
  }

  static bool get isConfigured =>
      url.startsWith('https://') && anonKey.length > 15;

  static void saveCredentials(String newUrl, String newKey) {
    AppStorage.setItem('stp_supabase_url', newUrl.trim());
    AppStorage.setItem('stp_supabase_key', newKey.trim());
  }

  static Map<String, String> get headers => {
        'apikey': anonKey,
        if (anonKey.startsWith('eyJ')) 'Authorization': 'Bearer $anonKey',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation,resolution=merge-duplicates',
      };

  static Future<List<Map<String, dynamic>>> selectAll(String table) async {
    if (!isConfigured) return [];
    final res = await http
        .get(Uri.parse('$url/rest/v1/$table?select=*'), headers: headers)
        .timeout(const Duration(seconds: 6));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final list = jsonDecode(res.body) as List;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  static Future<bool> upsert(String table, Map<String, dynamic> row) async {
    if (!isConfigured) return false;
    final res = await http
        .post(
          Uri.parse('$url/rest/v1/$table'),
          headers: headers,
          body: jsonEncode(row),
        )
        .timeout(const Duration(seconds: 6));
    return res.statusCode >= 200 && res.statusCode < 300;
  }

  static Future<bool> deleteByColumn(
      String table, String column, String value) async {
    if (!isConfigured) return false;
    final res = await http
        .delete(
          Uri.parse('$url/rest/v1/$table?$column=eq.${Uri.encodeComponent(value)}'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 6));
    return res.statusCode >= 200 && res.statusCode < 300;
  }
}

