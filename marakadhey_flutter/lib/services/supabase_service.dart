import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SupabaseService {
  // Configurable Supabase credentials
  // Replace these with your Supabase Project settings or set via environment
  static String supabaseUrl = 'https://YOUR_SUPABASE_PROJECT_ID.supabase.co';
  static String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      !supabaseUrl.contains('YOUR_SUPABASE_PROJECT_ID') &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseAnonKey.contains('YOUR_SUPABASE_ANON_KEY');

  static void init({required String url, required String anonKey}) {
    supabaseUrl = url.trim().replaceAll(RegExp(r'\/+$'), '');
    supabaseAnonKey = anonKey.trim();
    debugPrint('[SupabaseService] Initialized with URL: $supabaseUrl');
  }

  static Map<String, String> get _headers => {
        'apikey': supabaseAnonKey,
        'Authorization': 'Bearer $supabaseAnonKey',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      };

  /// Find account by email from Supabase table 'accounts'
  static Future<Map<String, dynamic>?> findAccount(String email) async {
    if (!isConfigured) return null;

    final cleanEmail = email.trim().toLowerCase();
    final url = Uri.parse('$supabaseUrl/rest/v1/accounts?email=eq.$cleanEmail&select=*');

    try {
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          return Map<String, dynamic>.from(data.first);
        }
      } else {
        debugPrint('[Supabase] findAccount error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('[Supabase] Network exception finding account: $e');
    }
    return null;
  }

  /// Insert new account into Supabase 'accounts' table
  static Future<bool> insertAccount({
    required String uid,
    required String name,
    required String email,
    required String password,
  }) async {
    if (!isConfigured) return false;

    final cleanEmail = email.trim().toLowerCase();
    final url = Uri.parse('$supabaseUrl/rest/v1/accounts');

    final body = json.encode({
      'uid': uid,
      'name': name.trim(),
      'email': cleanEmail,
      'password': password.trim(),
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });

    try {
      final response = await http.post(url, headers: _headers, body: body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('[Supabase] Account created successfully for $cleanEmail');
        return true;
      } else {
        debugPrint('[Supabase] insertAccount error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('[Supabase] Network exception creating account: $e');
    }
    return false;
  }
}
