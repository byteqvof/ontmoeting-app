import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/features/home/domain/entities/home_location.dart';

void main() {
  test('home location stores the resolved device coordinates', () {
    const location = HomeLocation(
      cityName: 'Amsterdam',
      latitude: 52.3676,
      longitude: 4.9041,
    );

    expect(location.cityName, 'Amsterdam');
    expect(location.latitude, 52.3676);
    expect(location.longitude, 4.9041);
  });
}
