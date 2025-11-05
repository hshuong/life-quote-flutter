// lib/widgets/theme_toggle_button.dart
// Widget để toggle theme nhanh (Light/Dark) ở AppBar

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final isSystem = themeProvider.isSystemMode;
        
        return IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return RotationTransition(
                turns: animation,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: Icon(
              themeProvider.currentThemeIcon,
              key: ValueKey(themeProvider.themeMode),
            ),
          ),
          tooltip: isSystem 
              ? 'System Theme'
              : (isDark ? 'Dark Theme' : 'Light Theme'),
          onPressed: () {
            // Toggle giữa Light và Dark (bỏ qua System)
            if (isDark || isSystem) {
              themeProvider.setThemeMode(ThemeMode.light);
            } else {
              themeProvider.setThemeMode(ThemeMode.dark);
            }
          },
        );
      },
    );
  }
}

// ============================================
// CÁCH SỬ DỤNG trong home_screen.dart:
// ============================================

// 1. Import widget:
// import '../widgets/theme_toggle_button.dart';

// 2. Thêm vào AppBar actions (thay thế hoặc thêm vào search icon):
/*
appBar: AppBar(
  title: _isSearching ? _buildSearchField() : _buildTitle(),
  centerTitle: true,
  elevation: 0,
  actions: [
    // Theme toggle button
    const ThemeToggleButton(),
    
    // Search button
    IconButton(
      icon: Icon(_isSearching ? Icons.close : Icons.search),
      onPressed: () {
        setState(() {
          _isSearching = !_isSearching;
          if (!_isSearching) {
            _searchController.clear();
            _searchResults = [];
          }
        });
      },
      iconSize: Responsive.fontSize(context, 24),
      tooltip: _isSearching ? 'Close Search' : 'Search',
    ),
  ],
),
*/