import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/always_24_hour_media_query.dart';
import '../../../../core/widgets/toch_snack_bar.dart';
import '../../domain/entities/home_category.dart';
import '../../domain/entities/home_location.dart';
import '../../domain/entities/meeting_location_suggestion.dart';
import '../../domain/usecases/create_activity.dart';
import '../../domain/usecases/search_meeting_locations.dart';
import '../bloc/create_activity_bloc.dart';
import '../widgets/create_activity_action_bar.dart';
import '../widgets/create_activity_capacity_stepper.dart';
import '../widgets/create_activity_category_picker.dart';

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
        sl<SearchMeetingLocations>(),
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
          final message = state.hasFutureStart
              ? 'Vul een titel in en kies een gevonden meetingplek.'
              : 'Kies een datum en tijd in de toekomst.';
          showTochSnackBar(context, message, type: TochSnackBarType.error);
        }
        if (status == CreateActivitySubmissionStatus.success) {
          showTochSnackBar(
            context,
            'Activiteit geplaatst.',
            type: TochSnackBarType.success,
          );
          context.pop();
        }
        if (status == CreateActivitySubmissionStatus.failure) {
          showTochSnackBar(
            context,
            state.errorMessage ?? 'Activiteit plaatsen is niet gelukt.',
            type: TochSnackBarType.error,
          );
        }
      },
      child: Scaffold(
        backgroundColor: colors.cream,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Stack(
              children: [
                Column(
                  children: [
                    const _CreateActivityHeader(),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 124),
                        children: const [
                          _CreateActivityHero(),
                          SizedBox(height: 18),
                          _CreateActivityCategoryGate(),
                          CreateActivityCategoryPicker(),
                          SizedBox(height: 10),
                          Divider(height: 1),
                          SizedBox(height: 16),
                          _CreateActivityFormRows(),
                          SizedBox(height: 18),
                          _CreateActivitySettingsSection(),
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
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: context.toch.card,
                shape: BoxShape.circle,
                boxShadow: TochShadows.card(context.toch),
              ),
              child: IconButton(
                tooltip: 'Sluiten',
                onPressed: () => context.pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: context.toch.ink2,
                  fixedSize: const Size.square(40),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.close_rounded, size: 22),
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
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }
}

class _CreateActivityHero extends StatelessWidget {
  const _CreateActivityHero();

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wat ga je\ndoen?',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: colors.ink,
            fontSize: 34,
            height: 1.02,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Kies een categorie om te beginnen',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colors.ink3,
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CreateActivityFormRows extends StatelessWidget {
  const _CreateActivityFormRows();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CreateActivityTextRow(
          label: 'Titel',
          icon: Icons.edit_rounded,
          hintText: 'bijv. iets doen in de buurt',
          onChanged: (value) {
            context.read<CreateActivityBloc>().add(
              CreateActivityTitleChanged(value),
            );
          },
        ),
        const SizedBox(height: 8),
        const _CreateActivityLocationField(),
        const SizedBox(height: 8),
        const _CreateActivityDateTimeSection(),
        const SizedBox(height: 8),
        const CreateActivityCapacityStepper(),
      ],
    );
  }
}

class _CreateActivityLocationField extends StatefulWidget {
  const _CreateActivityLocationField();

  @override
  State<_CreateActivityLocationField> createState() =>
      _CreateActivityLocationFieldState();
}

