import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../home/domain/entities/home_feed_filters.dart';
import '../../domain/entities/profile.dart';
import '../../domain/entities/profile_avatar_file.dart';
import '../../domain/usecases/update_profile.dart';
import '../bloc/edit_profile_bloc.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({required this.profile, super.key});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EditProfileBloc(sl<UpdateProfile>(), profile),
      child: const _EditProfileView(),
    );
  }
}

class MissingEditProfilePage extends StatelessWidget {
  const MissingEditProfilePage({super.key});

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
                Icon(Icons.person_off_rounded, color: colors.orange, size: 44),
                const SizedBox(height: TochSpacing.md),
                Text(
                  'Profiel niet gevonden',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: TochSpacing.lg),
                ElevatedButton(
                  onPressed: () => context.go('/profile'),
                  child: const Text('Terug naar profiel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditProfileView extends StatelessWidget {
  const _EditProfileView();

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return BlocListener<EditProfileBloc, EditProfileState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == EditProfileStatus.invalid) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vul je naam, plaats, leeftijdsband en gender in.'),
            ),
          );
        }
        if (state.status == EditProfileStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Profiel opslaan mislukt.'),
            ),
          );
        }
        if (state.status == EditProfileStatus.success) {
          context.pop(state.profile);
        }
      },
      child: Scaffold(
        backgroundColor: colors.cream,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
                children: const [
                  _EditProfileTopBar(),
                  SizedBox(height: TochSpacing.lg),
                  _EditProfileAvatarPreview(),
                  SizedBox(height: TochSpacing.xl),
                  _EditProfileForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditProfileTopBar extends StatelessWidget {
  const _EditProfileTopBar();

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Row(
      children: [
        SizedBox(
          width: 78,
          child: TextButton(
            onPressed: context.pop,
            style: TextButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.zero,
              foregroundColor: colors.green700.withValues(alpha: .72),
            ),
            child: const Text('Annuleer'),
          ),
        ),
        Expanded(
          child: Text(
            'Profiel bewerken',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        SizedBox(
          width: 78,
          child: BlocBuilder<EditProfileBloc, EditProfileState>(
            buildWhen: (previous, current) =>
                previous.isValid != current.isValid ||
                previous.status != current.status,
            builder: (context, state) {
              final isSubmitting = state.status == EditProfileStatus.submitting;
              return TextButton(
                onPressed: state.isValid && !isSubmitting
                    ? () {
                        context.read<EditProfileBloc>().add(
                          const EditProfileSubmitted(),
                        );
                      }
                    : null,
                style: TextButton.styleFrom(alignment: Alignment.centerRight),
                child: isSubmitting
                    ? SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.green,
                        ),
                      )
                    : const Text('Bewaar'),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EditProfileAvatarPreview extends StatelessWidget {
  const _EditProfileAvatarPreview();

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return BlocBuilder<EditProfileBloc, EditProfileState>(
      buildWhen: (previous, current) =>
          previous.displayName != current.displayName ||
          previous.avatarUrl != current.avatarUrl ||
          previous.avatarFile != current.avatarFile ||
          previous.removeAvatar != current.removeAvatar,
      builder: (context, state) {
        final avatarImage = _avatarImageFor(state);

        return Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: colors.green,
              backgroundImage: avatarImage,
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
            const SizedBox(height: TochSpacing.sm),
            Text(
              state.displayName.trim().isEmpty
                  ? 'Jouw naam'
                  : state.displayName.trim(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w900,
              ),
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
                if (avatarImage != null)
                  OutlinedButton.icon(
                    onPressed: () {
                      context.read<EditProfileBloc>().add(
                        const EditProfileAvatarRemoved(),
                      );
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Verwijder'),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickAvatar(BuildContext context) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kies een afbeelding kleiner dan 5 MB.')),
      );
      return;
    }

    final mimeType = image.mimeType ?? _mimeTypeForFileName(image.name);
    if (mimeType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kies een jpeg, png, webp of gif afbeelding.'),
        ),
      );
      return;
    }

    context.read<EditProfileBloc>().add(
      EditProfileAvatarPicked(
        ProfileAvatarFile(
          bytes: bytes,
          fileName: image.name.isEmpty ? 'avatar.jpg' : image.name,
          mimeType: mimeType,
        ),
      ),
    );
  }
}

class _EditProfileForm extends StatelessWidget {
  const _EditProfileForm();

  @override
  Widget build(BuildContext context) {
    final state = context.read<EditProfileBloc>().state;

    return Column(
      children: [
        _ProfileField(
          label: 'Naam',
          initialValue: state.displayName,
          textInputAction: TextInputAction.next,
          onChanged: (value) {
            context.read<EditProfileBloc>().add(
              EditProfileDisplayNameChanged(value),
            );
          },
        ),
        const SizedBox(height: TochSpacing.md),
        const _EditDemographicsSection(),
        const SizedBox(height: TochSpacing.md),
        _ProfileField(
          label: 'Plaats',
          initialValue: state.cityName,
          textInputAction: TextInputAction.next,
          onChanged: (value) {
            context.read<EditProfileBloc>().add(EditProfileCityChanged(value));
          },
        ),
      ],
    );
  }
}

class _EditDemographicsSection extends StatelessWidget {
  const _EditDemographicsSection();

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return BlocBuilder<EditProfileBloc, EditProfileState>(
      buildWhen: (previous, current) =>
          previous.ageBand != current.ageBand ||
          previous.gender != current.gender,
      builder: (context, state) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(TochRadius.lg),
            border: Border.all(color: colors.line),
          ),
          child: Padding(
            padding: const EdgeInsets.all(TochSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Doelgroep',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: TochSpacing.xs),
                Text(
                  'We gebruiken dit alleen om te controleren of je past binnen activiteiten die expliciet een doelgroep kiezen.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.green700.withValues(alpha: .74),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: TochSpacing.md),
                Text(
                  'Leeftijdsband',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: TochSpacing.xs),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final ageBand in tochAgeBands)
                      _EditChoiceChip(
                        label: ageBandLabel(ageBand),
                        selected: state.ageBand == ageBand,
                        onSelected: () => context.read<EditProfileBloc>().add(
                          EditProfileAgeBandSelected(ageBand),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: TochSpacing.md),
                Text(
                  'Gender',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: TochSpacing.xs),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final gender in tochGenderValues)
                      _EditChoiceChip(
                        label: genderLabel(gender),
                        selected: state.gender == gender,
                        onSelected: () => context.read<EditProfileBloc>().add(
                          EditProfileGenderSelected(gender),
                        ),
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

class _EditChoiceChip extends StatelessWidget {
  const _EditChoiceChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.textInputAction,
  });

  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      textInputAction: textInputAction,
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label),
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

ImageProvider<Object>? _avatarImageFor(EditProfileState state) {
  final avatarFile = state.avatarFile;
  if (avatarFile != null) {
    return MemoryImage(Uint8List.fromList(avatarFile.bytes));
  }

  if (state.removeAvatar || state.avatarUrl.trim().isEmpty) {
    return null;
  }

  return NetworkImage(state.avatarUrl.trim());
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
