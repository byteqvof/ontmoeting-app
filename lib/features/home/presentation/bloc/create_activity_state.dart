part of 'create_activity_bloc.dart';

enum CreateActivitySubmissionStatus {
  idle,
  invalid,
  submitting,
  success,
  failure,
}

enum CreateActivityLocationSearchStatus { idle, searching, success, failure }

class CreateActivityState extends Equatable {
  CreateActivityState({
    this.categories = const [],
    this.categoryId = 'fishing',
    this.cityName = '',
    this.title = '',
    this.location = '',
    this.locationResults = const [],
    this.locationSearchStatus = CreateActivityLocationSearchStatus.idle,
    this.selectedMeetingLocation,
    DateTime? selectedDate,
    this.selectedHour = 19,
    this.selectedMinute = 0,
    this.capacity = 5,
    this.groupType = 'open',
    this.minReputationLevel = 'new_member',
    this.isPrivateLocation = false,
    this.targetAgeBands = const [],
    this.targetGenders = const [],
    this.notes = '',
    this.submissionStatus = CreateActivitySubmissionStatus.idle,
    this.createdActivityId,
    this.errorMessage,
  }) : selectedDate = _dateOnly(selectedDate ?? DateTime.now());

  final List<HomeCategory> categories;
  final String categoryId;
  final String cityName;
  final String title;
  final String location;
  final List<MeetingLocationSuggestion> locationResults;
  final CreateActivityLocationSearchStatus locationSearchStatus;
  final MeetingLocationSuggestion? selectedMeetingLocation;
  final DateTime selectedDate;
  final int selectedHour;
  final int selectedMinute;
  final int capacity;
  final String groupType;
  final String minReputationLevel;
  final bool isPrivateLocation;
  final List<String> targetAgeBands;
  final List<String> targetGenders;
  final String notes;
  final CreateActivitySubmissionStatus submissionStatus;
  final String? createdActivityId;
  final String? errorMessage;

  bool get hasBackendCategoryId => _uuidPattern.hasMatch(categoryId);

  bool get hasSelectedMeetingLocation {
    final selected = selectedMeetingLocation;
    if (selected == null) {
      return false;
    }
    return selected.addressLine.trim() == location.trim();
  }

  DateTime get startsAt => DateTime(
    selectedDate.year,
    selectedDate.month,
    selectedDate.day,
    selectedHour,
    selectedMinute,
  );

  bool get hasRequiredFields {
    return hasBackendCategoryId &&
        title.trim().isNotEmpty &&
        location.trim().isNotEmpty &&
        hasSelectedMeetingLocation &&
        capacity >= 2;
  }

  bool get hasFutureStart => startsAt.isAfter(DateTime.now());

  String get dateLabel => _formatDateLabel(selectedDate);

  String get timeLabel =>
      '${selectedHour.toString().padLeft(2, '0')}:'
      '${selectedMinute.toString().padLeft(2, '0')}';

  bool get isValid {
    return hasRequiredFields && hasFutureStart;
  }

  List<String> get locationSuggestions {
    return locationResults.map((location) => location.addressLine).toList();
  }

  CreateActivityState copyWith({
    List<HomeCategory>? categories,
    String? categoryId,
    String? cityName,
    String? title,
    String? location,
    List<MeetingLocationSuggestion>? locationResults,
    CreateActivityLocationSearchStatus? locationSearchStatus,
    MeetingLocationSuggestion? selectedMeetingLocation,
    bool clearSelectedMeetingLocation = false,
    DateTime? selectedDate,
    int? selectedHour,
    int? selectedMinute,
    int? capacity,
    String? groupType,
    String? minReputationLevel,
    bool? isPrivateLocation,
    List<String>? targetAgeBands,
    List<String>? targetGenders,
    String? notes,
    CreateActivitySubmissionStatus? submissionStatus,
    String? createdActivityId,
    String? errorMessage,
  }) {
    return CreateActivityState(
      categories: categories ?? this.categories,
      categoryId: categoryId ?? this.categoryId,
      cityName: cityName ?? this.cityName,
      title: title ?? this.title,
      location: location ?? this.location,
      locationResults: locationResults ?? this.locationResults,
      locationSearchStatus: locationSearchStatus ?? this.locationSearchStatus,
      selectedMeetingLocation: clearSelectedMeetingLocation
          ? null
          : selectedMeetingLocation ?? this.selectedMeetingLocation,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedHour: selectedHour ?? this.selectedHour,
      selectedMinute: selectedMinute ?? this.selectedMinute,
      capacity: capacity ?? this.capacity,
      groupType: groupType ?? this.groupType,
      minReputationLevel: minReputationLevel ?? this.minReputationLevel,
      isPrivateLocation: isPrivateLocation ?? this.isPrivateLocation,
      targetAgeBands: targetAgeBands ?? this.targetAgeBands,
      targetGenders: targetGenders ?? this.targetGenders,
      notes: notes ?? this.notes,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      createdActivityId: createdActivityId,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    categories,
    categoryId,
    cityName,
    title,
    location,
    locationResults,
    locationSearchStatus,
    selectedMeetingLocation,
    selectedDate,
    selectedHour,
    selectedMinute,
    capacity,
    groupType,
    minReputationLevel,
    isPrivateLocation,
    targetAgeBands,
    targetGenders,
    notes,
    submissionStatus,
    createdActivityId,
    errorMessage,
  ];
}

final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

String _formatDateLabel(DateTime date) {
  final today = _dateOnly(DateTime.now());
  if (date == today) {
    return 'Vandaag';
  }
  if (date == today.add(const Duration(days: 1))) {
    return 'Morgen';
  }

  const weekdays = [
    'maandag',
    'dinsdag',
    'woensdag',
    'donderdag',
    'vrijdag',
    'zaterdag',
    'zondag',
  ];
  const months = [
    'jan',
    'feb',
    'mrt',
    'apr',
    'mei',
    'jun',
    'jul',
    'aug',
    'sep',
    'okt',
    'nov',
    'dec',
  ];

  final weekday = weekdays[date.weekday - 1];
  final month = months[date.month - 1];
  return '$weekday ${date.day} $month';
}
