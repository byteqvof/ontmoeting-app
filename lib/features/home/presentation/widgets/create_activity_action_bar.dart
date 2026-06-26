import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/toch_theme.dart';
import '../bloc/create_activity_bloc.dart';

class CreateActivityActionBar extends StatelessWidget {
  const CreateActivityActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors.cream.withValues(alpha: 0),
            colors.cream,
            colors.cream,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: BlocBuilder<CreateActivityBloc, CreateActivityState>(
            buildWhen: (previous, current) =>
                previous.isValid != current.isValid ||
                previous.submissionStatus != current.submissionStatus,
            builder: (context, state) {
              final isSubmitting =
                  state.submissionStatus ==
                  CreateActivitySubmissionStatus.submitting;
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: state.isValid && !isSubmitting
                      ? () {
                          context.read<CreateActivityBloc>().add(
                            const CreateActivitySubmitted(),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    disabledBackgroundColor: colors.green100,
                    disabledForegroundColor: colors.green700.withValues(
                      alpha: .45,
                    ),
                    minimumSize: const Size(0, 54),
                  ),
                  child: isSubmitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Text('Plaats activiteit'),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
