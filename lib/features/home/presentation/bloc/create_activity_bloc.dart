import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/create_activity_draft.dart';
import '../../domain/entities/home_category.dart';
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
  }) : _location = location,
       super(
         CreateActivityState(
           categories: categories,
           categoryId: categories.isEmpty ? '' : categories.first.id,
         ),
       ) {
    on<CreateActivityCategorySelected>(_onCategorySelected);
    on<CreateActivityTitleChanged>(_onTitleChanged);
    on<CreateActivityLocationChanged>(_onLocationChanged);
    on<CreateActivityDaySelected>(_onDaySelected);
    on<CreateActivityTimeSelected>(_onTimeSelected);
    on<CreateActivityCapacityDecremented>(_onCapacityDecremented);
    on<CreateActivityCapacityIncremented>(_onCapacityIncremented);
    on<CreateActivityNotesChanged>(_onNotesChanged);
    on<CreateActivitySubmitted>(_onSubmitted);
  }

  static const _minCapacity = 2;
  static const _maxCapacity = 20;

  final CreateActivity _createActivity;
  final HomeLocation _location;

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

  void _onDaySelected(
    CreateActivityDaySelected event,
    Emitter<CreateActivityState> emit,
  ) {
    emit(
      state.copyWith(
        day: event.day,
        submissionStatus: CreateActivitySubmissionStatus.idle,
      ),
    );
  }

  void _onTimeSelected(
    CreateActivityTimeSelected event,
    Emitter<CreateActivityState> emit,
  ) {
    emit(
      state.copyWith(
        time: event.time,
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
    final result = await _createActivity(_draftFromState(state));
    result.fold(
      (failure) => emit(
        state.copyWith(
          submissionStatus: CreateActivitySubmissionStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (activityId) => emit(
        state.copyWith(
          submissionStatus: CreateActivitySubmissionStatus.success,
          createdActivityId: activityId,
        ),
      ),
    );
  }

  CreateActivityDraft _draftFromState(CreateActivityState state) {
    final title = state.title.trim();
    final notes = state.notes.trim();

    return CreateActivityDraft(
      categoryId: state.categoryId,
      title: title,
      description: notes.isEmpty ? 'Ik ga $title. Sluit gezellig aan.' : notes,
      latitude: _location.latitude,
      longitude: _location.longitude,
      addressLine: state.location.trim(),
      city: _location.cityName,
      countryCode: 'NL',
      startsAt: _startsAt(state.day, state.time),
      maxParticipants: state.capacity,
    );
  }

  DateTime _startsAt(String day, String time) {
    final now = DateTime.now();
    final parts = time.split(':');
    final hour = int.tryParse(parts.first) ?? 19;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final baseDate = switch (day) {
      'Morgen' => now.add(const Duration(days: 1)),
      'Weekend' => _nextSaturday(now),
      _ => now,
    };
    var startsAt = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      hour,
      minute,
    );

    if (!startsAt.isAfter(now)) {
      startsAt = startsAt.add(const Duration(days: 1));
    }
    return startsAt;
  }

  DateTime _nextSaturday(DateTime now) {
    const saturday = DateTime.saturday;
    final daysUntilSaturday = (saturday - now.weekday) % DateTime.daysPerWeek;
    return now.add(
      Duration(days: daysUntilSaturday == 0 ? 7 : daysUntilSaturday),
    );
  }
}
