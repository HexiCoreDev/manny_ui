import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MannyTheme {
  MannyTheme._();

  // NEBULA brand colors — deep space palette
  static const primaryPurple = Color(0xFF6C3CE0);
  static const secondaryBlue = Color(0xFF3B82F6);
  static const tertiaryTeal = Color(0xFF14B8A6);
  static const primaryContainer = Color(0xFFE8DEFF);
  static const secondaryContainer = Color(0xFFDBEAFE);

  static ThemeData lightTheme =
      FlexThemeData.light(
        useMaterial3: true,
        colors: const FlexSchemeColor(
          primary: primaryPurple,
          primaryContainer: primaryContainer,
          primaryLightRef: primaryPurple,
          secondary: secondaryBlue,
          secondaryContainer: secondaryContainer,
          secondaryLightRef: secondaryBlue,
          tertiary: tertiaryTeal,
          tertiaryContainer: Color(0xFFCCFBF1),
          tertiaryLightRef: tertiaryTeal,
        ),
        textTheme: GoogleFonts.interTextTheme(),
        subThemesData: const FlexSubThemesData(
          interactionEffects: true,
          tintedDisabledControls: true,
          blendOnLevel: 10,
          blendOnColors: false,
          useM2StyleDividerInM3: true,
          inputDecoratorBorderType: FlexInputBorderType.outline,
          inputDecoratorRadius: 12.0,
          chipRadius: 8.0,
          fabRadius: 16.0,
          cardRadius: 12.0,
          dialogRadius: 16.0,
          appBarScrolledUnderElevation: 4.0,
          navigationBarIndicatorOpacity: 0.24,
        ),
      ).copyWith(
        scrollbarTheme: const ScrollbarThemeData(
          thumbVisibility: WidgetStatePropertyAll(false),
          trackVisibility: WidgetStatePropertyAll(false),
        ),
      );

  static ThemeData darkTheme =
      FlexThemeData.dark(
        useMaterial3: true,
        colors: const FlexSchemeColor(
          primary: Color(0xFFBB86FC),
          primaryContainer: Color(0xFF3700B3),
          primaryLightRef: primaryPurple,
          secondary: Color(0xFF90CAF9),
          secondaryContainer: Color(0xFF1565C0),
          secondaryLightRef: secondaryBlue,
          tertiary: Color(0xFF80CBC4),
          tertiaryContainer: Color(0xFF00695C),
          tertiaryLightRef: tertiaryTeal,
        ),
        textTheme: GoogleFonts.interTextTheme(),
        subThemesData: const FlexSubThemesData(
          interactionEffects: true,
          tintedDisabledControls: true,
          blendOnLevel: 20,
          useM2StyleDividerInM3: true,
          inputDecoratorBorderType: FlexInputBorderType.outline,
          inputDecoratorRadius: 12.0,
          chipRadius: 8.0,
          fabRadius: 16.0,
          cardRadius: 12.0,
          dialogRadius: 16.0,
          appBarScrolledUnderElevation: 4.0,
          navigationBarIndicatorOpacity: 0.24,
        ),
      ).copyWith(
        scrollbarTheme: const ScrollbarThemeData(
          thumbVisibility: WidgetStatePropertyAll(false),
          trackVisibility: WidgetStatePropertyAll(false),
        ),
      );
}
