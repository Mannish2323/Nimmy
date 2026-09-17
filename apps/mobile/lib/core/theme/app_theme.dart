import 'package:flutter/material.dart';

abstract final class NimmyColors {
  static const Color voidBlack = Color(0xFF05050A);
  static const Color background = Color(0xFF080810);
  static const Color surface = Color(0xFF11111C);
  static const Color surfaceRaised = Color(0xFF181827);
  static const Color surfaceSoft = Color(0xFF202034);
  static const Color border = Color(0xFF2B2A43);
  static const Color borderBright = Color(0xFF4A4770);

  static const Color purple = Color(0xFFA970FF);
  static const Color purpleLight = Color(0xFFD4B8FF);
  static const Color purpleDark = Color(0xFF6E3DEB);
  static const Color indigo = Color(0xFF5B66F6);
  static const Color cyan = Color(0xFF54D9FF);
  static const Color pink = Color(0xFFFF5DA8);
  static const Color amber = Color(0xFFFFBE5C);
  static const Color green = Color(0xFF5CE0A0);
  static const Color red = Color(0xFFFF6680);

  static const Color textPrimary = Color(0xFFF7F5FF);
  static const Color textSecondary = Color(0xFFBBB7CF);
  static const Color textMuted = Color(0xFF817D96);

  static const Color purpleGlow = Color(0x55A970FF);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [purpleDark, purple, indigo],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

abstract final class NimmySpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double hero = 48;
}

abstract final class NimmyRadius {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double pill = 999;
}

abstract final class NimmyDurations {
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration medium = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 520);
}

class NimmyTheme {
  static ThemeData get darkTheme {
    const scheme = ColorScheme.dark(
      primary: NimmyColors.purple,
      secondary: NimmyColors.cyan,
      surface: NimmyColors.surface,
      error: NimmyColors.red,
      onPrimary: Colors.white,
      onSecondary: NimmyColors.voidBlack,
      onSurface: NimmyColors.textPrimary,
      onError: Colors.white,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: NimmyColors.background,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displayLarge: const TextStyle(
          fontSize: 36,
          height: 1.05,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.2,
          color: NimmyColors.textPrimary,
        ),
        headlineLarge: const TextStyle(
          fontSize: 27,
          height: 1.15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
          color: NimmyColors.textPrimary,
        ),
        headlineMedium: const TextStyle(
          fontSize: 21,
          height: 1.2,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          color: NimmyColors.textPrimary,
        ),
        titleLarge: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: NimmyColors.textPrimary,
        ),
        titleMedium: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: NimmyColors.textPrimary,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          height: 1.45,
          color: NimmyColors.textPrimary,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          height: 1.45,
          color: NimmyColors.textSecondary,
        ),
        bodySmall: const TextStyle(
          fontSize: 12,
          height: 1.35,
          color: NimmyColors.textMuted,
        ),
        labelLarge: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: NimmyColors.textPrimary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: NimmyColors.textPrimary,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: NimmyColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NimmyRadius.lg),
          side: const BorderSide(color: NimmyColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NimmyColors.surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: NimmySpacing.md,
          vertical: NimmySpacing.md,
        ),
        hintStyle: const TextStyle(color: NimmyColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NimmyRadius.md),
          borderSide: const BorderSide(color: NimmyColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NimmyRadius.md),
          borderSide: const BorderSide(color: NimmyColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NimmyRadius.md),
          borderSide: const BorderSide(color: NimmyColors.purple, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NimmyRadius.md),
          borderSide: const BorderSide(color: NimmyColors.red),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: NimmySpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NimmyRadius.md),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          foregroundColor: NimmyColors.textPrimary,
          side: const BorderSide(color: NimmyColors.borderBright),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NimmyRadius.md),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: NimmyColors.border,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: NimmyColors.surface,
        modalBackgroundColor: NimmyColors.surface,
        showDragHandle: true,
        dragHandleColor: NimmyColors.borderBright,
      ),
    );
  }
}
