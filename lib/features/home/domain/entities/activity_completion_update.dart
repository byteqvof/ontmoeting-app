import 'package:equatable/equatable.dart';

class ActivityCompletionUpdate extends Equatable {
  const ActivityCompletionUpdate({
    required this.activityId,
    required this.status,
  });

  final String activityId;
  final String status;

  @override
  List<Object?> get props => [activityId, status];
}
