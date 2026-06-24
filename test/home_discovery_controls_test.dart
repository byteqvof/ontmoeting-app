import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/app/theme/app_theme.dart';
import 'package:meetings_app/features/home/presentation/widgets/home_discovery_controls.dart';
import 'package:meetings_app/features/home/presentation/widgets/home_header.dart';

void main() {
  testWidgets('shows only date filters on the homepage controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: HomeDiscoveryControls(
            timeFilters: const ['Alles', 'Vandaag', 'Dit weekend'],
            selectedTimeFilter: 'Alles',
            onTimeSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Alles'), findsOneWidget);
    expect(find.text('Vandaag'), findsOneWidget);
    expect(find.text('Dit weekend'), findsOneWidget);
    expect(find.text('Filter'), findsNothing);
    expect(find.text('10 km'), findsNothing);
    expect(find.text('Buiten'), findsNothing);
  });

  testWidgets('opens filters from the header button next to search', (
    tester,
  ) async {
    var openedFilters = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: HomeHeader(
            locationName: 'Groningen',
            onLocationTap: () {},
            hasActiveFilters: false,
            onFilterTap: () => openedFilters = true,
          ),
        ),
      ),
    );

    expect(find.byTooltip('Zoeken'), findsOneWidget);
    expect(find.byTooltip('Filters'), findsOneWidget);

    await tester.tap(find.byTooltip('Filters'));
    expect(openedFilters, isTrue);
  });
}
