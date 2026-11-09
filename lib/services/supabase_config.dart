import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'web_storage.dart';

/// Supabase Cloud PostgreSQL интеграциясы (REST API v1)
class SupabaseConfig {
  // Supabase Project URL және Publishable Key:
  static const String defaultUrl = 'https://tbuezeoqfcwyshxtnxiz.supabase.co';
  static const String defaultAnonKey =
      'sb_publishable_aDz8nUrzVwcp_hIZEfzcug_ZLNwflnw';

  static String get url => defaultUrl;
  static String get anonKey => defaultAnonKey;

  static bool get isConfigured => true;

  static void saveCredentials(String newUrl, String newKey) {
    AppStorage.setItem('stp_supabase_url', defaultUrl);
    AppStorage.setItem('stp_supabase_key', defaultAnonKey);
  }

  static Map<String, String> get headers => {
        'apikey': anonKey,
        if (anonKey.startsWith('eyJ')) 'Authorization': 'Bearer $anonKey',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation,resolution=merge-duplicates',
      };

  static Future<List<Map<String, dynamic>>> selectAll(String table) async {
    try {
      final res = await http
          .get(
            Uri.parse('$url/rest/v1/$table?select=*'),
            headers: {
              'apikey': anonKey,
              if (anonKey.startsWith('eyJ')) 'Authorization': 'Bearer $anonKey',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode >= 200 && res.statusCode < 300 && res.body.isNotEmpty) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      } else {
        debugPrint('Supabase selectAll($table) status ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      debugPrint('Supabase selectAll($table) error: $e');
    }
    return [];
  }

  static Future<bool> upsert(String table, Map<String, dynamic> row) async {
    try {
      final conflictCol = table == 'users' ? 'email' : 'id';
      final cleanRow = Map<String, dynamic>.from(row);
      if (table == 'users' &&
          cleanRow['email']?.toString().toLowerCase() ==
              'dinmuhammed@steppetrip.kz') {
        cleanRow['id'] = 'usr_admin_01';
      }
      final res = await http
          .post(
            Uri.parse('$url/rest/v1/$table?on_conflict=$conflictCol'),
            headers: headers,
            body: jsonEncode(cleanRow),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return true;
      }
      debugPrint('Supabase upsert($table) status ${res.statusCode}: ${res.body}');
    } catch (e) {
      debugPrint('Supabase upsert($table) error: $e');
    }
    return false;
  }

  static Future<bool> deleteByColumn(
      String table, String column, String value) async {
    try {
      final res = await http
          .delete(
            Uri.parse(
                '$url/rest/v1/$table?$column=eq.${Uri.encodeComponent(value)}'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 8));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      debugPrint('Supabase delete($table) error: $e');
      return false;
    }
  }
}
