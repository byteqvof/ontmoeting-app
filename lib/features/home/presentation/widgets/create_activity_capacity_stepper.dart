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
            borderRadius: BorderRadius.circular(TochRadius.md),
            boxShadow: TochShadows.card(colors),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.green100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SizedBox.square(
                    dimension: 36,
                    child: Icon(
                      Icons.groups_2_outlined,
                      color: colors.green,
                      size: 19,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hoeveel mensen',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.ink4,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ruimte voor ${state.capacity}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colors.ink,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          height: 1.18,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _StepperButton(
                      icon: Icons.remove_rounded,
                      filled: false,
                      onPressed: () {
                        context.read<CreateActivityBloc>().add(
                          const CreateActivityCapacityDecremented(),
                        );
                      },
                    ),
                    SizedBox(
                      width: 34,
                      child: Text(
                        '${state.capacity}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: colors.ink,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    _StepperButton(
                      icon: Icons.add_rounded,
                      filled: true,
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
  const _StepperButton({
    required this.icon,
    required this.filled,
    required this.onPressed,
  });

  final IconData icon;
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return IconButton(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: filled ? colors.green : colors.green100,
        foregroundColor: filled ? Colors.white : colors.green,
        fixedSize: const Size.square(28),
        minimumSize: const Size.square(28),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const CircleBorder(),
        side: BorderSide(
          color: filled ? colors.green : Colors.transparent,
          width: 0,
        ),
      ),
      icon: Icon(icon, size: 18),
    );
  }
}
