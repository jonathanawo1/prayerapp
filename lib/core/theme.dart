import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const background = Color(0xFF0A1628);
  static const surface = Color(0xFF1A2740);
  static const surfaceAlt = Color(0xFF243352);
  static const border = Color(0xFF2E4169);
  static const borderDim = Color(0xFF1E2F4A);

  /// PrayerWalk orange — Strava-inspired
  static const primary = Color(0xFFFC4C02);
  static const primaryDark = Color(0xFFB33400);

  static const success = Color(0xFF22C55E);
  static const danger = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);

  static const textPrimary = Color(0xFFF0F6FF);
  static const textSecondary = Color(0xFF8BA3C7);
  static const textMuted = Color(0xFF4E6B94);
  static const liveRed = Color(0xFFEF4444);

  /// Deterministic per-user route colors for the community map.
  static const List<Color> routeColors = [
    Color(0xFF22C55E), // emerald
    Color(0xFF3B82F6), // blue
    Color(0xFFEC4899), // pink
    Color(0xFFF59E0B), // amber
    Color(0xFF8B5CF6), // violet
    Color(0xFF06B6D4), // cyan
    Color(0xFFF97316), // orange (own)
    Color(0xFF14B8A6), // teal
  ];

  static Color routeColorForUser(String userId) =>
      routeColors[userId.hashCode.abs() % routeColors.length];

  /// Returns the route color as a CSS hex string (for Mapbox expressions).
  static String routeHexForUser(String userId) {
    final c = routeColorForUser(userId);
    final argb = c.toARGB32();
    return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
  }
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.dmSansTextTheme(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      textTheme: textTheme,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        hintStyle: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 15),
        labelStyle:
            GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.dmSans(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withOpacity(0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primary);
          }
          return GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted);
        }),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceAlt,
        selectedColor: AppColors.primary.withOpacity(0.2),
        labelStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600),
        side: const BorderSide(color: AppColors.border),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}
