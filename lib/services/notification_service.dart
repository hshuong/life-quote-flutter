// lib/services/notification_service.dart
// ✅ FIXED: Added exact alarm permission handling for Android 12+

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/quote_provider.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  
  // Notification IDs
  static const int quoteOfTheDayId = 1;
  
  // SharedPreferences keys
  static const String _enabledKey = 'quote_notification_enabled';
  static const String _hourKey = 'quote_notification_hour';
  static const String _minuteKey = 'quote_notification_minute';

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Initialize timezone
    tz.initializeTimeZones();
    
    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    // Initialize with callback for notification tap
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    
    _isInitialized = true;
  }

  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// ✅ NEW: Check if exact alarms are permitted (Android 12+)
  Future<bool> canScheduleExactAlarms() async {
    if (await Permission.scheduleExactAlarm.isGranted) {
      return true;
    }
    return false;
  }

  /// ✅ NEW: Request exact alarm permission (Android 12+)
  /// This will open system settings where user must enable manually
  Future<bool> requestExactAlarmPermission() async {
    // Check if already granted
    if (await canScheduleExactAlarms()) {
      return true;
    }
    
    // Request permission - this opens system settings on Android 12+
    final status = await Permission.scheduleExactAlarm.request();
    
    if (status.isGranted) {
      debugPrint('✅ Exact alarm permission granted');
      return true;
    } else if (status.isPermanentlyDenied) {
      debugPrint('❌ Exact alarm permission permanently denied');
      // Open app settings
      await openAppSettings();
      return false;
    } else {
      debugPrint('❌ Exact alarm permission denied');
      return false;
    }
  }

  /// Request notification permission (especially for Android 13+)
  Future<bool> requestPermission() async {
    if (await Permission.notification.isGranted) {
      return true;
    }
    
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// ✅ UPDATED: Schedule daily quote notification with exact alarm check
  Future<void> scheduleDailyQuote({
    required int hour,
    required int minute,
    required QuoteProvider quoteProvider,
  }) async {
    await initialize();
    
    // ✅ Step 1: Request notification permission
    final hasNotificationPermission = await requestPermission();
    if (!hasNotificationPermission) {
      debugPrint('❌ Notification permission denied');
      throw Exception('Notification permission is required');
    }
    
    // ✅ Step 2: Check/Request exact alarm permission (Android 12+)
    final canScheduleExact = await canScheduleExactAlarms();
    if (!canScheduleExact) {
      debugPrint('⚠️ Exact alarm permission not granted, requesting...');
      final granted = await requestExactAlarmPermission();
      if (!granted) {
        throw Exception('Exact alarm permission is required for daily notifications');
      }
    }
    
    // Get a random quote
    final quote = await quoteProvider.getRandomQuote();
    if (quote == null) {
      debugPrint('❌ No quote available for notification');
      throw Exception('No quote available');
    }
    
    // Create notification details
    const androidDetails = AndroidNotificationDetails(
      'daily_quote_channel',
      'Daily Quote',
      channelDescription: 'Daily inspirational quotes',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''),
      enableVibration: true,
      playSound: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    // Calculate next scheduled time
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    
    // If the scheduled time is in the past, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    try {
      // ✅ Schedule the notification with exact timing
      await _notifications.zonedSchedule(
        quoteOfTheDayId,
        'Quote of the Day 💭',
        _truncateQuote(quote.text, 100),
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
        
      );
      
      // Save settings
      await _saveNotificationSettings(true, hour, minute);
      
      debugPrint('✅ Quote notification scheduled for $hour:$minute');
    } catch (e) {
      debugPrint('❌ Failed to schedule notification: $e');
      rethrow;
    }
  }

  /// Cancel daily quote notification
  Future<void> cancelDailyQuote() async {
    await _notifications.cancel(quoteOfTheDayId);
    await _saveNotificationSettings(false, 9, 0);
    debugPrint('🗑️ Quote notification cancelled');
  }

  /// Check if notification is enabled
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  /// Get notification time
  Future<TimeOfDay> getNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_hourKey) ?? 9;
    final minute = prefs.getInt(_minuteKey) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Save notification settings
  Future<void> _saveNotificationSettings(
    bool enabled,
    int hour,
    int minute,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    await prefs.setInt(_hourKey, hour);
    await prefs.setInt(_minuteKey, minute);
  }

  /// Show immediate test notification
  Future<void> showTestNotification(String quoteText) async {
    await initialize();
    
    const androidDetails = AndroidNotificationDetails(
      'daily_quote_channel',
      'Daily Quote',
      channelDescription: 'Daily inspirational quotes',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''),
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.show(
      0,
      'Quote of the Day 💭',
      _truncateQuote(quoteText, 100),
      notificationDetails,
    );
  }

  /// Truncate quote text for notification
  String _truncateQuote(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Reschedule notification (call this after boot or app update)
  Future<void> rescheduleIfEnabled(QuoteProvider quoteProvider) async {
    final enabled = await isEnabled();
    if (!enabled) return;
    
    final time = await getNotificationTime();
    
    try {
      await scheduleDailyQuote(
        hour: time.hour,
        minute: time.minute,
        quoteProvider: quoteProvider,
      );
    } catch (e) {
      debugPrint('⚠️ Failed to reschedule notification: $e');
    }
  }
}