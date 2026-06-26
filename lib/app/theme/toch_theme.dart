import 'package:flutter/material.dart';

class TochColors {
  const TochColors._();

  static const green = Color(0xFF1E5740);
  static const greenPressed = Color(0xFF163D2C);
  static const greenDeep = Color(0xFF0F3325);
  static const green700 = Color(0xFF404843);
  static const green200 = Color(0xFFD6E5DC);
  static const green100 = Color(0xFFE6EFE9);
  static const orange = Color(0xFFE0913A);
  static const orangePressed = Color(0xFFC97C2A);
  static const orangeSoft = Color(0xFFFBEEDB);
  static const cream = Color(0xFFF5F2EB);
  static const card = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFFBF9F4);
  static const ink = Color(0xFF19211C);
  static const ink2 = Color(0xFF404843);
  static const ink3 = Color(0xFF737B75);
  static const ink4 = Color(0xFFA7AEA8);
  static const line = Color(0xFFEBE6DB);
  static const verified = Color(0xFF2E7E5C);
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
  static const xl = 28.0;
  static const pill = 999.0;
}

class TochTokens extends ThemeExtension<TochTokens> {
  const TochTokens({
    required this.green,
    required this.greenPressed,
    required this.greenDeep,
    required this.green700,
    required this.green200,
    required this.green100,
    required this.orange,
    required this.orangePressed,
    required this.orangeSoft,
    required this.cream,
    required this.card,
    required this.surface2,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.ink4,
    required this.line,
    required this.verified,
    required this.categoryVisel,
    required this.categoryKoffie,
    required this.categoryPaars,
  });

  factory TochTokens.light() {
    return const TochTokens(
      green: TochColors.green,
      greenPressed: TochColors.greenPressed,
      greenDeep: TochColors.greenDeep,
      green700: TochColors.green700,
      green200: TochColors.green200,
      green100: TochColors.green100,
      orange: TochColors.orange,
      orangePressed: TochColors.orangePressed,
      orangeSoft: TochColors.orangeSoft,
      cream: TochColors.cream,
      card: TochColors.card,
      surface2: TochColors.surface2,
      ink: TochColors.ink,
      ink2: TochColors.ink2,
      ink3: TochColors.ink3,
      ink4: TochColors.ink4,
      line: TochColors.line,
      verified: TochColors.verified,
      categoryVisel: TochColors.categoryVisel,
      categoryKoffie: TochColors.categoryKoffie,
      categoryPaars: TochColors.categoryPaars,
    );
  }

  final Color green;
  final Color greenPressed;
  final Color greenDeep;
  final Color green700;
  final Color green200;
  final Color green100;
  final Color orange;
  final Color orangePressed;
  final Color orangeSoft;
  final Color cream;
  final Color card;
  final Color surface2;
  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color ink4;
  final Color line;
  final Color verified;
  final Color categoryVisel;
  final Color categoryKoffie;
  final Color categoryPaars;

  @override
  TochTokens copyWith({
    Color? green,
    Color? greenPressed,
    Color? greenDeep,
    Color? green700,
    Color? green200,
    Color? green100,
    Color? orange,
    Color? orangePressed,
    Color? orangeSoft,
    Color? cream,
    Color? card,
    Color? surface2,
    Color? ink,
    Color? ink2,
    Color? ink3,
    Color? ink4,
    Color? line,
    Color? verified,
    Color? categoryVisel,
    Color? categoryKoffie,
    Color? categoryPaars,
  }) {
    return TochTokens(
      green: green ?? this.green,
      greenPressed: greenPressed ?? this.greenPressed,
      greenDeep: greenDeep ?? this.greenDeep,
      green700: green700 ?? this.green700,
      green200: green200 ?? this.green200,
      green100: green100 ?? this.green100,
      orange: orange ?? this.orange,
      orangePressed: orangePressed ?? this.orangePressed,
      orangeSoft: orangeSoft ?? this.orangeSoft,
      cream: cream ?? this.cream,
      card: card ?? this.card,
      surface2: surface2 ?? this.surface2,
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      ink3: ink3 ?? this.ink3,
      ink4: ink4 ?? this.ink4,
      line: line ?? this.line,
      verified: verified ?? this.verified,
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
      greenPressed: Color.lerp(greenPressed, other.greenPressed, t)!,
      greenDeep: Color.lerp(greenDeep, other.greenDeep, t)!,
      green700: Color.lerp(green700, other.green700, t)!,
      green200: Color.lerp(green200, other.green200, t)!,
      green100: Color.lerp(green100, other.green100, t)!,
      orange: Color.lerp(orange, other.orange, t)!,
      orangePressed: Color.lerp(orangePressed, other.orangePressed, t)!,
      orangeSoft: Color.lerp(orangeSoft, other.orangeSoft, t)!,
      cream: Color.lerp(cream, other.cream, t)!,
      card: Color.lerp(card, other.card, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      ink2: Color.lerp(ink2, other.ink2, t)!,
      ink3: Color.lerp(ink3, other.ink3, t)!,
      ink4: Color.lerp(ink4, other.ink4, t)!,
      line: Color.lerp(line, other.line, t)!,
      verified: Color.lerp(verified, other.verified, t)!,
      categoryVisel: Color.lerp(categoryVisel, other.categoryVisel, t)!,
      categoryKoffie: Color.lerp(categoryKoffie, other.categoryKoffie, t)!,
      categoryPaars: Color.lerp(categoryPaars, other.categoryPaars, t)!,
    );
  }
}

class TochShadows {
  const TochShadows._();

  static List<BoxShadow> card(TochTokens colors) {
    return [
      BoxShadow(
        color: colors.ink.withValues(alpha: .07),
        blurRadius: 24,
        offset: const Offset(0, 10),
      ),
    ];
  }

  static List<BoxShadow> raised(TochTokens colors) {
    return [
      BoxShadow(
        color: colors.ink.withValues(alpha: .12),
        blurRadius: 32,
        offset: const Offset(0, 16),
      ),
    ];
  }

  static List<BoxShadow> button(TochTokens colors) {
    return [
      BoxShadow(
        color: colors.green.withValues(alpha: .22),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ];
  }
}

extension TochThemeX on BuildContext {
  TochTokens get toch => Theme.of(this).extension<TochTokens>()!;
}
