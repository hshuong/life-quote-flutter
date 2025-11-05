// lib/theme.dart
// Material Design 3 Theme with proper color roles
// Generated from Material Theme Builder with seed color: #006874

import 'package:flutter/material.dart';

class AppTheme {
  // ==========================================
  // LIGHT THEME COLOR SCHEME
  // ==========================================
  static const lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    
    // Primary colors - Main brand color (Teal)
    primary: Color(0xFF006874),           // Main actions, FAB, highlights
    onPrimary: Color(0xFFFFFFFF),         // Text/icons on primary
    primaryContainer: Color(0xFF97F0FF),  // Lighter variant for containers
    onPrimaryContainer: Color(0xFF001F24), // Text on primary container
    
    // Secondary colors - Complementary accent
    secondary: Color(0xFF4A6267),         // Secondary actions
    onSecondary: Color(0xFFFFFFFF),       // Text on secondary
    secondaryContainer: Color(0xFFCCE8EC), // Secondary containers
    onSecondaryContainer: Color(0xFF051F23), // Text on secondary container
    
    // Tertiary colors - Third accent color
    tertiary: Color(0xFF525E7D),          // Tertiary elements
    onTertiary: Color(0xFFFFFFFF),        // Text on tertiary
    tertiaryContainer: Color(0xFFDAE2FF), // Tertiary containers
    onTertiaryContainer: Color(0xFF0E1B37), // Text on tertiary container
    
    // Error colors
    error: Color(0xFFBA1A1A),             // Error states
    onError: Color(0xFFFFFFFF),           // Text on error
    errorContainer: Color(0xFFFFDAD6),    // Error containers
    onErrorContainer: Color(0xFF410002),  // Text on error container
    
    // Surface colors - Backgrounds
    surface: Color(0xFFFAFDFD),           // Default surface (cards, sheets)
    onSurface: Color(0xFF191C1D),         // Text on surface
    surfaceContainerLowest: Color(0xFFFFFFFF),  // Elevated surfaces
    surfaceContainerLow: Color(0xFFF0F4F4),     // Slightly elevated
    surfaceContainer: Color(0xFFEBEEEF),        // Standard elevation
    surfaceContainerHigh: Color(0xFFE5E9E9),    // Higher elevation
    surfaceContainerHighest: Color(0xFFDFE3E3), // Highest elevation
    onSurfaceVariant: Color(0xFF3F484A),  // Secondary text on surface
    
    // Outline colors - Borders and dividers
    outline: Color(0xFF6F797A),           // Standard borders
    outlineVariant: Color(0xFFBEC8CA),    // Lighter borders
    
