// LingoPro — App Constants: colors, typography, spacing
import 'package:flutter/material.dart';

class AppColors {
  // Brand gradient
  static const Color primary   = Color(0xFF4F46E5); // indigo-600
  static const Color secondary = Color(0xFF7C3AED); // violet-600
  static const Color accent    = Color(0xFF06B6D4); // cyan-500

  // Backgrounds
  static const Color background = Color(0xFFF5F5FF); // very light lavender
  static const Color surface    = Color(0xFFFFFFFF);
  static const Color cardBg     = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary   = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint      = Color(0xFFCBD5E1);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color error   = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info    = Color(0xFF3B82F6);

  // Mastery levels
  static const Color mastered  = Color(0xFF10B981);
  static const Color learning  = Color(0xFF8B5CF6);
  static const Color reviewing = Color(0xFF3B82F6);
  static const Color newWord   = Color(0xFF94A3B8);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFF8F7FF), Color(0xFFEDE9FE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Centralized box shadows for premium styling
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get premiumShadow => [
    BoxShadow(
      color: primary.withOpacity(0.25),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
}

class AppSpacing {
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 16.0;
  static const double lg  = 24.0;
  static const double xl  = 32.0;
  static const double xxl = 48.0;
}

class AppRadius {
  static const double sm  = 8.0;
  static const double md  = 12.0;
  static const double lg  = 16.0;
  static const double xl  = 24.0;
  static const double full = 100.0;
}

class AppTextStyles {
  static const TextStyle h1 = TextStyle(
    fontSize: 28, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: -0.5,
  );
  static const TextStyle h2 = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: -0.3,
  );
  static const TextStyle h3 = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle body = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary, height: 1.5,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static const TextStyle label = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w600,
    color: AppColors.textSecondary, letterSpacing: 0.8,
  );
  static const TextStyle button = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600,
    color: Colors.white, letterSpacing: 0.2,
  );
}
