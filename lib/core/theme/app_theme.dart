import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const paper = Color(0xFFF5F4F0);
  static const paperRaised = Color(0xFFFBFAF7);
  static const ink = Color(0xFF1C1F22);
  static const inkSoft = Color(0xFF4A4E52);
  static const muted = Color(0xFF8A8677);
  static const line = Color(0xFFDAD6CC);
  static const accent = Color(0xFF5B4FE8);
  static const accentSoft = Color(0xFFEDEBFB);
  static const rust = Color(0xFFC1442D);
  static const rustSoft = Color(0xFFF7E9E5);
}
ThemeData buildAppTheme() {
  final base = ThemeData(useMaterial3: true, brightness: Brightness.light);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.paper,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.accent,
      error: AppColors.rust,
      surface: AppColors.paperRaised,
    ),
    textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
      headlineSmall: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.ink),
      titleLarge: GoogleFonts.fraunces(fontSize: 24, fontWeight: FontWeight.w500, color: AppColors.ink),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.line)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.line),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    ),
  );
}