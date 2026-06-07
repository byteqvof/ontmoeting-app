import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/features/home/data/datasources/home_location_data_source.dart';
import 'package:meetings_app/features/home/domain/entities/home_location.dart';

void main() {
  test('returns default location immediately by default', () async {
    final dataSource = HomeLocationDataSourceImpl();

    final location = await dataSource.getCurrentLocation();

    expect(location, defaultHomeLocation);
  });
}
