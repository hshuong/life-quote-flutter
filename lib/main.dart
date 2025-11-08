// lib/main.dart
// ✅ Updated with Notification Navigation Handling

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // ✅ ADD THIS
import 'providers/quote_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'services/ads_service.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';

// ✅ NEW: Global key for navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ========================================
  // ✅ INITIALIZE NOTIFICATION SERVICE
  // ========================================
  try {
    await NotificationService().initialize();
    debugPrint('✅ Notification service initialized');

    // ✅ NEW: Check if app was launched by tapping notification
    final notificationAppLaunchDetails = await FlutterLocalNotificationsPlugin()
        .getNotificationAppLaunchDetails();
    
    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      final payload = notificationAppLaunchDetails?.notificationResponse?.payload;
      debugPrint('🚀 App launched from notification with payload: $payload');
      
      if (payload != null) {
        // Store payload to be handled after app builds
        NotificationService().storeLaunchPayload(payload);
      }
    }
  } catch (e) {
    debugPrint('❌ Failed to initialize notification service: $e');
  }

  // ========================================
  // ✅ INITIALIZE BACKGROUND SERVICE
  // ========================================
  try {
    await BackgroundService().initialize();
    await BackgroundService().registerBootTask();
    debugPrint('✅ Background service initialized and boot task registered');
  } catch (e) {
    debugPrint('❌ Failed to initialize background service: $e');
  }

  // ========================================
  // ✅ RESCHEDULE NOTIFICATIONS IF ENABLED
  // ========================================
  try {
    final quoteProvider = QuoteProvider();
    await NotificationService().rescheduleIfEnabled(quoteProvider);
    debugPrint('✅ Notifications rescheduled if enabled');
  } catch (e) {
    debugPrint('❌ Failed to reschedule notifications: $e');
  }

  // ========================================
  // INITIALIZE ADS
  // ========================================
  await MobileAds.instance.updateRequestConfiguration(
    RequestConfiguration(
      testDeviceIds: ['93DC8935CA5C5D6E7F9B9C2D0C577EAA'],
    ),
  );
  await AdsService().initialize();
  
  // ========================================
  // LOCK ORIENTATION
  // ========================================
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => QuoteProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          // Update system UI overlay theo theme hiện tại
          final brightness = themeProvider.themeMode == ThemeMode.dark
              ? Brightness.light
              : Brightness.dark;
          
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: brightness,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarIconBrightness: brightness,
            ),
          );

          return MaterialApp(
            // ✅ Add navigator key for global navigation
            navigatorKey: navigatorKey,
            title: 'Life Quote',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}