import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryAccent,
        primary: AppColors.primaryAccent,
        surface: AppColors.primaryBg,
      ),
      scaffoldBackgroundColor: AppColors.secondaryBg,
      textTheme: _textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryBg,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
    );
  }

  static TextTheme get _textTheme {
    return TextTheme(
      // heading: fontSize 32, fontWeight 700
      displayLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
        height: 1.06,
      ),
      // subheading: fontSize 20, fontWeight 600
      displayMedium: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
        height: 1.3,
      ),
      // body: fontSize 16, fontWeight 500
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textDark,
        height: 1.375,
      ),
      // bodySmall: fontSize 14, fontWeight 400
      bodySmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textDark,
        height: 1.43,
      ),
      // button: fontSize 14, fontWeight 700, uppercase
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
        color: AppColors.textDark,
      ),
    );
  }
}

// Convenience extensions for text styles
extension TextStyleExt on BuildContext {
  TextStyle get heading => Theme.of(this).textTheme.displayLarge!;
  TextStyle get subheading => Theme.of(this).textTheme.displayMedium!;
  TextStyle get body => Theme.of(this).textTheme.bodyLarge!;
  TextStyle get bodySmall => Theme.of(this).textTheme.bodySmall!;
  TextStyle get buttonText => Theme.of(this).textTheme.labelLarge!;
}
