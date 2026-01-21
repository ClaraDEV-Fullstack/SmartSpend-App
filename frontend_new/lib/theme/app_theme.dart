import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Define your color palette
  static const Color primaryPurple = Color(0xFF6A1B9A); // Deep Purple
  static const Color lightPurple = Color(0xFFAB47BC); // Lighter for dark mode
  static const Color darkPurple = Color(0xFF4A148C);

  static const Color deepGold = Color(0xFFD4AF37); // Deep Gold
  static const Color lightGold = Color(0xFFFFD54F); // Brighter for dark mode
  static const Color darkGold = Color(0xFFB8860B);

  // Surface colors - IMPROVED CONTRAST
  static const Color lightSurface = Color(0xFFF5F5F5);
  static const Color darkSurface = Color(0xFF1A1A1A); // Lighter than before
  static const Color darkCard = Color(0xFF2A2A2A); // Much lighter for visibility

  // ==================== LIGHT THEME ====================
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: primaryPurple,
        secondary: deepGold,
        tertiary: lightPurple,
        surface: Colors.white,
        background: Color(0xFFFAFAFA),
        error: Color(0xFFD32F2F),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF1A1A1A), // Dark text
        onBackground: Color(0xFF1A1A1A), // Dark text
        onError: Colors.white,
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1A1A1A),
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: Color(0xFF1A1A1A),
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: primaryPurple),
      ),

      // Card Theme - FIXED
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: primaryPurple.withOpacity(0.4),
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryPurple,
          side: BorderSide(color: primaryPurple, width: 2),
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryPurple,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: deepGold,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryPurple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        labelStyle: TextStyle(color: Colors.black54),
        hintStyle: TextStyle(color: Colors.black38),
      ),

      // Icon Theme
      iconTheme: IconThemeData(
        color: primaryPurple,
        size: 24,
      ),

      // Text Theme - EXPLICIT TEXT COLORS
      textTheme: TextTheme(
        displayLarge: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: Color(0xFF1A1A1A)),
        bodyMedium: TextStyle(color: Color(0xFF1A1A1A)),
        bodySmall: TextStyle(color: Color(0xFF424242)),
        labelLarge: TextStyle(color: Color(0xFF1A1A1A)),
        labelMedium: TextStyle(color: Color(0xFF424242)),
        labelSmall: TextStyle(color: Color(0xFF616161)),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade300,
        thickness: 1,
        space: 1,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryPurple,
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: lightSurface,
        selectedColor: primaryPurple,
        secondarySelectedColor: deepGold,
        labelStyle: TextStyle(color: Color(0xFF1A1A1A)),
        secondaryLabelStyle: TextStyle(color: Colors.white),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        textColor: Color(0xFF1A1A1A),
        iconColor: primaryPurple,
      ),

      // Scaffold Background
      scaffoldBackgroundColor: Color(0xFFFAFAFA),
    );
  }

  // ==================== DARK THEME (FIXED FOR VISIBILITY) ====================
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color Scheme - BETTER CONTRAST
      colorScheme: ColorScheme.dark(
        primary: lightPurple,
        secondary: lightGold,
        tertiary: deepGold,
        surface: darkCard, // Lighter surface
        background: darkSurface,
        error: Color(0xFFEF5350),
        onPrimary: Colors.white,
        onSecondary: Color(0xFF1A1A1A),
        onSurface: Color(0xFFE5E5E5), // Light text - HIGH CONTRAST
        onBackground: Color(0xFFE5E5E5), // Light text - HIGH CONTRAST
        onError: Colors.white,
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: darkSurface,
        foregroundColor: Color(0xFFE5E5E5), // Light text
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: Color(0xFFE5E5E5), // Light text
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: lightGold),
      ),

      // Card Theme - FIXED
      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: darkCard, // Lighter card color
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPurple,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: lightPurple.withOpacity(0.5),
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightGold,
          side: BorderSide(color: lightGold, width: 2),
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightGold,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: lightGold,
        foregroundColor: Color(0xFF1A1A1A),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.redAccent, width: 2),
        ),
        labelStyle: TextStyle(color: Color(0xFFB0B0B0)),
        hintStyle: TextStyle(color: Color(0xFF707070)),
      ),

      // Icon Theme
      iconTheme: IconThemeData(
        color: lightGold,
        size: 24,
      ),

      // Text Theme - EXPLICIT LIGHT TEXT COLORS FOR DARK MODE
      textTheme: TextTheme(
        displayLarge: TextStyle(color: Color(0xFFE5E5E5), fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: Color(0xFFE5E5E5), fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: Color(0xFFE5E5E5), fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: Color(0xFFE5E5E5), fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: Color(0xFFE5E5E5), fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: Color(0xFFE5E5E5), fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: Color(0xFFE5E5E5), fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: Color(0xFFE5E5E5), fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: Color(0xFFE5E5E5), fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: Color(0xFFE5E5E5)),
        bodyMedium: TextStyle(color: Color(0xFFE5E5E5)),
        bodySmall: TextStyle(color: Color(0xFFB0B0B0)),
        labelLarge: TextStyle(color: Color(0xFFE5E5E5)),
        labelMedium: TextStyle(color: Color(0xFFB0B0B0)),
        labelSmall: TextStyle(color: Color(0xFF909090)),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade700,
        thickness: 1,
        space: 1,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkCard,
        selectedItemColor: lightGold,
        unselectedItemColor: Colors.grey.shade500,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: darkCard,
        selectedColor: lightPurple,
        secondarySelectedColor: lightGold,
        labelStyle: TextStyle(color: Color(0xFFE5E5E5)),
        secondaryLabelStyle: TextStyle(color: Color(0xFF1A1A1A)),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        textColor: Color(0xFFE5E5E5),
        iconColor: lightGold,
      ),

      // Scaffold Background
      scaffoldBackgroundColor: darkSurface,
    );
  }

  // ==================== GRADIENT HELPERS ====================
  static LinearGradient get purpleGoldGradient => LinearGradient(
    colors: [primaryPurple, deepGold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get purpleGoldGradientDark => LinearGradient(
    colors: [lightPurple, lightGold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get purpleGradient => LinearGradient(
    colors: [darkPurple, lightPurple],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}