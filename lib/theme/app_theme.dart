import 'package:flutter/material.dart';

class AppColors {
  // Background
  static const Color backgroundMain = Color(0xFF1E293B);
  static const Color backgroundCard = Color(0x991E293B);

  // Primary (pink/salmon)
  static const Color primaryPink = Color(0xFFF19B9B);
  static const Color primaryPinkDark = Color(0xFFE88B8B);

  // Secondary (cyan/turquoise)
  static const Color secondaryCyan = Color(0xFF7DD3C0);
  static const Color secondaryCyanDark = Color(0xFF6ECBB8);

  // States
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFE88B8B);
  static const Color warning = Color(0xFFFBBF24);

  // Grays
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);

  // Team colors
  static const Color team1 = Color(0xFFF19B9B);
  static const Color team2 = Color(0xFF7DD3C0);
  static const Color team3 = Color(0xFFA78BFA);
  static const Color team4 = Color(0xFFFBBF24);

  static Color getTeamColor(int teamIndex) {
    switch (teamIndex) {
      case 0:
        return team1;
      case 1:
        return team2;
      case 2:
        return team3;
      case 3:
        return team4;
      default:
        return team1;
    }
  }
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundMain,
      fontFamily: 'Poppins',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Bangers',
          fontSize: 72,
          color: Colors.white,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Bangers',
          fontSize: 48,
          color: Colors.white,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Bangers',
          fontSize: 36,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Bangers',
          fontSize: 28,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: Colors.white,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPink,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.secondaryCyan, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.secondaryCyan, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.secondaryCyanDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: TextStyle(color: Colors.grey[400]),
      ),
    );
  }
}

class AppTextStyles {
  static TextStyle title({double fontSize = 72}) {
    return TextStyle(
      fontFamily: 'Bangers',
      fontSize: fontSize,
      color: Colors.white,
      shadows: const [
        Shadow(
          offset: Offset(4, 4),
          color: AppColors.primaryPinkDark,
          blurRadius: 0,
        ),
      ],
    );
  }

  static TextStyle subtitle({double fontSize = 32}) {
    return TextStyle(
      fontFamily: 'Bangers',
      fontSize: fontSize,
      color: Colors.white,
      shadows: const [
        Shadow(
          offset: Offset(2, 2),
          color: AppColors.primaryPinkDark,
          blurRadius: 0,
        ),
      ],
    );
  }

  static const TextStyle body = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    color: Colors.white,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    color: Colors.white,
  );

  static const TextStyle label = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}
