import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/toch_theme.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/create_activity_draft.dart';
import '../../domain/entities/home_activity.dart';
import '../../domain/usecases/update_activity.dart';

class EditActivityPage extends StatefulWidget {
  const EditActivityPage({required this.activity, super.key});

  final HomeActivity activity;

  @override
  State<EditActivityPage> createState() => _EditActivityPageState();
}

class _EditActivityPageState extends State<EditActivityPage> {
  final UpdateActivity _updateActivity = sl();
  late final TextEditingController _titleController = TextEditingController(
    text: widget.activity.title,
  );
  late final TextEditingController _descriptionController =
      TextEditingController(text: widget.activity.description);
  late final TextEditingController _locationController = TextEditingController(
    text: widget.activity.meetingPoint,
  );
  late DateTime _dateTime =
      widget.activity.startsAt ?? DateTime.now().add(const Duration(hours: 1));
  late int _capacity =
      widget.activity.participants.length + widget.activity.availableSpots;
  late String _groupType = widget.activity.groupType;
  late bool _isPrivateLocation = widget.activity.isPrivateLocation;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }

    final title = _titleController.text.trim();
    final locationText = _locationController.text.trim();
    if (title.length < 3 || locationText.length < 3) {
      _showMessage('Vul een titel en exacte meetingplek in.');
      return;
    }
    if (_capacity < widget.activity.participants.length) {
      _showMessage('Capaciteit kan niet lager zijn dan huidige deelnemers.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final resolved = await _resolveLocation(locationText);
    if (!mounted) {
      return;
    }
    if (resolved == null) {
      setState(() {
        _isSaving = false;
      });
      _showMessage('We kunnen deze meetingplek niet vinden.');
      return;
    }

    final result = await _updateActivity(
      UpdateActivityParams(
        activityId: widget.activity.id,
        draft: CreateActivityDraft(
          categoryId: widget.activity.category.id,
          title: title,
          description: _descriptionFor(
            title: title,
            description: _descriptionController.text,
          ),
          latitude: resolved.latitude,
          longitude: resolved.longitude,
          addressLine: locationText,
          city: resolved.city,
          countryCode: 'NL',
          startsAt: _dateTime,
          maxParticipants: _capacity,
          groupType: _groupType,
          minReputationLevel: widget.activity.minReputationLevel,
          requiresIdentityVerified: widget.activity.requiresIdentityVerified,
          isPrivateLocation: _isPrivateLocation,
          targetAgeBands: widget.activity.targetAgeBands,
          targetGenders: widget.activity.targetGenders,
        ),
      ),
    );
    if (!mounted) {
      return;
    }

    result.fold((failure) {
      setState(() {
        _isSaving = false;
      });
      _showMessage(failure.message);
    }, (activity) => context.pop(activity));
  }

  Future<_ResolvedEditLocation?> _resolveLocation(String query) async {
    if (query == widget.activity.meetingPoint &&
        (widget.activity.latitude != 0 || widget.activity.longitude != 0)) {
      return _ResolvedEditLocation(
        city: widget.activity.locationName,
        latitude: widget.activity.latitude,
        longitude: widget.activity.longitude,
      );
    }

    final locations = await locationFromAddress(
      '$query, Nederland',
    ).timeout(const Duration(seconds: 6), onTimeout: () => const []);
    if (locations.isEmpty) {
      return null;
    }
    final location = locations.first;
    final placemarks = await placemarkFromCoordinates(
      location.latitude,
      location.longitude,
    ).timeout(const Duration(seconds: 4), onTimeout: () => const <Placemark>[]);
    final city = _cityFromPlacemark(
      placemarks.isEmpty ? null : placemarks.first,
    );
    return _ResolvedEditLocation(
      city: city ?? widget.activity.locationName,
      latitude: location.latitude,
      longitude: location.longitude,
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _dateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _dateTime.hour,
        _dateTime.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _dateTime.hour, minute: _dateTime.minute),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _dateTime = DateTime(
        _dateTime.year,
        _dateTime.month,
        _dateTime.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.toch;

    return Scaffold(
      backgroundColor: colors.cream,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
              children: [
                Row(
                  children: [
                    IconButton.filled(
                      onPressed: _isSaving ? null : context.pop,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: TochSpacing.sm),
                    Expanded(
                      child: Text(
                        'Activiteit bewerken',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Bewaar'),
                    ),
                  ],
                ),
                const SizedBox(height: TochSpacing.lg),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Titel'),
                ),
                const SizedBox(height: TochSpacing.md),
                TextField(
                  controller: _descriptionController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Beschrijving'),
                ),
                const SizedBox(height: TochSpacing.md),
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Meetingplek',
                    helperText: 'Gebruik een herkenbare plek of adres.',
                  ),
                ),
                const SizedBox(height: TochSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_month_rounded),
                        label: Text(_formatDate(_dateTime)),
                      ),
                    ),
                    const SizedBox(width: TochSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.schedule_rounded),
                        label: Text(_formatTime(_dateTime)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TochSpacing.md),
                _CapacityEditor(
                  capacity: _capacity,
                  minCapacity: widget.activity.participants.length,
                  onChanged: (value) => setState(() => _capacity = value),
                ),
                const SizedBox(height: TochSpacing.md),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'open', label: Text('Open')),
                    ButtonSegment(value: 'approval', label: Text('Goedkeuren')),
                    ButtonSegment(value: 'closed', label: Text('Gesloten')),
                  ],
                  selected: {_groupType},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _groupType = selection.first;
                    });
                  },
                ),
                const SizedBox(height: TochSpacing.md),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _isPrivateLocation,
                  onChanged: (value) => setState(() {
                    _isPrivateLocation = value;
                  }),
                  title: const Text('Prive/thuislocatie'),
                  subtitle: const Text(
                    'Toon extra waarschuwing aan deelnemers.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CapacityEditor extends StatelessWidget {
  const _CapacityEditor({
    required this.capacity,
    required this.minCapacity,
    required this.onChanged,
  });

  final int capacity;
  final int minCapacity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Capaciteit',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        IconButton.filledTonal(
          onPressed: capacity <= minCapacity
              ? null
              : () => onChanged(capacity - 1),
          icon: const Icon(Icons.remove_rounded),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            '$capacity',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        IconButton.filledTonal(
          onPressed: () => onChanged(capacity + 1),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}

class _ResolvedEditLocation {
  const _ResolvedEditLocation({
    required this.city,
    required this.latitude,
    required this.longitude,
  });

  final String city;
  final double latitude;
  final double longitude;
}

String? _cityFromPlacemark(Placemark? placemark) {
  if (placemark == null) {
    return null;
  }
  for (final value in [
    placemark.locality,
    placemark.subAdministrativeArea,
    placemark.administrativeArea,
  ]) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
  }
  return null;
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _formatTime(DateTime date) {
  return '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}

String _descriptionFor({required String title, required String description}) {
  final trimmed = description.trim();
  if (trimmed.length >= 10) {
    return trimmed;
  }
  return 'Ik ga $title. Sluit gezellig aan.';
}
