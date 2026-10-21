import 'package:flutter/material.dart';

/// Clear Careway — replacement world for GramHealth.
///
/// Light, high-contrast, opaque surfaces.
/// See `.impeccable/design.json` for canonical ramps.
class AppColors {
  AppColors._();

  // ── Core Clear Careway ───────────────────────────────────────────────
  // Ink (neutral)
  static const Color ink = Color(0xFF17211D);
  static const Color inkMid = Color(0xFF26352E);
  static const Color inkSoft = Color(0xFF3B4A43);
  static const Color inkMuted = Color(0xFF53625A);
  static const Color inkFaint = Color(0xFF718078);
  static const Color inkPale = Color(0xFFA5B0AA);
  static const Color inkGhost = Color(0xFFD1D9D4);

  // Clear Teal (primary)
  static const Color teal = Color(0xFF007A6E);
  static const Color tealDeep = Color(0xFF00574F);
  static const Color tealDark = Color(0xFF003C36);
  static const Color tealMid = Color(0xFF006A60);
  static const Color tealBright = Color(0xFF29988A);
  static const Color tealSoft = Color(0xFF72BDB3);
  static const Color tealPale = Color(0xFFB2DED8);
  static const Color tealWash = Color(0xFFE1F5F1);

  // Careway Mint (primary-container)
  static const Color mint = Color(0xFFD5F3EC);
  static const Color mintLight = Color(0xFFF0FCF9);
  static const Color mintBorder = Color(0xFFB2DED8);

  // Sunlit Amber (secondary)
  static const Color amber = Color(0xFFF0A624);
  static const Color amberDeep = Color(0xFF9A5B00);
  static const Color amberDark = Color(0xFF6E4300);
  static const Color amberSoft = Color(0xFFF7C968);
  static const Color amberPale = Color(0xFFFFE3A6);
  static const Color amberWash = Color(0xFFFFF7E2);
  static const Color amberChipBg = Color(0xFFFFF0C7);

  // Warm Coral (tertiary)
  static const Color coral = Color(0xFFD9584B);
  static const Color coralDeep = Color(0xFF9D352A);
  static const Color coralSoft = Color(0xFFE88C82);
  static const Color coralPale = Color(0xFFF6C2BC);
  static const Color coralWash = Color(0xFFFFF0EE);

  // Emergency (error)
  static const Color emergency = Color(0xFFB3261E);
  static const Color emergencyDeep = Color(0xFF8F1C15);
  static const Color emergencySoft = Color(0xFFCE554D);
  static const Color emergencyPale = Color(0xFFF5C5C1);
  static const Color emergencyWash = Color(0xFFFFF0EE);

  // Ground & surface
  static const Color ground = Color(0xFFF7FAF7);
  static const Color groundAlt = Color(0xFFF2F7F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFEAF1ED);

  // Borders
  static const Color borderLight = Color(0xFFEAF1ED);
  static const Color border = Color(0xFFC4CEC8);
  static const Color borderStrong = Color(0xFF718078);

  // ── Semantic text ───────────────────────────────────────────────────
  static const Color textDark = ink;
  static const Color textMedium = inkSoft;
  static const Color textMuted = inkFaint;
  static const Color textOnTeal = Colors.white;
  static const Color textPlaceholder = Color(0xFF425149);

  // ── Status ──────────────────────────────────────────────────────────
  static const Color onlineGreen = Color(0xFF2E7D32);
  static const Color onlineWash = Color(0xFFE8F5E9);
  static const Color offlineOrange = Color(0xFFE65100);
  static const Color offlineWash = Color(0xFFFFF3E0);
  static const Color weakAmber = Color(0xFFF9A825);

  // Aliases required by shared widgets (legacy call-sites)
  static const Color success = teal;
  static const Color warning = amber;
  static const Color error = emergency;
  @Deprecated('Use AppColors.ground')
  static const Color primaryBg = surface;
  @Deprecated('Use AppColors.ground')
  static const Color secondaryBg = ground;
  @Deprecated('Use AppColors.mint')
  static const Color leafBg = mintLight;

