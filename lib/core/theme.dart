import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color accent = Color(0xFFE94560);
  static const Color success = Color(0xFF4CAF50);
  static const Color mutedText = Color(0xFF888888);
  
  static const Color borderEmpty = Color(0xFF2A2A2A);
  static const Color placeholderText = Color(0xFF3A3A3A);
  
  static const Color doneBackground = Color(0xFF0F200F);
  static const Color doneBorder = Color(0xFF1E3A1E);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: accent,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        surface: surface,
        secondary: success,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.spaceGrotesk(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: GoogleFonts.dmSans(
          color: Colors.white,
        ),
        bodyMedium: GoogleFonts.dmSans(
          color: Colors.white,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
