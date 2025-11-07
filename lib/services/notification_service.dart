// lib/services/notification_service.dart
// ✅ FIXED: Proper timezone handling for notifications

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

  /// ✅ FIXED: Initialize notification service with proper timezone
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // ✅ Initialize timezone database
    tz.initializeTimeZones();
    
    // ✅ CRITICAL FIX: Set local timezone based on device
    // This ensures scheduled times match user's expectation
    final String timeZoneName = await _getLocalTimeZoneName();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
    
    debugPrint('🌍 Timezone set to: $timeZoneName');
    
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
    debugPrint('✅ Notification service initialized');
  }

  /// ✅ GLOBAL: Get device's local timezone name for ALL countries
  Future<String> _getLocalTimeZoneName() async {
    try {
      // Get current DateTime with timezone info
      final DateTime now = DateTime.now();
      final Duration offset = now.timeZoneOffset;
      
      // Get offset in minutes for precise matching
      final int offsetMinutes = offset.inMinutes;
      final int offsetHours = offset.inHours;
      final int offsetRemainder = offsetMinutes.abs() % 60;
      
      debugPrint('🌍 Device timezone offset: ${offset.inHours}h ${offsetRemainder}m (${offsetMinutes}m total)');
      
      // Find matching timezone from timezone database
      // This searches through ALL available timezones
      final List<String> allLocations = tz.timeZoneDatabase.locations.keys.toList();
      
      // Try to find exact match based on current offset
      for (final locationName in allLocations) {
        try {
          final location = tz.getLocation(locationName);
          final tzNow = tz.TZDateTime.now(location);
          
          // Check if offset matches
          if (tzNow.timeZoneOffset.inMinutes == offsetMinutes) {
            debugPrint('✅ Matched timezone: $locationName (offset: ${tzNow.timeZoneOffset})');
            return locationName;
          }
        } catch (e) {
          // Skip invalid locations
          continue;
        }
      }
      
      // If no exact match found, use comprehensive fallback mapping
      debugPrint('⚠️ No exact match, using fallback mapping for offset: $offsetHours:${offsetRemainder.toString().padLeft(2, '0')}');
      return _getFallbackTimezone(offsetHours, offsetRemainder);
      
    } catch (e) {
      debugPrint('❌ Error getting timezone: $e, using UTC');
      return 'UTC';
    }
  }
  
  /// Fallback timezone mapping for all UTC offsets worldwide
  String _getFallbackTimezone(int hours, int minutes) {
    // Create offset key (e.g., "+7:0" or "-5:30")
    final String offsetKey = hours >= 0 
        ? '+$hours:$minutes' 
        : '$hours:$minutes';
    
    // Comprehensive timezone mapping for all world regions
    final Map<String, String> timezoneMap = {
      // UTC-12 to UTC-10 (Pacific)
      '-12:0': 'Pacific/Wallis',
      '-11:0': 'Pacific/Midway',
      '-10:0': 'Pacific/Honolulu',
      
      // UTC-9.5 to UTC-9 (Alaska, French Polynesia)
      '-9:30': 'Pacific/Marquesas',
      '-9:0': 'America/Anchorage',
      
      // UTC-8 (PST - US West Coast)
      '-8:0': 'America/Los_Angeles',
      
      // UTC-7 (MST - US Mountain)
      '-7:0': 'America/Denver',
      
      // UTC-6 (CST - US Central, Mexico)
      '-6:0': 'America/Chicago',
      
      // UTC-5 (EST - US East Coast, Colombia, Peru)
      '-5:0': 'America/New_York',
      
      // UTC-4 (Atlantic, Venezuela, Bolivia)
      '-4:0': 'America/Halifax',
      
      // UTC-3.5 (Newfoundland)
      '-3:30': 'America/St_Johns',
      
      // UTC-3 (Brazil, Argentina)
      '-3:0': 'America/Sao_Paulo',
      
      // UTC-2 (Mid-Atlantic)
      '-2:0': 'Atlantic/South_Georgia',
      
      // UTC-1 (Azores, Cape Verde)
      '-1:0': 'Atlantic/Azores',
      
      // UTC+0 (GMT, UK, Portugal, West Africa)
      '+0:0': 'Europe/London',
      
      // UTC+1 (CET - Central Europe, West Africa)
      '+1:0': 'Europe/Paris',
      
      // UTC+2 (EET - Eastern Europe, Egypt, South Africa)
      '+2:0': 'Europe/Athens',
      
      // UTC+3 (Moscow, East Africa, Saudi Arabia)
      '+3:0': 'Europe/Moscow',
      
      // UTC+3.5 (Iran)
      '+3:30': 'Asia/Tehran',
      
      // UTC+4 (UAE, Caucasus)
      '+4:0': 'Asia/Dubai',
      
      // UTC+4.5 (Afghanistan)
      '+4:30': 'Asia/Kabul',
      
      // UTC+5 (Pakistan, West Asia)
      '+5:0': 'Asia/Karachi',
      
      // UTC+5.5 (India, Sri Lanka)
      '+5:30': 'Asia/Kolkata',
      
      // UTC+5.75 (Nepal)
      '+5:45': 'Asia/Kathmandu',
      
      // UTC+6 (Bangladesh, Bhutan, Kazakhstan)
      '+6:0': 'Asia/Dhaka',
      
      // UTC+6.5 (Myanmar, Cocos Islands)
      '+6:30': 'Asia/Yangon',
      
      // UTC+7 (Thailand, Vietnam, Indonesia West)
      '+7:0': 'Asia/Bangkok',
      
      // UTC+8 (China, Singapore, Malaysia, Philippines, Australia West)
      '+8:0': 'Asia/Singapore',
      
      // UTC+8.75 (Australia Eucla)
      '+8:45': 'Australia/Eucla',
      
      // UTC+9 (Japan, Korea, Indonesia East)
      '+9:0': 'Asia/Tokyo',
      
      // UTC+9.5 (Australia Central)
      '+9:30': 'Australia/Darwin',
      
      // UTC+10 (Australia East, Papua New Guinea)
      '+10:0': 'Australia/Sydney',
      
      // UTC+10.5 (Australia Lord Howe)
      '+10:30': 'Australia/Lord_Howe',
      
      // UTC+11 (Solomon Islands, Vanuatu)
      '+11:0': 'Pacific/Guadalcanal',
      
      // UTC+12 (New Zealand, Fiji)
      '+12:0': 'Pacific/Auckland',
      
      // UTC+12.75 (Chatham Islands)
      '+12:45': 'Pacific/Chatham',
      
      // UTC+13 (Tonga, Samoa)
      '+13:0': 'Pacific/Tongatapu',
      
      // UTC+14 (Kiribati Line Islands)
      '+14:0': 'Pacific/Kiritimati',
    };
    
    // Return matched timezone or UTC as ultimate fallback
    final timezone = timezoneMap[offsetKey] ?? 'UTC';
    debugPrint('📍 Using fallback timezone: $timezone for offset $offsetKey');
    return timezone;
  }

  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Check if exact alarms are permitted (Android 12+)
  Future<bool> canScheduleExactAlarms() async {
    if (await Permission.scheduleExactAlarm.isGranted) {
      return true;
    }
    return false;
  }

  /// Request exact alarm permission (Android 12+)
  Future<bool> requestExactAlarmPermission() async {
    if (await canScheduleExactAlarms()) {
      return true;
    }
    
    final status = await Permission.scheduleExactAlarm.request();
    
    if (status.isGranted) {
      debugPrint('✅ Exact alarm permission granted');
      return true;
    } else if (status.isPermanentlyDenied) {
      debugPrint('❌ Exact alarm permission permanently denied');
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

  /// ✅ FIXED: Schedule daily quote notification with correct timezone
  Future<void> scheduleDailyQuote({
    required int hour,
    required int minute,
    required QuoteProvider quoteProvider,
  }) async {
    await initialize();
    
    // Step 1: Request notification permission
    final hasNotificationPermission = await requestPermission();
    if (!hasNotificationPermission) {
      debugPrint('❌ Notification permission denied');
      throw Exception('Notification permission is required');
    }
    
    // Step 2: Check/Request exact alarm permission (Android 12+)
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
    
    // ✅ FIXED: Calculate next scheduled time using LOCAL timezone
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    
    // Create scheduled date in LOCAL timezone
    tz.TZDateTime scheduledDate = tz.TZDateTime(
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
      debugPrint('⏭️ Scheduled time is in the past, moving to tomorrow');
    }
    
    // ✅ Debug logging to verify times
    debugPrint('📅 Current time: ${now.toString()}');
    debugPrint('⏰ Scheduled time: ${scheduledDate.toString()}');
    debugPrint('🌍 Timezone: ${tz.local.name}');
    debugPrint('🕐 User requested time: $hour:${minute.toString().padLeft(2, '0')}');
    
    try {
      // Schedule the notification with exact timing
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
      
      debugPrint('✅ Quote notification scheduled successfully');
      debugPrint('   Next notification: ${scheduledDate.toString()}');
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
    
    debugPrint('✅ Test notification sent');
  }

  /// Truncate quote text for notification
  String _truncateQuote(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Reschedule notification (call this after boot or app update)
  Future<void> rescheduleIfEnabled(QuoteProvider quoteProvider) async {
    final enabled = await isEnabled();
    if (!enabled) {
      debugPrint('ℹ️ Notifications not enabled, skipping reschedule');
      return;
    }
    
    final time = await getNotificationTime();
    
    try {
      await scheduleDailyQuote(
        hour: time.hour,
        minute: time.minute,
        quoteProvider: quoteProvider,
      );
      debugPrint('✅ Notifications rescheduled successfully');
    } catch (e) {
      debugPrint('⚠️ Failed to reschedule notification: $e');
    }
  }

  /// ✅ NEW: Get pending notifications for debugging
  Future<void> debugPendingNotifications() async {
    final pendingNotifications = 
        await _notifications.pendingNotificationRequests();
    
    debugPrint('📋 Pending notifications: ${pendingNotifications.length}');
    for (var notification in pendingNotifications) {
      debugPrint('   ID: ${notification.id}, Title: ${notification.title}');
      debugPrint('   Body: ${notification.body}');
    }
  }
}