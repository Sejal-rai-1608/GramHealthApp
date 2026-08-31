import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Backgrounds
  static const Color primaryBg = Color(0xFFFFFFFF);
  static const Color secondaryBg = Color(0xFFF2F8F4);
  static const Color leafBg = Color(0xFFEBF5EE);

  // Leaf Green Color System
  static const Color leafGreenDark = Color(0xFF143628); // Deep forest leaf green (replaces black/dark navy)
  static const Color leafGreenDeep = Color(0xFF1B4332);
  static const Color leafGreenPrimary = Color(0xFF2D6A4F);
  static const Color leafGreenMedium = Color(0xFF40916C);
  static const Color leafGreenLight = Color(0xFF52B788);
  static const Color leafGreenMint = Color(0xFF74C69D);
  static const Color leafGreenPale = Color(0xFFD8F3DC);
  static const Color leafGreenAccent = Color(0xFF95D5B2);

  // Core Theme Accents
  static const Color primaryAccent = Color(0xFF40916C); // Vibrant leaf green
  static const Color secondaryAccent = Color(0xFF74C69D);
  static const Color lightGreenAccent = Color(0xFFB7E4C7);
  static const Color medicalGreen = Color(0xFF52B788);
  static const Color darkNavy = Color(0xFF143628); // Replaced with deep forest green

  // Text Colors
  static const Color textDark = Color(0xFF0F291E); // Deep botanical charcoal green
  static const Color textMedium = Color(0xFF385748);
  static const Color textMuted = Color(0xFF6B8A7A);

  // Glassmorphism & Shadows
  static const Color glassBorder = Color(0x3340916C);
  static const Color glassBackground = Color(0xD9FFFFFF);
  static const Color shadow = Color(0x14143628);
  static const Color cardShadow = Color(0x1A1B4332);

  // Status & Utility Colors
  static const Color error = Color(0xFFFF4D4D);
  static const Color success = Color(0xFF40916C);
  static const Color warning = Color(0xFFF59E0B);
  static const Color emergency = Color(0xFFE53935);
  static const Color indigo = Color(0xFF40916C);

  // Leaf Green Gradients
  static const LinearGradient leafGradient = LinearGradient(
    colors: [Color(0xFF1B4332), Color(0xFF2D6A4F), Color(0xFF40916C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient leafGradientFresh = LinearGradient(
    colors: [Color(0xFF2D6A4F), Color(0xFF40916C), Color(0xFF52B788)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient leafGradientLight = LinearGradient(
    colors: [Color(0xFF40916C), Color(0xFF52B788), Color(0xFF74C69D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient leafGradientHero = LinearGradient(
    colors: [Color(0xFF0F291E), Color(0xFF1B4332), Color(0xFF2D6A4F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient leafGradientSubtle = LinearGradient(
    colors: [Color(0xFFEBF5EE), Color(0xFFD8F3DC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient leafGradientCard = LinearGradient(
    colors: [Color(0xFF2D6A4F), Color(0xFF52B788)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient leafGradientFloating = LinearGradient(
    colors: [Color(0xFF2D6A4F), Color(0xFF52B788), Color(0xFF74C69D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

