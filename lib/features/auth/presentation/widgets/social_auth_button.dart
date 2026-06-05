import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';

class SocialAuthButton extends StatelessWidget {
  const SocialAuthButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: context.toch.ink,
          disabledForegroundColor: context.toch.ink.withValues(alpha: .44),
          minimumSize: const Size(0, 48),
          side: BorderSide(color: context.toch.line),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