class _CreateActivityLocationFieldState
    extends State<_CreateActivityLocationField> {
  final TextEditingController _controller = TextEditingController();
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onLocationChanged(String value) {
    context.read<CreateActivityBloc>().add(
      CreateActivityLocationChanged(value),
    );
    _searchDebounce?.cancel();
    final query = value.trim();
    if (query.length < 3) {
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) {
        return;
      }
      context.read<CreateActivityBloc>().add(
        CreateActivityMeetingLocationSearchRequested(query),
      );
    });
  }

  void _searchNow() {
    _searchDebounce?.cancel();
    final query = _controller.text.trim();
    if (query.length < 3) {
      return;
    }
    context.read<CreateActivityBloc>().add(
      CreateActivityMeetingLocationSearchRequested(query),
    );
  }

  void _selectLocation(MeetingLocationSuggestion location) {
    _searchDebounce?.cancel();
    _controller.text = location.addressLine;
    context.read<CreateActivityBloc>().add(
      CreateActivityMeetingLocationSelected(location),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return BlocBuilder<CreateActivityBloc, CreateActivityState>(
      buildWhen: (previous, current) =>
          previous.location != current.location ||
          previous.locationResults != current.locationResults ||
          previous.locationSearchStatus != current.locationSearchStatus ||
          previous.selectedMeetingLocation != current.selectedMeetingLocation,
      builder: (context, state) {
        final results = state.locationResults;
        final isSearching =
            state.locationSearchStatus ==
            CreateActivityLocationSearchStatus.searching;
        final hasSelectedLocation = state.hasSelectedMeetingLocation;
        final canSearch = state.location.trim().length >= 3 && !isSearching;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(TochRadius.md),
                boxShadow: TochShadows.card(colors),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
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
                          Icons.location_on_outlined,
                          color: colors.green,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InlineRowLabel('Waar'),
                          TextField(
                            controller: _controller,
                            textInputAction: TextInputAction.search,
                            onChanged: _onLocationChanged,
                            onSubmitted: (_) => _searchNow(),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                              hintText: 'Typ een plek of adres',
                              contentPadding: EdgeInsets.only(top: 2),
                            ),
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: colors.ink,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  height: 1.18,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (isSearching)
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            color: colors.green,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    else
                      IconButton(
                        tooltip: hasSelectedLocation
                            ? 'Locatie gekozen'
                            : 'Zoek locatie',
                        onPressed: hasSelectedLocation
                            ? null
                            : canSearch
                            ? _searchNow
                            : null,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: hasSelectedLocation
                              ? colors.green
                              : colors.ink4,
                          fixedSize: const Size.square(36),
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: Icon(
                          hasSelectedLocation
                              ? Icons.check_rounded
                              : Icons.chevron_right_rounded,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              hasSelectedLocation
                  ? 'Gekozen meetingplek. Deze locatie wordt op de kaart gebruikt.'
                  : 'Typ minimaal 3 tekens en kies daarna 1 gevonden locatie.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.green700.withValues(alpha: .66),
                fontWeight: FontWeight.w700,
              ),
            ),
            if (results.isNotEmpty) ...[
              const SizedBox(height: TochSpacing.sm),
              _LocationResultsCard(
                results: results,
                onSelected: _selectLocation,
              ),
            ] else if (state.locationSearchStatus ==
                    CreateActivityLocationSearchStatus.failure ||
                (state.locationSearchStatus ==
                        CreateActivityLocationSearchStatus.success &&
                    state.location.trim().length >= 3 &&
                    !hasSelectedLocation)) ...[
              const SizedBox(height: TochSpacing.sm),
              _LocationSearchEmptyState(
                isFailure:
                    state.locationSearchStatus ==
                    CreateActivityLocationSearchStatus.failure,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _LocationResultsCard extends StatelessWidget {
  const _LocationResultsCard({required this.results, required this.onSelected});

  final List<MeetingLocationSuggestion> results;
  final ValueChanged<MeetingLocationSuggestion> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(TochRadius.md),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TochSpacing.md,
              TochSpacing.md,
              TochSpacing.md,
              TochSpacing.xs,
            ),
            child: Row(
              children: [
                Icon(Icons.location_searching_rounded, color: colors.green),
                const SizedBox(width: TochSpacing.sm),
                Expanded(
                  child: Text(
                    'Kies de juiste locatie',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (final result in results.take(5)) ...[
            Divider(height: 1, color: colors.line),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelected(result),
                child: Padding(
                  padding: const EdgeInsets.all(TochSpacing.md),
                  child: Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.green100,
                          borderRadius: BorderRadius.circular(TochRadius.sm),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.place_outlined,
                            color: colors.green,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: TochSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result.addressLine,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: colors.ink,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            Text(
                              result.city,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colors.green700.withValues(
                                      alpha: .68,
                                    ),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: TochSpacing.sm),
                      FilledButton(
                        onPressed: () => onSelected(result),
                        child: const Text('Kies'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LocationSearchEmptyState extends StatelessWidget {
  const _LocationSearchEmptyState({required this.isFailure});

  final bool isFailure;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(TochRadius.md),
        border: Border.all(color: colors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TochSpacing.md),
        child: Row(
          children: [
            Icon(
              isFailure ? Icons.wifi_off_rounded : Icons.search_off_rounded,
              color: colors.orange,
            ),
            const SizedBox(width: TochSpacing.sm),
            Expanded(
              child: Text(
                isFailure
                    ? 'Locaties zoeken lukt nu niet. Probeer een exactere plek of later opnieuw.'
                    : 'Geen plek gevonden. Probeer de naam met straat of plaatsnaam.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.green700.withValues(alpha: .72),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateActivityDateTimeSection extends StatelessWidget {
  const _CreateActivityDateTimeSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateActivityBloc, CreateActivityState>(
      builder: (context, state) {
        final colors = context.toch;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wanneer',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.green700.withValues(alpha: .55),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final shortcut in const ['Vandaag', 'Morgen', 'Weekend'])
                  _DateShortcutChip(
                    label: shortcut,
                    selected: _isSameDate(
                      state.selectedDate,
                      _dateForShortcut(shortcut),
                    ),
                    onSelected: () {
                      context.read<CreateActivityBloc>().add(
                        CreateActivityDateShortcutSelected(shortcut),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _DateTimePickerTile(
                    label: 'Datum',
                    value: state.dateLabel,
                    icon: Icons.calendar_month_rounded,
                    onTap: () => _pickDate(context, state),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DateTimePickerTile(
                    label: 'Tijd',
                    value: state.timeLabel,
                    icon: Icons.schedule_rounded,
                    onTap: () => _pickTime(context, state),
                  ),
                ),
              ],
            ),
            if (!state.hasFutureStart) ...[
              const SizedBox(height: 8),
              Text(
                'Kies een moment dat nog moet komen.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.orange,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    CreateActivityState state,
  ) async {
    final today = _today();
    final selectedDate = state.selectedDate.isBefore(today)
        ? today
        : state.selectedDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'Kies een datum',
      cancelText: 'Annuleer',
      confirmText: 'Kies',
    );
    if (!context.mounted || pickedDate == null) {
      return;
    }
    context.read<CreateActivityBloc>().add(
      CreateActivityDateSelected(pickedDate),
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    CreateActivityState state,
  ) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: state.selectedHour,
        minute: state.selectedMinute,
      ),
      initialEntryMode: TimePickerEntryMode.dial,
      helpText: 'Kies een tijd',
      cancelText: 'Annuleer',
      confirmText: 'Kies',
      hourLabelText: 'Uur',
      minuteLabelText: 'Minuut',
      builder: (context, child) {
        return Always24HourMediaQuery(child: child ?? const SizedBox.shrink());
      },
    );
    if (!context.mounted || pickedTime == null) {
      return;
    }
    context.read<CreateActivityBloc>().add(
      CreateActivityTimeSelected(
        hour: pickedTime.hour,
        minute: pickedTime.minute,
      ),
    );
  }
}

class _DateShortcutChip extends StatelessWidget {
  const _DateShortcutChip({
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
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: selected ? Colors.white : colors.ink,
        fontWeight: FontWeight.w900,
      ),
      backgroundColor: colors.card,
      selectedColor: colors.green,
      side: BorderSide(color: selected ? colors.green : colors.line),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TochRadius.pill),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    );
  }
}

class _DateTimePickerTile extends StatelessWidget {
  const _DateTimePickerTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(TochRadius.lg),
      shadowColor: colors.ink.withValues(alpha: .08),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TochRadius.lg),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TochRadius.lg),
            border: Border.all(color: colors.line),
          ),
          child: Row(
            children: [
              Icon(icon, color: colors.green, size: 22),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.green700.withValues(alpha: .62),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.green700.withValues(alpha: .45),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateActivitySettingsSection extends StatelessWidget {
  const _CreateActivitySettingsSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateActivityBloc, CreateActivityState>(
      buildWhen: (previous, current) =>
          previous.requiresIdentityVerified !=
              current.requiresIdentityVerified ||
          previous.groupType != current.groupType ||
          previous.isPrivateLocation != current.isPrivateLocation,
      builder: (context, state) {
        final colors = context.toch;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deelname-instellingen',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.ink,
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(TochRadius.lg),
                boxShadow: TochShadows.card(colors),
              ),
              child: Column(
                children: [
                  _SettingsSwitchRow(
                    icon: Icons.verified_user_outlined,
                    title: 'Geverifieerd profiel nodig',
                    subtitle: 'Alleen leden met bevestigde identiteit',
                    value: state.requiresIdentityVerified,
                    onChanged: (value) {
                      context.read<CreateActivityBloc>().add(
                        CreateActivityIdentityRequirementToggled(value),
                      );
                    },
                  ),
                  Divider(height: 1, color: colors.line),
                  _SettingsSwitchRow(
                    icon: Icons.groups_2_outlined,
                    title: 'Goedkeuren wie aansluit',
                    subtitle: 'Jij beslist wie mag meedoen',
                    value: state.groupType == 'approval',
                    onChanged: (value) {
                      context.read<CreateActivityBloc>().add(
                        CreateActivityGroupTypeSelected(
                          value ? 'approval' : 'open',
                        ),
                      );
                    },
                  ),
                  Divider(height: 1, color: colors.line),
                  _SettingsSwitchRow(
                    icon: Icons.location_on_outlined,
                    title: 'Locatie privé',
                    subtitle: 'Exacte plek pas na aanmelding',
                    value: state.isPrivateLocation,
                    onChanged: (value) {
                      context.read<CreateActivityBloc>().add(
                        CreateActivityPrivateLocationToggled(value),
                      );
                    },
                  ),
                ],
              ),
            ),
            if (state.isPrivateLocation) ...[
              const SizedBox(height: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.orangeSoft,
                  borderRadius: BorderRadius.circular(TochRadius.md),
                  border: Border.all(
                    color: colors.orange.withValues(alpha: .2),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_rounded, color: colors.orange, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Voor eerste ontmoetingen werkt een openbare plek meestal beter.',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: colors.ink,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SettingsSwitchRow extends StatelessWidget {
  const _SettingsSwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          _RowIcon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    height: 1.18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.ink4,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: colors.green,
            inactiveThumbColor: colors.card,
            inactiveTrackColor: colors.line,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

class _CreateActivityTextRow extends StatelessWidget {
  const _CreateActivityTextRow({
    required this.label,
    required this.hintText,
    required this.onChanged,
    required this.icon,
  });

  final String label;
  final String hintText;
  final ValueChanged<String> onChanged;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(TochRadius.md),
        boxShadow: TochShadows.card(colors),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            _RowIcon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InlineRowLabel(label),
                  TextField(
                    onChanged: onChanged,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      hintText: hintText,
                      contentPadding: const EdgeInsets.only(top: 2),
                    ),
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
            Icon(Icons.chevron_right_rounded, color: colors.ink4, size: 20),
          ],
        ),
      ),
    );
  }
}

class _RowIcon extends StatelessWidget {
  const _RowIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.green100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: SizedBox.square(
        dimension: 36,
        child: Icon(icon, color: colors.green, size: 19),
      ),
    );
  }
}

class _InlineRowLabel extends StatelessWidget {
  const _InlineRowLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: context.toch.ink4,
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

DateTime _dateForShortcut(String shortcut) {
  final today = _today();
  return switch (shortcut) {
    'Morgen' => today.add(const Duration(days: 1)),
    'Weekend' => _nextSaturdayOrToday(today),
    _ => today,
  };
}

DateTime _nextSaturdayOrToday(DateTime today) {
  const saturday = DateTime.saturday;
  final daysUntilSaturday = (saturday - today.weekday) % DateTime.daysPerWeek;
  return today.add(Duration(days: daysUntilSaturday));
}

bool _isSameDate(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}
