import 'package:flutter/material.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../domain/entities/home_category.dart';
import '../../domain/entities/home_feed_filters.dart';
import 'home_category_style.dart';

Future<HomeFeedFilters?> showHomeFilterSheet({
  required BuildContext context,
  required HomeFeedFilters filters,
  required List<HomeCategory> categories,
}) {
  return showModalBottomSheet<HomeFeedFilters>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return HomeFilterSheet(filters: filters, categories: categories);
    },
  );
}

class HomeFilterButton extends StatelessWidget {
  const HomeFilterButton({
    required this.hasActiveFilters,
    required this.onPressed,
    super.key,
  });

  final bool hasActiveFilters;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
      child: SizedBox(
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: hasActiveFilters ? colors.green100 : colors.surface2,
            borderRadius: BorderRadius.circular(TochRadius.xl),
            border: Border.all(
              color: hasActiveFilters ? colors.green200 : colors.line,
            ),
          ),
          child: TextButton.icon(
            onPressed: onPressed,
            icon: Icon(
              hasActiveFilters ? Icons.tune_rounded : Icons.filter_list_rounded,
              size: 19,
            ),
            label: Text(hasActiveFilters ? 'Filters actief' : 'Meer filters'),
            style: TextButton.styleFrom(
              foregroundColor: colors.green,
              minimumSize: const Size(0, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TochRadius.xl),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeFilterSheet extends StatefulWidget {
  const HomeFilterSheet({
    required this.filters,
    required this.categories,
    super.key,
  });

  final HomeFeedFilters filters;
  final List<HomeCategory> categories;

  @override
  State<HomeFilterSheet> createState() => _HomeFilterSheetState();
}

class _HomeFilterSheetState extends State<HomeFilterSheet> {
  late HomeFeedFilters _draft = widget.filters;

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: .88,
            minChildSize: .55,
            maxChildSize: .96,
            builder: (context, scrollController) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Filters',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: colors.ink,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
                      children: [
                        _SectionTitle('Afstand'),
                        const _SectionHelper(
                          'Kies hoe breed je rondom je huidige plaats wilt zoeken.',
                        ),
                        _DistanceChoices(
                          selectedDistanceKm: _draft.distanceKm,
                          onChanged: (distanceKm) {
                            setState(
                              () => _draft = _draft.copyWith(
                                distanceKm: distanceKm,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: TochSpacing.lg),
                        _SectionTitle('Datum'),
                        const _SectionHelper(
                          'Gebruik datumfilters om alleen activiteiten te zien die echt binnen jouw planning vallen.',
                        ),
                        _DateChoices(
                          filters: _draft,
                          onChanged: (filters) {
                            setState(() => _draft = filters);
                          },
                        ),
                        const SizedBox(height: TochSpacing.lg),
                        _SectionTitle('Categorie'),
                        const _SectionHelper(
                          'Categorieen combineren met afstand werkt het best: kies eerst dichtbij, verfijn daarna op type activiteit.',
                        ),
                        _CategoryChoices(
                          categories: widget.categories,
                          selectedIds: _draft.categoryIds,
                          onChanged: (ids) {
                            setState(
                              () => _draft = _draft.copyWith(categoryIds: ids),
                            );
                          },
                        ),
                        const SizedBox(height: TochSpacing.lg),
                        _SectionTitle('Doelgroep'),
                        const _SectionHelper(
                          'Doelgroep betekent: de host zoekt expliciet deze leeftijdsband of gendergroep. Leeg betekent iedereen.',
                        ),
                        _ChoiceWrap(
                          values: tochAgeBands,
                          selectedValues: _draft.targetAgeBands,
                          labelFor: ageBandLabel,
                          onChanged: (values) {
                            setState(
                              () => _draft = _draft.copyWith(
                                targetAgeBands: values,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: TochSpacing.sm),
                        _ChoiceWrap(
                          values: tochGenderValues,
                          selectedValues: _draft.targetGenders,
                          labelFor: genderLabel,
                          onChanged: (values) {
                            setState(
                              () => _draft = _draft.copyWith(
                                targetGenders: values,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: TochSpacing.lg),
                        _SectionTitle('Beschikbaarheid'),
                        const _SectionHelper(
                          'Gebruik deze opties als je alleen direct beschikbare of specifieker ingestelde activiteiten wilt zien.',
                        ),
                        SwitchListTile(
                          value: _draft.availableOnly,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Alleen met vrije plekken'),
                          activeThumbColor: colors.green,
                          onChanged: (value) {
                            setState(
                              () => _draft = _draft.copyWith(
                                availableOnly: value,
                              ),
                            );
                          },
                        ),
                        SwitchListTile(
                          value: _draft.requiresIdentityVerified,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Identiteit bevestigd vereist'),
                          subtitle: const Text(
                            'Toont activiteiten waar hosts dit expliciet vragen.',
                          ),
                          activeThumbColor: colors.green,
                          onChanged: (value) {
                            setState(
                              () => _draft = _draft.copyWith(
                                requiresIdentityVerified: value,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: TochSpacing.sm),
                        _ParticipantLimits(
                          minParticipants: _draft.minParticipants,
                          maxParticipants: _draft.maxParticipants,
                          onChanged: (minValue, maxValue) {
                            setState(
                              () => _draft = _draft.copyWith(
                                minParticipants: minValue,
                                maxParticipants: maxValue,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: TochSpacing.lg),
                        _SectionTitle('Sortering'),
                        const _SectionHelper(
                          'Dichtbij is handig voor spontaan afspreken; binnenkort is handig als je vandaag nog iets zoekt.',
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: _draft.sort,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: homeSortDistance,
                              child: Text('Dichtbij eerst'),
                            ),
                            DropdownMenuItem(
                              value: homeSortStartTime,
                              child: Text('Binnenkort eerst'),
                            ),
                            DropdownMenuItem(
                              value: homeSortParticipants,
                              child: Text('Meeste deelnemers'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(
                              () => _draft = _draft.copyWith(sort: value),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(
                                  () => _draft = const HomeFeedFilters(),
                                );
                              },
                              child: const Text('Reset'),
                            ),
                          ),
                          const SizedBox(width: TochSpacing.sm),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop(_draft);
                              },
                              icon: const Icon(Icons.check_rounded),
                              label: const Text('Toepassen'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DistanceChoices extends StatelessWidget {
  const _DistanceChoices({
    required this.selectedDistanceKm,
    required this.onChanged,
  });

  final int selectedDistanceKm;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final distance in const [5, 10, 25, 50])
          ChoiceChip(
            label: Text('$distance km'),
            selected: selectedDistanceKm == distance,
            onSelected: (_) => onChanged(distance),
          ),
      ],
    );
  }
}

class _DateChoices extends StatelessWidget {
  const _DateChoices({required this.filters, required this.onChanged});

  final HomeFeedFilters filters;
  final ValueChanged<HomeFeedFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _DateChip(
              label: 'Alles',
              value: homeDateFilterAll,
              filters: filters,
              onChanged: onChanged,
            ),
            _DateChip(
              label: 'Vandaag',
              value: homeDateFilterToday,
              filters: filters,
              onChanged: onChanged,
            ),
            _DateChip(
              label: 'Dit weekend',
              value: homeDateFilterWeekend,
              filters: filters,
              onChanged: onChanged,
            ),
          ],
        ),
        const SizedBox(height: TochSpacing.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickCustomDate(context, isStart: true),
                icon: const Icon(Icons.calendar_today_rounded),
                label: Text(_dateLabel(filters.dateFrom) ?? 'Vanaf'),
              ),
            ),
            const SizedBox(width: TochSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickCustomDate(context, isStart: false),
                icon: const Icon(Icons.event_rounded),
                label: Text(_dateLabel(filters.dateTo) ?? 'Tot'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickCustomDate(
    BuildContext context, {
    required bool isStart,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = isStart
        ? filters.dateFrom ?? today
        : filters.dateTo?.subtract(const Duration(days: 1)) ?? today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(today) ? today : initial,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: isStart ? 'Vanaf datum' : 'Tot en met datum',
      cancelText: 'Annuleer',
      confirmText: 'Kies',
    );
    if (picked == null) {
      return;
    }
    final start = DateTime(picked.year, picked.month, picked.day);
    final nextFilters = isStart
        ? filters.copyWith(dateFrom: start)
        : filters.copyWith(dateTo: start.add(const Duration(days: 1)));
    onChanged(nextFilters.copyWith(dateFilter: homeDateFilterCustom));
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.value,
    required this.filters,
    required this.onChanged,
  });

  final String label;
  final String value;
  final HomeFeedFilters filters;
  final ValueChanged<HomeFeedFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: filters.dateFilter == value,
      onSelected: (_) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        if (value == homeDateFilterToday) {
          onChanged(
            filters.copyWith(
              dateFilter: value,
              dateFrom: today,
              dateTo: today.add(const Duration(days: 1)),
            ),
          );
          return;
        }
        if (value == homeDateFilterWeekend) {
          final daysUntilSaturday =
              (DateTime.saturday - today.weekday) % DateTime.daysPerWeek;
          final saturday = today.add(Duration(days: daysUntilSaturday));
          onChanged(
            filters.copyWith(
              dateFilter: value,
              dateFrom: saturday,
              dateTo: saturday.add(const Duration(days: 2)),
            ),
          );
          return;
        }
        onChanged(filters.copyWith(dateFilter: value, clearDateRange: true));
      },
    );
  }
}

class _CategoryChoices extends StatelessWidget {
  const _CategoryChoices({
    required this.categories,
    required this.selectedIds,
    required this.onChanged,
  });

  final List<HomeCategory> categories;
  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final categoryValues = categories.where((category) => category.id != 'all');

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          label: const Text('Alles'),
          selected: selectedIds.isEmpty,
          onSelected: (_) => onChanged(const []),
        ),
        for (final category in categoryValues)
          FilterChip(
            avatar: Icon(category.icon, size: 17, color: category.color),
            label: Text(category.label),
            selected: selectedIds.contains(category.id),
            onSelected: (_) {
              final next = [...selectedIds];
              if (!next.remove(category.id)) {
                next.add(category.id);
              }
              onChanged(next);
            },
          ),
      ],
    );
  }
}

class _ChoiceWrap extends StatelessWidget {
  const _ChoiceWrap({
    required this.values,
    required this.selectedValues,
    required this.labelFor,
    required this.onChanged,
  });

  final List<String> values;
  final List<String> selectedValues;
  final String Function(String value) labelFor;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          label: const Text('Iedereen'),
          selected: selectedValues.isEmpty,
          onSelected: (_) => onChanged(const []),
        ),
        for (final value in values)
          FilterChip(
            label: Text(labelFor(value)),
            selected: selectedValues.contains(value),
            onSelected: (_) {
              final next = [...selectedValues];
              if (!next.remove(value)) {
                next.add(value);
              }
              onChanged(next);
            },
          ),
      ],
    );
  }
}

class _ParticipantLimits extends StatelessWidget {
  const _ParticipantLimits({
    required this.minParticipants,
    required this.maxParticipants,
    required this.onChanged,
  });

  final int? minParticipants;
  final int? maxParticipants;
  final void Function(int? minParticipants, int? maxParticipants) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: minParticipants,
            decoration: const InputDecoration(labelText: 'Min deelnemers'),
            items: _participantItems('Geen min'),
            onChanged: (value) => onChanged(value, maxParticipants),
          ),
        ),
        const SizedBox(width: TochSpacing.sm),
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: maxParticipants,
            decoration: const InputDecoration(labelText: 'Max deelnemers'),
            items: _participantItems('Geen max'),
            onChanged: (value) => onChanged(minParticipants, value),
          ),
        ),
      ],
    );
  }
}

List<DropdownMenuItem<int>> _participantItems(String emptyLabel) {
  return [
    DropdownMenuItem<int>(child: Text(emptyLabel)),
    for (final value in const [1, 2, 3, 5, 8, 12, 20])
      DropdownMenuItem<int>(value: value, child: Text(value.toString())),
  ];
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TochSpacing.xs),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: context.toch.green700.withValues(alpha: .62),
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _SectionHelper extends StatelessWidget {
  const _SectionHelper(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TochSpacing.sm),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: context.toch.green700.withValues(alpha: .66),
          fontWeight: FontWeight.w700,
          height: 1.32,
        ),
      ),
    );
  }
}

String? _dateLabel(DateTime? value) {
  if (value == null) {
    return null;
  }
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}-${local.month.toString().padLeft(2, '0')}';
}
