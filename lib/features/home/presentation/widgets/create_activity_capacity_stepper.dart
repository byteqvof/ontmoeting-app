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
        return Row(
          children: [
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
                    ),
                  ),
                  const SizedBox(height: 4),
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
                  width: 50,
                  child: Text(
                    '${state.capacity}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
