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

final class CreateActivityMeetingLocationSearchRequested
    extends CreateActivityEvent {
  const CreateActivityMeetingLocationSearchRequested(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class CreateActivityMeetingLocationSelected extends CreateActivityEvent {
  const CreateActivityMeetingLocationSelected(this.location);

  final ResolvedMeetingLocation location;

  @override
  List<Object?> get props => [location];
}

final class CreateActivityDateShortcutSelected extends CreateActivityEvent {
  const CreateActivityDateShortcutSelected(this.shortcut);

  final String shortcut;

  @override
  List<Object?> get props => [shortcut];
}

final class CreateActivityDateSelected extends CreateActivityEvent {
  const CreateActivityDateSelected(this.date);

  final DateTime date;

  @override
  List<Object?> get props => [date];
}

final class CreateActivityTimeSelected extends CreateActivityEvent {
  const CreateActivityTimeSelected({required this.hour, required this.minute});

  final int hour;
  final int minute;

  @override
  List<Object?> get props => [hour, minute];
}

final class CreateActivityCapacityDecremented extends CreateActivityEvent {
  const CreateActivityCapacityDecremented();
}

final class CreateActivityCapacityIncremented extends CreateActivityEvent {
  const CreateActivityCapacityIncremented();
}

final class CreateActivityGroupTypeSelected extends CreateActivityEvent {
  const CreateActivityGroupTypeSelected(this.groupType);

  final String groupType;

  @override
  List<Object?> get props => [groupType];
}

final class CreateActivityMinReputationSelected extends CreateActivityEvent {
  const CreateActivityMinReputationSelected(this.reputationLevel);

  final String reputationLevel;

  @override
  List<Object?> get props => [reputationLevel];
}

final class CreateActivityPrivateLocationToggled extends CreateActivityEvent {
  const CreateActivityPrivateLocationToggled(this.isPrivateLocation);

  final bool isPrivateLocation;

  @override
  List<Object?> get props => [isPrivateLocation];
}

final class CreateActivityTargetAgeBandToggled extends CreateActivityEvent {
  const CreateActivityTargetAgeBandToggled(this.ageBand);

  final String ageBand;

  @override
  List<Object?> get props => [ageBand];
}

final class CreateActivityTargetGenderToggled extends CreateActivityEvent {
  const CreateActivityTargetGenderToggled(this.gender);

  final String gender;

  @override
  List<Object?> get props => [gender];
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
