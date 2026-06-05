import 'package:equatable/equatable.dart';

class ProfileInterest extends Equatable {
  const ProfileInterest({
    required this.id,
    required this.label,
    required this.iconKey,
    required this.foregroundColorHex,
    required this.backgroundColorHex,
  });

  final String id;
  final String label;
  final String iconKey;
  final String foregroundColorHex;
  final String backgroundColorHex;

  @override
  List<Object?> get props => [
    id,
    label,
    iconKey,
    foregroundColorHex,
    backgroundColorHex,
  ];
}