    // Other colors
    shadow: Color(0xFF000000),            // Shadows
    scrim: Color(0xFF000000),             // Scrims (overlays)
    inverseSurface: Color(0xFF2E3132),    // Inverse surface
    onInverseSurface: Color(0xFFEFF1F1),  // Text on inverse surface
    inversePrimary: Color(0xFF4FD8EB),    // Primary color on dark bg
  );

  // ==========================================
  // DARK THEME COLOR SCHEME
  // ==========================================
  static const darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    
    primary: Color(0xFF4FD8EB),
    onPrimary: Color(0xFF00363D),
    primaryContainer: Color(0xFF004F58),
    onPrimaryContainer: Color(0xFF97F0FF),
    
    secondary: Color(0xFFB0CBCF),
    onSecondary: Color(0xFF1B3438),
    secondaryContainer: Color(0xFF324B4F),
    onSecondaryContainer: Color(0xFFCCE8EC),
    
    tertiary: Color(0xFFBAC6EA),
    onTertiary: Color(0xFF24304D),
    tertiaryContainer: Color(0xFF3B4664),
    onTertiaryContainer: Color(0xFFDAE2FF),
    
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    
    surface: Color(0xFF191C1D),
    onSurface: Color(0xFFE1E3E3),
    surfaceContainerLowest: Color(0xFF0E1415),
    surfaceContainerLow: Color(0xFF191C1D),
    surfaceContainer: Color(0xFF1D2021),
    surfaceContainerHigh: Color(0xFF282B2C),
    surfaceContainerHighest: Color(0xFF333537),
    onSurfaceVariant: Color(0xFFBFC8CA),
    
    outline: Color(0xFF899294),
    outlineVariant: Color(0xFF3F484A),
    
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE1E3E3),
    onInverseSurface: Color(0xFF2E3132),
    inversePrimary: Color(0xFF006874),
  );

  // ==========================================
  // LIGHT THEME DATA
  // ==========================================
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: lightColorScheme,
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        // ✅ Use surface for light app bar, not primary
        backgroundColor: lightColorScheme.surface,
        foregroundColor: lightColorScheme.onSurface,
        surfaceTintColor: lightColorScheme.surfaceTint,
        iconTheme: IconThemeData(
          color: lightColorScheme.onSurface,
          size: 24,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: lightColorScheme.onSurface,
          letterSpacing: 0.15,
        ),
      ),
      
      // Scaffold Background
      scaffoldBackgroundColor: lightColorScheme.surface,
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: 1,
        surfaceTintColor: lightColorScheme.surfaceTint,
        color: lightColorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // Text Theme
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 57,
          fontWeight: FontWeight.w400,
          color: lightColorScheme.onSurface,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 45,
          fontWeight: FontWeight.w400,
          color: lightColorScheme.onSurface,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: lightColorScheme.onSurface,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 32,
          fontWeight: FontWeight.w400,
          color: lightColorScheme.onSurface,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 28,
          fontWeight: FontWeight.w400,
          color: lightColorScheme.onSurface,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: lightColorScheme.onSurface,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: lightColorScheme.onSurface,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
          color: lightColorScheme.onSurface,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: lightColorScheme.onSurface,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          color: lightColorScheme.onSurface,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          color: lightColorScheme.onSurfaceVariant,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          color: lightColorScheme.onSurfaceVariant,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: lightColorScheme.onSurface,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: lightColorScheme.onSurface,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: lightColorScheme.onSurface,
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 1,
          backgroundColor: lightColorScheme.primary,
          foregroundColor: lightColorScheme.onPrimary,
          disabledBackgroundColor: lightColorScheme.onSurface.withValues(alpha:0.12),
          disabledForegroundColor: lightColorScheme.onSurface.withValues(alpha:0.38),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
      ),
      
      // Filled Button Theme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: lightColorScheme.primary,
          foregroundColor: lightColorScheme.onPrimary,
          disabledBackgroundColor: lightColorScheme.onSurface.withValues(alpha:0.12),
          disabledForegroundColor: lightColorScheme.onSurface.withValues(alpha:0.38),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightColorScheme.primary,
          side: BorderSide(color: lightColorScheme.outline),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightColorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      
      // Icon Button Theme
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: lightColorScheme.onSurfaceVariant,
          highlightColor: lightColorScheme.primary.withValues(alpha: 0.12),
        ),
      ),
      
      // FAB Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: lightColorScheme.primaryContainer,
        foregroundColor: lightColorScheme.onPrimaryContainer,
        elevation: 3,
        focusElevation: 4,
        hoverElevation: 4,
        highlightElevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // ✅ Bottom Navigation Bar Theme - UPDATED for Light Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 3,
        backgroundColor: lightColorScheme.surfaceContainer,
        selectedItemColor: lightColorScheme.primary, // Màu teal đậm - nổi bật
        unselectedItemColor: lightColorScheme.onSurfaceVariant.withValues(alpha: 0.6), // Xám mờ
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w600, // Bold hơn cho selected
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      
      // Navigation Bar Theme (M3 style)
      navigationBarTheme: NavigationBarThemeData(
        elevation: 3,
        backgroundColor: lightColorScheme.surfaceContainer,
        indicatorColor: lightColorScheme.secondaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: lightColorScheme.onSurface,
            );
          }
          return TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: lightColorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: lightColorScheme.onSecondaryContainer,
              size: 24,
            );
          }
          return IconThemeData(
            color: lightColorScheme.onSurfaceVariant,
            size: 24,
          );
        }),
      ),
      
      // Drawer Theme
      drawerTheme: DrawerThemeData(
        backgroundColor: lightColorScheme.surface,
        elevation: 1,
        surfaceTintColor: lightColorScheme.surfaceTint,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
      ),
      
      // List Tile Theme
      listTileTheme: ListTileThemeData(
        iconColor: lightColorScheme.onSurfaceVariant,
        textColor: lightColorScheme.onSurface,
        selectedColor: lightColorScheme.onSecondaryContainer,
        selectedTileColor: lightColorScheme.secondaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      
      // Divider Theme
      dividerTheme: DividerThemeData(
        color: lightColorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      
      // Icon Theme
      iconTheme: IconThemeData(
        color: lightColorScheme.onSurfaceVariant,
        size: 24,
      ),
      
      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightColorScheme.inverseSurface,
        contentTextStyle: TextStyle(
          fontFamily: 'Poppins',
          color: lightColorScheme.onInverseSurface,
          fontSize: 14,
        ),
        actionTextColor: lightColorScheme.inversePrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: lightColorScheme.surfaceContainerHigh,
        surfaceTintColor: lightColorScheme.surfaceTint,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: lightColorScheme.onSurface,
        ),
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: lightColorScheme.surfaceContainerLow,
        deleteIconColor: lightColorScheme.onSurfaceVariant,
        disabledColor: lightColorScheme.onSurface.withValues(alpha: 0.12),
        selectedColor: lightColorScheme.secondaryContainer,
        secondarySelectedColor: lightColorScheme.secondaryContainer,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        labelStyle: TextStyle(
          fontFamily: 'Poppins',
          color: lightColorScheme.onSurfaceVariant,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: 'Poppins',
          color: lightColorScheme.onSecondaryContainer,
        ),
        brightness: Brightness.light,
      ),
    );
  }

  // ==========================================
  // DARK THEME DATA
  // ==========================================
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme,
      
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: darkColorScheme.surface,
        foregroundColor: darkColorScheme.onSurface,
        surfaceTintColor: darkColorScheme.surfaceTint,
        iconTheme: IconThemeData(
          color: darkColorScheme.onSurface,
          size: 24,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: darkColorScheme.onSurface,
          letterSpacing: 0.15,
        ),
      ),
      
      scaffoldBackgroundColor: darkColorScheme.surface,
      
      cardTheme: CardThemeData(
        elevation: 1,
        surfaceTintColor: darkColorScheme.surfaceTint,
        color: darkColorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      textTheme: ThemeData.dark().textTheme.apply(
        fontFamily: 'Poppins',
        bodyColor: darkColorScheme.onSurface,
        displayColor: darkColorScheme.onSurface,
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 1,
          backgroundColor: darkColorScheme.primary,
          foregroundColor: darkColorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      
      // ✅ Bottom Navigation Bar Theme - UPDATED for Dark Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 3,
        backgroundColor: darkColorScheme.surfaceContainer,
        selectedItemColor: darkColorScheme.primary, // Màu cyan sáng #4FD8EB - rất nổi bật
        unselectedItemColor: darkColorScheme.onSurfaceVariant.withValues(alpha: 0.5), // Xám mờ hơn
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w600, // Bold hơn
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      
      navigationBarTheme: NavigationBarThemeData(
        elevation: 3,
        backgroundColor: darkColorScheme.surfaceContainer,
        indicatorColor: darkColorScheme.secondaryContainer,
      ),
      
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: darkColorScheme.primaryContainer,
        foregroundColor: darkColorScheme.onPrimaryContainer,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      drawerTheme: DrawerThemeData(
        backgroundColor: darkColorScheme.surface,
        elevation: 1,
        surfaceTintColor: darkColorScheme.surfaceTint,
      ),
      
      listTileTheme: ListTileThemeData(
        iconColor: darkColorScheme.onSurfaceVariant,
        textColor: darkColorScheme.onSurface,
        selectedColor: darkColorScheme.onSecondaryContainer,
        selectedTileColor: darkColorScheme.secondaryContainer,
      ),
      
      dividerTheme: DividerThemeData(
        color: darkColorScheme.outlineVariant,
        thickness: 1,
      ),
      
      iconTheme: IconThemeData(
        color: darkColorScheme.onSurfaceVariant,
        size: 24,
      ),
      
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkColorScheme.inverseSurface,
        contentTextStyle: TextStyle(
          fontFamily: 'Poppins',
          color: darkColorScheme.onInverseSurface,
          fontSize: 14,
        ),
        actionTextColor: darkColorScheme.inversePrimary,
      ),
    );
  }
}