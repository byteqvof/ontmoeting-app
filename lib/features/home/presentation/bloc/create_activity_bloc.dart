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
    MeetingPlaceGeocoder geocodeMeetingPlace = _defaultGeocodeMeetingPlace,
  }) : _location = location,
       _geocodeMeetingPlace = geocodeMeetingPlace,
       super(_initialState(categories)) {
    on<CreateActivityCategorySelected>(_onCategorySelected);
    on<CreateActivityTitleChanged>(_onTitleChanged);
    on<CreateActivityLocationChanged>(_onLocationChanged);
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

  static CreateActivityState _initialState(List<HomeCategory> categories) {
    final defaultStart = _defaultStart();
    return CreateActivityState(
      categories: categories,
      categoryId: categories.isEmpty ? '' : categories.first.id,
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
  final MeetingPlaceGeocoder _geocodeMeetingPlace;

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

    try {
      return await _geocodeMeetingPlace(query, _location);
    } catch (_) {
      emit(
        state.copyWith(
          submissionStatus: CreateActivitySubmissionStatus.failure,
          errorMessage:
              'We kunnen deze meetingplek niet vinden. Vul een exactere plek of adres in.',
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

typedef MeetingPlaceGeocoder =
    Future<ResolvedMeetingLocation> Function(
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

Future<ResolvedMeetingLocation> _defaultGeocodeMeetingPlace(
  String query,
  HomeLocation fallbackLocation,
) async {
  final searchQuery = _queryWithFallbackCity(query, fallbackLocation.cityName);
  final locations = await locationFromAddress(
    searchQuery,
  ).timeout(const Duration(seconds: 6));
  if (locations.isEmpty) {
    throw StateError('No geocoding result for meeting place.');
  }

  final location = locations.first;
  final placemarks = await placemarkFromCoordinates(
    location.latitude,
    location.longitude,
  ).timeout(const Duration(seconds: 4), onTimeout: () => const <Placemark>[]);
  final placemark = placemarks.isEmpty ? null : placemarks.first;
  final city = _cityFromPlacemark(placemark) ?? fallbackLocation.cityName;

  return ResolvedMeetingLocation(
    addressLine: query.trim(),
    city: city,
    latitude: location.latitude,
    longitude: location.longitude,
  );
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
