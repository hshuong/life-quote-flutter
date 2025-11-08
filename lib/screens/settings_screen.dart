// lib/screens/quote_of_day_settings_screen.dart
// ✅ FIXED: Proper async context handling

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../providers/quote_provider.dart';
import '../utils/responsive.dart';
import 'package:permission_handler/permission_handler.dart';

class QuoteOfDaySettingsScreen extends StatefulWidget {
  const QuoteOfDaySettingsScreen({super.key});

  @override
  State<QuoteOfDaySettingsScreen> createState() => _QuoteOfDaySettingsScreenState();
}

class _QuoteOfDaySettingsScreenState extends State<QuoteOfDaySettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  
  bool _isEnabled = false;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    final enabled = await _notificationService.isEnabled();
    final time = await _notificationService.getNotificationTime();
    
    if (mounted) {
      setState(() {
        _isEnabled = enabled;
        _selectedTime = time;
        _isLoading = false;
      });
    }
  }

  /// ✅ FIXED: Check mounted before using context
  Future<void> _showPermissionDialog(String title, String message) async {
    if (!mounted) return;
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// ✅ FIXED: Get provider before async operations
  Future<void> _toggleNotification(bool value) async {
    if (value) {
      // ✅ Get provider BEFORE any async operation
      final quoteProvider = context.read<QuoteProvider>();
      
      // Try to enable notification
      try {
        await _notificationService.scheduleDailyQuote(
          hour: _selectedTime.hour,
          minute: _selectedTime.minute,
          quoteProvider: quoteProvider,
        );
        
        if (!mounted) return;
        
        setState(() => _isEnabled = true);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Daily quote enabled at ${_selectedTime.format(context)}',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        
        setState(() => _isEnabled = false);
        
        final errorMessage = e.toString();
        
        if (errorMessage.contains('Exact alarm permission')) {
          // Exact alarm permission needed
          await _showPermissionDialog(
            'Permission Required',
            'To receive daily quotes at exact times, you need to enable "Alarms & reminders" permission in your device settings.\n\n'
            'Steps:\n'
            '1. Tap "Open Settings"\n'
            '2. Find "Alarms & reminders"\n'
            '3. Enable the permission\n'
            '4. Return to the app',
          );
        } else if (errorMessage.contains('Notification permission')) {
          // Notification permission needed
          await _showPermissionDialog(
            'Notification Permission Required',
            'Please enable notification permission to receive daily quotes.',
          );
        } else {
          // Other errors
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Failed to enable: ${e.toString()}'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      }
    } else {
      // Disable notification
      await _notificationService.cancelDailyQuote();
      
      if (!mounted) return;
      
      setState(() => _isEnabled = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daily quote disabled'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _selectTime() async {
    if (!mounted) return;
    
    final colorScheme = Theme.of(context).colorScheme;
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: colorScheme.surface,
              dialHandColor: colorScheme.primary,
              dialBackgroundColor: colorScheme.surfaceContainerHighest,
              hourMinuteTextColor: colorScheme.onSurface,
              dayPeriodTextColor: colorScheme.onSurfaceVariant,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (!mounted) return;
    
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
      
      // If notification is enabled, reschedule with new time
      if (_isEnabled) {
        // ✅ Get provider BEFORE async operation
        final quoteProvider = context.read<QuoteProvider>();
        
        try {
          await _notificationService.scheduleDailyQuote(
            hour: picked.hour,
            minute: picked.minute,
            quoteProvider: quoteProvider,
          );
          
          if (!mounted) return;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Time updated to ${picked.format(context)}',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } catch (e) {
          if (!mounted) return;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Failed to update time: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _testNotification() async {
  // ✅ Get provider BEFORE async operation
  final quoteProvider = context.read<QuoteProvider>();
  final quote = await quoteProvider.getRandomQuote();
  
  if (!mounted) return;
  
  if (quote != null) {
    // ✅ Pass full quote data including ID and author
    await _notificationService.showTestNotification(
      quote.text,
      quoteId: quote.id,
      author: quote.author,
    );
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔔 Test notification sent! Tap it to view the quote.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Quote of the Day'),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header Section
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(Responsive.padding(context, 24)),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primaryContainer,
                          colorScheme.secondaryContainer,
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.notifications_active,
                          size: Responsive.fontSize(context, 48),
                          color: colorScheme.onPrimaryContainer,
                        ),
                        SizedBox(height: Responsive.padding(context, 12)),
                        Text(
                          'Daily Inspiration',
                          style: textTheme.headlineMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: Responsive.padding(context, 8)),
                        Text(
                          'Receive a motivational quote every day',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: Responsive.padding(context, 8)),
                  
                  // Settings Cards
                  Padding(
                    padding: EdgeInsets.all(Responsive.padding(context, 16)),
                    child: Column(
                      children: [
                        // Enable/Disable Switch
                        Card(
                          elevation: 0,
                          color: colorScheme.surfaceContainerLow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: SwitchListTile(
                            value: _isEnabled,
                            onChanged: _toggleNotification,
                            title: Text(
                              'Daily Quote Notification',
                              style: textTheme.titleLarge?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              _isEnabled ? 'Enabled' : 'Disabled',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            secondary: Container(
                              padding: EdgeInsets.all(Responsive.padding(context, 8)),
                              decoration: BoxDecoration(
                                color: _isEnabled 
                                    ? colorScheme.primaryContainer 
                                    : colorScheme.surfaceContainerHighest,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isEnabled ? Icons.notifications_active : Icons.notifications_off,
                                color: _isEnabled 
                                    ? colorScheme.onPrimaryContainer 
                                    : colorScheme.onSurfaceVariant,
                                size: Responsive.fontSize(context, 24),
                              ),
                            ),
                            activeThumbColor: colorScheme.primary,
                          ),
                        ),
                        
                        SizedBox(height: Responsive.padding(context, 12)),
                        
                        // Time Picker
                        Card(
                          elevation: 0,
                          color: colorScheme.surfaceContainerLow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: Responsive.padding(context, 16),
                              vertical: Responsive.padding(context, 8),
                            ),
                            leading: Container(
                              padding: EdgeInsets.all(Responsive.padding(context, 8)),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.access_time,
                                color: colorScheme.onSecondaryContainer,
                                size: Responsive.fontSize(context, 24),
                              ),
                            ),
                            title: Text(
                              'Notification Time',
                              style: textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              _selectedTime.format(context),
                              style: textTheme.titleLarge?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            onTap: _selectTime,
                          ),
                        ),
                        
                        SizedBox(height: Responsive.padding(context, 24)),
                        
                        // Test Notification Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _testNotification,
                            icon: const Icon(Icons.send),
                            label: const Text('Test Notification'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.all(Responsive.padding(context, 16)),
                              side: BorderSide(
                                color: colorScheme.outline,
                                width: 1.5,
                              ),
                              foregroundColor: colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        
                        SizedBox(height: Responsive.padding(context, 24)),
                        
                        // Info Section
                        Container(
                          padding: EdgeInsets.all(Responsive.padding(context, 20)),
                          decoration: BoxDecoration(
                            color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.outline.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: Responsive.fontSize(context, 22),
                                    color: colorScheme.onTertiaryContainer,
                                  ),
                                  SizedBox(width: Responsive.padding(context, 8)),
                                  Text(
                                    'How it works',
                                    style: textTheme.titleMedium?.copyWith(
                                      color: colorScheme.onTertiaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: Responsive.padding(context, 16)),
                              _buildInfoItem(
                                context,
                                Icons.check_circle_outline,
                                'You will receive a random inspirational quote at your chosen time',
                              ),
                              SizedBox(height: Responsive.padding(context, 12)),
                              _buildInfoItem(
                                context,
                                Icons.phone_android,
                                'Notifications work even when the app is closed',
                              ),
                              SizedBox(height: Responsive.padding(context, 12)),
                              _buildInfoItem(
                                context,
                                Icons.schedule,
                                'You can change the time anytime',
                              ),
                              SizedBox(height: Responsive.padding(context, 12)),
                              _buildInfoItem(
                                context,
                                Icons.settings,
                                'Make sure "Alarms & reminders" permission is enabled in your device settings (required for Android 12+)',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: Responsive.fontSize(context, 20),
          color: colorScheme.onTertiaryContainer.withValues(alpha: 0.8),
        ),
        SizedBox(width: Responsive.padding(context, 12)),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onTertiaryContainer,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}