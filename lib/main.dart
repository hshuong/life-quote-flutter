// lib/main.dart
// Updated to use Material Design 3 theme from separate theme.dart file

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/quote_provider.dart';
import 'screens/home_screen.dart';
import 'theme.dart'; // ✅ Import theme file

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

  // ✅ Set system UI based on theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // Dark icons for light theme
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => QuoteProvider()),
      ],
      child: MaterialApp(
        title: 'Life Quotes',
        debugShowCheckedModeBanner: false,
        
        // ✅ Use theme from AppTheme class
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        
        // ✅ You can change this to ThemeMode.dark or ThemeMode.system
        themeMode: ThemeMode.light,
        
        home: const HomeScreen(),
      ),
    );
  }
}