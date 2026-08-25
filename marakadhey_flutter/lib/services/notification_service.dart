import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/opportunity.dart' hide Priority;

class NotificationService {
  static const MethodChannel _alarmChannel = MethodChannel('com.marakadhey.app/alarms');
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'marakadhey_high_priority_v9';
  static const String channelName = 'Marakadhey Deadline Alarms';
  static const String channelDesc = 'Critical alarms and reminders for saved opportunities and deadlines';

  static Future<void> initialize() async {
    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      // Create Android Notification Channel with Max Importance
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDesc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      );

      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(channel);
    } catch (e) {
      debugPrint('Notification init error: $e');
    }
  }

  /// Request standard notification and alarm permissions on startup (without battery popup)
  static Future<bool> requestPermissions() async {
    try {
      final notifStatus = await Permission.notification.request();
      await Permission.scheduleExactAlarm.request();

      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();

      return notifStatus.isGranted;
    } catch (e) {
      debugPrint('Notification permission request error: $e');
      return false;
    }
  }

  /// Request battery optimization exemption only on explicit user request
  static Future<bool> requestBatteryOptimizationExemption() async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('Battery optimization request error: $e');
      return false;
    }
  }

  /// Check whether all required permissions are granted
  static Future<Map<String, bool>> checkPermissionsStatus() async {
    final notif = await Permission.notification.isGranted;
    final exactAlarm = await Permission.scheduleExactAlarm.isGranted;
    final battery = await Permission.ignoreBatteryOptimizations.isGranted;
    return {
      'notification': notif,
      'exactAlarm': exactAlarm,
      'batteryOptimized': battery,
    };
  }



  /// Stop any currently playing alarm immediately
  static Future<void> stopAlarm() async {
    try {
      await _alarmChannel.invokeMethod('stopAlarm');
    } catch (e) {
      debugPrint('Stop alarm error: $e');
    }
  }

  /// Schedule a notification using direct Native Android AlarmClock API
  static Future<void> scheduleOpportunityReminder(Opportunity opportunity) async {
    try {
      DateTime triggerTime = opportunity.deadline;
      if (opportunity.leadTimeMinutes > 0) {
        triggerTime = triggerTime.subtract(Duration(minutes: opportunity.leadTimeMinutes));
      }

      final Duration durationFromNow = triggerTime.difference(DateTime.now());
      if (durationFromNow.isNegative) {
        return; // Deadline is in the past
      }

      final int notifId = opportunity.id.hashCode.abs() % 100000;
      final int epochMs = triggerTime.millisecondsSinceEpoch;

      final String formattedDeadline = DateFormat('EEEE, MMM dd • hh:mm a').format(opportunity.deadline);
      final String richMessage = '🎯 Category: ${opportunity.category}\n'
          '⏰ Deadline: $formattedDeadline\n'
          '${opportunity.description != null && opportunity.description!.isNotEmpty ? "📝 Notes: ${opportunity.description}\n" : ""}'
          '⚡ Tap here to open and complete your application now!';

      // Single definitive call to Native Android setAlarmClock (0-1s latency, no Doze delay)
      await _alarmChannel.invokeMethod('scheduleNativeAlarm', {
        'id': notifId,
        'title': opportunity.title,
        'message': richMessage,
        'epochMs': epochMs,
        'category': opportunity.category,
        'url': opportunity.websiteUrl,
      });

      debugPrint('Scheduled native AlarmClock for ${opportunity.title} at epoch $epochMs');
    } catch (e) {
      debugPrint('Schedule reminder error: $e');
    }
  }

  /// Cancel notification for an opportunity
  static Future<void> cancelOpportunityReminder(Opportunity opportunity) async {
    try {
      final int notifId = opportunity.id.hashCode.abs() % 100000;
      await _alarmChannel.invokeMethod('cancelNativeAlarm', {'id': notifId});
      await _notificationsPlugin.cancel(notifId);
    } catch (e) {
      debugPrint('Cancel reminder error: $e');
    }
  }

  /// Reschedule all active pending opportunities
  static Future<void> rescheduleAll(List<Opportunity> opportunities) async {
    try {
      await _notificationsPlugin.cancelAll();
      for (final opp in opportunities) {
        if (opp.status == OpportunityStatus.pending ||
            opp.status == OpportunityStatus.inProgress) {
          await scheduleOpportunityReminder(opp);
        }
      }
    } catch (e) {
      debugPrint('Reschedule all error: $e');
    }
  }
}
