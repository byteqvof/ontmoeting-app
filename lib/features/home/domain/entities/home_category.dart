import 'package:equatable/equatable.dart';

class HomeCategory extends Equatable {
  const HomeCategory({
    required this.id,
    required this.label,
    this.iconKey,
    this.colorHex,
    this.backgroundColorHex,
  });

  final String id;
  final String label;
  final String? iconKey;
  final String? colorHex;
  final String? backgroundColorHex;

  @override
  List<Object?> get props => [id, label, iconKey, colorHex, backgroundColorHex];
}
