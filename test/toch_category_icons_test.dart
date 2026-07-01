import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/core/utils/toch_category_icons.dart';

void main() {
  group('tochCategoryIcon', () {
    test('maps backend category keys to the definitive TOCH icons', () {
      expect(
        tochCategoryIcon(iconKey: 'utensils', label: 'Eten en drinken'),
        Icons.restaurant_rounded,
      );
      expect(
        tochCategoryIcon(iconKey: 'palette', label: 'Cultuur'),
        Icons.palette_rounded,
      );
      expect(
        tochCategoryIcon(iconKey: 'trees', label: 'Buiten'),
        Icons.park_rounded,
      );
      expect(
        tochCategoryIcon(iconKey: 'dice-5', label: 'Spelletjes'),
        Icons.casino_rounded,
      );
    });

    test('uses category identity before stale generic icon keys', () {
      expect(
        tochCategoryIcon(id: 'vissen', label: 'Vissen', iconKey: 'grid_view'),
        Icons.phishing_rounded,
      );
      expect(
        tochCategoryIcon(id: 'coffee', label: 'Koffie', iconKey: 'tag'),
        Icons.local_cafe_rounded,
      );
    });

    test('falls back to a branded activity icon instead of the old grid', () {
      expect(
        tochCategoryIcon(
          id: 'unknown',
          label: 'Onbekend',
          iconKey: 'grid_view',
        ),
        Icons.local_activity_rounded,
      );
    });
  });
}
