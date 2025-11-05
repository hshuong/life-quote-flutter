// lib/screens/theme_settings_screen.dart
// Màn hình để người dùng chọn theme (Light/Dark/System)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/responsive.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Theme Settings'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.maxContentWidth(context),
          ),
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return ListView(
                padding: EdgeInsets.all(Responsive.padding(context, 16)),
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: Responsive.padding(context, 16),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(Responsive.padding(context, 20)),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            themeProvider.currentThemeIcon,
                            size: Responsive.fontSize(context, 48),
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        SizedBox(height: Responsive.padding(context, 16)),
                        Text(
                          'Choose Your Theme',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: Responsive.padding(context, 8)),
                        Text(
                          'Select the theme that suits you best',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: Responsive.padding(context, 8)),

                  // Light Theme Option
                  _buildThemeOption(
                    context: context,
                    themeMode: ThemeMode.light,
                    title: 'Light Theme',
                    description: 'Bright and clear interface',
                    icon: Icons.light_mode,
                    isSelected: themeProvider.themeMode == ThemeMode.light,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                  ),

                  SizedBox(height: Responsive.padding(context, 12)),

                  // Dark Theme Option
                  _buildThemeOption(
                    context: context,
                    themeMode: ThemeMode.dark,
                    title: 'Dark Theme',
                    description: 'Easy on the eyes at night',
                    icon: Icons.dark_mode,
                    isSelected: themeProvider.themeMode == ThemeMode.dark,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                  ),

                  SizedBox(height: Responsive.padding(context, 12)),

                  // System Theme Option
                  _buildThemeOption(
                    context: context,
                    themeMode: ThemeMode.system,
                    title: 'System Default',
                    description: 'Follow system settings',
                    icon: Icons.brightness_auto,
                    isSelected: themeProvider.themeMode == ThemeMode.system,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                  ),

                  SizedBox(height: Responsive.padding(context, 32)),

                  // Info Card
                  Container(
                    padding: EdgeInsets.all(Responsive.padding(context, 16)),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer.withValues(alpha:0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha:0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: colorScheme.onSecondaryContainer,
                          size: Responsive.fontSize(context, 24),
                        ),
                        SizedBox(width: Responsive.padding(context, 12)),
                        Expanded(
                          child: Text(
                            'Your theme preference will be saved and applied across all screens.',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required ThemeMode themeMode,
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.all(Responsive.padding(context, 16)),
            decoration: BoxDecoration(
              color: isSelected 
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected 
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha:0.2),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha:0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ] : [],
            ),
            child: Row(
              children: [
                // Icon container
                Container(
                  padding: EdgeInsets.all(Responsive.padding(context, 12)),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected 
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                    size: Responsive.fontSize(context, 28),
                  ),
                ),

                SizedBox(width: Responsive.padding(context, 16)),

                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected 
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: Responsive.padding(context, 4)),
                      Text(
                        description,
                        style: textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? colorScheme.onPrimaryContainer.withValues(alpha:0.8)
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Check icon
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: colorScheme.primary,
                    size: Responsive.fontSize(context, 28),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}