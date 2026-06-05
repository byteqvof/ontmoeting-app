part of 'create_activity_bloc.dart';

sealed class CreateActivityEvent extends Equatable {
  const CreateActivityEvent();

  @override
  List<Object?> get props => [];
}

final class CreateActivityCategorySelected extends CreateActivityEvent {
  const CreateActivityCategorySelected(this.categoryId);

  final String categoryId;

  @override
  List<Object?> get props => [categoryId];
}

final class CreateActivityTitleChanged extends CreateActivityEvent {
  const CreateActivityTitleChanged(this.title);

  final String title;

  @override
  List<Object?> get props => [title];
}

final class CreateActivityLocationChanged extends CreateActivityEvent {
  const CreateActivityLocationChanged(this.location);

  final String location;

  @override
  List<Object?> get props => [location];
}

final class CreateActivityDaySelected extends CreateActivityEvent {
  const CreateActivityDaySelected(this.day);

  final String day;

  @override
  List<Object?> get props => [day];
}

final class CreateActivityTimeSelected extends CreateActivityEvent {
  const CreateActivityTimeSelected(this.time);

  final String time;

  @override
  List<Object?> get props => [time];
}

final class CreateActivityCapacityDecremented extends CreateActivityEvent {
  const CreateActivityCapacityDecremented();
}

final class CreateActivityCapacityIncremented extends CreateActivityEvent {
  const CreateActivityCapacityIncremented();
}

final class CreateActivityNotesChanged extends CreateActivityEvent {
  const CreateActivityNotesChanged(this.notes);

  final String notes;

  @override
  List<Object?> get props => [notes];
}

final class CreateActivitySubmitted extends CreateActivityEvent {
  const CreateActivitySubmitted();
}
