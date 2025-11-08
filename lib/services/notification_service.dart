// lib/services/notification_service.dart
// ✅ FIXED: Proper timezone handling for notifications

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart'; // ✅ ADD THIS
import '../providers/quote_provider.dart';
import '../models/quote.dart'; // ✅ ADD THIS
import '../screens/quote_detail_screen.dart'; // ✅ ADD THIS
import '../main.dart' show navigatorKey; // ✅ ADD THIS

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
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

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

  /// ✅ OPTIMIZED: Get device's local timezone with smart prioritization
Future<String> _getLocalTimeZoneName() async {
  try {
    final DateTime now = DateTime.now();
    final Duration offset = now.timeZoneOffset;
    final int offsetMinutes = offset.inMinutes;
    final int offsetHours = offset.inHours;
    final int offsetRemainder = offsetMinutes.abs() % 60;

    debugPrint(
      '🌍 Device timezone offset: ${offset.inHours}h ${offsetRemainder}m (${offsetMinutes}m total)',
    );

    // ✅ NEW: Find ALL matching timezones and prioritize by region
    final List<String> matchingTimezones = [];
    final List<String> allLocations = tz.timeZoneDatabase.locations.keys.toList();

    for (final locationName in allLocations) {
      try {
        final location = tz.getLocation(locationName);
        final tzNow = tz.TZDateTime.now(location);

        if (tzNow.timeZoneOffset.inMinutes == offsetMinutes) {
          matchingTimezones.add(locationName);
        }
      } catch (e) {
        continue;
      }
    }

    if (matchingTimezones.isNotEmpty) {
      debugPrint('🔍 Found ${matchingTimezones.length} matching timezones');
      
      // ✅ Prioritize timezones by region (most populous first)
      final prioritized = _prioritizeTimezone(matchingTimezones, offsetHours);
      debugPrint('✅ Selected timezone: $prioritized');
      return prioritized;
    }

    debugPrint(
      '⚠️ No exact match, using fallback mapping for offset: $offsetHours:${offsetRemainder.toString().padLeft(2, '0')}',
    );
    return _getFallbackTimezone(offsetHours, offsetRemainder);
  } catch (e) {
    debugPrint('❌ Error getting timezone: $e, using UTC');
    return 'UTC';
  }
}

/// ✅ NEW: Prioritize timezone based on population and region
String _prioritizeTimezone(List<String> timezones, int offsetHours) {
  // Define priority regions (major cities/countries)
  final priorityPrefixes = [
    'Asia/',      // Asia (highest population)
    'America/',   // Americas
    'Europe/',    // Europe
    'Africa/',    // Africa
    'Pacific/',   // Pacific
    'Australia/', // Australia/Oceania
    'Atlantic/',  // Atlantic
    'Indian/',    // Indian Ocean
    'Arctic/',    // Arctic (rare)
    'Antarctica/', // Antarctica (lowest priority)
  ];

  // Filter out "Etc/" timezones (generic/UTC offsets)
  final filtered = timezones.where((tz) => !tz.startsWith('Etc/')).toList();
  
  if (filtered.isEmpty) return timezones.first;

  // Try to find timezone matching priority order
  for (final prefix in priorityPrefixes) {
    final matching = filtered.where((tz) => tz.startsWith(prefix)).toList();
    if (matching.isNotEmpty) {
      // For each region, prefer major cities
      final preferred = _selectMajorCity(matching, offsetHours);
      return preferred;
    }
  }

  // Fallback to first filtered timezone
  return filtered.first;
}

