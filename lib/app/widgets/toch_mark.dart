import 'package:flutter/material.dart';

import '../theme/toch_theme.dart';

class TochMark extends StatelessWidget {
  const TochMark({this.size = 64, this.backgroundColor, super.key});

  final double size;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        borderRadius: BorderRadius.circular(size * .5),
        boxShadow: [
          BoxShadow(
            color: colors.green.withValues(alpha: .18),
            blurRadius: size * .18,
            offset: Offset(0, size * .08),
          ),
        ],
      ),
      child: SizedBox.square(
        dimension: size,
        child: Padding(
          padding: EdgeInsets.all(size * .04),
          child: Image.asset(
            'assets/pip/pip-icon.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            semanticLabel: 'Pip',
          ),
        ),
      ),
    );
  }
}
