part of 'create_activity_bloc.dart';

enum CreateActivitySubmissionStatus {
  idle,
  invalid,
  submitting,
  success,
  failure,
}

class CreateActivityState extends Equatable {
  const CreateActivityState({
    this.categories = const [],
    this.categoryId = 'fishing',
    this.title = '',
    this.location = '',
    this.day = 'Vandaag',
    this.time = '19:00',
    this.capacity = 5,
    this.notes = '',
    this.submissionStatus = CreateActivitySubmissionStatus.idle,
    this.createdActivityId,
    this.errorMessage,
  });

  final List<HomeCategory> categories;
  final String categoryId;
  final String title;
  final String location;
  final String day;
  final String time;
  final int capacity;
  final String notes;
  final CreateActivitySubmissionStatus submissionStatus;
  final String? createdActivityId;
  final String? errorMessage;

  bool get hasBackendCategoryId => _uuidPattern.hasMatch(categoryId);

  bool get isValid {
    return hasBackendCategoryId &&
        title.trim().isNotEmpty &&
        location.trim().isNotEmpty &&
        day.trim().isNotEmpty &&
        time.trim().isNotEmpty &&
        capacity >= 2;
  }

  CreateActivityState copyWith({
    List<HomeCategory>? categories,
    String? categoryId,
    String? title,
    String? location,
    String? day,
    String? time,
    int? capacity,
    String? notes,
    CreateActivitySubmissionStatus? submissionStatus,
    String? createdActivityId,
    String? errorMessage,
  }) {
    return CreateActivityState(
      categories: categories ?? this.categories,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      location: location ?? this.location,
      day: day ?? this.day,
      time: time ?? this.time,
      capacity: capacity ?? this.capacity,
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
    title,
    location,
    day,
    time,
    capacity,
    notes,
    submissionStatus,
    createdActivityId,
    errorMessage,
  ];
}

final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);
