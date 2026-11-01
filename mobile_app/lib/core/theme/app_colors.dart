import 'package:flutter/material.dart';

class AppColors {
  // Dark Theme Palette
  static const Color darkBg = Color(0xFF090D16);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkCard = Color(0xFF1F2937);
  static const Color darkCardBorder = Color(0xFF374151);

  // Light Theme Palette
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF1F5F9);
  static const Color lightCardBorder = Color(0xFFE2E8F0);

  // Brand Accents & Status Colors
  static const Color primaryRed = Color(0xFFEF4444);
  static const Color primaryRedDark = Color(0xFFDC2626);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentPurple = Color(0xFF8B5CF6);

  // Glassmorphic Overlays
  static final Color glassDark = const Color(0xFF0F172A).withValues(alpha: 0.75);
  static final Color glassLight = const Color(0xFFFFFFFF).withValues(alpha: 0.85);

  // Gradients
  static const LinearGradient redWarningGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
