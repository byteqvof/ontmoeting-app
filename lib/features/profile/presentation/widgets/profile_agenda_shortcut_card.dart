import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';

class ProfileAgendaShortcutCard extends StatelessWidget {
  const ProfileAgendaShortcutCard({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(TochRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TochRadius.lg),
            border: Border.all(color: colors.line),
            boxShadow: TochShadows.card(colors),
          ),
          child: Padding(
            padding: const EdgeInsets.all(TochSpacing.md),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.green100,
                    borderRadius: BorderRadius.circular(TochRadius.md),
                  ),
                  child: SizedBox.square(
                    dimension: 48,
                    child: Icon(
                      Icons.event_note_rounded,
                      color: colors.green,
                      size: 25,
                    ),
                  ),
                ),
                const SizedBox(width: TochSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mijn agenda',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: colors.ink,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Bekijk waar je meegaat en wat je organiseert.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.ink3,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: TochSpacing.sm),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.green700.withValues(alpha: .50),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
