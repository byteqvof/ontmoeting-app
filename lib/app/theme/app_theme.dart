import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'toch_theme.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final textTheme = GoogleFonts.nunitoSansTextTheme().apply(
      bodyColor: TochColors.ink,
      displayColor: TochColors.green,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: TochColors.green,
        onPrimary: TochColors.cream,
        secondary: TochColors.orange,
        onSecondary: TochColors.green,
        tertiary: TochColors.categoryVisel,
        onTertiary: TochColors.cream,
        error: Color(0xFFB05540),
        onError: TochColors.cream,
        surface: TochColors.card,
        onSurface: TochColors.ink,
      ),
      scaffoldBackgroundColor: TochColors.cream,
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(
          color: TochColors.green,
          fontSize: 64,
          fontWeight: FontWeight.w900,
          height: 1,
          letterSpacing: 0,
        ),
        headlineLarge: textTheme.headlineLarge?.copyWith(
          color: TochColors.green,
          fontSize: 40,
          fontWeight: FontWeight.w800,
          height: 1.05,
          letterSpacing: 0,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          color: TochColors.green,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          color: TochColors.green700,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(
          color: TochColors.ink,
          fontSize: 17,
          fontWeight: FontWeight.w400,
          height: 1.5,
          letterSpacing: 0,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: TochColors.green700,
          fontWeight: FontWeight.w400,
          height: 1.45,
          letterSpacing: 0,
        ),
        labelLarge: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
      extensions: [TochTokens.light()],
      appBarTheme: const AppBarTheme(
        backgroundColor: TochColors.cream,
        foregroundColor: TochColors.green,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        color: TochColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(TochRadius.lg)),
          side: BorderSide(color: TochColors.line),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: TochColors.line,
        thickness: 1,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: TochColors.card,
        labelStyle: TextStyle(color: TochColors.green700),
        floatingLabelStyle: TextStyle(
          color: TochColors.green,
          fontWeight: FontWeight.w700,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(TochRadius.md)),
          borderSide: BorderSide(color: TochColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(TochRadius.md)),
          borderSide: BorderSide(color: TochColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(TochRadius.md)),
          borderSide: BorderSide(color: TochColors.green, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(TochRadius.md)),
          borderSide: BorderSide(color: Color(0xFFB05540)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(TochRadius.md)),
          borderSide: BorderSide(color: Color(0xFFB05540), width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: TochColors.green,
          foregroundColor: TochColors.cream,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
          shape: const StadiumBorder(),
          elevation: 0,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: TochColors.green,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: TochColors.green,
          backgroundColor: TochColors.green100,
        ),
      ),
    );
  }
}
