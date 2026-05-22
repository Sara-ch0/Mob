import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Handles scheduling and cancellation of daily Quran listening reminders.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _channelId   = 'quran_daily_reminder';
  static const _channelName = 'Quran Daily Reminder';
  static const _notifId     = 42;

  static String get _kEnabled => 'notif_enabled_${FirebaseAuth.instance.currentUser?.uid ?? 'guest'}';
  static String get _kHour    => 'notif_hour_${FirebaseAuth.instance.currentUser?.uid ?? 'guest'}';
  static String get _kMinute  => 'notif_minute_${FirebaseAuth.instance.currentUser?.uid ?? 'guest'}';

  // ── Initialisation ────────────────────────────────────────────────────────
  static Future<void> init() async {
    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);

    // Restore previously scheduled notification after app restart
    await restoreIfEnabled();
  }

  // ── Schedule daily reminder ───────────────────────────────────────────────
  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await _plugin.cancelAll();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, true);
    await prefs.setInt(_kHour,   hour);
    await prefs.setInt(_kMinute, minute);

    await _plugin.zonedSchedule(
      _notifId,
      '📖 Rappel Coran',
      "N'oubliez pas votre écoute quotidienne du Coran.",
      _nextInstanceOf(hour, minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Rappel quotidien d\'écoute du Coran',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: const BigTextStyleInformation(''),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  // ── Cancel ────────────────────────────────────────────────────────────────
  static Future<void> cancel() async {
    await _plugin.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, false);
  }

  // ── Clear (Logout) ────────────────────────────────────────────────────────
  static Future<void> clear() async {
    await _plugin.cancelAll();
  }

  // ── Getters ───────────────────────────────────────────────────────────────
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kEnabled) ?? false;
  }

  static Future<TimeOfDay> getSavedTime() async {
    final prefs = await SharedPreferences.getInstance();
    return TimeOfDay(
      hour:   prefs.getInt(_kHour)   ?? 8,
      minute: prefs.getInt(_kMinute) ?? 0,
    );
  }

  static Future<void> restoreIfEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kEnabled) ?? false) {
      await scheduleDailyReminder(
        hour:   prefs.getInt(_kHour)   ?? 8,
        minute: prefs.getInt(_kMinute) ?? 0,
      );
    }
  }
}
