import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/toch_theme.dart';
import '../../../../app/widgets/toch_wordmark.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/toch_category_icons.dart';
import '../../../../core/widgets/toch_snack_bar.dart';
import '../../../home/domain/entities/home_feed_filters.dart';
import '../../domain/entities/profile_avatar_file.dart';
import '../../domain/entities/profile_interest.dart';
import '../bloc/profile_setup_bloc.dart';

class ProfileSetupPage extends StatelessWidget {
  const ProfileSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProfileSetupBloc>()..add(const ProfileSetupStarted()),
      child: const _ProfileSetupView(),
    );
  }
}

class _ProfileSetupView extends StatefulWidget {
  const _ProfileSetupView();

  @override
  State<_ProfileSetupView> createState() => _ProfileSetupViewState();
}

class _ProfileSetupViewState extends State<_ProfileSetupView> {
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int stepIndex) {
    context.read<ProfileSetupBloc>().add(ProfileSetupStepChanged(stepIndex));
    _pageController.animateToPage(
      stepIndex,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return BlocConsumer<ProfileSetupBloc, ProfileSetupState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == ProfileSetupStatus.invalid) {
          showTochSnackBar(
            context,
            'Vul alle verplichte velden in.',
            type: TochSnackBarType.error,
          );
        }
        if (state.status == ProfileSetupStatus.failure) {
          showTochSnackBar(
            context,
            state.errorMessage ?? 'Profiel aanmaken mislukt.',
            type: TochSnackBarType.error,
          );
        }
        if (state.status == ProfileSetupStatus.success) {
          context.go(AppRoutes.home);
        }
      },
      builder: (context, state) {
        final isLoading = state.status == ProfileSetupStatus.loading;
        final isSubmitting = state.status == ProfileSetupStatus.submitting;

        return Scaffold(
          backgroundColor: colors.cream,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(TochRadius.lg),
                      border: Border.all(color: colors.line),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(TochSpacing.lg),
                      child: isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                color: colors.green,
                              ),
                            )
                          : Column(
                              children: [
                                const _SetupHeader(),
                                const SizedBox(height: TochSpacing.md),
                                _ProgressDots(stepIndex: state.stepIndex),
                                const SizedBox(height: TochSpacing.lg),
                                Expanded(
                                  child: PageView(
                                    controller: _pageController,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    onPageChanged: (index) {
                                      context.read<ProfileSetupBloc>().add(
                                        ProfileSetupStepChanged(index),
                                      );
                                    },
                                    children: const [
                                      _NameStep(),
                                      _CityStep(),
                                      _DemographicsStep(),
                                      _InterestsStep(),
                                      _AvatarStep(),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: TochSpacing.md),
                                _SetupActions(
                                  isSubmitting: isSubmitting,
                                  onBack: state.stepIndex == 0
                                      ? null
                                      : () => _goToStep(state.stepIndex - 1),
                                  onNext: () {
                                    if (!_canContinueCurrentStep(state)) {
                                      showTochSnackBar(
                                        context,
                                        _validationMessageFor(state.stepIndex),
                                        type: TochSnackBarType.error,
                                      );
                                      return;
                                    }
                                    if (state.stepIndex == 4) {
                                      context.read<ProfileSetupBloc>().add(
                                        const ProfileSetupSubmitted(),
                                      );
                                      return;
                                    }
                                    _goToStep(state.stepIndex + 1);
                                  },
                                  nextLabel: state.stepIndex == 4
                                      ? 'Profiel opslaan'
                                      : 'Verder',
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

bool _canContinueCurrentStep(ProfileSetupState state) {
  return switch (state.stepIndex) {
    0 => state.hasValidName,
    1 => state.hasValidCity,
    2 => state.hasSelectedDemographics,
    3 => state.hasSelectedInterests,
    _ => state.canSubmit,
  };
}

String _validationMessageFor(int stepIndex) {
  return switch (stepIndex) {
    0 => 'Vul je naam in.',
    1 => 'Vul je plaats in.',
    2 => 'Kies je leeftijdsband en doelgroepweergave.',
    3 => 'Kies minimaal een interesse.',
    _ => 'Vul alle verplichte velden in.',
  };
}

class _SetupHeader extends StatelessWidget {
  const _SetupHeader();

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TochWordmark(fontSize: 28),
        const SizedBox(height: TochSpacing.lg),
        Text(
          'Maak je profiel af',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: colors.green,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: TochSpacing.xs),
        Text(
          'Zo weten anderen met wie ze afspreken. Je foto mag later ook.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.stepIndex});

  final int stepIndex;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Row(
      children: List.generate(5, (index) {
        final selected = index == stepIndex;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 6,
            margin: EdgeInsets.only(right: index == 4 ? 0 : 8),
            decoration: BoxDecoration(
              color: selected ? colors.green : colors.line,
              borderRadius: BorderRadius.circular(TochRadius.pill),
            ),
          ),
        );
      }),
    );
  }
}

class _NameStep extends StatelessWidget {
  const _NameStep();

  @override
  Widget build(BuildContext context) {
    return _StepSurface(
      icon: Icons.badge_rounded,
      title: 'Hoe heet je?',
      body: 'Gebruik je echte naam. Zo weten mensen wie er meedoet.',
      child: BlocBuilder<ProfileSetupBloc, ProfileSetupState>(
        buildWhen: (previous, current) =>
            previous.displayName != current.displayName,
        builder: (context, state) {
          return TextFormField(
            initialValue: state.displayName,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: 'Naam'),
            onChanged: (value) {
              context.read<ProfileSetupBloc>().add(
                ProfileSetupDisplayNameChanged(value),
              );
            },
          );
        },
      ),
    );
  }
}

class _CityStep extends StatelessWidget {
  const _CityStep();

  @override
  Widget build(BuildContext context) {
    return _StepSurface(
      icon: Icons.location_city_rounded,
      title: 'Waar ben je meestal?',
      body: 'Je plaats wordt op je profiel getoond en helpt lokaal zoeken.',
      child: BlocBuilder<ProfileSetupBloc, ProfileSetupState>(
        buildWhen: (previous, current) => previous.cityName != current.cityName,
        builder: (context, state) {
          return TextFormField(
            initialValue: state.cityName,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: 'Plaats'),
            onChanged: (value) {
              context.read<ProfileSetupBloc>().add(
                ProfileSetupCityChanged(value),
              );
            },
          );
        },
      ),
    );
  }
}

class _DemographicsStep extends StatelessWidget {
  const _DemographicsStep();

  @override
  Widget build(BuildContext context) {
    return _StepSurface(
      icon: Icons.tune_rounded,
      title: 'Voor wie zijn activiteiten bedoeld?',
      body:
          'We gebruiken dit voor event-doelgroepen en filters. Je exacte geboortedatum wordt niet gevraagd.',
      child: BlocBuilder<ProfileSetupBloc, ProfileSetupState>(
        buildWhen: (previous, current) =>
            previous.ageBand != current.ageBand ||
            previous.gender != current.gender,
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Leeftijdsband',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: context.toch.green700.withValues(alpha: .68),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: TochSpacing.xs),
              Wrap(
                spacing: TochSpacing.xs,
                runSpacing: TochSpacing.xs,
                children: [
                  for (final ageBand in tochAgeBands)
                    _SetupChoiceChip(
                      label: ageBandLabel(ageBand),
                      selected: state.ageBand == ageBand,
                      onSelected: () {
                        context.read<ProfileSetupBloc>().add(
                          ProfileSetupAgeBandSelected(ageBand),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: TochSpacing.lg),
              Text(
                'Gender',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: context.toch.green700.withValues(alpha: .68),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: TochSpacing.xs),
              Wrap(
                spacing: TochSpacing.xs,
                runSpacing: TochSpacing.xs,
                children: [
                  for (final gender in tochGenderValues)
                    _SetupChoiceChip(
                      label: genderLabel(gender),
                      selected: state.gender == gender,
                      onSelected: () {
                        context.read<ProfileSetupBloc>().add(
                          ProfileSetupGenderSelected(gender),
                        );
                      },
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InterestsStep extends StatelessWidget {
  const _InterestsStep();

  @override
  Widget build(BuildContext context) {
    return _StepSurface(
      icon: Icons.interests_rounded,
      title: 'Wat doe je graag?',
      body: 'Kies minimaal een interesse. Dit maakt je profiel herkenbaar.',
      child: BlocBuilder<ProfileSetupBloc, ProfileSetupState>(
        buildWhen: (previous, current) =>
            previous.availableInterests != current.availableInterests ||
            previous.selectedInterestIds != current.selectedInterestIds,
        builder: (context, state) {
          return Wrap(
            spacing: TochSpacing.xs,
            runSpacing: TochSpacing.xs,
            children: state.availableInterests.map((interest) {
              final selected = state.selectedInterestIds.contains(interest.id);
              return _InterestChip(interest: interest, selected: selected);
            }).toList(),
          );
        },
      ),
    );
  }
}

class _AvatarStep extends StatelessWidget {
  const _AvatarStep();

  @override
  Widget build(BuildContext context) {
    return _StepSurface(
      icon: Icons.photo_camera_rounded,
      title: 'Voeg een foto toe',
      body: 'Optioneel, maar wel fijn voor vertrouwen. Je kunt dit overslaan.',
      child: BlocBuilder<ProfileSetupBloc, ProfileSetupState>(
        buildWhen: (previous, current) =>
            previous.avatarFile != current.avatarFile ||
            previous.displayName != current.displayName,
        builder: (context, state) {
          final avatarFile = state.avatarFile;
          final avatarImage = avatarFile == null
              ? null
              : MemoryImage(Uint8List.fromList(avatarFile.bytes));

          return Column(
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: context.toch.green,
                foregroundImage: avatarImage,
                child: avatarImage == null
                    ? Text(
                        _initialsFor(state.displayName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: TochSpacing.md),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: TochSpacing.sm,
                runSpacing: TochSpacing.xs,
                children: [
                  FilledButton.icon(
                    onPressed: () => _pickAvatar(context),
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Foto kiezen'),
                  ),
                  if (avatarFile != null)
                    OutlinedButton.icon(
                      onPressed: () {
                        context.read<ProfileSetupBloc>().add(
                          const ProfileSetupAvatarRemoved(),
                        );
                      },
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Wissen'),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickAvatar(BuildContext context) async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 88,
    );
    if (image == null || !context.mounted) {
      return;
    }

    final bytes = await image.readAsBytes();
    if (!context.mounted) {
      return;
    }
    if (bytes.length > 5 * 1024 * 1024) {
      showTochSnackBar(
        context,
        'Kies een afbeelding kleiner dan 5 MB.',
        type: TochSnackBarType.error,
      );
      return;
    }

    final mimeType = image.mimeType ?? _mimeTypeForFileName(image.name);
    if (mimeType == null) {
      showTochSnackBar(
        context,
        'Kies een jpeg, png, webp of gif afbeelding.',
        type: TochSnackBarType.error,
      );
      return;
    }

    context.read<ProfileSetupBloc>().add(
      ProfileSetupAvatarPicked(
        ProfileAvatarFile(
          bytes: bytes,
          fileName: image.name.isEmpty ? 'avatar.jpg' : image.name,
          mimeType: mimeType,
        ),
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({required this.interest, required this.selected});

  final ProfileInterest interest;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return FilterChip(
      selected: selected,
      label: Text(interest.label),
      avatar: Icon(
        tochCategoryIcon(
          id: interest.id,
          label: interest.label,
          iconKey: interest.iconKey,
        ),
        size: 18,
        color: selected
            ? colors.cream
            : _colorFromHex(
                interest.foregroundColorHex,
                fallback: colors.green,
              ),
      ),
      selectedColor: colors.green,
      backgroundColor: _colorFromHex(
        interest.backgroundColorHex,
        fallback: colors.green100,
      ),
      labelStyle: TextStyle(
        color: selected ? colors.cream : colors.ink,
        fontWeight: FontWeight.w900,
      ),
      side: BorderSide(color: selected ? colors.green : colors.line),
      onSelected: (_) {
        context.read<ProfileSetupBloc>().add(
          ProfileSetupInterestToggled(interest.id),
        );
      },
    );
  }
}

class _SetupChoiceChip extends StatelessWidget {
  const _SetupChoiceChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: colors.green,
      backgroundColor: colors.card,
      side: BorderSide(color: selected ? colors.green : colors.line),
      labelStyle: TextStyle(
        color: selected ? colors.cream : colors.ink,
        fontWeight: FontWeight.w900,
      ),
      onSelected: (_) => onSelected(),
    );
  }
}

class _StepSurface extends StatelessWidget {
  const _StepSurface({
    required this.icon,
    required this.title,
    required this.body,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.green100,
            borderRadius: BorderRadius.circular(TochRadius.lg),
          ),
          child: SizedBox(
            height: 120,
            child: Icon(icon, color: colors.green, size: 54),
          ),
        ),
        const SizedBox(height: TochSpacing.lg),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: colors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: TochSpacing.xs),
        Text(body, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: TochSpacing.lg),
        child,
      ],
    );
  }
}

class _SetupActions extends StatelessWidget {
  const _SetupActions({
    required this.isSubmitting,
    required this.onNext,
    required this.nextLabel,
    this.onBack,
  });

  final bool isSubmitting;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isSubmitting ? null : onBack,
            child: const Text('Terug'),
          ),
        ),
        const SizedBox(width: TochSpacing.sm),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: isSubmitting ? null : onNext,
            icon: isSubmitting
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.arrow_forward_rounded),
            label: Text(nextLabel),
          ),
        ),
      ],
    );
  }
}

String _initialsFor(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) {
    return '';
  }
  if (parts.length == 1) {
    return parts.first
        .substring(0, parts.first.length.clamp(0, 2))
        .toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

Color _colorFromHex(String hex, {required Color fallback}) {
  final normalized = hex.replaceFirst('#', '').trim();
  if (normalized.length != 6 && normalized.length != 8) {
    return fallback;
  }

  final value = int.tryParse(normalized, radix: 16);
  if (value == null) {
    return fallback;
  }

  return Color(normalized.length == 6 ? 0xFF000000 | value : value);
}

String? _mimeTypeForFileName(String fileName) {
  final extension = fileName.split('.').last.toLowerCase();
  return switch (extension) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    'gif' => 'image/gif',
    _ => null,
  };
}
