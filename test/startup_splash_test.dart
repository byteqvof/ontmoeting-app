import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/app/theme/app_theme.dart';
import 'package:meetings_app/app/widgets/toch_mark.dart';
import 'package:meetings_app/app/widgets/toch_wordmark.dart';
import 'package:meetings_app/features/onboarding/presentation/pages/splash_page.dart';

void main() {
  test(
    'startup has one Flutter splash layer after the native launchscreen',
    () {
      final mainDart = File('lib/main.dart').readAsStringSync();

      expect(mainDart, isNot(contains('_StartupSplashApp')));
      expect(mainDart, isNot(contains('FutureBuilder<void>')));
      expect(mainDart, contains('await _initializeApplication();'));
      expect(mainDart, contains('runApp(const App());'));
    },
  );

  test('native launchscreens use the TOCH splash background consistently', () {
    final androidV31Styles = File(
      'android/app/src/main/res/values-v31/styles.xml',
    ).readAsStringSync();
    final iosStoryboard = File(
      'ios/Runner/Base.lproj/LaunchScreen.storyboard',
    ).readAsStringSync();

    expect(androidV31Styles, contains('@color/toch_green'));
    expect(
      androidV31Styles,
      isNot(
        contains(
          '<item name="android:windowBackground">@drawable/launch_background</item>',
        ),
      ),
    );
    expect(iosStoryboard, contains('red="0.1176470588"'));
    expect(iosStoryboard, contains('green="0.3411764706"'));
    expect(iosStoryboard, contains('blue="0.2509803922"'));
    expect(
      File(
        'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png',
      ).existsSync(),
      isTrue,
    );
  });

  testWidgets('Flutter splash matches the single launchscreen design', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const SplashPage()),
    );

    expect(find.byType(TochWordmark), findsOneWidget);
    expect(find.byType(TochMark), findsNothing);
    expect(find.text('Ik ga toch.'), findsNothing);
    expect(find.text('Ga je mee?'), findsNothing);
    expect(find.text('TIK OM TE STARTEN'), findsNothing);
  });
}
