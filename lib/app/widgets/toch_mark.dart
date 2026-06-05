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
        color: backgroundColor ?? colors.green,
        borderRadius: BorderRadius.circular(size * .22),
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
        child: Center(
          child: Icon(
            Icons.place_rounded,
            color: colors.cream,
            size: size * .58,
          ),
        ),
      ),
    );
  }
}
