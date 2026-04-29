import 'package:flutter/material.dart';

class AppColors {
  // Nature-Inspired Green Palette (from index.css)
  static const Color primary50 = Color(0xFFD1F2EB);
  static const Color primary100 = Color(0xFFB8EBE0);
  static const Color primary200 = Color(0xFF8FDDD0);
  static const Color primary500 = Color(0xFF50C878);
  static const Color primary600 = Color(0xFF0B6E4F);
  static const Color primary700 = Color(0xFF095840);
  static const Color primary800 = Color(0xFF013220);

  static const Color accent500 = Color(0xFF50C878);
  static const Color accent600 = Color(0xFF3EB369);
  static const Color accent700 = Color(0xFF0B6E4F);

  // Grays
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  // Status Colors
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Specific Colors
  static const Color yellow500 = Color(0xFFF59E0B);
  static const Color blue600 = Color(0xFF2563EB);
  static const Color purple600 = Color(0xFF9333EA);
  static const Color orange600 = Color(0xFFEA580C);
  static const Color red500 = Color(0xFFEF4444);
  static const Color red600 = Color(0xFFDC2626);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary500, primary600],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent500, accent600],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Card Shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF013220).withValues(alpha: 0.25),
          offset: const Offset(0, 12),
          blurRadius: 28,
          spreadRadius: -14,
        ),
      ];

  static List<BoxShadow> get cardHoverShadow => [
        BoxShadow(
          color: const Color(0xFF013220).withValues(alpha: 0.35),
          offset: const Offset(0, 18),
          blurRadius: 36,
          spreadRadius: -14,
        ),
      ];
}