/// ✅ NEW: Select major city timezone for each offset
String _selectMajorCity(List<String> timezones, int offsetHours) {
  // Map of preferred cities for each UTC offset
  final Map<int, List<String>> preferredCities = {
    -12: ['Pacific/Wallis'],
    -11: ['Pacific/Midway', 'Pacific/Pago_Pago'],
    -10: ['Pacific/Honolulu', 'Pacific/Tahiti'],
    -9: ['America/Anchorage', 'America/Juneau'],
    -8: ['America/Los_Angeles', 'America/Vancouver'],
    -7: ['America/Denver', 'America/Phoenix'],
    -6: ['America/Chicago', 'America/Mexico_City'],
    -5: ['America/New_York', 'America/Toronto'],
    -4: ['America/Halifax', 'America/Caracas'],
    -3: ['America/Sao_Paulo', 'America/Buenos_Aires'],
    -2: ['Atlantic/South_Georgia'],
    -1: ['Atlantic/Azores', 'Atlantic/Cape_Verde'],
    0: ['Europe/London', 'Africa/Lagos'],
    1: ['Europe/Paris', 'Europe/Berlin', 'Africa/Lagos'],
    2: ['Europe/Athens', 'Africa/Cairo', 'Africa/Johannesburg'],
    3: ['Europe/Moscow', 'Africa/Nairobi', 'Asia/Riyadh'],
    4: ['Asia/Dubai', 'Asia/Muscat'],
    5: ['Asia/Karachi', 'Asia/Tashkent'],
    6: ['Asia/Dhaka', 'Asia/Almaty'],
    7: ['Asia/Bangkok', 'Asia/Ho_Chi_Minh', 'Asia/Jakarta'], // Vietnam here
    8: ['Asia/Singapore', 'Asia/Hong_Kong', 'Asia/Shanghai'],
    9: ['Asia/Tokyo', 'Asia/Seoul'],
    10: ['Australia/Sydney', 'Australia/Melbourne'],
    11: ['Pacific/Guadalcanal', 'Pacific/Noumea'],
    12: ['Pacific/Auckland', 'Pacific/Fiji'],
    13: ['Pacific/Tongatapu', 'Pacific/Apia'],
    14: ['Pacific/Kiritimati'],
  };

  final preferred = preferredCities[offsetHours] ?? [];
  
  // Try to find preferred city in the list
  for (final city in preferred) {
    if (timezones.contains(city)) {
      return city;
    }
  }

  // Return first timezone as fallback
  return timezones.first;
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

  /// ✅ Handle notification tap with immediate navigation
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('🔔 ===== NOTIFICATION TAPPED =====');
    debugPrint('📱 Notification tapped: ${response.payload}');

    if (response.payload != null && response.payload!.isNotEmpty) {
      // Store for fallback
      _lastNotificationPayload = response.payload;
      debugPrint('✅ Stored notification payload for navigation');

      try {
        // Parse payload
        final data = jsonDecode(response.payload!);
        final quoteId = data['quoteId'] as int?;
        final text = data['text'] as String?;
        final author = data['author'] as String?;

        debugPrint('🔢 Quote ID: $quoteId');
        // ✅ FIX: Safe substring
        if (text != null) {
          final preview = text.length > 30
              ? '${text.substring(0, 30)}...'
              : text;
          debugPrint('📝 Text: $preview');
        }
        debugPrint('✍️ Author: $author');

        if (quoteId != null && text != null) {
          // Schedule navigation for next frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _performNavigation(quoteId, text, author);
          });
        } else {
          debugPrint(
            '❌ Missing required data: quoteId=$quoteId, text=${text != null}',
          );
        }
      } catch (e, stackTrace) {
        debugPrint('❌ Error parsing notification payload: $e');
        debugPrint('Stack: $stackTrace');
      }
    } else {
      debugPrint('⚠️ No payload received');
    }

    debugPrint('🔔 ================================');
  }

  /// ✅ Perform navigation to quote detail
  Future<void> _performNavigation(
    int quoteId,
    String text,
    String? author,
  ) async {
    debugPrint('🚀 Starting navigation for quote $quoteId');

    final navigator = navigatorKey.currentState;

    if (navigator == null) {
      debugPrint('❌ Navigator is null, cannot navigate');
      return;
    }

    final context = navigator.context;
    debugPrint('✅ Got context from navigator');

    try {
      // Create fallback quote first
      final fallbackQuote = Quote(
        id: quoteId,
        text: text,
        author: author,
        categoryId: 0,
        isFavorite: false,
      );

      // ✅ FIX: Use non-nullable type
      Quote quoteToShow = fallbackQuote;

      // Try to get from database
      try {
        final quoteProvider = Provider.of<QuoteProvider>(
          context,
          listen: false,
        );
        final dbQuote = await quoteProvider.getQuoteById(quoteId);
        if (dbQuote != null) {
          quoteToShow = dbQuote;
          debugPrint(
            '✅ Found quote in database with favorite status: ${dbQuote.isFavorite}',
          );
        } else {
          debugPrint(
            '⚠️ Quote not found in DB, using fallback data from notification',
          );
        }
      } catch (e) {
        debugPrint('⚠️ Error getting quote from DB: $e, using fallback');
      }

      // Navigate - now quoteToShow is guaranteed non-null
      debugPrint('🎯 Navigating to QuoteDetailScreen...');

      await navigator.push(
        MaterialPageRoute(
          builder: (_) => QuoteDetailScreen(
            quotes: [quoteToShow], // ✅ No error now
            initialIndex: 0,
          ),
        ),
      );

      debugPrint('✅ Navigation completed successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Navigation failed: $e');
      debugPrint('📍 Stack trace: $stackTrace');
    }
  }

  /// ✅ NEW: Store last notification payload
  String? _lastNotificationPayload;
  
  /// ✅ NEW: Store launch payload (when app is killed)
  String? _launchPayload;
  
  /// ✅ NEW: Store launch payload for later processing
  void storeLaunchPayload(String payload) {
    _launchPayload = payload;
    debugPrint('💾 Stored launch payload: $payload');
  }
  
  /// ✅ UPDATED: Get and clear last notification payload
  /// This now checks both tap payload and launch payload
  String? getAndClearLastPayload() {
    // Check launch payload first (when app was killed)
    if (_launchPayload != null) {
      final payload = _launchPayload;
      _launchPayload = null;
      debugPrint('📱 Retrieved launch payload: $payload');
      return payload;
    }
    
    // Then check tap payload (when app was in foreground/background)
    if (_lastNotificationPayload != null) {
      final payload = _lastNotificationPayload;
      _lastNotificationPayload = null;
      debugPrint('📱 Retrieved tap payload: $payload');
      return payload;
    }
    
    return null;
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

  // ✅ CRITICAL: Force re-initialize timezone before scheduling
  final String timeZoneName = await _getLocalTimeZoneName();
  tz.setLocalLocation(tz.getLocation(timeZoneName));
  debugPrint('🔄 Re-initialized timezone to: $timeZoneName');

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
      throw Exception(
        'Exact alarm permission is required for daily notifications',
      );
    }
  }

  // Get a random quote
  final quote = await quoteProvider.getRandomQuote();
  if (quote == null) {
    debugPrint('❌ No quote available for notification');
    throw Exception('No quote available');
  }

  // ✅ CREATE PAYLOAD - This is critical!
  final payload = jsonEncode({
    'quoteId': quote.id,
    'text': quote.text,
    'author': quote.author,
  });

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
  debugPrint(
    '🕐 User requested time: $hour:${minute.toString().padLeft(2, '0')}',
  );

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
      payload: payload, // ✅ CRITICAL: Add payload here!
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

  /// Show immediate test notification with navigation payload
  Future<void> showTestNotification(
    String quoteText, {
    int? quoteId,
    String? author,
  }) async {
    await initialize();

    // ✅ Create JSON payload for navigation
    final payload = quoteId != null
        ? jsonEncode({'quoteId': quoteId, 'text': quoteText, 'author': author})
        : null;

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
      payload: payload, // ✅ Add payload for navigation
    );

    debugPrint('✅ Test notification sent with payload: $payload');
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
    final pendingNotifications = await _notifications
        .pendingNotificationRequests();

    debugPrint('📋 Pending notifications: ${pendingNotifications.length}');
    for (var notification in pendingNotifications) {
      debugPrint('   ID: ${notification.id}, Title: ${notification.title}');
      debugPrint('   Body: ${notification.body}');
    }
  }
}
