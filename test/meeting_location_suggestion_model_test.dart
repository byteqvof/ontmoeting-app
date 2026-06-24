import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/features/home/data/models/meeting_location_suggestion_model.dart';

void main() {
  test('maps locations-search response to a location suggestion', () {
    final suggestion = MeetingLocationSuggestionModel.fromJson(const {
      'id': 'pdok-id',
      'label': 'Markeweg 23, 9561 AB Ter Apel',
      'address_line': 'Markeweg 23, 9561 AB Ter Apel',
      'city': 'Ter Apel',
      'postcode': '9561 AB',
      'type': 'adres',
      'latitude': 52.876,
      'longitude': 7.059,
      'source': 'pdok',
    });

    expect(suggestion.id, 'pdok-id');
    expect(suggestion.addressLine, 'Markeweg 23, 9561 AB Ter Apel');
    expect(suggestion.city, 'Ter Apel');
    expect(suggestion.postcode, '9561 AB');
    expect(suggestion.type, 'adres');
    expect(suggestion.latitude, 52.876);
    expect(suggestion.longitude, 7.059);
    expect(suggestion.source, 'pdok');
  });

  test('accepts camelCase addressLine fallback', () {
    final suggestion = MeetingLocationSuggestionModel.fromJson(const {
      'id': 'pdok-id',
      'label': 'Ter Apel',
      'addressLine': 'Ter Apel',
      'city': 'Ter Apel',
      'type': 'woonplaats',
      'latitude': '52.876',
      'longitude': '7.059',
    });

    expect(suggestion.addressLine, 'Ter Apel');
    expect(suggestion.source, 'pdok');
    expect(suggestion.latitude, 52.876);
    expect(suggestion.longitude, 7.059);
  });
}
