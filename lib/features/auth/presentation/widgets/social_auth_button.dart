import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';

class SocialAuthButton extends StatelessWidget {
  const SocialAuthButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.dark = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;
    final background = dark ? colors.ink : colors.card;
    final foreground = dark ? Colors.white : colors.ink;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background.withValues(alpha: .6),
          disabledForegroundColor: foreground.withValues(alpha: .46),
          elevation: 0,
          shape: const StadiumBorder(),
          side: BorderSide(color: dark ? Colors.transparent : colors.line),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
