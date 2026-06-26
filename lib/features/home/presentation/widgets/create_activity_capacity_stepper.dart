import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/toch_theme.dart';
import '../bloc/create_activity_bloc.dart';

class CreateActivityCapacityStepper extends StatelessWidget {
  const CreateActivityCapacityStepper({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return BlocBuilder<CreateActivityBloc, CreateActivityState>(
      buildWhen: (previous, current) => previous.capacity != current.capacity,
      builder: (context, state) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(22),
            boxShadow: TochShadows.card(colors),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.green100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SizedBox.square(
                    dimension: 44,
                    child: Icon(Icons.groups_rounded, color: colors.green),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MAX. MENSEN',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.green700.withValues(alpha: .62),
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: .7,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ruimte voor ${state.capacity}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: colors.ink,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      Text(
                        'inclusief jezelf',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.green700.withValues(alpha: .62),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _StepperButton(
                      icon: Icons.remove_rounded,
                      onPressed: () {
                        context.read<CreateActivityBloc>().add(
                          const CreateActivityCapacityDecremented(),
                        );
                      },
                    ),
                    SizedBox(
                      width: 42,
                      child: Text(
                        '${state.capacity}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: colors.ink,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    _StepperButton(
                      icon: Icons.add_rounded,
                      onPressed: () {
                        context.read<CreateActivityBloc>().add(
                          const CreateActivityCapacityIncremented(),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return IconButton(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: colors.card,
        foregroundColor: colors.ink,
        fixedSize: const Size.square(42),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TochRadius.md),
          side: BorderSide(color: colors.line, width: 1.5),
        ),
      ),
      icon: Icon(icon, size: 21),
    );
  }
}
