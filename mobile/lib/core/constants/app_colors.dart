import 'package:flutter/material.dart';

class AppColors {
  // Deep Obsidian Dark Mode Backgrounds
  static const Color background = Color(0xFF0B0D14);
  static const Color surface = Color(0xFF121620);
  static const Color surfaceCard = Color(0xFF181E2C);
  static const Color surfaceElevated = Color(0xFF20293C);
  static const Color surfaceLight = Color(0xFF2B364E);

  // Light Theme Palette
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceCard = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Brand / Electric Purple & Violet Gradients
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryLight = Color(0xFF9333EA);
  static const Color primaryDark = Color(0xFF5B21B6);
  static const Color primaryAccent = Color(0xFF6366F1);
  static const Color secondary = Color(0xFF6366F1);

  // Rewards / 3D Glowing Gold Coins
  static const Color coinGold = Color(0xFFFFB800);
  static const Color coinGoldLight = Color(0xFFFFD159);
  static const Color coinGoldDark = Color(0xFFD99B00);
  static const Color coinAmber = Color(0xFFF59E0B);

  // Accents & Gamification
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color flameOrange = Color(0xFFFF6B00);

  // Dark Theme Text
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);

  // Borders & Dividers
  static const Color border = Color(0xFF242C3D);
  static const Color borderLight = Color(0xFF333E56);
  static const Color divider = Color(0xFF1A2232);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient walletCardGradient = LinearGradient(
    colors: [Color(0xFF6D28D9), Color(0xFF4338CA), Color(0xFF312E81)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD159), Color(0xFFFFB800), Color(0xFFD99B00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient fireStreakGradient = LinearGradient(
    colors: [Color(0xFFFF4500), Color(0xFFFF8C00)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
