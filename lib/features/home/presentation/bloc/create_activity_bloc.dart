import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';

import '../../../../core/services/analytics_service.dart';
import '../../domain/entities/create_activity_draft.dart';
import '../../domain/entities/home_category.dart';
import '../../domain/entities/home_feed_filters.dart';
import '../../domain/entities/home_location.dart';
import '../../domain/usecases/create_activity.dart';

part 'create_activity_event.dart';
part 'create_activity_state.dart';

class CreateActivityBloc
    extends Bloc<CreateActivityEvent, CreateActivityState> {
  CreateActivityBloc(
    this._createActivity, {
    required HomeLocation location,
    required List<HomeCategory> categories,
    MeetingPlaceSearcher? searchMeetingPlaces,
  }) : _location = location,
       _searchMeetingPlaces =
           searchMeetingPlaces ?? _defaultSearchMeetingPlaces,
       super(_initialState(categories, location)) {
    on<CreateActivityCategorySelected>(_onCategorySelected);
    on<CreateActivityTitleChanged>(_onTitleChanged);
    on<CreateActivityLocationChanged>(_onLocationChanged);
    on<CreateActivityMeetingLocationSearchRequested>(
      _onMeetingLocationSearchRequested,
    );
    on<CreateActivityMeetingLocationSelected>(_onMeetingLocationSelected);
    on<CreateActivityDateShortcutSelected>(_onDateShortcutSelected);
    on<CreateActivityDateSelected>(_onDateSelected);
    on<CreateActivityTimeSelected>(_onTimeSelected);
    on<CreateActivityCapacityDecremented>(_onCapacityDecremented);
    on<CreateActivityCapacityIncremented>(_onCapacityIncremented);
    on<CreateActivityGroupTypeSelected>(_onGroupTypeSelected);
    on<CreateActivityMinReputationSelected>(_onMinReputationSelected);
    on<CreateActivityPrivateLocationToggled>(_onPrivateLocationToggled);
    on<CreateActivityTargetAgeBandToggled>(_onTargetAgeBandToggled);
    on<CreateActivityTargetGenderToggled>(_onTargetGenderToggled);
    on<CreateActivityNotesChanged>(_onNotesChanged);
    on<CreateActivitySubmitted>(_onSubmitted);
  }

  static const _minCapacity = 2;
  static const _maxCapacity = 20;

  static CreateActivityState _initialState(
    List<HomeCategory> categories,
    HomeLocation location,
  ) {
    final defaultStart = _defaultStart();
    return CreateActivityState(
      categories: categories,
      categoryId: categories.isEmpty ? '' : categories.first.id,
      cityName: location.cityName,
      selectedDate: defaultStart,
      selectedHour: defaultStart.hour,
      selectedMinute: defaultStart.minute,
    );
  }

  static DateTime _defaultStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, now.hour + 1);
  }

  final CreateActivity _createActivity;
  final HomeLocation _location;
  final MeetingPlaceSearcher _searchMeetingPlaces;

  void _onCategorySelected(
    CreateActivityCategorySelected event,
    Emitter<CreateActivityState> emit,
  ) {
    emit(
      state.copyWith(
        categoryId: event.categoryId,
        submissionStatus: CreateActivitySubmissionStatus.idle,
      ),
    );
  }

  void _onTitleChanged(
    CreateActivityTitleChanged event,
    Emitter<CreateActivityState> emit,
  ) {
    emit(
      state.copyWith(
        title: event.title,
        submissionStatus: CreateActivitySubmissionStatus.idle,
      ),
    );
  }

  void _onLocationChanged(
    CreateActivityLocationChanged event,
    Emitter<CreateActivityState> emit,
  ) {
    emit(
      state.copyWith(
        location: event.location,
        locationResults: const [],
        locationSearchStatus: CreateActivityLocationSearchStatus.idle,
        clearSelectedMeetingLocation: true,
        submissionStatus: CreateActivitySubmissionStatus.idle,
      ),
    );
  }

  Future<void> _onMeetingLocationSearchRequested(
    CreateActivityMeetingLocationSearchRequested event,
    Emitter<CreateActivityState> emit,
  ) async {
    final query = event.query.trim();
    if (query.length < 3) {
      emit(
        state.copyWith(
          locationResults: const [],
          locationSearchStatus: CreateActivityLocationSearchStatus.idle,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        locationSearchStatus: CreateActivityLocationSearchStatus.searching,
        locationResults: const [],
      ),
    );

    try {
      final results = await _searchMeetingPlaces(query, _location);
      if (state.location.trim() != query) {
        return;
      }
      emit(
        state.copyWith(
          locationResults: results,
          locationSearchStatus: CreateActivityLocationSearchStatus.success,
        ),
      );
    } catch (_) {
      if (state.location.trim() != query) {
        return;
      }
      emit(
        state.copyWith(
          locationResults: const [],
          locationSearchStatus: CreateActivityLocationSearchStatus.failure,
        ),
      );
    }
  }

  void _onMeetingLocationSelected(
    CreateActivityMeetingLocationSelected event,
    Emitter<CreateActivityState> emit,
  ) {
    emit(
      state.copyWith(
        location: event.location.addressLine,
        locationResults: const [],
        locationSearchStatus: CreateActivityLocationSearchStatus.success,
        selectedMeetingLocation: event.location,
        submissionStatus: CreateActivitySubmissionStatus.idle,
      ),
    );
  }

  void _onDateShortcutSelected(
    CreateActivityDateShortcutSelected event,
    Emitter<CreateActivityState> emit,
  ) {
    emit(
      state.copyWith(
        selectedDate: _dateForShortcut(event.shortcut),
        submissionStatus: CreateActivitySubmissionStatus.idle,
      ),
    );
  }

  void _onDateSelected(
    CreateActivityDateSelected event,
    Emitter<CreateActivityState> emit,
  ) {
    emit(
      state.copyWith(
        selectedDate: _dateOnly(event.date),
        submissionStatus: CreateActivitySubmissionStatus.idle,
      ),
    );
  }

  void _onTimeSelected(
    CreateActivityTimeSelected event,
    Emitter<CreateActivityState> emit,
  ) {
    if (event.hour < 0 ||
        event.hour > 23 ||
        event.minute < 0 ||
        event.minute > 59) {
      return;
    }

    emit(
      state.copyWith(
        selectedHour: event.hour,
        selectedMinute: event.minute,
        submissionStatus: CreateActivitySubmissionStatus.idle,
      ),
    );
  }

  void _onCapacityDecremented(
    CreateActivityCapacityDecremented event,
    Emitter<CreateActivityState> emit,
  ) {
    final nextCapacity = state.capacity - 1;
    if (nextCapacity < _minCapacity) {
      return;
    }
    emit(
      state.copyWith(
        capacity: nextCapacity,
        submissionStatus: CreateActivitySubmissionStatus.idle,
      ),
    );
  }

  void _onCapacityIncremented(
    CreateActivityCapacityIncremented event,
    Emitter<CreateActivityState> emit,
  ) {
    final nextCapacity = state.capacity + 1;
    if (nextCapacity > _maxCapacity) {
      return;
    }
    emit(
      state.copyWith(
        capacity: nextCapacity,
        submissionStatus: CreateActivitySubmissionStatus.idle,
      ),
    );
  }

  void _onGroupTypeSelected(
    CreateActivityGroupTypeSelected event,
    Emitter<CreateActivityState> emit,
  ) {
    if (!const ['open', 'approval', 'closed'].contains(event.groupType)) {
      return;
    }
    emit(
      state.copyWith(
        groupType: event.groupType,
        submissionStatus: CreateActivitySubmissionStatus.idle,
      ),
    );
  }

  void _onMinReputationSelected(
    CreateActivityMinReputationSelected event,
    Emitter<CreateActivityState> emit,
  ) {
    if (!const [
      'new_member',
      'active_member',
      'known_member',
      'top_participant',
    ].contains(event.reputationLevel)) {
      return;
    }
    emit(
      state.copyWith(
        minReputationLevel: event.reputationLevel,
        submissionStatus: CreateActivitySubmissionStatus.idle,
      ),
    );
  }

  void _onPrivateLocationToggled(
    CreateActivityPrivateLocationToggled event,
    Emitter<CreateActivityState> emit,
  ) {
    emit(
      state.copyWith(
        isPrivateLocation: event.isPrivateLocation,
        submissionStatus: CreateActivitySubmissionStatus.idle,
      ),
    );
  }

  void _onTargetAgeBandToggled(
    CreateActivityTargetAgeBandToggled event,
    Emitter<CreateActivityState> emit,
  ) {
    if (!tochAgeBands.contains(event.ageBand)) {
      return;
    }
    final next = [...state.targetAgeBands];
    if (!next.remove(event.ageBand)) {
      next.add(event.ageBand);
    }
    emit(
      state.copyWith(
        targetAgeBands: next,
        submissionStatus: CreateActivitySubmissionStatus.idle,
      ),
    );
  }

  void _onTargetGenderToggled(
    CreateActivityTargetGenderToggled event,
    Emitter<CreateActivityState> emit,
  ) {
    if (!tochGenderValues.contains(event.gender)) {
      return;
    }
    final next = [...state.targetGenders];
    if (!next.remove(event.gender)) {
      next.add(event.gender);
    }
    emit(
      state.copyWith(
        targetGenders: next,
        submissionStatus: CreateActivitySubmissionStatus.idle,
      ),
    );
  }

  void _onNotesChanged(
    CreateActivityNotesChanged event,
    Emitter<CreateActivityState> emit,
  ) {
    emit(
      state.copyWith(
        notes: event.notes,
        submissionStatus: CreateActivitySubmissionStatus.idle,
      ),
    );
  }

  Future<void> _onSubmitted(
    CreateActivitySubmitted event,
    Emitter<CreateActivityState> emit,
  ) async {
    if (!state.isValid) {
      emit(
        state.copyWith(
          submissionStatus: CreateActivitySubmissionStatus.invalid,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        submissionStatus: CreateActivitySubmissionStatus.submitting,
      ),
    );
    final resolvedLocation = await _resolveMeetingPlace(state, emit);
    if (resolvedLocation == null) {
      return;
    }

    final result = await _createActivity(
      _draftFromState(state, resolvedLocation),
    );
    result.fold(
      (failure) {
        AnalyticsService.instance.track(
          'activity_created_failed',
          properties: _activityAnalyticsProperties(state),
        );
        emit(
          state.copyWith(
            submissionStatus: CreateActivitySubmissionStatus.failure,
            errorMessage: failure.message,
          ),
        );
      },
      (activityId) {
        AnalyticsService.instance.track(
          'activity_created',
          properties: _activityAnalyticsProperties(state),
        );
        emit(
          state.copyWith(
            submissionStatus: CreateActivitySubmissionStatus.success,
            createdActivityId: activityId,
          ),
        );
      },
    );
  }

  Future<ResolvedMeetingLocation?> _resolveMeetingPlace(
    CreateActivityState state,
    Emitter<CreateActivityState> emit,
  ) async {
    final query = state.location.trim();
    if (_looksLikeOnlyCity(query, _location.cityName)) {
      emit(
        state.copyWith(
          submissionStatus: CreateActivitySubmissionStatus.failure,
          errorMessage:
              'Vul een herkenbare meetingplek in, bijvoorbeeld een adres, plein of cafe.',
        ),
      );
      return null;
    }

    final selected = state.selectedMeetingLocation;
    if (selected != null && selected.addressLine.trim() == query) {
      return selected;
    }

    {
      emit(
        state.copyWith(
          submissionStatus: CreateActivitySubmissionStatus.failure,
          errorMessage:
              'Kies een gevonden meetingplek uit de lijst voordat je plaatst.',
        ),
      );
      return null;
    }
  }

  CreateActivityDraft _draftFromState(
    CreateActivityState state,
    ResolvedMeetingLocation meetingLocation,
  ) {
    final title = state.title.trim();
    final notes = state.notes.trim();

    return CreateActivityDraft(
      categoryId: state.categoryId,
      title: title,
      description: _descriptionFor(title: title, notes: notes),
      latitude: meetingLocation.latitude,
      longitude: meetingLocation.longitude,
      addressLine: meetingLocation.addressLine,
      city: meetingLocation.city,
      countryCode: 'NL',
      startsAt: state.startsAt,
      maxParticipants: state.capacity,
      groupType: state.groupType,
      minReputationLevel: state.minReputationLevel,
      isPrivateLocation: state.isPrivateLocation,
      targetAgeBands: state.targetAgeBands,
      targetGenders: state.targetGenders,
    );
  }

  DateTime _dateForShortcut(String shortcut) {
    final now = DateTime.now();
    final date = switch (shortcut) {
      'Morgen' => now.add(const Duration(days: 1)),
      'Weekend' => _nextSaturdayOrToday(now),
      _ => now,
    };
    return _dateOnly(date);
  }

  DateTime _nextSaturdayOrToday(DateTime now) {
    const saturday = DateTime.saturday;
    final daysUntilSaturday = (saturday - now.weekday) % DateTime.daysPerWeek;
    return now.add(
      Duration(days: daysUntilSaturday == 0 ? 0 : daysUntilSaturday),
    );
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}

String _descriptionFor({required String title, required String notes}) {
  if (notes.trim().length >= 10) {
    return notes.trim();
  }
  return 'Ik ga $title. Sluit gezellig aan.';
}

typedef MeetingPlaceSearcher =
    Future<List<ResolvedMeetingLocation>> Function(
      String query,
      HomeLocation fallbackLocation,
    );

class ResolvedMeetingLocation extends Equatable {
  const ResolvedMeetingLocation({
    required this.addressLine,
    required this.city,
    required this.latitude,
    required this.longitude,
  });

  final String addressLine;
  final String city;
  final double latitude;
  final double longitude;

  @override
  List<Object?> get props => [addressLine, city, latitude, longitude];
}

Future<List<ResolvedMeetingLocation>> _defaultSearchMeetingPlaces(
  String query,
  HomeLocation fallbackLocation,
) async {
  final searchQuery = _queryWithFallbackCity(query, fallbackLocation.cityName);
  final locations = await locationFromAddress(
    searchQuery,
  ).timeout(const Duration(seconds: 6));
  if (locations.isEmpty) {
    return const [];
  }

  final results = <ResolvedMeetingLocation>[];
  final seen = <String>{};

  for (final location in locations.take(5)) {
    final placemarks = await placemarkFromCoordinates(
      location.latitude,
      location.longitude,
    ).timeout(const Duration(seconds: 2), onTimeout: () => const <Placemark>[]);
    final placemark = placemarks.isEmpty ? null : placemarks.first;
    final city = _cityFromPlacemark(placemark) ?? fallbackLocation.cityName;
    final addressLine = formatMeetingPlaceAddressLine(
      query: query,
      city: city,
      placemark: placemark,
    );
    final key =
        '${addressLine.toLowerCase()}|${location.latitude.toStringAsFixed(5)}|'
        '${location.longitude.toStringAsFixed(5)}';
    if (!seen.add(key)) {
      continue;
    }

    results.add(
      ResolvedMeetingLocation(
        addressLine: addressLine,
        city: city,
        latitude: location.latitude,
        longitude: location.longitude,
      ),
    );
  }

  return results;
}

String _queryWithFallbackCity(String query, String city) {
  final trimmed = query.trim();
  if (trimmed.toLowerCase().contains(city.trim().toLowerCase())) {
    return '$trimmed, Nederland';
  }
  return '$trimmed, $city, Nederland';
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

String formatMeetingPlaceAddressLine({
  required String query,
  required String city,
  required Placemark? placemark,
}) {
  final parts = <String>[];
  final typedAddress = _typedAddressWithHouseNumber(query, city);
  final streetAddress = _streetAddressFromPlacemark(placemark);

  for (final value in [typedAddress, placemark?.name, streetAddress, city]) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      continue;
    }
    if (_looksLikeHouseNumberOnly(trimmed)) {
      continue;
    }
    if (parts.any((part) => part.toLowerCase() == trimmed.toLowerCase())) {
      continue;
    }
    if (_duplicatesStreetAddress(
      existingParts: parts,
      candidate: trimmed,
    )) {
      continue;
    }
    parts.add(trimmed);
  }

  if (parts.isEmpty) {
    return query.trim();
  }
  return parts.take(3).join(', ');
}

String? _streetAddressFromPlacemark(Placemark? placemark) {
  if (placemark == null) {
    return null;
  }

  final street = _firstNonEmpty([
    placemark.street,
    placemark.thoroughfare,
  ]);
  final houseNumber = _firstNonEmpty([
    placemark.subThoroughfare,
    _houseNumberFromText(placemark.name),
  ]);
  if (street == null) {
    return null;
  }
  if (_containsDigit(street) || houseNumber == null) {
    return street;
  }
  return '$street $houseNumber';
}

String? _typedAddressWithHouseNumber(String query, String city) {
  final withoutPostcode = query
      .replaceAll(RegExp(r'\b\d{4}\s?[a-zA-Z]{2}\b'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final firstPart = withoutPostcode
      .split(',')
      .first
      .replaceAll(
        RegExp('\\b${RegExp.escape(city)}\\b', caseSensitive: false),
        ' ',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (firstPart.isEmpty ||
      !_containsDigit(firstPart) ||
      !RegExp(r'[a-zA-Z]').hasMatch(firstPart)) {
    return null;
  }
  return firstPart;
}

String? _houseNumberFromText(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) {
    return null;
  }
  final match = RegExp(r'\b\d+[a-zA-Z]?\b').firstMatch(text);
  return match?.group(0);
}

String? _firstNonEmpty(Iterable<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
  }
  return null;
}

bool _containsDigit(String value) => RegExp(r'\d').hasMatch(value);

bool _looksLikeHouseNumberOnly(String value) {
  return RegExp(r'^\d+[a-zA-Z]?$').hasMatch(value.trim());
}

bool _duplicatesStreetAddress({
  required List<String> existingParts,
  required String candidate,
}) {
  final candidateStreet = candidate
      .replaceAll(RegExp(r'\b\d+[a-zA-Z]?\b'), '')
      .trim()
      .toLowerCase();
  if (candidateStreet.isEmpty) {
    return false;
  }
  return existingParts.any((part) {
    final existingStreet = part
        .replaceAll(RegExp(r'\b\d+[a-zA-Z]?\b'), '')
        .trim()
        .toLowerCase();
    return existingStreet == candidateStreet &&
        (_containsDigit(part) || _containsDigit(candidate));
  });
}

bool _looksLikeOnlyCity(String query, String city) {
  final normalizedQuery = query.trim().toLowerCase();
  final normalizedCity = city.trim().toLowerCase();
  if (normalizedQuery == normalizedCity) {
    return true;
  }
  return !normalizedQuery.contains(RegExp(r'[\s,]')) &&
      !normalizedQuery.contains(RegExp(r'\d')) &&
      normalizedQuery.length < 16;
}

Map<String, Object> _activityAnalyticsProperties(CreateActivityState state) {
  return {
    'capacity': state.capacity,
    'group_type': state.groupType,
    'min_reputation_level': state.minReputationLevel,
    'is_private_location': state.isPrivateLocation,
    'target_age_band_count': state.targetAgeBands.length,
    'target_gender_count': state.targetGenders.length,
  };
}
