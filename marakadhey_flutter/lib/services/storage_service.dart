import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/opportunity.dart';

class StorageService {
  static const String _baseKey = '@marakadhey_opportunities_v2';
  static const String _keyNotificationsEnabled = '@marakadhey_pref_notifications';
  static const String _keyDefaultSnooze = '@marakadhey_pref_default_snooze';

  static String _getUserKey(String? userId) {
    if (userId == null || userId.isEmpty) {
      return '$_baseKey:_guest';
    }
    return '$_baseKey:$userId';
  }

  /// Load all opportunities for a specific user
  static Future<List<Opportunity>> getOpportunities({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getUserKey(userId);
      String? jsonStr = prefs.getString(key);

      // Fallback migration for legacy pre-v2 data if user is default/legacy
      if (jsonStr == null || jsonStr.isEmpty) {
        jsonStr = prefs.getString('@marakadhey_opportunities_v1');
      }

      if (jsonStr == null || jsonStr.isEmpty) {
        return [];
      }
      final List<dynamic> decoded = json.decode(jsonStr);
      return decoded.map((item) => Opportunity.fromMap(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Save all opportunities for a specific user
  static Future<bool> saveOpportunities(List<Opportunity> opportunities, {String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getUserKey(userId);
      final List<Map<String, dynamic>> mapped = opportunities.map((o) => o.toMap()).toList();
      final String jsonStr = json.encode(mapped);
      return await prefs.setString(key, jsonStr);
    } catch (e) {
      return false;
    }
  }

  /// Clear stored opportunities for a specific user
  static Future<bool> clearOpportunities({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getUserKey(userId);
      return await prefs.remove(key);
    } catch (e) {
      return false;
    }
  }

  /// Export backup string for specific user
  static Future<String> exportBackup({String? userId}) async {
    final opps = await getOpportunities(userId: userId);
    final Map<String, dynamic> data = {
      'app': 'Marakadhey Mobile',
      'version': '2.1.4',
      'userId': userId ?? 'guest',
      'exportDate': DateTime.now().toIso8601String(),
      'totalCount': opps.length,
      'opportunities': opps.map((o) => o.toMap()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Import from backup string for specific user (supports both wrapped Map and direct List)
  static Future<bool> importBackup(String jsonStr, {String? userId}) async {
    try {
      if (jsonStr.trim().isEmpty) return false;
      final dynamic decoded = json.decode(jsonStr.trim());
      List<dynamic>? rawList;

      if (decoded is Map && decoded.containsKey('opportunities')) {
        rawList = decoded['opportunities'] as List<dynamic>?;
      } else if (decoded is List) {
        rawList = decoded;
      }

      if (rawList != null && rawList.isNotEmpty) {
        final List<Opportunity> importedOpps = [];
        for (final item in rawList) {
          if (item is Map<String, dynamic>) {
            try {
              importedOpps.add(Opportunity.fromMap(item));
            } catch (e) {
              debugPrint('Skipping malformed opportunity during import: $e');
            }
          }
        }

        if (importedOpps.isNotEmpty) {
          await saveOpportunities(importedOpps, userId: userId);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Import backup error: $e');
      return false;
    }
  }

  static const String _keyMarkCompletedOnOpen = '@marakadhey_pref_mark_completed_on_open';
  static const String _keyHideCompletedFromInbox = '@marakadhey_pref_hide_completed_inbox';
  static const String _keyAutoDelete90Days = '@marakadhey_pref_auto_delete_90_days';

  /// Get notifications enabled preference
  static Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationsEnabled) ?? true;
  }

  /// Set notifications enabled preference
  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, enabled);
  }

  /// Get default snooze minutes preference
  static Future<int> getDefaultSnoozeMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyDefaultSnooze) ?? 60;
  }

  /// Set default snooze minutes preference
  static Future<void> setDefaultSnoozeMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDefaultSnooze, minutes);
  }

  /// 1. Mark reminder completed after opening link
  static Future<bool> getMarkCompletedOnOpen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyMarkCompletedOnOpen) ?? true;
  }

  static Future<void> setMarkCompletedOnOpen(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMarkCompletedOnOpen, val);
  }

  /// 2. Hide completed reminders from Inbox
  static Future<bool> getHideCompletedFromInbox() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHideCompletedFromInbox) ?? true;
  }

  static Future<void> setHideCompletedFromInbox(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHideCompletedFromInbox, val);
  }

  /// 3. Auto-delete completed reminders older than 90 days
  static Future<bool> getAutoDelete90Days() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoDelete90Days) ?? true;
  }

  static Future<void> setAutoDelete90Days(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoDelete90Days, val);
  }
}
