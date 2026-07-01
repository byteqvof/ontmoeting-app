import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/app/theme/app_theme.dart';
import 'package:meetings_app/features/profile/presentation/widgets/profile_agenda_shortcut_card.dart';
import 'package:meetings_app/features/profile/presentation/widgets/profile_menu_list.dart';

void main() {
  testWidgets('shows agenda shortcut for the current user profile', (
    tester,
  ) async {
    var openedAgenda = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ProfileMenuList(
            isOwnProfile: true,
            onAgendaPressed: () => openedAgenda = true,
            onSignOutPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('Agenda'), findsOneWidget);

    await tester.tap(find.text('Agenda'));

    expect(openedAgenda, isTrue);
  });

  testWidgets('does not show personal agenda on another profile', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ProfileMenuList(isOwnProfile: false, onSignOutPressed: () {}),
        ),
      ),
    );

    expect(find.text('Agenda'), findsNothing);
  });

  testWidgets('agenda shortcut card opens the agenda', (tester) async {
    var openedAgenda = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ProfileAgendaShortcutCard(onPressed: () => openedAgenda = true),
        ),
      ),
    );

    expect(find.text('Mijn agenda'), findsOneWidget);
    expect(
      find.text('Bekijk waar je meegaat en wat je organiseert.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Mijn agenda'));

    expect(openedAgenda, isTrue);
  });
}
