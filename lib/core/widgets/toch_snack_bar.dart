import 'package:flutter/material.dart';

import '../../app/theme/toch_theme.dart';

enum TochSnackBarType { info, success, error }

void showTochSnackBar(
  BuildContext context,
  String message, {
  TochSnackBarType type = TochSnackBarType.info,
  Duration duration = const Duration(seconds: 4),
}) {
  final colors = context.toch;
  final (icon, accent, background) = switch (type) {
    TochSnackBarType.success => (
      Icons.check_circle_rounded,
      colors.green,
      colors.green100,
    ),
    TochSnackBarType.error => (
      Icons.error_outline_rounded,
      const Color(0xFFC0492F),
      const Color(0xFFF8E6E1),
    ),
    TochSnackBarType.info => (
      Icons.info_outline_rounded,
      colors.orange,
      colors.orangeSoft,
    ),
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: duration,
        elevation: 0,
        backgroundColor: Colors.transparent,
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        padding: EdgeInsets.zero,
        content: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: accent.withValues(alpha: .18)),
            boxShadow: TochShadows.raised(colors),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.square(
                    dimension: 34,
                    child: Icon(icon, color: Colors.white, size: 19),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
}
