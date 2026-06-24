import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/app/theme/app_theme.dart';
import 'package:meetings_app/features/home/domain/entities/home_category.dart';
import 'package:meetings_app/features/home/presentation/widgets/home_discovery_controls.dart';

void main() {
  testWidgets('keeps distance and category chips collapsed behind filter', (
    tester,
  ) async {
    var selectedDistance = 10;
    var openedAdvancedFilters = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: HomeDiscoveryControls(
            timeFilters: const ['Alles', 'Vandaag', 'Dit weekend'],
            selectedTimeFilter: 'Alles',
            onTimeSelected: (_) {},
            distances: const [5, 10, 25, 50],
            selectedDistanceKm: selectedDistance,
            onDistanceSelected: (value) => selectedDistance = value,
            categories: const [
              HomeCategory(
                id: 'outside',
                label: 'Buiten',
                icon: Icons.grid_view_rounded,
                color: Color(0xFF1E5740),
                backgroundColor: Color(0xFFE6EFE9),
              ),
            ],
            selectedCategoryIds: const [],
            onCategorySelected: (_) {},
            hasActiveFilters: false,
            onAdvancedFiltersPressed: () => openedAdvancedFilters = true,
          ),
        ),
      ),
    );

    expect(find.text('Alles'), findsOneWidget);
    expect(find.text('Filter'), findsOneWidget);
    expect(find.text('10 km'), findsNothing);
    expect(find.text('Buiten'), findsNothing);

    await tester.tap(find.text('Filter'));
    await tester.pumpAndSettle();

    expect(find.text('10 km'), findsOneWidget);
    expect(find.text('Buiten'), findsOneWidget);
    expect(find.text('Meer filters'), findsOneWidget);

    await tester.tap(find.text('5 km'));
    expect(selectedDistance, 5);

    await tester.tap(find.text('Meer filters'));
    expect(openedAdvancedFilters, isTrue);
  });
}
