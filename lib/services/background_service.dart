// lib/services/background_service.dart
// ✅ Service để reschedule notification sau khi restart app
// ✅ FIXED: Updated for latest workmanager version

import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import '../providers/quote_provider.dart';
import 'notification_service.dart';

/// Background task handler
/// Được gọi khi app restart hoặc device reboot
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('🔄 Background task started: $task');
    
    try {
      // Initialize notification service
      await NotificationService().initialize();
      
      // Create a temporary quote provider (without context)
      final quoteProvider = QuoteProvider();
      
      // Reschedule notification if enabled
      await NotificationService().rescheduleIfEnabled(quoteProvider);
      
      debugPrint('✅ Background task completed successfully');
      return Future.value(true);
    } catch (e) {
      debugPrint('❌ Background task failed: $e');
      return Future.value(false);
    }
  });
}

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  /// Initialize background service
  /// Call this in main.dart
  Future<void> initialize() async {
    try {
      // ✅ FIXED: Removed deprecated isInDebugMode parameter
      await Workmanager().initialize(
        callbackDispatcher,
      );
      
      debugPrint('✅ Background service initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize background service: $e');
    }
  }

  /// Register a task to reschedule notifications after boot
  Future<void> registerBootTask() async {
    try {
      // Register a one-time task that runs after boot
      await Workmanager().registerOneOffTask(
        'reschedule_notification_task',
        'rescheduleNotification',
        initialDelay: const Duration(seconds: 10), // Wait 10s after boot
        // ✅ FIXED: Updated Constraints syntax for new version
        constraints: Constraints(
          networkType: NetworkType.notRequired, // Changed from not_required
        ),
      );
      
      debugPrint('✅ Boot task registered');
    } catch (e) {
      debugPrint('❌ Failed to register boot task: $e');
    }
  }

  /// Cancel all background tasks
  Future<void> cancelAll() async {
    try {
      await Workmanager().cancelAll();
      debugPrint('🗑️ All background tasks cancelled');
    } catch (e) {
      debugPrint('❌ Failed to cancel tasks: $e');
    }
  }
}