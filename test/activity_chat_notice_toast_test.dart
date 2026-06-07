import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/app/theme/app_theme.dart';
import 'package:meetings_app/features/home/domain/entities/activity_chat_notice.dart';
import 'package:meetings_app/features/home/presentation/widgets/activity_chat_notice_host.dart';

void main() {
  testWidgets('chat notice toast shows activity, sender, preview and action', (
    tester,
  ) async {
    final notice = ActivityChatNotice(
      id: 'message-1',
      activityId: 'activity-1',
      senderId: 'profile-2',
      senderName: 'Sanne',
      senderInitials: 'S',
      activityTitle: 'Avondvissen aan de Maas',
      body: 'Top, ik neem extra aas mee, zien we elkaar bij de steiger?',
      createdAt: DateTime(2026, 6, 6, 21),
      isMine: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ActivityChatNoticeToast(notice: notice, onOpen: () {}),
        ),
      ),
    );

    expect(find.text('Avondvissen aan de Maas'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('Sanne: Top, ik neem extra aas'),
      ),
      findsOneWidget,
    );
    expect(find.text('ig'), findsOneWidget);
  });
}
