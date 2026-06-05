import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/home_category.dart';
import '../../domain/entities/home_location.dart';
import '../../domain/usecases/create_activity.dart';
import '../bloc/create_activity_bloc.dart';
import '../widgets/create_activity_action_bar.dart';
import '../widgets/create_activity_capacity_stepper.dart';
import '../widgets/create_activity_category_picker.dart';
import '../widgets/create_activity_choice_chips.dart';

class CreateActivityPage extends StatelessWidget {
  const CreateActivityPage({
    required this.location,
    required this.categories,
    super.key,
  });

  final HomeLocation location;
  final List<HomeCategory> categories;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CreateActivityBloc(
        sl<CreateActivity>(),
        location: location,
        categories: categories
            .where((category) => category.id != 'all')
            .toList(),
      ),
      child: const _CreateActivityView(),
    );
  }
}

class CreateActivityPageArgs {
  const CreateActivityPageArgs({
    required this.location,
    required this.categories,
  });

  final HomeLocation location;
  final List<HomeCategory> categories;
}

class MissingCreateActivityPage extends StatelessWidget {
  const MissingCreateActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Scaffold(
      backgroundColor: colors.cream,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(TochSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_off_rounded,
                  color: colors.orange,
                  size: 44,
                ),
                const SizedBox(height: TochSpacing.md),
                Text(
                  'Open vanuit de feed',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: TochSpacing.sm),
                Text(
                  'We hebben je locatie en categorieen nodig om een activiteit te plaatsen.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: TochSpacing.lg),
                ElevatedButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.explore_rounded),
                  label: const Text('Naar de feed'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateActivityView extends StatelessWidget {
  const _CreateActivityView();

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return BlocListener<CreateActivityBloc, CreateActivityState>(
      listenWhen: (previous, current) =>
          previous.submissionStatus != current.submissionStatus,
      listener: (context, state) {
        final status = state.submissionStatus;
        if (status == CreateActivitySubmissionStatus.invalid) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vul titel en locatie nog even in.')),
          );
        }
        if (status == CreateActivitySubmissionStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Activiteit geplaatst.')),
          );
          context.pop();
        }
        if (status == CreateActivitySubmissionStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.errorMessage ?? 'Activiteit plaatsen is niet gelukt.',
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: colors.cream,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(child: _CreateActivityHeader()),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 140),
                      sliver: SliverList.list(
                        children: const [
                          _CreateActivityIntro(),
                          SizedBox(height: TochSpacing.lg),
                          _CreateActivityCategoryGate(),
                          CreateActivityCategoryPicker(),
                          SizedBox(height: TochSpacing.lg),
                          _CreateActivityTextFields(),
                          SizedBox(height: TochSpacing.lg),
                          _CreateActivityDateTimeSection(),
                          SizedBox(height: TochSpacing.lg),
                          CreateActivityCapacityStepper(),
                          SizedBox(height: TochSpacing.lg),
                          _CreateActivityNotesField(),
                        ],
                      ),
                    ),
                  ],
                ),
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: CreateActivityActionBar(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateActivityCategoryGate extends StatelessWidget {
  const _CreateActivityCategoryGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateActivityBloc, CreateActivityState>(
      buildWhen: (previous, current) =>
          previous.categories != current.categories ||
          previous.categoryId != current.categoryId,
      builder: (context, state) {
        if (state.categories.isNotEmpty && state.hasBackendCategoryId) {
          return const SizedBox.shrink();
        }

        final colors = context.toch;
        return Padding(
          padding: const EdgeInsets.only(bottom: TochSpacing.md),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.orangeSoft,
              borderRadius: BorderRadius.circular(TochRadius.lg),
              border: Border.all(color: colors.orange.withValues(alpha: .22)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(TochSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_rounded, color: colors.orange, size: 20),
                  const SizedBox(width: TochSpacing.sm),
                  Expanded(
                    child: Text(
                      'Categorieen konden niet geladen worden. Ga terug naar de feed en probeer opnieuw.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CreateActivityHeader extends StatelessWidget {
  const _CreateActivityHeader();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
        child: Row(
          children: [
            SizedBox(
              width: 76,
              child: TextButton(
                onPressed: context.pop,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  foregroundColor: context.toch.green700.withValues(alpha: .72),
                ),
                child: const Text('Annuleer'),
              ),
            ),
            Expanded(
              child: Text(
                'Nieuwe activiteit',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: context.toch.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 76),
          ],
        ),
      ),
    );
  }
}

class _CreateActivityIntro extends StatelessWidget {
  const _CreateActivityIntro();

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: colors.green700.withValues(alpha: .42),
              fontSize: 52,
            ),
            children: [
              const TextSpan(text: 'Ik ga'),
              TextSpan(
                text: '.',
                style: TextStyle(color: colors.orange),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Geen evenement. Je deelt gewoon wat je toch al gaat doen.',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colors.green700.withValues(alpha: .68),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CreateActivityTextFields extends StatelessWidget {
  const _CreateActivityTextFields();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LabeledField(
          label: 'Titel',
          hintText: 'bijv. avondvissen aan de Maas',
          onChanged: (value) {
            context.read<CreateActivityBloc>().add(
              CreateActivityTitleChanged(value),
            );
          },
        ),
        const SizedBox(height: TochSpacing.md),
        _LabeledField(
          label: 'Waar',
          hintText: 'Locatie of plek',
          leadingIcon: Icons.location_on_rounded,
          onChanged: (value) {
            context.read<CreateActivityBloc>().add(
              CreateActivityLocationChanged(value),
            );
          },
        ),
      ],
    );
  }
}

class _CreateActivityDateTimeSection extends StatelessWidget {
  const _CreateActivityDateTimeSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateActivityBloc, CreateActivityState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel('Wanneer'),
            const SizedBox(height: TochSpacing.xs),
            CreateActivityChoiceChips(
              options: const ['Vandaag', 'Morgen', 'Weekend'],
              selectedOption: state.day,
              expand: true,
              onSelected: (day) {
                context.read<CreateActivityBloc>().add(
                  CreateActivityDaySelected(day),
                );
              },
            ),
            const SizedBox(height: 9),
            CreateActivityChoiceChips(
              options: const ['09:00', '12:00', '17:00', '19:00', '20:30'],
              selectedOption: state.time,
              icon: Icons.schedule_rounded,
              onSelected: (time) {
                context.read<CreateActivityBloc>().add(
                  CreateActivityTimeSelected(time),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _CreateActivityNotesField extends StatelessWidget {
  const _CreateActivityNotesField();

  @override
  Widget build(BuildContext context) {
    return _LabeledField(
      label: 'Iets erbij',
      suffixLabel: '(optioneel)',
      hintText: 'Tempo, wat mee te nemen, sfeer...',
      minLines: 4,
      maxLines: 5,
      onChanged: (value) {
        context.read<CreateActivityBloc>().add(
          CreateActivityNotesChanged(value),
        );
      },
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.hintText,
    required this.onChanged,
    this.leadingIcon,
    this.suffixLabel,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final String label;
  final String hintText;
  final ValueChanged<String> onChanged;
  final IconData? leadingIcon;
  final String? suffixLabel;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SectionLabel(label),
            if (suffixLabel != null) ...[
              const SizedBox(width: 5),
              Text(
                suffixLabel!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.green700.withValues(alpha: .55),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: TochSpacing.xs),
        TextField(
          minLines: minLines,
          maxLines: maxLines,
          onChanged: onChanged,
          textInputAction: maxLines == 1
              ? TextInputAction.next
              : TextInputAction.newline,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: leadingIcon == null
                ? null
                : Icon(leadingIcon, color: colors.green),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: context.toch.green700.withValues(alpha: .62),
        fontWeight: FontWeight.w900,
        fontSize: 11,
      ),
    );
  }
}
