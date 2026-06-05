import 'package:flutter/material.dart';

import '../theme/toch_theme.dart';

class TochWordmark extends StatelessWidget {
  const TochWordmark({this.fontSize = 52, this.onDark = false, super.key});

  final double fontSize;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final wordColor = onDark ? colors.cream : colors.green;

    return Text.rich(
      TextSpan(
        text: 'toch',
        children: [
          TextSpan(
            text: '.',
            style: TextStyle(color: colors.orange),
          ),
        ],
      ),
      style: Theme.of(context).textTheme.displayLarge?.copyWith(
        color: wordColor,
        fontSize: fontSize,
        letterSpacing: 0,
      ),
    );
  }
}
