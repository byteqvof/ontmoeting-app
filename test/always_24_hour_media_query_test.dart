import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/core/widgets/always_24_hour_media_query.dart';

void main() {
  testWidgets('forces 24 hour time format for picker children', (tester) async {
    bool? uses24HourClock;

    await tester.pumpWidget(
      MaterialApp(
        home: Always24HourMediaQuery(
          child: Builder(
            builder: (context) {
              uses24HourClock = MediaQuery.of(context).alwaysUse24HourFormat;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(uses24HourClock, isTrue);
  });
}
