import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/features/home/data/datasources/home_location_data_source.dart';

void main() {
  test('throws when device location is disabled', () async {
    final dataSource = HomeLocationDataSourceImpl();

    await expectLater(
      dataSource.getCurrentLocation(),
      throwsA(isA<StateError>()),
    );
  });
}
