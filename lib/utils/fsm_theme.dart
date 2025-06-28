// lib/utils/fsm_theme.dart - FSM Theme Constants

import 'package:flutter/material.dart';

class FSMTheme {
  // Primary Colors
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color lightBlue = Color(0xFF1976D2);
  static const Color darkBlue = Color(0xFF0D47A1);
  
  // Background Colors
  static const Color backgroundColor = Color(0xFFF5F6FA);
  static const Color cardBackground = Colors.white;
  static const Color surfaceColor = Color(0xFFFAFBFC);
  
  // Text Colors
  static const Color primaryText = Color(0xFF2E3A59);
  static const Color secondaryText = Color(0xFF6B7280);
  static const Color hintText = Color(0xFF9CA3AF);
  
  // Status Colors
  static const Map<String, Color> statusColors = {
    'new': Color(0xFF2196F3),
    'autopsy_scheduled': Color(0xFFFF9800),
    'autopsy_in_progress': Color(0xFFFFC107),
    'autopsy_completed': Color(0xFF4CAF50),
    'technical_check_pending': Color(0xFF9C27B0),
    'technical_check_rejected': Color(0xFFF44336),
    'technical_check_approved': Color(0xFF4CAF50),
    'work_orders_created': Color(0xFF3F51B5),
    'job_completed': Color(0xFF4CAF50),
    'job_cancelled': Color(0xFF9E9E9E),
  };
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, lightBlue],
  );
  
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryBlue, lightBlue],
  );
  
  // Shadows
  static final List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];
  
  static final List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];
  
  // Border Radius
  static const double smallRadius = 8.0;
  static const double mediumRadius = 12.0;
  static const double largeRadius = 16.0;
  static const double extraLargeRadius = 20.0;
  
  // Spacing
  static const double smallSpacing = 8.0;
  static const double mediumSpacing = 16.0;
  static const double largeSpacing = 24.0;
  static const double extraLargeSpacing = 32.0;
  
  // Typography
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: primaryText,
    height: 1.2,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: primaryText,
    height: 1.3,
  );
  
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: primaryText,
    height: 1.3,
  );
  
  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: primaryText,
    height: 1.4,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: primaryText,
    height: 1.4,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: primaryText,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: primaryText,
    height: 1.5,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: secondaryText,
    height: 1.4,
  );
  
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: primaryText,
    height: 1.3,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: secondaryText,
    height: 1.3,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: hintText,
    height: 1.3,
  );
  
  // Helper Methods
  static Color getStatusColor(String? status) {
    return statusColors[status] ?? statusColors['job_cancelled']!;
  }
  
  static BoxDecoration cardDecoration({
    Color? color,
    List<BoxShadow>? boxShadow,
    double? borderRadius,
  }) {
    return BoxDecoration(
      color: color ?? cardBackground,
      borderRadius: BorderRadius.circular(borderRadius ?? mediumRadius),
      boxShadow: boxShadow ?? cardShadow,
    );
  }
  
  static BoxDecoration statusBadgeDecoration(String? status) {
    final color = getStatusColor(status);
    return BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(extraLargeRadius),
      border: Border.all(color: color, width: 1),
    );
  }
  
  static InputDecoration searchInputDecoration({
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText ?? 'Search...',
      hintStyle: TextStyle(color: FSMTheme.hintText),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(mediumRadius),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(mediumRadius),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      filled: true,
      fillColor: surfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
  
  static ButtonStyle primaryButtonStyle({
    Color? backgroundColor,
    Color? foregroundColor,
    EdgeInsets? padding,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? primaryBlue,
      foregroundColor: foregroundColor ?? Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(mediumRadius),
      ),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    );
  }
  
  static ButtonStyle secondaryButtonStyle({
    Color? backgroundColor,
    Color? foregroundColor,
    EdgeInsets? padding,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? Colors.white,
      foregroundColor: foregroundColor ?? primaryBlue,
      elevation: 0,
      shadowColor: Colors.transparent,
      side: const BorderSide(color: primaryBlue, width: 1.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(mediumRadius),
      ),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    );
  }
  
  // Theme Data
  static ThemeData get themeData {
    return ThemeData(
      primarySwatch: Colors.blue,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: 'Inter', // Make sure to add Inter font to your pubspec.yaml
      
      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(mediumRadius),
        ),
      ),
      
      // Input Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(mediumRadius),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(mediumRadius),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      
      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: primaryButtonStyle(),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: secondaryButtonStyle(),
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: primaryText,
        size: 24,
      ),
      
      // Divider Theme
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
        space: 1,
      ),
      
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: lightBlue,
        surface: cardBackground,
        background: backgroundColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: primaryText,
        onBackground: primaryText,
      ),
    );
  }
}