import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/always_24_hour_media_query.dart';
import '../../../../core/widgets/toch_snack_bar.dart';
import '../../domain/entities/home_category.dart';
import '../../domain/entities/home_feed_filters.dart';
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
                          _CreateActivityAccessSection(),
                          SizedBox(height: TochSpacing.lg),
                          _CreateActivityAudienceSection(),
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
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              child: TextButton(
                onPressed: () => context.pop(),
                style: TextButton.styleFrom(
                  foregroundColor: context.toch.ink3,
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
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
            const SizedBox(width: 96),
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
        Text.rich(
          TextSpan(
            text: 'Ik ga',
            children: [
              TextSpan(
                text: '.',
                style: TextStyle(color: colors.orange),
              ),
            ],
          ),
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            color: colors.ink4,
            fontSize: 72,
            height: .94,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Geen evenement. Je deelt gewoon wat je toch al gaat doen.',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: colors.ink3,
            fontWeight: FontWeight.w800,
            height: 1.3,
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
          icon: Icons.edit_rounded,
          hintText: 'bijv. avondvissen aan de Maas',
          onChanged: (value) {
            context.read<CreateActivityBloc>().add(
              CreateActivityTitleChanged(value),
            );
          },
        ),
        const SizedBox(height: TochSpacing.md),
        const _CreateActivityLocationField(),
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
            const _SectionLabel('Waar'),
            const SizedBox(height: TochSpacing.xs),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(22),
                boxShadow: TochShadows.card(colors),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                child: Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.green100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SizedBox.square(
                        dimension: 44,
                        child: Icon(
                          Icons.location_on_rounded,
                          color: colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.search,
                        onChanged: _onLocationChanged,
                        onSubmitted: (_) => _searchNow(),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: 'Typ een plek of adres',
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: colors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    if (isSearching)
                      Padding(
                        padding: const EdgeInsets.all(12),
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
                          backgroundColor: hasSelectedLocation
                              ? colors.green100
                              : colors.green100.withValues(alpha: .7),
                          foregroundColor: colors.green,
                          fixedSize: const Size.square(48),
                        ),
                        icon: Icon(
                          hasSelectedLocation
                              ? Icons.check_rounded
                              : Icons.keyboard_arrow_down_rounded,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: TochSpacing.xs),
            Text(
              hasSelectedLocation
                  ? 'Gekozen meetingplek. Deze locatie wordt op de kaart gebruikt.'
                  : 'Typ minimaal 3 tekens, tik op zoeken en kies daarna 1 locatie.',
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel('Wanneer'),
            const SizedBox(height: TochSpacing.xs),
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
            const SizedBox(height: TochSpacing.sm),
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
                const SizedBox(width: TochSpacing.sm),
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
              const SizedBox(height: TochSpacing.xs),
              Row(
                children: [
                  Icon(
                    Icons.info_rounded,
                    color: context.toch.orange,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Kies een moment dat nog moet komen.',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: context.toch.orange,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
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
      initialEntryMode: TimePickerEntryMode.input,
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
            ],
          ),
        ),
      ),
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
      icon: Icons.notes_rounded,
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

class _CreateActivityAudienceSection extends StatelessWidget {
  const _CreateActivityAudienceSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateActivityBloc, CreateActivityState>(
      buildWhen: (previous, current) =>
          previous.targetAgeBands != current.targetAgeBands ||
          previous.targetGenders != current.targetGenders,
      builder: (context, state) {
        final colors = context.toch;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel('Doelgroep'),
            const SizedBox(height: TochSpacing.xs),
            Text(
              'Laat leeg als iedereen welkom is. Dit wordt alleen gebruikt om deelname te matchen met expliciete event-doelgroepen.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.green700.withValues(alpha: .72),
                fontWeight: FontWeight.w700,
                height: 1.32,
              ),
            ),
            const SizedBox(height: TochSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final ageBand in tochAgeBands)
                  _AudienceChip(
                    label: ageBandLabel(ageBand),
                    selected: state.targetAgeBands.contains(ageBand),
                    onSelected: () {
                      context.read<CreateActivityBloc>().add(
                        CreateActivityTargetAgeBandToggled(ageBand),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: TochSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final gender in tochGenderValues)
                  _AudienceChip(
                    label: genderLabel(gender),
                    selected: state.targetGenders.contains(gender),
                    onSelected: () {
                      context.read<CreateActivityBloc>().add(
                        CreateActivityTargetGenderToggled(gender),
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

class _AudienceChip extends StatelessWidget {
  const _AudienceChip({
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

    return FilterChip(
      selected: selected,
      label: Text(label),
      selectedColor: colors.green,
      backgroundColor: colors.card,
      side: BorderSide(color: selected ? colors.green : colors.line),
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: selected ? colors.cream : colors.ink,
        fontWeight: FontWeight.w900,
      ),
      onSelected: (_) => onSelected(),
    );
  }
}

class _CreateActivityAccessSection extends StatelessWidget {
  const _CreateActivityAccessSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateActivityBloc, CreateActivityState>(
      buildWhen: (previous, current) =>
          previous.groupType != current.groupType ||
          previous.minReputationLevel != current.minReputationLevel ||
          previous.isPrivateLocation != current.isPrivateLocation,
      builder: (context, state) {
        final colors = context.toch;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel('Toelating'),
            const SizedBox(height: TochSpacing.xs),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _AccessChoiceChip(
                  label: 'Open groep',
                  value: 'open',
                  icon: Icons.group_add_rounded,
                ),
                _AccessChoiceChip(
                  label: 'Goedkeuring',
                  value: 'approval',
                  icon: Icons.fact_check_rounded,
                ),
              ],
            ),
            const SizedBox(height: TochSpacing.md),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(22),
                boxShadow: TochShadows.card(colors),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                    child: Row(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.green100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: SizedBox.square(
                            dimension: 42,
                            child: Icon(
                              Icons.workspace_premium_rounded,
                              color: colors.green,
                              size: 21,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: state.minReputationLevel,
                              isExpanded: true,
                              icon: const Icon(Icons.expand_more_rounded),
                              items: const [
                                DropdownMenuItem(
                                  value: 'new_member',
                                  child: Text('Minimum: Nieuw lid'),
                                ),
                                DropdownMenuItem(
                                  value: 'active_member',
                                  child: Text('Minimum: Actief lid'),
                                ),
                                DropdownMenuItem(
                                  value: 'known_member',
                                  child: Text('Minimum: Bekend lid'),
                                ),
                                DropdownMenuItem(
                                  value: 'top_participant',
                                  child: Text('Minimum: Top deelnemer'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                context.read<CreateActivityBloc>().add(
                                  CreateActivityMinReputationSelected(value),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: colors.line),
                  SwitchListTile(
                    value: state.isPrivateLocation,
                    contentPadding: const EdgeInsets.fromLTRB(14, 4, 10, 4),
                    secondary: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.green100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SizedBox.square(
                        dimension: 42,
                        child: Icon(
                          Icons.home_work_rounded,
                          color: colors.green,
                          size: 21,
                        ),
                      ),
                    ),
                    title: const Text('Prive- of thuislocatie'),
                    subtitle: const Text(
                      'Kies dit alleen als de plek niet openbaar toegankelijk is.',
                    ),
                    activeThumbColor: colors.green,
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
              const SizedBox(height: TochSpacing.xs),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.orangeSoft,
                  borderRadius: BorderRadius.circular(TochRadius.md),
                  border: Border.all(
                    color: colors.orange.withValues(alpha: .2),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(TochSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_rounded, color: colors.orange, size: 18),
                      const SizedBox(width: TochSpacing.xs),
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

class _AccessChoiceChip extends StatelessWidget {
  const _AccessChoiceChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateActivityBloc, CreateActivityState>(
      buildWhen: (previous, current) => previous.groupType != current.groupType,
      builder: (context, state) {
        final colors = context.toch;
        final selected = state.groupType == value;

        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17),
              const SizedBox(width: 6),
              Text(label),
            ],
          ),
          selected: selected,
          onSelected: (_) {
            context.read<CreateActivityBloc>().add(
              CreateActivityGroupTypeSelected(value),
            );
          },
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
      },
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.hintText,
    required this.onChanged,
    this.icon,
    this.suffixLabel,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final String label;
  final String hintText;
  final ValueChanged<String> onChanged;
  final IconData? icon;
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
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(22),
            boxShadow: TochShadows.card(colors),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(14, maxLines == 1 ? 8 : 12, 14, 8),
            child: Row(
              crossAxisAlignment: maxLines == 1
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.green100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SizedBox.square(
                      dimension: 44,
                      child: Icon(icon, color: colors.green, size: 21),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: TextField(
                    minLines: minLines,
                    maxLines: maxLines,
                    onChanged: onChanged,
                    textInputAction: maxLines == 1
                        ? TextInputAction.next
                        : TextInputAction.newline,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: hintText,
                      contentPadding: maxLines == 1
                          ? EdgeInsets.zero
                          : const EdgeInsets.only(top: 2),
                    ),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
