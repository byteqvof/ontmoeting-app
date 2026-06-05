import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';

class EmailAuthDivider extends StatelessWidget {
  const EmailAuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TochSpacing.lg),
      child: Row(
        children: [
          Expanded(child: Divider(color: context.toch.line)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TochSpacing.md),
            child: Text(
              'of met e-mail',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: context.toch.green700,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(child: Divider(color: context.toch.line)),
        ],
      ),
    );
  }
}
