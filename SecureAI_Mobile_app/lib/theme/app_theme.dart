import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Theme Color Tokens matching the glassmorphic web app
  static const Color bgDark = Color(0xFF0F172A);
  static const Color cardGlassBg = Color(0x73000000); // rgba(0, 0, 0, 0.45)
  static const Color glassBorder = Color(0x33FFFFFF); // rgba(255, 255, 255, 0.2)
  
  static const Color primaryIndigo = Color(0xFF6366F1);
  static const Color accentPurple = Color(0xFFA78BFA);
  static const Color accentTeal = Color(0xFF2DD4BF);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentRed = Color(0xFFEF4444);

  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF312E81),
      Color(0xFF581C87),
      Color(0xFF831843),
      Color(0xFF1E3A8A),
    ],
  );

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: bgDark,
      primaryColor: primaryIndigo,
      colorScheme: const ColorScheme.dark(
        primary: primaryIndigo,
        secondary: accentTeal,
        surface: cardGlassBg,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }
}
