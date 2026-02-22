import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // V2 UI Aesthetic Ovelhaul: Dark Navy & Neon palette
  static const Color primaryColor = Color(0xFF00E5FF); // Neon Cyan
  static const Color secondaryColor = Color(0xFF00B8D4); // Deep Cyan
  static const Color accentColor = Color(
    0xFF00E676,
  ); // Neon Green (Success/Accent)
  static const Color backgroundColor = Color(0xFF0A0E17); // Deep Navy/Black
  static const Color surfaceColor = Color(0xFF0F1423); // Dark surface/sidebar
  static const Color cardColor = Color(0xFF141A29); // Card background
  static const Color textColor = Color(0xFFF8FAFC); // Very light blue/gray
  static const Color mutedTextColor = Color(0xFF94A3B8); // Muted slate gray
  static const Color errorColor = Color(0xFFFF3D00); // Vibrant Red
  static const Color successColor = Color(0xFF00E676); // Bright Green
  static const Color warningColor = Color(0xFFFFB300); // Amber

  // Gradient colors for subtle glow effects (optimized for performance)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF00B8D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient shadowGradient = LinearGradient(
    colors: [Color(0xFF121A2F), Color(0xFF0A0E17)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient glowGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Colors.transparent],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: _colorScheme,
    textTheme: _textTheme,
    appBarTheme: _appBarTheme,
    cardTheme: _cardTheme,
    navigationRailTheme: _navigationRailTheme,
    drawerTheme: _drawerTheme,
    elevatedButtonTheme: _elevatedButtonTheme,
    outlinedButtonTheme: _outlinedButtonTheme,
    textButtonTheme: _textButtonTheme,
    inputDecorationTheme: _inputDecorationTheme,
    switchTheme: _switchTheme,
    dividerTheme: _dividerTheme,
    iconTheme: _iconTheme,
  );

  // --- Sub-Theme Definitions ---

  static const ColorScheme _colorScheme = ColorScheme.dark(
    primary: primaryColor,
    secondary: secondaryColor,
    tertiary: accentColor,
    surface: surfaceColor,
    surfaceContainerHighest: cardColor,
    error: errorColor,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: textColor,
    onError: Colors.white,
    outline: Color(0xFF374151),
  );

  static final TextTheme _textTheme = GoogleFonts.orbitronTextTheme(
        ThemeData.dark().textTheme,
      )
      .apply(bodyColor: textColor, displayColor: textColor)
      .copyWith(
        headlineLarge: GoogleFonts.orbitron(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 32,
          letterSpacing: 1.2,
        ),
        headlineMedium: GoogleFonts.orbitron(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 24,
          letterSpacing: 1.0,
        ),
        titleLarge: GoogleFonts.orbitron(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          letterSpacing: 0.8,
        ),
        bodyLarge: GoogleFonts.roboto(color: textColor, fontSize: 16),
        bodyMedium: GoogleFonts.roboto(color: textColor, fontSize: 14),
        bodySmall: GoogleFonts.roboto(color: mutedTextColor, fontSize: 12),
      );

  static final AppBarTheme _appBarTheme = AppBarTheme(
    backgroundColor: backgroundColor,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: GoogleFonts.orbitron(
      color: textColor,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.0,
    ),
    iconTheme: const IconThemeData(color: textColor),
  );

  static final CardThemeData _cardTheme = CardThemeData(
    color: cardColor,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: Colors.white.withAlpha(15), width: 1),
    ),
  );

  static final NavigationRailThemeData _navigationRailTheme =
      NavigationRailThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: primaryColor.withValues(alpha: 0.3),
        selectedIconTheme: const IconThemeData(color: primaryColor, size: 24),
        unselectedIconTheme: IconThemeData(color: mutedTextColor, size: 22),
        selectedLabelTextStyle: GoogleFonts.orbitron(
          color: primaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: GoogleFonts.orbitron(
          color: mutedTextColor,
          fontSize: 12,
        ),
      );

  static const DrawerThemeData _drawerTheme = DrawerThemeData(
    backgroundColor: surfaceColor,
    elevation: 4,
    shadowColor: Colors.black54,
  );

  static final ElevatedButtonThemeData _elevatedButtonTheme =
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: primaryColor.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.orbitron(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      );

  static final OutlinedButtonThemeData _outlinedButtonTheme =
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.orbitron(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      );

  static final TextButtonThemeData _textButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: accentColor,
      textStyle: GoogleFonts.orbitron(
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
    ),
  );

  static final InputDecorationTheme _inputDecorationTheme =
      InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor),
        ),
        labelStyle: GoogleFonts.roboto(color: mutedTextColor),
        hintStyle: GoogleFonts.roboto(color: mutedTextColor),
      );

  static final SwitchThemeData _switchTheme = SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return primaryColor;
      }
      return mutedTextColor;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return primaryColor.withValues(alpha: 0.3);
      }
      return cardColor;
    }),
  );

  static final DividerThemeData _dividerTheme = DividerThemeData(
    color: Colors.white.withAlpha(15),
    thickness: 1,
    space: 1,
  );

  static const IconThemeData _iconTheme = IconThemeData(
    color: textColor,
    size: 24,
  );

  // Custom box decorations for special effects
  static BoxDecoration get glowBoxDecoration => BoxDecoration(
    borderRadius: BorderRadius.circular(8),
    color: cardColor,
    border: Border.all(color: primaryColor.withValues(alpha: 0.5), width: 1),
    boxShadow: [
      BoxShadow(
        color: primaryColor.withValues(alpha: 0.15),
        blurRadius: 8,
        spreadRadius: 1,
      ),
    ],
  );

  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.white.withAlpha(15), width: 1),
    // Removed heavy drop shadows for better performance requested in V2
  );

  static BoxDecoration get primaryGradientDecoration => BoxDecoration(
    gradient: primaryGradient,
    borderRadius: BorderRadius.circular(6),
  );
}
