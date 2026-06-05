import 'package:flutter/material.dart';

class TochColors {
  const TochColors._();

  static const green = Color(0xFF1E5740);
  static const green700 = Color(0xFF404843);
  static const green200 = Color(0xFFD6E5DC);
  static const green100 = Color(0xFFE6EFE9);
  static const orange = Color(0xFFE0913A);
  static const orangeSoft = Color(0xFFFBEEDB);
  static const cream = Color(0xFFF5F2EB);
  static const card = Color(0xFFFFFFFF);
  static const ink = Color(0xFF19211C);
  static const line = Color(0xFFEBE6DB);
  static const categoryVisel = Color(0xFF3E8E8C);
  static const categoryKoffie = Color(0xFFB07A52);
  static const categoryPaars = Color(0xFF7E5C9E);
}

class TochSpacing {
  const TochSpacing._();

  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

class TochRadius {
  const TochRadius._();

  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const pill = 999.0;
}

class TochTokens extends ThemeExtension<TochTokens> {
  const TochTokens({
    required this.green,
    required this.green700,
    required this.green200,
    required this.green100,
    required this.orange,
    required this.orangeSoft,
    required this.cream,
    required this.card,
    required this.ink,
    required this.line,
    required this.categoryVisel,
    required this.categoryKoffie,
    required this.categoryPaars,
  });

  factory TochTokens.light() {
    return const TochTokens(
      green: TochColors.green,
      green700: TochColors.green700,
      green200: TochColors.green200,
      green100: TochColors.green100,
      orange: TochColors.orange,
      orangeSoft: TochColors.orangeSoft,
      cream: TochColors.cream,
      card: TochColors.card,
      ink: TochColors.ink,
      line: TochColors.line,
      categoryVisel: TochColors.categoryVisel,
      categoryKoffie: TochColors.categoryKoffie,
      categoryPaars: TochColors.categoryPaars,
    );
  }

  final Color green;
  final Color green700;
  final Color green200;
  final Color green100;
  final Color orange;
  final Color orangeSoft;
  final Color cream;
  final Color card;
  final Color ink;
  final Color line;
  final Color categoryVisel;
  final Color categoryKoffie;
  final Color categoryPaars;

  @override
  TochTokens copyWith({
    Color? green,
    Color? green700,
    Color? green200,
    Color? green100,
    Color? orange,
    Color? orangeSoft,
    Color? cream,
    Color? card,
    Color? ink,
    Color? line,
    Color? categoryVisel,
    Color? categoryKoffie,
    Color? categoryPaars,
  }) {
    return TochTokens(
      green: green ?? this.green,
      green700: green700 ?? this.green700,
      green200: green200 ?? this.green200,
      green100: green100 ?? this.green100,
      orange: orange ?? this.orange,
      orangeSoft: orangeSoft ?? this.orangeSoft,
      cream: cream ?? this.cream,
      card: card ?? this.card,
      ink: ink ?? this.ink,
      line: line ?? this.line,
      categoryVisel: categoryVisel ?? this.categoryVisel,
      categoryKoffie: categoryKoffie ?? this.categoryKoffie,
      categoryPaars: categoryPaars ?? this.categoryPaars,
    );
  }

  @override
  TochTokens lerp(ThemeExtension<TochTokens>? other, double t) {
    if (other is! TochTokens) {
      return this;
    }

    return TochTokens(
      green: Color.lerp(green, other.green, t)!,
      green700: Color.lerp(green700, other.green700, t)!,
      green200: Color.lerp(green200, other.green200, t)!,
      green100: Color.lerp(green100, other.green100, t)!,
      orange: Color.lerp(orange, other.orange, t)!,
      orangeSoft: Color.lerp(orangeSoft, other.orangeSoft, t)!,
      cream: Color.lerp(cream, other.cream, t)!,
      card: Color.lerp(card, other.card, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      line: Color.lerp(line, other.line, t)!,
      categoryVisel: Color.lerp(categoryVisel, other.categoryVisel, t)!,
      categoryKoffie: Color.lerp(categoryKoffie, other.categoryKoffie, t)!,
      categoryPaars: Color.lerp(categoryPaars, other.categoryPaars, t)!,
    );
  }
}

extension TochThemeX on BuildContext {
  TochTokens get toch => Theme.of(this).extension<TochTokens>()!;
}
