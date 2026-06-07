import 'package:equatable/equatable.dart';

class HomeLocation extends Equatable {
  const HomeLocation({
    required this.cityName,
    required this.latitude,
    required this.longitude,
  });

  final String cityName;
  final double latitude;
  final double longitude;

  @override
  List<Object?> get props => [cityName, latitude, longitude];
}
