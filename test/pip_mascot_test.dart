import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/app/theme/app_theme.dart';
import 'package:meetings_app/app/widgets/pip_mascot.dart';

void main() {
  testWidgets('renders Pip mascot from the official asset set', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: PipMascot(expression: PipExpression.proud)),
      ),
    );

    expect(find.byType(PipMascot), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(PipMascot),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
    expect(
      find.byWidgetPredicate((widget) {
        if (widget is! Image || widget.image is! AssetImage) {
          return false;
        }
        return (widget.image as AssetImage).assetName ==
            'assets/pip/pip-trots.png';
      }),
      findsOneWidget,
    );
  });
}
