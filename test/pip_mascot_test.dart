import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/app/theme/app_theme.dart';
import 'package:meetings_app/app/widgets/pip_mascot.dart';

void main() {
  testWidgets('renders Pip mascot as a reusable brand component', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: PipMascot(expression: PipExpression.proud)),
      ),
    );

    expect(find.byType(PipMascot), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
