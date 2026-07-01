import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/app/theme/app_theme.dart';
import 'package:meetings_app/app/widgets/toch_mark.dart';

void main() {
  testWidgets('renders the official Pip icon asset', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: TochMark()),
      ),
    );

    expect(find.byIcon(Icons.place_rounded), findsNothing);
    expect(
      find.byWidgetPredicate((widget) {
        if (widget is! Image || widget.image is! AssetImage) {
          return false;
        }
        return (widget.image as AssetImage).assetName ==
            'assets/pip/pip-icon.png';
      }),
      findsOneWidget,
    );
  });
}
