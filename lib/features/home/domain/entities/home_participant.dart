import 'package:equatable/equatable.dart';

class HomeParticipant extends Equatable {
  const HomeParticipant({
    required this.id,
    required this.displayName,
    required this.initials,
    required this.isHost,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final String initials;
  final bool isHost;
  final String? avatarUrl;

  bool get canOpenProfile => id.isNotEmpty;

  @override
  List<Object?> get props => [id, displayName, initials, isHost, avatarUrl];
}
