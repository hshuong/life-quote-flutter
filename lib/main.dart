// lib/main.dart
// ✅ Updated với ThemeProvider để hỗ trợ đổi theme

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/quote_provider.dart';
import 'providers/theme_provider.dart'; // ✅ Import ThemeProvider
import 'screens/home_screen.dart';
import 'theme.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'services/ads_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MobileAds.instance.updateRequestConfiguration(
    RequestConfiguration(
      testDeviceIds: ['93DC8935CA5C5D6E7F9B9C2D0C577EAA'],
    ),
  );
  await AdsService().initialize();
  
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
        ChangeNotifierProvider(create: (_) => ThemeProvider()), // ✅ Thêm ThemeProvider
      ],
      // ✅ Consumer để lắng nghe thay đổi theme
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          // ✅ Cập nhật system UI overlay theo theme hiện tại
          final brightness = themeProvider.themeMode == ThemeMode.dark
              ? Brightness.light // Light icons cho dark theme
              : Brightness.dark; // Dark icons cho light theme
          
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: brightness,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarIconBrightness: brightness,
            ),
          );

          return MaterialApp(
            title: 'Life Quote',
            debugShowCheckedModeBanner: false,
            
            // ✅ Sử dụng theme từ AppTheme
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            
            // ✅ Sử dụng themeMode từ ThemeProvider
            themeMode: themeProvider.themeMode,
            
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}