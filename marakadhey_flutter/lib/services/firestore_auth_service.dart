import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/firebase_config.dart';

class FirestoreAuthService {
  static const String projectId = FirebaseConfig.projectId;
  static const String apiKey = FirebaseConfig.apiKey;

  static String _docId(String email) =>
      email.trim().toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

  static String get _baseUrl =>
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/accounts';

  /// Query an account document from Firestore by email
  static Future<Map<String, dynamic>?> findAccount(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return null;

    final docKey = _docId(cleanEmail);
    final url = Uri.parse('$_baseUrl/$docKey?key=$apiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final fields = data['fields'] as Map<String, dynamic>?;
        if (fields != null) {
          final account = {
            'uid': fields['uid']?['stringValue'] ?? 'usr_$docKey',
            'name': fields['name']?['stringValue'] ?? cleanEmail.split('@')[0],
            'email': fields['email']?['stringValue'] ?? cleanEmail,
            'password': fields['password']?['stringValue'] ?? '',
            'photoUrl': fields['photoUrl']?['stringValue'],
          };
          debugPrint('[FirestoreAuth] Found account in Firestore for $cleanEmail');
          return account;
        }
      } else if (response.statusCode == 404) {
        debugPrint('[FirestoreAuth] Account not found in Firestore for $cleanEmail');
      } else {
        debugPrint('[FirestoreAuth] Error fetching account (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[FirestoreAuth] Network error checking Firestore: $e');
    }
    return null;
  }

  /// Store or update an account document in Firestore
  static Future<bool> saveAccount({
    required String uid,
    required String name,
    required String email,
    required String password,
    String? photoUrl,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = name.trim();
    final docKey = _docId(cleanEmail);
    final url = Uri.parse('$_baseUrl/$docKey?key=$apiKey');

    final body = json.encode({
      'fields': {
        'uid': {'stringValue': uid},
        'name': {'stringValue': cleanName},
        'email': {'stringValue': cleanEmail},
        'password': {'stringValue': password.trim()},
        'createdAt': {'stringValue': DateTime.now().toUtc().toIso8601String()},
        if (photoUrl != null) 'photoUrl': {'stringValue': photoUrl},
      }
    });

    try {
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('[FirestoreAuth] Account successfully saved to Firestore for $cleanEmail');
        return true;
      } else {
        debugPrint('[FirestoreAuth] Error saving account to Firestore (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[FirestoreAuth] Network error saving to Firestore: $e');
    }
    return false;
  }
}