  // ── Shadows (ambient-low / ambient-raised) ──────────────────────────
  static const BoxShadow shadowLow = BoxShadow(
    color: Color(0x1F17211D), // 12%
    blurRadius: 3,
    offset: Offset(0, 1),
  );
  static const BoxShadow shadowRaised = BoxShadow(
    color: Color(0x2417211D), // 14%
    blurRadius: 18,
    offset: Offset(0, 6),
  );

  // ── Tonal ramps (for reference / swatches) ──────────────────────────
  static const List<Color> inkRamp = [
    Color(0xFF17211D),
    Color(0xFF26352E),
    Color(0xFF3B4A43),
    Color(0xFF53625A),
    Color(0xFF718078),
    Color(0xFFA5B0AA),
    Color(0xFFD1D9D4),
    Color(0xFFF7FAF7),
  ];
  static const List<Color> tealRamp = [
    Color(0xFF003C36),
    Color(0xFF00574F),
    Color(0xFF006A60),
    Color(0xFF007A6E),
    Color(0xFF29988A),
    Color(0xFF72BDB3),
    Color(0xFFB2DED8),
    Color(0xFFE1F5F1),
  ];

  // ── Legacy leaf aliases (keep build green until screens migrated) ───
  @Deprecated('Use teal')
  static const Color leafGreenPrimary = teal;
  @Deprecated('Use tealDeep')
  static const Color leafGreenDark = tealDeep;
  @Deprecated('Use tealDark')
  static const Color leafGreenDeep = tealDark;
  @Deprecated('Use tealBright')
  static const Color leafGreenMedium = tealBright;
  @Deprecated('Use tealSoft')
  static const Color leafGreenLight = tealSoft;
  @Deprecated('Use mint')
  static const Color leafGreenPale = mint;
  @Deprecated('Use mintBorder')
  static const Color leafGreenAccent = mintBorder;
  @Deprecated('Use teal')
  static const Color primaryAccent = teal;
  @Deprecated('Use mintBorder')
  static const Color secondaryAccent = tealSoft;
  @Deprecated('Use mintLight')
  static const Color lightGreenAccent = mintLight;
  @Deprecated('Use teal')
  static const Color medicalGreen = teal;
  @Deprecated('Use ink')
  static const Color darkNavy = ink;
  static const Color glassBorder = Color(0x1A718078);
  static const Color glassBackground = Color(0xCCFFFFFF);
  static const Color shadow = Color(0x1417211D);
  static const Color cardShadow = Color(0x1A17211D);
  static const Color indigo = teal;

  static const LinearGradient leafGradient = LinearGradient(
    colors: [Color(0xFF003C36), Color(0xFF007A6E), Color(0xFF29988A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient leafGradientFresh = LinearGradient(
    colors: [Color(0xFF007A6E), Color(0xFF29988A), Color(0xFF72BDB3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient leafGradientLight = LinearGradient(
    colors: [Color(0xFF29988A), Color(0xFF72BDB3), Color(0xFFB2DED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient leafGradientHero = LinearGradient(
    colors: [Color(0xFF17211D), Color(0xFF003C36), Color(0xFF007A6E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient leafGradientSubtle = LinearGradient(
    colors: [Color(0xFFF0FCF9), Color(0xFFD5F3EC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient leafGradientCard = LinearGradient(
    colors: [Color(0xFF007A6E), Color(0xFF29988A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient leafGradientFloating = LinearGradient(
    colors: [Color(0xFF007A6E), Color(0xFF29988A), Color(0xFF72BDB3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Radii — Clear Careway (4-step + pill)
class AppRadii {
  AppRadii._();
  static const double sm = 8;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 20;
  static const double pill = 999;
}

/// Motion — Clear Careway
class AppMotion {
  AppMotion._();
  static const Duration state = Duration(milliseconds: 180);
  static const Duration route = Duration(milliseconds: 280);
  static const Curve standard = Cubic(0.2, 0, 0, 1);
}

/// Breakpoints — compact / medium / expanded
class AppBreakpoints {
  AppBreakpoints._();
  static const double compactMax = 600;
  static const double mediumMax = 840;
  static const double expandedMin = 840;
  static const double maxContent = 1200;
}
